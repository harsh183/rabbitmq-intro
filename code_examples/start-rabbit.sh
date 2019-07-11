#!/usr/bin/env bash

NAME=rabbitmq

docker rm -f $NAME

docker run \
    -d \
    --hostname $NAME \
    --name $NAME \
    -p 5672:5672 \
    -p 15671:15671 \
    -p 15672:15672 \
    -p 15674:15674 \
    -p 15670:15670 \
    -p 61613:61613 \
    rabbit
