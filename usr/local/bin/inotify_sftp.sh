#!/bin/bash
set -ex

WATCH_DIR='/opt/test'
REMOTE_DIR='/hfq'
PID_FILE='/var/run/inotify_sftp.pid'
REMOTE_ADDRESS='172.16.0.200'
KEY_FILE='~/.ssh/id_rsa'

# verify inotify installed
if ! which inotifywait &> /dev/null; then
    echo "dont have inotifywait command."
    exit 1
elif ! which lftp &> /dev/null; then
    exit 2
fi

echo $$ > $PID_FILE

# init main progress
inotifywait -mrq --format '%T %e %w%f' --timefmt='%Y-%m-%d/%H:%M:%S' -e modify,create,move  $WATCH_DIR |\
while read time mothod file; do
    ssh-agent bash -c "ssh-add $KEY_FILE & lftp -u sftp-user, -e \"mirror -R  $WATCH_DIR $REMOTE_DIR; bye\" sftp://$REMOTE_ADDRESS  -p 56000"
    echo "[$time] sync the $file, inotify mothod is ${mothod}." >> /var/log/inotify-sftp-$(date +%F).log
done
