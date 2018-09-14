#!/bin/bash

# This script generates and copies helm charts within the helm tree of this repo.

# Initial setup
ISTIO_BASE=$(cd "$(dirname "$0")/.." ; pwd -P)
CHARTS_TARGET_DIR=${ISTIO_BASE}/static/charts
WORK_DIR=$(mktemp -d)
HELM_DIR=$(mktemp -d)

echo WORK_DIR = $WORK_DIR
echo HELM_DIR = $HELM_DIR
echo CHARTS_TARGET_DIR = $CHARTS_TARGET_DIR

# Helm setup
HELM_BUILD_DIR=${HELM_DIR}/istio-repository
HELM_IMAGE=linkyard/docker-helm:2.10.0
HELM="docker run -t -i --user $UID --rm -v ${HELM_DIR}:${HELM_DIR} -v ${WORK_DIR}:${WORK_DIR} -w $WORK_DIR $HELM_IMAGE --home $HELM_DIR"
# If you don't have or can't run docker, uncomment the following line
#HELM="helm --home $HELM_DIR"

# The repos to mine for charts, just add new entries here to pull in more repos.
REPOS=(
    https://github.com/istio/istio.git@master
)

# Charts to extract from repos
CHARTS=(
  ${WORK_DIR}/istio/install/kubernetes/helm/istio
  ${WORK_DIR}/istio/install/kubernetes/helm/istio-remote
)

# Prepare the work directory by cloning all the repos into it.
mkdir -vp $WORK_DIR
pushd $WORK_DIR
for repo in "${REPOS[@]}"
do
    REPO_URL=$(echo $repo | cut -d @ -f 1)
    REPO_BRANCH=$(echo $repo | cut -d @ -f 2)

    git clone -b $REPO_BRANCH $REPO_URL
done
popd

# Prepare helm setup
mkdir -vp $HELM_DIR
$HELM init --client-only

# Create a package for each charts and build the repo index.
mkdir -vp $HELM_BUILD_DIR
for CHART_PATH in "${CHARTS[@]}"
do
    $HELM package $CHART_PATH -d $HELM_BUILD_DIR
done
$HELM repo index $HELM_BUILD_DIR

# Copy the new built helm repo to the target dir.
mkdir -vp $CHARTS_TARGET_DIR
cp -vr ${HELM_BUILD_DIR}/* $CHARTS_TARGET_DIR

# Do the cleanup.
rm -fr ${HELM_DIR}
rm -fr ${WORK_DIR}
