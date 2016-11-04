#!/bin/bash

#######CONFIG#######
workpath=/home/yorsh/work
devserver=95.213.237.199
devport=1759
devuser=root
testdomain=test.mryorsh.org
#####################

fullpath=$workpath/$2

docker &> /dev/null

if [[ $? -eq 127 ]]; then
    echo "Get and install Docker"
    which wget &> /dev/null #check availability wget
    if [[ $? -eq 127 ]]; then
        sudo apt-get update
        sudo apt-get install wget -yq
    fi
    wget -qO- https://get.docker.com/ | sh
    sudo groupadd docker
    sudo usermod -aG docker $USER
fi

curl &> /dev/null #check availability curl

if [[ $? -eq 127 ]]; then
    echo "Install curl"
    sudo apt-get update
    sudo apt-get install curl -yq
fi

docker-compose &> /dev/null

if [[ $? -eq 127 ]]; then
    echo "Get and install docker-compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.8.1/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

tar &> /dev/null #check availability tar

if [[ $? -eq 127 ]]; then
    echo "Get and install tar"
    sudo apt-get update
    sudo apt-get install tar -yq
fi

git &> /dev/null #check availability git

if [[ $? -eq 127 ]]; then
    echo "Get and install tar"
    sudo apt-get update
    sudo apt-get install git-core -yq
fi

function checkProjectName(){

    if ! [[ $1 ]]; then
        echo "Format: [action] [project name] [type]"
        echo "Use --help to get help"
        exit 1
    fi

}

function newProject(){

    checkProjectName "$1"
    if [ -d $fullpath/ ]; then
        echo 'Project already exist!'
        exit 1
    fi

    mkdir -p $fullpath/src/wp-content
    mkdir -p $fullpath/src/db
    mkdir -p $fullpath/src/logs
    mkdir -p $fullpath/__files

    cp -r ./example-project/* $fullpath/
    cp -r ./docker/* $fullpath/src/

    cd $fullpath/src
    git init

}

function runDocker(){

    checkProjectName "$1"
    cd $fullpath/src
    echo "start docker"
    docker-compose build #remove after debugging
    docker-compose up -d
    echo "Wait 15 seconds for loading mysql..."
    sleep 15
    echo "Project is available at http://localhost"
    dbImport "$1"

}

function stopDocker(){

    dbDump "$1"
    docker-compose stop
    docker-compose rm -v --force

}

function dbImport(){

    checkProjectName "$1"
    echo "Import Mysql dump file"
    cd $fullpath/src
    docker exec -i src_mysql_1 mysql -u root -pdocker wordpress < ./db/dump.sql

}

function dbDump(){

    checkProjectName "$1"
    echo "Creating Mysql dump file"
    cd $fullpath/src
    docker exec src_mysql_1 mysqldump -u root -pdocker wordpress > ./db/dump.sql

}

function backup(){

    dbDump "$3"
    cd $fullpath
    tar -cvzf  $2-$3-backup-`date +%d-%m-%Y-%H-%M-%S`.tar.gz .$1 --exclude='*.tar.gz' --exclude='*.log'

}

function deploy(){

    dbDump "$1"
    rsync -e="ssh -p $devport" -avz --exclude '__*' --exclude '*.log' --exclude '.git' $fullpath $devuser@$devserver:$workpath
    ssh $devuser@$devserver -p $devport 'cd '$fullpath'/src/db;find -name dump.sql -print0 | xargs -0 sed -i "s|localhost|'$testdomain'|g";cd /home/wp-docker;./run.sh start '$1';'

}

function printHelp(){

    echo -e "
    \t\taction 'new' - create new project\b
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
    'new')
        newProject "$2"
        ;;
    'start')
        runDocker "$2"
        ;;
    'stop')
        stopDocker "$2"
        ;;
    'b') #create www and db backup
        backup "/src" "src" "$2"
        ;;
    'bf') #create full project backup
        backup "" "full" "$2"
        ;;
    'd') #create db dump
        dbDump "$2"
        ;;
    '--help') #Print help info
        printHelp
        ;;
    'i') #import db dump 
        dbImport "$2"
        ;;
    'deploy') #deploy for test server
        deploy "$2"
        ;;
    *)
        printHelp
        ;;
esac;

exit 0