terracotta-scripts: tmcRestClient.sh
==================

A script to perform Terracotta management operations (enable/disable caches, clear caches, enable) directly from shell.
Currently supported operations are:
 - enable/disable caches, 
 - clear caches, 
 - enable/disable statistics

## Dependencies

This script sends HTTP requests to the Terracotta REST API endpoint [Terracotta Manager Server](http://terracotta.org/documentation/4.0/tms/tms-rest-api) using CURL, and parse JSON response using [JQ](http://stedolan.github.io/jq/download/)

 - A Running [Terracotta Management Server](http://terracotta.org/documentation/4.0/tms)
 - [CURL](http://curl.haxx.se/)
 - [JQ](http://stedolan.github.io/jq/download/)

## Install

First, get the tmcRestClient script:

      curl -L http://raw.githubusercontent.com/lanimall/terracotta-scripts/master/tmc-restclient/tmcRestClient.sh > tmcRestClient.sh

And make it executable:

    chmod 755 tmcRestClient.sh

Then, if not available already, install CURL for your target platform. 
It's of course recommended to use your favorite package manager for the target platform.

Finally, get [JQ](http://stedolan.github.io/jq/download/) binaries for your target platform, and put it in the same path as tmcRestClient. Also, make it executable:

    chmod 755 jq

## Configuration

Edit the tmcRestClient.sh, and specify the right "TMC_URL" variable for your environment.

Note: TMC_URL should contain the URL to the "Terracotta REST API endpoint"...(does not have to be localhost...)

## Running

    ./tmcRestClient.sh -o <operations> -a <Agents> -m <cache Maganagers> -c <Cache>

Options: 
 - "-o": Operation to perform (“clear”, “disable”, “enable")
 - "-a": List of agents (comma-separated), or “all” for all cache agents
 - "-m": List of cache managers (comma-separated), or “all” for all cache managers
 - "-c": List of caches (comma-separated), or "all" for all caches
 
Sample commands:

Disable all the caches:

    ./tmcRestClient.sh -a all -o disable -m all -c all

Enable all the caches:

    ./tmcRestClient.sh -a all -o enable -m all -c all

Disable CACHE1 CACHE2 caches only:

    ./tmcRestClient.sh -a all -o disable -m all -c CACHE1,CACHE2

Enable CACHE1 CACHE2 caches only:

    ./tmcRestClient.sh -a all -o enable -m all -c CACHE1,CACHE2

Clear CACHE1 CACHE2 caches only:

    ./tmcRestClient.sh -a all -o clear -m all -c CACHE1,CACHE2

Clear all caches:

    ./tmcRestClient.sh -a all -o clear -m all -c all
