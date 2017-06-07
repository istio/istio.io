#!/bin/bash

# This script builds and pushes the current branch
# to a firebase project
# The ci token produced by 'firebase login:ci'
# MUST have access to the given projects

PROJECT_ID=${PROJECT_ID:?"PROJECT_ID required"}
FIREBASE_TOKEN=${FIREBASE_TOKEN:?"FIREBASE_TOKEN required"}

if [[ -z ${INDOCKER} ]];then
	docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll \
		-e PROJECT_ID=$PROJECT_ID \
		-e FIREBASE_TOKEN=$FIREBASE_TOKEN \
		-e INDOCKER=true \
		jekyll/jekyll scripts/build.sh
else
	set -e
	# The directory now is /srv/jekyll inside the container
	# TODO bake a new docker image with correct versions from bundler 
	jekyll build
	npm install -g firebase-tools
	firebase use $PROJECT_ID --non-interactive --token $FIREBASE_TOKEN
	firebase deploy --public _site --non-interactive --token $FIREBASE_TOKEN
fi

