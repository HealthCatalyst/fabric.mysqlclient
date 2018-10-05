#!/bin/sh

echo "starting docker-entrypoint.sh version 2018.04.16.01 with argument: $1"


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

if [[ ! -v COMMAND_TO_RUN ]]; then
    if [[ ! -z $1 ]]; then
        COMMAND_TO_RUN=$1
    fi
fi    

if [[ ! -v COMMAND_TO_RUN ]]; then
    echo 'COMMAND_TO_RUN was not set'
    exit 1
fi

echo "Command to run= $COMMAND_TO_RUN"

echo "Connecting to $MYSQL_SERVER:3306"
wait-for-it $MYSQL_SERVER:3306 -t 300 -- echo "mysql is up"

# bash if statement syntax: https://ryanstutorials.net/bash-scripting-tutorial/bash-if-statements.php

if [[ $COMMAND_TO_RUN == "backup" ]]; then
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
 
elif [[ $COMMAND_TO_RUN == "backupall" ]]; then
    echo "backupall command received"
    if [[ ! -v BACKUP_NAME_PREFIX ]]; then
        echo 'BACKUP_NAME_PREFIX was not set'
        exit 1
    fi    

    if [[ ! -v MYSQL_ROOT_PASSWORD ]]; then
        echo 'MYSQL_ROOT_PASSWORD was not set'
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

elif [[ $COMMAND_TO_RUN == "restore" ]]; then

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
elif [[ $COMMAND_TO_RUN == "restoreall" ]]; then

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
elif [[ $COMMAND_TO_RUN == "monitor" ]]; then

    if [[ -z "$ENVNAME" ]]; then
        echo "ERROR: ENVNAME is empty"
        exit 1
    fi

    if [[ -z "$SLACKURL" ]]; then
        echo "SLACKURL is empty"
        SLACKURL="https://hooks.slack.com/services/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"
    fi

    if [[ -z "$SLEEPINTERVAL" ]]; then
        echo "SLEEPINTERVAL is empty.  Defaulting to 5 seconds"
        SLEEPINTERVAL="5"
    fi

    if [[ -z "$INTERVALBETWEENMESSAGES" ]]; then
        echo "INTERVALBETWEENMESSAGES is empty"
        INTERVALBETWEENMESSAGES="5"
    fi

    curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$ENVNAME Started monitoring MySql server $MYSQL_SERVER every $SLEEPINTERVAL seconds"'"}' "$SLACKURL"

    declare -i numberOfTimesFailed
    declare -i sleepTimeInSeconds

    declare -i timeLastSentSlackMessage
    declare -i intervalBetweenSendingSlackMessages

    timeLastSentSlackMessage=$SECONDS

    sleepTimeInSeconds=$SLEEPINTERVAL
    intervalBetweenSendingSlackMessages=$INTERVALBETWEENMESSAGES

    hasFailed=false

    while true
    do
        result=$(mysql -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE -e "show tables;")
        if [ $? != 0 ]; then
            echo "$(date -Iseconds) MySql failed: $result"
            hasFailed=true
            numberOfTimesFailed=$numberOfTimesFailed+1
            timeSinceLastSentSlackMessage=$((SECONDS - timeLastSentSlackMessage))
            echo "Time since last sent slack message: $timeSinceLastSentSlackMessage"
            if [[ $timeSinceLastSentSlackMessage -gt $intervalBetweenSendingSlackMessages ]]; then
                curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$ENVNAME MySql Failed($numberOfTimesFailed): $MYSQL_SERVER"'", "attachments":[{"text":"'"$result"'"}]}' "$SLACKURL"
                echo ""
                timeLastSentSlackMessage=$SECONDS
            else
                echo "Cannot send slack message since we sent one $timeSinceLastSentSlackMessage seconds ago and the minimum interval is  $intervalBetweenSendingSlackMessages"
            fi
        else
            echo "$(date -Iseconds) All is good now"
            numberOfTimesFailed=0
            if [ "$hasFailed" = true ] ; then
                curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$ENVNAME MySql is now working"'"}' "$SLACKURL"
                hasFailed=false
            fi
        fi

        echo "$(date -Iseconds) Sleeping for $sleepTimeInSeconds"
        sleep $sleepTimeInSeconds
    done
else
    echo "No command was passed in.  Use the args property in kubernetes to pass in a command (sleep, backup or restore)"
    mysql -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE -e "show tables;"
#    mysql -h $MYSQL_SERVER -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQL_DATABASE -e "select * from users;"
    echo "You can connect to mysqlserver:"
    echo "mysql -h $MYSQL_SERVER -u $MYSQL_USER -p $MYSQL_DATABASE"


fi

if [[ $COMMAND_TO_RUN == "sleep" ]]; then
    echo "sleeping forever via tail -f /dev/null"
    tail -f /dev/null
    exit 0
fi