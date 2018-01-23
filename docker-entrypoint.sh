#!/bin/sh

echo 'starting docker-entrypoint.sh'

echo "Connecting to $MYSQL_SERVER:3306"
wait-for-it $MYSQL_SERVER:3306 -t 300 -- echo "mysql is up"

if( "$DOBACKUP" -eq "true" )
{
    today=`date '+%Y_%m_%d__%H_%M_%S'`;
    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME}-${today}.sql"
    # $MYSQL_DATABASE

    echo "Backing up to $BACKUP_FILE"
    mysqldump -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE > $BACKUP_FILE
}
else
{
    # to restore 
    # mysql -h [hostname] -u [uname] -p[pass] [db_to_restore] < [backupfile.sql]

    # MYSQL_USER
    # $MYSQL_PASSWORD
    BACKUP_FILE= "/var/lib/mysql/${BACKUP_NAME}.sql"
    # $MYSQL_DATABASE
    
    echo "restoring from $BACKUP_FILE"

    mysql -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE < $BACKUP_FILE
}
