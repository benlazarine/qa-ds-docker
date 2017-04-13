FROM centos:6
MAINTAINER tedgin@cyverse.org

#
# Install PostgreSQL
#

RUN yum --assumeyes install \
        https://download.postgresql.org/pub/repos/yum/9.3/redhat/rhel-6-x86_64/pgdg-centos93-9.3-3.noarch.rpm
RUN yum --assumeyes install postgresql93-server
RUN su --command '/usr/pgsql-9.3/bin/initdb --auth ident \
                                            --locale en_US.UTF-8 \
                                            --lc-collate C \
                                            --pgdata /var/lib/pgsql/9.3/data' \
       postgres

COPY postgresql/* /var/lib/pgsql/9.3/data/

RUN /etc/init.d/postgresql-9.3 start && \
    su --command "psql --command 'CREATE DATABASE \"ICAT\"' && \
                  psql --command \"CREATE USER irods WITH PASSWORD 'testpassword'\" && \
                  psql --command 'GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO irods'" \
       --login postgres && \
    /etc/init.d/postgresql-9.3 stop

EXPOSE 5432/tcp

#
# Install RabbitMQ
#

RUN yum --assumeyes install epel-release wget
RUN yum --assumeyes install \
        https://www.rabbitmq.com/releases/rabbitmq-server/v3.3.1/rabbitmq-server-3.3.1-1.noarch.rpm

RUN rabbitmq-plugins enable rabbitmq_management
RUN /etc/init.d/rabbitmq-server start && \
    wget --output-document /sbin/rabbitmqadmin http://localhost:15672/cli/rabbitmqadmin && \
    chmod +x /sbin/rabbitmqadmin && \
    su --command 'rabbitmqctl add_vhost /qa-3/data-store && \
                  rabbitmqctl set_permissions -p /qa-3/data-store guest ".*" ".*" ".*"' \
       --login rabbitmq && \
    rabbitmqadmin --vhost /qa-3/data-store declare exchange name=irods type=topic && \
    /etc/init.d/rabbitmq-server stop

EXPOSE 5672/tcp

#
# Install iRODS
#

RUN yum --assumeyes install sudo

RUN yum --assumeyes install \
        ftp://ftp.renci.org/pub/irods/releases/4.1.10/centos6/irods-icat-4.1.10-centos6-x86_64.rpm \
        ftp://ftp.renci.org/pub/irods/releases/4.1.10/centos6/irods-database-plugin-postgres93-1.10-centos6-x86_64.rpm

COPY irods/etc/service_account.config irods/etc/*.re /etc/irods/

RUN adduser --system --comment 'iRODS Administrator' --home-dir /var/lib/irods irods
RUN chown --recursive irods:irods /var/lib/irods /etc/irods

COPY irods/setup_irods.in .

RUN /etc/init.d/postgresql-9.3 start && \
    /var/lib/irods/packaging/setup_irods.sh < setup_irods.in && \
    /etc/init.d/postgresql-9.3 stop

RUN rm setup_irods.in

COPY irods/etc/database_config.json irods/etc/server_config.json /etc/irods/
COPY irods/var/irods_environment.json /var/lib/irods/.irods/irods_environment.json

RUN chown --recursive irods:irods /etc/irods /var/lib/irods/.irods/irods_environment.json

EXPOSE 1247/tcp 20000-20009/tcp 20000-20009/udp

#
# Install bootstrap
# 

RUN wget --directory-prefix /etc/yum.repos.d/ \
         http://download.opensuse.org/repositories/home:/tange/CentOS_CentOS-6/home:tange.repo
RUN yum --assumeyes install parallel

COPY bootstrap.sh .

ENTRYPOINT ["/bootstrap.sh"]
