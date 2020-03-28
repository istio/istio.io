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

# Determine the SHA for the Istio dependency by parsing the go.mod file.
export ISTIO_SHA=${ISTIO_SHA:-$(< go.mod grep 'istio.io/istio v' | cut -d'-' -f3)}

echo "ISTIOIO_GO=${ISTIOIO_GO}"
echo "ISTIO_GO=${ISTIO_GO}"
echo "ISTIO_REMOTE=${ISTIO_REMOTE}"
echo "ISTIO_BRANCH=${ISTIO_BRANCH}"
echo "ISTIO_SHA=${ISTIO_SHA}"

# Download the Istio source if not available.
if [[ -d "${ISTIO_GO}" ]]
then
  echo "${ISTIO_GO} already exists. Using existing repository ..."
else
  echo "${ISTIO_GO} not found. Cloning Istio repository ..."
  git clone https://github.com/istio/istio.git "${ISTIO_GO}"
fi

pushd "${ISTIO_GO}" > /dev/null

# Get updates to the remote repository
git fetch "$ISTIO_REMOTE"

# Checkout the Istio version from the git dependency.
git checkout "$ISTIO_SHA"

# Build and install istioctl
go install ./istioctl/cmd/istioctl

popd > /dev/null

# Copy install/samples files over from Istio. These are needed by the tests.
rm -rf "${ISTIOIO_GO}/install" "${ISTIOIO_GO}/samples" "${ISTIOIO_GO}/tests/integration"
cp -a "${ISTIO_GO}/install" "${ISTIOIO_GO}/install"
cp -a "${ISTIO_GO}/samples" "${ISTIOIO_GO}/samples"
mkdir "${ISTIOIO_GO}/tests/integration/"
cp -a "${ISTIO_GO}/tests/integration/iop-integration-test-defaults.yaml" "${ISTIOIO_GO}/tests/integration/"

# For generating junit.xml files
echo "Installing go-junit-report..."
unset GOOS && unset GOARCH && CGO_ENABLED=1 go get github.com/jstemmer/go-junit-report
