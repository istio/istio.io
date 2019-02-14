#!/usr/bin/env bash

HUB=gcr.io/istio-testing
VERSION=$(date +%Y-%m-%d)
VERSION=2019-02-13

docker build --no-cache -t $HUB/website-builder:$VERSION .
docker push $HUB/website-builder:$VERSION
