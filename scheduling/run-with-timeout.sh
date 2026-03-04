#!/bin/bash
# Usage: run-with-timeout.sh SECONDS COMMAND [ARGS...]
#
# Runs COMMAND with a watchdog that kills it after SECONDS.
# Sends SIGTERM first, then SIGKILL after 5s grace period.
#
# Why this exists: macOS launchd's TimeOut key only controls the
# SIGTERM-to-SIGKILL grace period when launchd STOPS a job. It does
# NOT cap execution time. Without this wrapper, a hung process runs
# forever and blocks future scheduled runs.
#
# Example:
#   run-with-timeout.sh 900 claude -p "/daily-summary"

TIMEOUT_SECS=$1
shift

"$@" &
CMD_PID=$!

(sleep "$TIMEOUT_SECS" && kill "$CMD_PID" 2>/dev/null && sleep 5 && kill -9 "$CMD_PID" 2>/dev/null) &
WATCHDOG_PID=$!

wait "$CMD_PID"
EXIT_CODE=$?

kill "$WATCHDOG_PID" 2>/dev/null
wait "$WATCHDOG_PID" 2>/dev/null
exit $EXIT_CODE
