#!/bin/bash
# Unix sucks bad.
trap 'kill -HUP 0' EXIT

cd "$( dirname "${BASH_SOURCE[0]}" )"

LOG_HOST=localhost
LOG_PORT=10102

exec 3>&1
./utils/websocketd --port=$LOG_PORT --address=$LOG_HOST bash -c "tee 1>&3" 1>&2 &

BROWSER="chromium --allow-file-access-from-files --disable-gpu-blacklist --user-data-dir=chromium-data --app="


APP="file://$PWD/webtrajsim/index.html?disableDefaultLogger=true&wsLogger=ws://$LOG_HOST:$LOG_PORT/&experiment=blindPursuit"

$BROWSER$APP
