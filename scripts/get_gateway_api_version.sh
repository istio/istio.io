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
if [[ $GATEWAY_VERSION == *"-"* ]]; then
  #echo "Found -, GATEWAY_VERSION=${GATEWAY_VERSION}"
  if ! [[ $GATEWAY_VERSION =~ -rc ]]; then
    #echo "Not -rcN, unpublished GATEWAY_VERSION=${GATEWAY_VERSION}"
    SHORT_SHA=$(echo "$GATEWAY_VERSION" | awk -F '-' '{ print $NF }')
    GATEWAY_VERSION=$(curl -s -L -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/kubernetes-sigs/gateway-api/commits/"${SHORT_SHA}" | jq -r .sha)
  else
    GATEWAY_VERSION=$(echo "$GATEWAY_VERSION" | awk '{ match($0, /-rc[.]?[0-9]+/); print substr($0, 1, RSTART+RLENGTH-1) }')
    #echo "Published -rcN, GATEWAY_VERSION=${GATEWAY_VERSION}"
  fi
fi

if [[ $GATEWAY_VERSION == "null" ]]; then
  GATEWAY_VERSION=$(grep k8s_gateway_api_version data/args.yml | cut -d '"' -f2)
fi

echo "$GATEWAY_VERSION"
