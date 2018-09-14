#!/bin/bash

# This script generate and copies helm charts within the helm tree of this repo.

ISTIO_BASE=$(cd "$(dirname "$0")" ; pwd -P)/..
export GOPATH=$(mktemp -d)
WORK_DIR=${GOPATH}/src/istio.io
CHART_OUTPUT_DIR=$ISTIO_BASE/helm
echo "WORK_DIR =" $WORK_DIR

# The repos to mine for charts, just add new entries here to pull in more repos.
REPOS=(
    https://github.com/istio/istio.git@master
)

# The charts to extracts from repos.
CHARTS=(
  ${WORK_DIR}/istio/install/kubernetes/helm/istio:istio
  ${WORK_DIR}/istio/install/kubernetes/helm/istio-remote:istio-remote
)

# Prepare the work directory by cloning all the repos into it
mkdir -p ${WORK_DIR}
pushd $WORK_DIR
for repo in "${REPOS[@]}"
do
    REPO_URL=$(echo $repo | cut -d @ -f 1)
    REPO_BRANCH=$(echo $repo | cut -d @ -f 2)

    git clone -b $REPO_BRANCH $REPO_URL
done
popd

# delete all the existing generated files so that any stale files are removed
rm -fr $WORK_DIR/helm/{*,.*}

helm init --client-only

for chart in "${CHARTS[@]}"
do
    CHART_PATH=$(echo $chart | cut -d : -f 1)
    CHART_NAME=$(echo $chart | cut -d : -f 2)

    helm package $CHART_PATH -d $CHART_OUTPUT_DIR
done

pushd $CHART_OUTPUT_DIR
helm repo index .
popd

rm -fr ${GOPATH}
