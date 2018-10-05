docker stop fabric.mysqlclient
docker rm fabric.mysqlclient
docker pull healthcatalyst/fabric.baseos:latest
docker build -t healthcatalyst/fabric.mysqlclient . 

docker run --rm --name fabric.mysqlclient -e MYSQL_DATABASE=nlpmt -e MYSQL_SERVER=mysqlserver -e MYSQL_USER=foo -e MYSQL_PASSWORD=bar -e COMMAND_TO_RUN=monitor -t healthcatalyst/fabric.mysqlclient 

Start-Sleep 5

