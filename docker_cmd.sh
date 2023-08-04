#!/bin/bash
set -e

# run custom entrypoint commands
for CMD in $(compgen -v ENTRYPOINT_CMD); do
    if [ -n "${!CMD}" ] ; then
        eval "${!CMD}"
    fi
done

exec "$@"
