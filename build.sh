#! /bin/bash

readonly AMQP_MGMT_PORT=15672
readonly AMQP_BROKER_PORT=5672
readonly AMQP_VHOST=/qa-fun/data-store
readonly AMQP_USER=guest
readonly AMQP_EXCHANGE=irods
readonly DBMS_PORT=5432
readonly DBMS_DB=ICAT
readonly DBMS_USER=irods
readonly DBMS_PASSWORD=testpassword
readonly IRODS_SYSTEM_USER=irods
readonly IRODS_SYSTEM_GROUP=irods
readonly IRODS_ZONE_PORT=1247
readonly IRODS_FIRST_TRANSPORT_PORT=20000
readonly IRODS_LAST_TRANSPORT_PORT=20009

readonly BaseDir=$(dirname "$0")

docker build --build-arg AMQP_MGMT_PORT="$AMQP_MGMT_PORT" \
             --build-arg AMQP_BROKER_PORT="$AMQP_BROKER_PORT" \
             --build-arg AMQP_VHOST="$AMQP_VHOST" \
             --build-arg AMQP_USER="$AMQP_USER" \
             --build-arg AMQP_EXCHANGE="$AMQP_EXCHANGE" \
             --build-arg DBMS_PORT="$DBMS_PORT" \
             --build-arg DBMS_DB="$DBMS_DB" \
             --build-arg DBMS_USER="$DBMS_USER" \
             --build-arg DBMS_PASSWORD="$DBMS_PASSWORD" \
             --build-arg IRODS_SYSTEM_USER="$IRODS_SYSTEM_USER" \
             --build-arg IRODS_SYSTEM_GROUP="$IRODS_SYSTEM_GROUP" \
             --build-arg IRODS_ZONE_PORT="$IRODS_ZONE_PORT" \
             --build-arg IRODS_FIRST_TRANSPORT_PORT="$IRODS_FIRST_TRANSPORT_PORT" \
             --build-arg IRODS_LAST_TRANSPORT_PORT="$IRODS_LAST_TRANSPORT_PORT" \
             --file "$BaseDir"/Dockerfile \
             --tag qa-ds \
             "$BaseDir"
 
