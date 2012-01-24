#!/bin/sh

source ./datacouch.conf

DC_SETUP_DIR=`pwd`

DC_BUILD_PORT=5914

if [ -z "$DATACOUCH_ADMIN_PASSWORD" ]
then
    echo "
    
    Set an admin name and passowrd in the datacouch.conf file,
    it should look like:

    DATACOUCH_ADMIN_NAME=\"yourusername\"
    DATACOUCH_ADMIN_PASSWORD=\"unguessable\"
    
    This a new name for a new db, it doesn't have
    to be the same as other couches on your system,
    if any are installed.

    "
    
    exit
fi

DC_REBAR_VSN=`which rebar`

if [ -z "$DC_REBAR_VSN" ]
then
    echo "
    
    adding rebar... if you want to
    keep this around post install, copy 
    `pwd`/rebar to /usr/local/bin...
    
    "
    git clone git://github.com/basho/rebar.git
    cd rebar
    ./bootstrap
    chmod +x rebar
    PATH=$PATH:`pwd`
fi

cd $DC_SETUP_DIR

if [ ! -d "$HOME/.rebar" ]
then
    mkdir "$HOME/.rebar"
fi

if [ ! -d "$HOME/.rebar/templates" ]
then
    mkdir "$HOME/.rebar/templates"
fi

cp -r ./datacouch_template "$HOME/.rebar/templates"

DC_NPM_EXECUTABLE=`which npm`

if [ ! NODE_EXECUTABLE ]; then
    echo "
    
    requires node from http://nodejs.org
    
    "
    exit
else 
    echo "using npm : $DC_NPM_EXECUTABLE"
fi

echo "getting datacouch..."

git clone https://github.com/bvmou/datacouch.git

rebar create template=datacouch appid=datacouch

echo "

    YOU MAY GET AN ERROR ABOUT THE README, FOR
    CONTENTS OF ORIGINAL README, SEE LOWER 2/3
    OF THE CURRENT ONE. ERROR IS INCONSEQUENTIAL

    "

make rel

$DC_SETUP_DIR/rel/datacouch/bin/datacouch start
echo "CouchDB 1.3 + GeoCouch running on port $DC_BUILD_PORT..."
echo "pushing Datacouch applications..."

sleep 3

curl -X PUT http://localhost:$DC_BUILD_PORT/datacouch
curl -X PUT http://localhost:$DC_BUILD_PORT/datacouch-users
curl -X PUT http://localhost:$DC_BUILD_PORT/datacouch-analytics
curl -X PUT http://localhost:$DC_BUILD_PORT/apps

curl -X POST http://localhost:5914/_replicate -d '{"target":"http://localhost:5914/apps","source":"http://max.iriscouch.com/apps", "create_target": true}' -H "Content-type: application/json"

cd $DC_SETUP_DIR/datacouch

node node_modules/couchapp/bin.js push app.js http://localhost:$DC_BUILD_PORT/datacouch
node node_modules/couchapp/bin.js push db.js http://localhost:$DC_BUILD_PORT/datacouch
node node_modules/couchapp/bin.js push users.js http://localhost:$DC_BUILD_PORT/datacouch-users
node node_modules/couchapp/bin.js push analytics.js http://localhost:$DC_BUILD_PORT/datacouch-analytics

sleep 2

curl -X PUT http://localhost:$DC_BUILD_PORT/_config/admins/$DATACOUCH_ADMIN_NAME -d \"$DATACOUCH_ADMIN_PASSWORD\"

sleep 2

echo "restarting (Data)CouchDB..."
$DC_SETUP_DIR/rel/datacouch/bin/datacouch restart

echo "  
    dont forget to add the following lines to /etc/hosts:
    
    127.0.0.1  datacouch.dev 
    127.0.0.1  couchdb.dev 

    Visit your new couch at http://localhost:5914/_utils and the app
    at http://datacouch.dev:5914
    "
