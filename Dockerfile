FROM healthcatalyst/fabric.baseos:latest

LABEL maintainer="imran.qureshi@healthcatalyst.com"


# install mariadb-client (i.e., mysql client) so we can wait for our tables to become ready
ADD mariadb.repo /etc/yum.repos.d/

RUN yum -y install MariaDB-client; yum clean all


ENTRYPOINT ["./docker-entrypoint.sh"]

