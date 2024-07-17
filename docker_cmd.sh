#!/bin/bash

check_leader() {
  sleep 10s
  while true; do
    leader_status=$(docker ps -f name=leader --format '{{.Status}}')
    if [[ ${leader_status} != *"Up"* ]]; then
      exit
    fi
    sleep 5s
  done
}

check_leader &
check_pid=$!

"$@" &
cmd_pid=$!

wait -n

if ! kill -0 $check_pid 2>/dev/null; then
  echo "Leader is down, exiting..."
  exit 137
fi

if ! kill -0 $cmd_pid 2>/dev/null; then
  exit
fi
