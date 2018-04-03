#!/bin/sh

echo "starting docker-entrypoint.sh with argument: $1"

if [[ $1 == "sleep" ]]; then
    echo "sleeping forever"
    tail -f /dev/null
    exit 0
fi

if [[ ! -v MYSQL_SERVER ]]; then
    echo 'MYSQL_SERVER was not set'
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

echo "Connecting to $MYSQL_SERVER:3306"
wait-for-it $MYSQL_SERVER:3306 -t 300 -- echo "mysql is up"

# bash if statement syntax: https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php

if [[ $1 == "backup" ]]; then
    echo "backup command received"
    if [[ ! -v BACKUP_NAME_PREFIX ]]; then
        echo 'BACKUP_NAME_PREFIX was not set'
        exit 1
    fi    

    # bash date formats: https://zxq9.com/archives/795
    today=`date '+%Y%m%d_%H%M%S'`;
    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE="/var/lib/mysql/${BACKUP_NAME_PREFIX}_${today}.sql"
    # $MYSQL_DATABASE

    echo "Backing up to $BACKUP_FILE"
    mysqldump -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD"  $MYSQL_DATABASE > "$BACKUP_FILE"
    echo "Finished backing up to $BACKUP_FILE"
 
elif [[ $1 == "backupall" ]]; then
    echo "backupall command received"
    if [[ ! -v BACKUP_NAME_PREFIX ]]; then
        echo 'BACKUP_NAME_PREFIX was not set'
        exit 1
    fi    

    # bash date formats: https://zxq9.com/archives/795
    today=`date '+%Y%m%d_%H%M%S'`;
    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE="/var/lib/mysql/${BACKUP_NAME_PREFIX}_${today}.sql"
    # $MYSQL_DATABASE

    echo "Backing up all databases to $BACKUP_FILE"
    mysqldump -h $MYSQL_SERVER -u "root" -p"$MYSQL_ROOT_PASSWORD" --all-databases > "$BACKUP_FILE"
    echo "Finished backing up all databases to $BACKUP_FILE"

elif [[ $1 == "restore" ]]; then

    echo "restore command received"

    if [[ ! -v BACKUP_NAME ]]; then
        echo 'BACKUP_NAME was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_ROOT_PASSWORD ]]; then
        echo 'MYSQL_ROOT_PASSWORD was not set'
        exit 1
    fi    

    # to restore 
    # mysql -h [hostname] -u [uname] -p[pass] [db_to_restore] < [backupfile.sql]

    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME}.sql"
    # $MYSQL_DATABASE
    
    echo "restoring from $BACKUP_FILE"

    # restoring requires root privileges
    mysql -h $MYSQL_SERVER -u "root" -p"$MYSQL_ROOT_PASSWORD" $MYSQL_DATABASE < "$BACKUP_FILE"

    echo "Finished restoring from $BACKUP_FILE"    
elif [[ $1 == "restoreall" ]]; then

    echo "restoreall command received"

    if [[ ! -v BACKUP_NAME ]]; then
        echo 'BACKUP_NAME was not set'
        exit 1
    fi    
    if [[ ! -v MYSQL_ROOT_PASSWORD ]]; then
        echo 'MYSQL_ROOT_PASSWORD was not set'
        exit 1
    fi    

    # to restore 
    # mysql -h [hostname] -u [uname] -p[pass] [db_to_restore] < [backupfile.sql]

    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME}.sql"
    # $MYSQL_DATABASE
    
    echo "restoring from $BACKUP_FILE"

    # restoring requires root privileges
    mysql -h $MYSQL_SERVER -u "root" -p"$MYSQL_ROOT_PASSWORD" < "$BACKUP_FILE"

    echo "Finished restoring from $BACKUP_FILE"    
else
    echo "No command was passed in.  Use the args property in kubernetes to pass in a command (sleep, backup or restore)"
fi
