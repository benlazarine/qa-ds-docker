#! /bin/bash

set -e


terse_start()
{
  local svc="$1"
  local startCmd="$2"

  printf 'Starting %s: ' "$svc"

  if err=$(eval "$startCmd 2>&1 > /dev/null")
  then
    printf 'SUCCESS\n'
    return 0
  else
    printf 'FAILURE\n'
    printf '%s\n' "$err"
    return 1
  fi
}
export -f terse_start


start_postgresql()
{
  terse_start postgresql "su --command '/usr/pgsql-9.3/bin/pg_ctl -w start' --login postgres"
  exit "$?"
}
export -f start_postgresql


start_rabbitmq()
{
  terse_start rabbitmq-server '/etc/init.d/rabbitmq-server start'
  exit "$?"
}
export -f start_rabbitmq


parallel --no-notice eval ::: start_postgresql start_rabbitmq
terse_start irods "/etc/init.d/irods start && su --command '/usr/bin/iadmin modresc demoResc host $(hostname)' --login irods"

bash
