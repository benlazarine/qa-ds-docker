FROM centos:6
MAINTAINER Tony Edgin <tedgin@cyverse.org>

#
# Create volume
#

RUN mkdir --parents /data/icat /data/vaults/default /logs && \
    chmod --recursive a+rwx /data /logs

#
# Install PostgreSQL
#

ARG DBMS_PORT=5432
ARG DBMS_DB=ICAT
ARG DBMS_USER=irods
ARG DBMS_PASSWORD=testpassword

ENV PGDATA /var/lib/pgsql/9.3

RUN yum --assumeyes install \
        https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-3.noarch.rpm && \
    yum --assumeyes install postgresql93-server && \
    chown postgres:postgres /data/icat && \
    su --command "sed --in-place 's|^PGDATA=.*|PGDATA=\"$PGDATA\"|' /var/lib/pgsql/.bash_profile && \
                  /usr/pgsql-9.3/bin/initdb --auth ident \
                                            --lc-collate C \
                                            --locale en_US.UTF-8 \
                                            --pgdata /data/icat" \
       postgres && \
    mv /data/icat/*.conf "$PGDATA"/

COPY postgresql/* "$PGDATA"/

RUN chown postgres:postgres "$PGDATA"/* && \
    su --command "/usr/pgsql-9.3/bin/pg_ctl -w start && \
                  psql --command 'CREATE DATABASE \"$DBMS_DB\"' && \
                  psql --command \"CREATE USER $DBMS_USER WITH PASSWORD '$DBMS_PASSWORD'\" && \
                  psql --command 'GRANT ALL PRIVILEGES ON DATABASE \"$DBMS_DB\" TO $DBMS_USER' && \
                  /usr/pgsql-9.3/bin/pg_ctl -w stop" \
       --login postgres

EXPOSE "$DBMS_PORT"/tcp

#
# Install RabbitMQ
#

ARG AMQP_MGMT_PORT=15672
ARG AMQP_BROKER_PORT=5672
ARG AMQP_VHOST=/data-store
ARG AMQP_USER=guest
ARG AMQP_EXCHANGE=irods

ENV RABBITMQ_LOG_BASE /logs

RUN yum --assumeyes install epel-release wget && \
    yum --assumeyes install \
        https://www.rabbitmq.com/releases/rabbitmq-server/v3.3.1/rabbitmq-server-3.3.1-1.noarch.rpm && \
    rabbitmq-plugins enable rabbitmq_management && \
    /etc/init.d/rabbitmq-server start && \
    wget --output-document /sbin/rabbitmqadmin \
         http://localhost:"$AMQP_MGMT_PORT"/cli/rabbitmqadmin && \
    chmod +x /sbin/rabbitmqadmin && \
    su --command "rabbitmqctl add_vhost '$AMQP_VHOST' && \
                  rabbitmqctl set_permissions -p '$AMQP_VHOST' '$AMQP_USER' '.*' '.*' '.*'" \
       --login rabbitmq && \
    rabbitmqadmin --vhost "$AMQP_VHOST" declare exchange name="$AMQP_EXCHANGE" type=topic && \
    /etc/init.d/rabbitmq-server stop

EXPOSE "$AMQP_BROKER_PORT"/tcp "$AMQP_MGMT_PORT"/tcp

#
# Install iRODS
#

ARG IRODS_SYSTEM_USER=irods
ARG IRODS_SYSTEM_GROUP=irods
ARG IRODS_ZONE_PORT=1247
ARG IRODS_FIRST_TRANSPORT_PORT=20000
ARG IRODS_LAST_TRANSPORT_PORT=20199

RUN yum --assumeyes install \
        sudo \
        ftp://ftp.renci.org/pub/irods/releases/4.1.10/centos6/irods-icat-4.1.10-centos6-x86_64.rpm \
        ftp://ftp.renci.org/pub/irods/releases/4.1.10/centos6/irods-database-plugin-postgres93-1.10-centos6-x86_64.rpm && \
    rmdir /var/lib/irods/iRODS/server/log && \
    ln --symbolic /logs /var/lib/irods/iRODS/server/log

COPY irods/etc/service_account.config irods/etc/*.re /etc/irods/

RUN adduser --system --comment 'iRODS Administrator' --home-dir /var/lib/irods \
            "$IRODS_SYSTEM_USER" && \
    chown --recursive "$IRODS_SYSTEM_USER":"$IRODS_SYSTEM_GROUP" \
          /var/lib/irods /etc/irods /data/vaults
 
COPY irods/setup_irods.in .

RUN su --command '/usr/pgsql-9.3/bin/pg_ctl -w start' --login postgres && \
    /var/lib/irods/packaging/setup_irods.sh < setup_irods.in && \
    su --command '/usr/pgsql-9.3/bin/pg_ctl -w stop' --login postgres && \
    rm --force setup_irods.in

COPY irods/etc/database_config.json irods/etc/server_config.json /etc/irods/
COPY irods/var/irods_environment.json /var/lib/irods/.irods/irods_environment.json

RUN chown --recursive "$IRODS_SYSTEM_USER":"$IRODS_SYSTEM_GROUP" \
          /etc/irods /var/lib/irods/.irods/irods_environment.json

EXPOSE "$IRODS_ZONE_PORT"/tcp \
       "$IRODS_FIRST_TRANSPORT_PORT"-"$IRODS_LAST_TRANSPORT_PORT"/tcp \
       "$IRODS_FIRST_TRANSPORT_PORT"-"$IRODS_LAST_TRANSPORT_PORT"/udp

#
# Install bootstrap
#

RUN wget --directory-prefix /etc/yum.repos.d/ \
         http://download.opensuse.org/repositories/home:/tange/CentOS_CentOS-6/home:tange.repo && \
    yum --assumeyes install parallel && \
    rm --force --recursive /logs/*

COPY bootstrap.sh .

VOLUME /data /logs

ENTRYPOINT ["/bootstrap.sh"]
