#! /bin/bash

start_postgresql()
{
  su --command '/usr/pgsql-9.3/bin/pg_ctl -w start' --login postgres
}
export -f start_postgresql


start_rabbitmq()
{
   /etc/init.d/rabbitmq-server start
}
export -f start_rabbitmq


parallel --no-notice eval ::: start_postgresql start_rabbitmq
/etc/init.d/irods start
su --command "/usr/bin/iadmin modresc demoResc host $(hostname)" --login irods 
bash
