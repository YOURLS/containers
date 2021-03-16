#!/bin/bash

#Usage:
#	% ./start.bash
#or:
#	% ./start.bash "stack-pgsql.yml"

exec docker-compose -f "${1:-stack.yml}" up --build

exit ${?}
