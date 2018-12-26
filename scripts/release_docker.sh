#!/bin/bash

echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker build -t $DOCKER_USERNAME/$APP_NAME:$1 .
docker push $DOCKER_USERNAME/$APP_NAME:$1
