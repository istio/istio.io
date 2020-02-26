#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

export ISTIO_REMOTE=${ISTIO_REMOTE:-origin}
export ISTIO_BRANCH=${ISTIO_BRANCH:-master}

echo "ISTIOIO_GO=${ISTIOIO_GO}"
echo "ISTIO_GO=${ISTIO_GO}"
echo "ISTIO_REMOTE=${ISTIO_REMOTE}"
echo "ISTIO_BRANCH=${ISTIO_BRANCH}"

# Download the Istio source if not available.
if [[ -d "${ISTIO_GO}" ]]
then
  echo "${ISTIO_GO} already exists. Using existing repository ..."
else
  echo "${ISTIO_GO} not found. Cloning Istio repository ..."
  git clone https://github.com/istio/istio.git "${ISTIO_GO}"
fi

pushd "${ISTIO_GO}" > /dev/null

REMOTE_BRANCH="${ISTIO_REMOTE}/${ISTIO_BRANCH}"

# Switch to latest for requested branch if possible
if [ -z "$(git status --porcelain)" ]; then
  # Get updates to the remote repository
  git fetch "$ISTIO_REMOTE"

  # Switch to the desired local branch (create if necessary)
  git checkout -B "${ISTIO_BRANCH}"

  LOCAL_REV=$(git rev-parse @)
  REMOTE_REV=$(git rev-parse "${REMOTE_BRANCH}")
  BASE_REV=$(git merge-base @ "${REMOTE_BRANCH}")

  if [[ "${LOCAL_REV}" == "${REMOTE_REV}" ]]; then
    echo "Istio already up-to-date with ${REMOTE_BRANCH}"
  elif [[ "${LOCAL_REV}" == "${BASE_REV}" ]]; then
    echo "WARNING: Istio is out-of-date with ${REMOTE_BRANCH}. Merging remote changes."
    git pull "${ISTIO_REMOTE}" "${ISTIO_BRANCH}"
  elif [[ "${REMOTE_REV}" == "${BASE_REV}" ]]; then
    echo "WARNING: Istio is ahead of ${REMOTE_BRANCH}. Using local branch."
  else
    echo "WARNING: Istio has diverged with ${REMOTE_BRANCH}. Using local branch."
  fi

else
  echo "WARNING: Istio has uncommitted changes. To use latest from ${REMOTE_BRANCH} clear your local changes."
fi

# Build and install istioctl
go install ./istioctl/cmd/istioctl

popd > /dev/null

# Copy install/samples files over from Istio. These are needed by the tests.
rm -rf "${ISTIOIO_GO}/install" "${ISTIOIO_GO}/samples"
cp -a "${ISTIO_GO}/install" "${ISTIOIO_GO}/install"
cp -a "${ISTIO_GO}/samples" "${ISTIOIO_GO}/samples"

# For generating junit.xml files
echo "Installing go-junit-report..."
unset GOOS && unset GOARCH && CGO_ENABLED=1 go get github.com/jstemmer/go-junit-report
