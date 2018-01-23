docker stop fabric.mysqlclient
docker rm fabric.mysqlclient
docker pull healthcatalyst/fabric.baseos:latest
docker build -t healthcatalyst/fabric.mysqlclient . 

docker run --rm --name fabric.mysqlclient -e MYSQL_DATABASE=nlpmt -t healthcatalyst/fabric.mysqlclient

sleep 5

