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

set -x

# Download the Istio source if not available.
if [[ ! -d "${ISTIO_GO}" ]]
then
    git clone https://github.com/istio/istio.git "${ISTIO_GO}"
fi

export ISTIO_BRANCH=${ISTIO_BRANCH:-master}

# Switch to the selected branch and build/install istioctl
pushd "${ISTIO_GO}"
git checkout "${ISTIO_BRANCH}"
go install ./istioctl/cmd/istioctl
popd

# Copy install/samples files over from Istio. These are needed by the tests.
rm -rf "${ISTIOIO_GO}/install"
cp -a "${ISTIO_GO}/install" "${ISTIOIO_GO}/install"

rm -rf "${ISTIOIO_GO}/samples"
cp -a "${ISTIO_GO}/samples" "${ISTIOIO_GO}/samples"

# For generating junit.xml files
echo "Installing go-junit-report..."
unset GOOS && unset GOARCH && CGO_ENABLED=1 go get github.com/jstemmer/go-junit-report
