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

set -e

GATEWAY_VERSION=$(grep gateway-api go.mod | awk '{ print $2 }')
#echo "GATEWAY_VERSION=${GATEWAY_VERSION}"
if [[ $GATEWAY_VERSION == *"-rc"* ]]; then
  GATEWAY_VERSION=$(echo "$GATEWAY_VERSION" | awk -F '.0.202' '{ print $1 }')
#  echo "Found -rc, GATEWAY_VERSION=${GATEWAY_VERSION}"
else
  if [[ $GATEWAY_VERSION == *"-"* ]]; then
    SHORT_SHA=$(echo "$GATEWAY_VERSION" | awk -F '-' '{ print $NF }')
    GATEWAY_VERSION=$(curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/kubernetes-sigs/gateway-api/commits/"${SHORT_SHA}" | jq -r .sha)
#   echo "Found -, GATEWAY_VERSION=${GATEWAY_VERSION}"
# else
#   echo "no - or -rc found"
  fi
fi
echo "$GATEWAY_VERSION"
