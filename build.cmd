docker stop fabric.mysqlclient
docker rm fabric.mysqlclient
docker pull healthcatalyst/fabric.baseos:latest
docker build -t healthcatalyst/fabric.mysqlclient . 

