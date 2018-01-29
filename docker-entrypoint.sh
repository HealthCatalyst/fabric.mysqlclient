#!/bin/sh

echo "starting docker-entrypoint.sh with argument: $1"

if [[ $1 == "shell" ]]; then
    bash
    exit 0
fi

if [[ ! -v MYSQL_SERVER ]]; then
    echo 'MYSQL_SERVER was not set'
    exit 1
fi 

echo "Connecting to $MYSQL_SERVER:3306"
wait-for-it $MYSQL_SERVER:3306 -t 300 -- echo "mysql is up"

if [[ -v DOBACKUP ]]; then
    if [[ ! -v BACKUP_NAME_PREFIX ]]; then
        echo 'BACKUP_NAME_PREFIX was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_USER ]]; then
        echo 'MYSQL_USER was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_PASSWORD ]]; then
        echo 'MYSQL_PASSWORD was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_DATABASE ]]; then
        echo 'MYSQL_DATABASE was not set'
        exit 1
    fi    

    today=`date '+%Y_%m_%d_%H_%M_%S'`;
    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME_PREFIX}_${today}.sql"
    # $MYSQL_DATABASE

    echo "Backing up to $BACKUP_FILE"
    mysqldump -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD"  $MYSQL_DATABASE > "$BACKUP_FILE"
else

    if [[ ! -v BACKUP_NAME ]]; then
        echo 'BACKUP_NAME was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_USER ]]; then
        echo 'MYSQL_USER was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_PASSWORD ]]; then
        echo 'MYSQL_PASSWORD was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_DATABASE ]]; then
        echo 'MYSQL_DATABASE was not set'
        exit 1
    fi    

    # to restore 
    # mysql -h [hostname] -u [uname] -p[pass] [db_to_restore] < [backupfile.sql]

    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME}.sql"
    # $MYSQL_DATABASE
    
    echo "restoring from $BACKUP_FILE"

    mysql -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE < "$BACKUP_FILE"
fi
