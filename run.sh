#!/bin/bash

#######CONFIG#######
devserver=IP_ADDRESS_TEST_SERVER
devport=22
devuser=root
testdomain=TEST_DOMAIN
#####################

#check availability wget
which wget &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Get and install wget"
    sudo apt-get update
    sudo apt-get install wget -yq
fi

#check availability docker
docker &> /dev/null 
if [[ $? -eq 127 ]]; then
    echo "Get and install docker"
    wget -qO- https://get.docker.com/ | sh
    sudo groupadd docker
    sudo usermod -aG docker $USER
fi

#check availability curl
curl &> /dev/null 
if [[ $? -eq 127 ]]; then
    echo "Get and install curl"
    sudo apt-get update
    sudo apt-get install curl -yq
fi

#check availability docker-compose
docker-compose &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Get and install docker-compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0-rc2/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

#check availability tar
tar &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Get and install tar"
    sudo apt-get update
    sudo apt-get install tar -yq
fi

#check availability git
git &> /dev/null
if [[ $? -eq 127 ]]; then
    echo "Get and install git"
    sudo apt-get update
    sudo apt-get install git-core -yq
fi

function runDocker(){

    cd src
    echo "start docker"
    docker-compose build #remove after debugging
    docker-compose up -d
    echo "Wait 15 seconds for loading mysql..."
    sleep 15
    echo "Project is available at http://localhost"
    dbImport

}

function stopDocker(){

    dbDump
    docker-compose stop
    docker-compose rm -v --force

}

function dbImport(){

    echo "Import Mysql dump file"
    cd src
    docker exec -i src_mysql_1 mysql -u root -pdocker wordpress < ./db/dump.sql
    cd ..

}

function dbDump(){

    echo "Creating Mysql dump file"
    cd src
    docker exec src_mysql_1 mysqldump -u root -pdocker wordpress > ./db/dump.sql
    cd ..

}

function backup(){

    dbDump
    tar -cvzf  backup-`date +%d-%m-%Y-%H-%M-%S`.tar.gz $1 --exclude='*.gz' --exclude='*.log'

}

function deploy(){

    dbDump
    rsync -e="ssh -p $devport" -avz --exclude '__*' --exclude '*.log' --exclude '.git' --exclude '*.gz' ./src $devuser@$devserver:/
    ssh $devuser@$devserver -p $devport 'cd /src/db;find -name dump.sql -print0 | xargs -0 sed -i "s|localhost|'$testdomain'|g";cd /src;docker-compose build;docker-compose up -d;sleep 15;echo "Import Mysql dump file";docker exec -i src_mysql_1 mysql -u root -pdocker wordpress < ./db/dump.sql;chown -R www-data:www-data *;'

}

function printHelp(){

    echo -e "
    \t\taction 'start' - runing docker\b
    \t\taction 'stop' - stoping docker\b
    \t\taction 'b' - creating www and db backup\b
    \t\taction 'bf' - creating full project backup\b
    \t\taction 'd' - creating db dump\b
    \t\taction 'i' - import db dump\b
    \t\taction 'deploy' - deploy project for test server\b
    "

}

case $1 in

    'start')
        runDocker
        ;;
    'stop')
        stopDocker
        ;;
    'b') #create www and db backup
        backup "./src"
        ;;
    'bf') #create full project backup
        backup "."
        ;;
    'd') #create db dump
        dbDump
        ;;
    '--help') #Print help info
        printHelp
        ;;
    'i') #import db dump 
        dbImport
        ;;
    'deploy') #deploy for test server
        deploy
        ;;
    *)
        printHelp
        ;;
esac;

exit 0