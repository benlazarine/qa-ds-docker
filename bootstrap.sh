#! /bin/bash

readonly PriorServices=(postgresql-9.3 rabbitmq-server)

start_service() {
  local service="$1"

  eval "/etc/init.d/$service start"
}

export -f start_service

parallel --no-notice start_service ::: ${PriorServices[@]}

start_service irods

bash
