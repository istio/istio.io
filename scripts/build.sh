#!/bin/bash

#example: PROJECT_ID=istiodocs-v01 RELEASE=0.1 FIREBASE_TOKEN=aabbccdd ./scripts/build.sh

# This script builds and pushes the current branch
# to a firebase project
# The ci token produced by 'firebase login:ci'
# MUST have access to the given projects

PROJECT_ID=${PROJECT_ID:?"PROJECT_ID required"}
FIREBASE_TOKEN=${FIREBASE_TOKEN:?"FIREBASE_TOKEN required"}
RELEASE=${RELEASE:?"RELEASE is required"}

if [[ -z ${INDOCKER} ]];then
	docker run --rm --label=jekyll --volume=$(pwd):/srv/jekyll \
		-e PROJECT_ID=$PROJECT_ID \
		-e FIREBASE_TOKEN=$FIREBASE_TOKEN \
		-e INDOCKER=true \
		-e RELEASE=${RELEASE} \
		jekyll/jekyll scripts/build.sh
else
	set -e
	# The directory now is /srv/jekyll inside the container
	# TODO bake a new docker image with correct versions from bundler
	PUBLIC=_static_site
	rm -Rf ${PUBLIC} ; mkdir ${PUBLIC}
	echo "baseurl: /v-${RELEASE}" > config_override.yml
	jekyll build --config _config.yml,config_override.yml
	mv _site "${PUBLIC}/v-${RELEASE}"
	npm install -g firebase-tools
	firebase use $PROJECT_ID --non-interactive --token $FIREBASE_TOKEN
	firebase deploy --public ${PUBLIC} --non-interactive --token $FIREBASE_TOKEN
fi
