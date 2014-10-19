#!/bin/bash

TMC_URL="http://localhost:9889/tmc"
TMC_LOGIN_PATH="/login.jsp"
TMC_API_BASE="/api"
TMC_AGENT_INFO="$TMC_API_BASE/agents/info"

HTTP_JSON_HEADERS="Content-Type: application/json; charset=utf-8"
CURL_OPTIONS="-s" #-v
COOKIE_PATH="/tmp/tmccookie"

TMC_USER=
TMC_PASSWORD=

PRG="$0"
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
    else
    PRG=`dirname "$PRG"`/"$link"
    fi
done
PRGDIR=`dirname "$PRG"`
BASEDIR=`cd "$PRGDIR" > /dev/null; pwd`

JQ="$BASEDIR/jq"

function login()
{
    URL=$TMC_URL$TMC_LOGIN_PATH
    POSTPARAMS="username=$1&password=$2"
    HTTP_HEADERS="Accept: text/html,application/xml; Content-Type:application/x-www-form-urlencoded; charset=utf-8"
    OUTPUT=$(curl $CURL_OPTIONS -H "$HTTP_HEADERS" -d $POSTPARAMS -c $COOKIE_PATH -X POST $URL)
    RETVAL=$?
    return $RETVAL
}

function retrieveAllCacheAgents()
{
    URL=$TMC_URL$TMC_AGENT_INFO
    OUTPUT=$(curl $CURL_OPTIONS -H "$HTTP_JSON_HEADERS" -b $COOKIE_PATH $URL)
    RETVAL=$?
    
    echo $OUTPUT | $JQ '.[] | select(.agencyOf == "Ehcache") | .agentId' | tr "\\n" "," | sed 's/"//g' | sed 's/,$//'; echo ''
    return $RETVAL
}

function retrieveAllCacheManagers()
{
    CACHEFILTER=$(constructCacheURL $1)
    URL=$TMC_URL$TMC_API_BASE$CACHEFILTER
    OUTPUT=$(curl $CURL_OPTIONS -H "$HTTP_JSON_HEADERS" -b $COOKIE_PATH $URL)
    RETVAL=$?

    echo $OUTPUT | $JQ 'unique_by(.cacheManagerName)|.[].cacheManagerName' | tr "\\n" "," | sed 's/"//g' | sed 's/,$//'; echo ''
    return $RETVAL
}

function retrieveAllCacheManagerCaches()
{
    CACHEFILTER=$(constructCacheURL $1 $2)
    URL=$TMC_URL$TMC_API_BASE$CACHEFILTER
    OUTPUT=$(curl $CURL_OPTIONS -H "$HTTP_JSON_HEADERS" -b $COOKIE_PATH $URL)
    RETVAL=$?

    echo $OUTPUT | $JQ 'unique_by(.name)|.[].name' | tr "\\n" "," | sed 's/"//g' | sed 's/,$//'; echo ''
    return $RETVAL
}

function constructCacheURL()
{
    AGENTFILTER=$1
    CACHEMANAGERFILTER=$2
    CACHEFILTER=$3
    
    FULLFILTER="/agents"
    if [ "x$AGENTFILTER" != "x" ] ; then
        FULLFILTER="$FULLFILTER;ids=$AGENTFILTER"
    fi

    FULLFILTER="$FULLFILTER/cacheManagers"
    if [ "x$CACHEMANAGERFILTER" != "x" ] ; then
        FULLFILTER="$FULLFILTER;names=$CACHEMANAGERFILTER"
    fi

    FULLFILTER="$FULLFILTER/caches"
    if [ "x$CACHEFILTER" != "x" ] ; then
        FULLFILTER="$FULLFILTER;names=$CACHEFILTER"
    fi

    echo $FULLFILTER
    return 0 
}

# Takes 4 params:
# - agents (comma separated string)
# - cache managers (comma separated string)
# - caches (comma separated string)
# - "true" for enable, "false" for disable
function changeCacheState()
{
    AGENTIDS=$1
    CACHEMANAGERS=$2
    CACHES=$3   
    ENABLE=$4

    IFS=',' read -a arrAgentIds <<< "$AGENTIDS"
    IFS=',' read -a arrCacheMgr <<< "$CACHEMANAGERS"
    IFS=',' read -a arrCaches <<< "$CACHES"

    for agentid in "${arrAgentIds[@]}"
    do
        for cacheMgr in "${arrCacheMgr[@]}"
        do
            for cache in "${arrCaches[@]}"
            do
                CACHEFILTER=$(constructCacheURL $agentid $cacheMgr $cache)
                URL=$TMC_URL$TMC_API_BASE$CACHEFILTER
                BODY="{\"attributes\":{\"Enabled\":$ENABLE}}"
                OUTPUT=$(curl $CURL_OPTIONS -H "$HTTP_JSON_HEADERS" -b $COOKIE_PATH -d $BODY -X PUT $URL)
                RETVAL=$?
            done
        done
    done

    return $RETVAL
}

function print_success()
{
    echo "      [Success]"
}

function print_failure()
{
    echo "      [failure]"
}

while [[ $# > 1 ]]
do
key="$1"
shift

case $key in
    -a|--agentids)
        AGENTIDS="$1"
        shift
    ;;
    -m|--cachemgrs)
        CACHEMGRS="$1"
        shift
    ;;
    -c|--caches)
        CACHES="$1"
        shift
    ;;
    -o|--operation)
        OPS="$1"
        shift
    ;;
    --default)
        DEFAULT=YES
        shift
    ;;
    *)
        echo "Unknown Option"
        exit 1
    ;;
esac
done

login "$TMC_USER" "$TMC_PASSWORD"
if [ "$AGENTIDS" == "all" ]; then
    AGENTIDS=$(retrieveAllCacheAgents)
fi

if [ "$CACHEMGRS" == "all" ]; then
    CACHEMGRS=$(retrieveAllCacheManagers)
fi

if [ "$CACHES" == "all" ]; then
    CACHES=$(retrieveAllCacheManagerCaches)
fi

echo "OPERATION = ${OPS}"
echo "AGENTS = ${AGENTIDS}"
echo "CACHE MANAGERS = ${CACHEMGRS}"
echo "CACHES = ${CACHES}"
case "$OPS" in
    ""|"--help"|"-h"|"-?")
        echo "Syntax:"
        echo "$0 -o {enable,disable,clear}"
        exit 1
    ;;
    "enable")
        changeCacheState "$AGENTIDS" "$CACHEMGRS" "$CACHES" "true"
    ;;
    "disable")
        changeCacheState "$AGENTIDS" "$CACHEMGRS" "$CACHES" "false"
    ;;
    "clear")
    
    ;;
    *)
        echo "Unknown Option"
        echo "Syntax:"
        echo "$0 -o {enable,disable,clear}"
        exit 1
    ;;
esac
RETVAL=$?

dt=`date +%Y%m%d_%H%M%S`
echo -n "$dt - Operation submitted:"
if [ $RETVAL -eq 0 ]; then
    print_success
else
    print_failure
fi
exit $RETVAL