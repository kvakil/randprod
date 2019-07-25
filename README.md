# Productivity Tracking with Random Sampling

randprod is a productivity tracker based on sampling: it randomly
chooses times to ask about your current task. Because of this,
randprod doesn't require tedious tracking like manual productivity
managers.  Unlike automatic productivity trackers, randprod never
makes a mistake and can give finer grained insights into how you
spend your time.

<p align="center"><img src="https://raw.githubusercontent.com/kvakil/randprod/master/screenshot.png" /></p>

randprod outputs data to a CSV file, which you can munge using
your preferred tools. More notably, randprod is very simple, and
fits into roughly 25 lines of Bash:

```bash
#!/bin/bash
set -Eeuo pipefail
source config
readarray -t TASKS < tasks
[ -f "$OUTPUT_FILENAME" ] || echo Time,Task > "$OUTPUT_FILENAME"
MAX_RANDOM=$((2**15))
THRESHOLD=$((MAX_RANDOM / SAMPLE_RATE))
while : ; do
    if [ "$RANDOM" -lt "$THRESHOLD" ]; then
        printf "%s,%s\n" \
            "$(date +"%Y-%m-%dT%H:%M:%S%:z")" \
            "$(zenity --title=randprod --timeout="$TIMEOUT" \
                      --height "$HEIGHT" --list --column "Task" \
                      "${TASKS[@]}" || echo Timeout)" \
                      >> "$OUTPUT_FILENAME"
        sleep "$MIN_ALERT_SPACING"
    fi
    sleep 1
done
```
## Installation

Clone this repository or download the `zip` file from Github.

randprod runs in `bash(1)` (version 4+) and requires
[`zenity(1)`](https://en.wikipedia.org/wiki/Zenity), which should be
available on most Linux/Unix/BSD systems. On Debian based systems,
you can install it from the package repository:

    sudo apt install zenity

The file `config` contains some basic configuration variables--most
notably the list of tasks and how often to interrupt you will allow
interruptions for sampling.

## Why randprod?

Since there are more productivity trackers than there are people who
use productivity trackers, every productivity tracker must justify
its existence. There are two types of productivity trackers:

1. _Manual trackers_ make you input your activities throughout the
   day. For example, you might log "I am working on task X for the
   next 30 minutes".

2. _Automatic trackers_ work based on reading your window titles and
   seeing which applications you have open. Then you associate window
   titles with the corresponding task. For example, you might
   associate having `vim` open with "Programming", or having
   `nethack` open with "Gaming".

Manual tracking is rather difficult. It requires the user to keep
track of their [context
switches](https://en.wikipedia.org/wiki/Context_switch). I find this
tedious, and also rather error-prone: sometimes I switch contexts
without even realizing it, such as when I get an important email or
mindlessly open Hacker News.  Thinking about this context switching
does act as a good [forcing
function](https://en.wikipedia.org/wiki/Forcing_function) to stay on
task, but I feel that the tedium and possibility of forgetting
outweighs this benefit.

Automatic tracking requires very little user effort, but it can also
lead to misclassifications. For example, having "Firefox" open can
either mean that I am looking up technical documentation or reading
the news. I would like to differentiate between those two tasks.
While there are some more advanced automatic trackers which use the
stronger heuristics, these are still not 100% accurate.  Using these
sorts of trackers can represent a privacy concern, especially if it
sends the data to a third-party for analysis.

I wanted a productivity tracker which would work without requiring
that I constantly keep track of it, and would allow more
fine-grained control over which tasks I was doing. I also didn't
want to [spend a large amount of time developing
it](https://xkcd.com/1319/). The result is randprod. Although it
is very barebones, I've found it rather effective.


## Example Munging

A productivity tracker is not terribly useful without some way to get
data out of it. randprod's log is a simple CSV format, so it can be
imported by your preferred spreadsheet. You can also use tools like
[`sqlite3(1)`](https://sqlite.org/index.html) to easily craft complex
queries. For example, the following script outputs how often each
task was done on a per-day basis:

```sql
#!/bin/bash
echo "Day,Time"
source config

SECONDS_PER_HOUR=3600.0
EXPECTED_RATE=$((SAMPLE_RATE + MIN_ALERT_SPACING))

sqlite3 << EOF
.mode csv
.import "$OUTPUT_FILENAME" log
SELECT Day, "$EXPECTED_RATE" * COUNT() / "$SECONDS_PER_HOUR" FROM
(SELECT *, date(Time, 'localtime') as Day FROM log)
WHERE Task <> 'Timeout'
GROUP BY Day;
EOF
```

More sample scripts are included in the `sql/` directory.

## Possible Improvements

My personal experience after using randprod for a few months is
mostly positive. At first, the sampling feels a little intrusive, but
by now I rarely notice it. In fact, having the random sampling is a
good check. Sometimes I run off-task, and then the dialog box appears
and reminds me about the task I should be doing.

However, there are definitely some pain points:

- Sometimes a task doesn't fit into any of the current categories,
  but the current method only allows a fixed list of topics. The
  user should be allowed to dynamically enter tasks.

- randprod could track the more common tasks and display those at
  the top.

- The dialog occasionally pops up while typing, which can be very
  annoying. Sometimes I accidentally cancel the dialog with
  escape. It would be great to detect if the user was currently
  typing, and if so, do not display the dialog until they stop.

- There is some research into how unpredictable rewards can help
  reinforce behavior more strongly than predictable rewards. Using
  randprod along with a gamification method would help exploit
  this research.

- Augmenting randprod along with an automatic system and using the
  random sampling as a "validation" or for more data points could
  achieve the best of both worlds.
