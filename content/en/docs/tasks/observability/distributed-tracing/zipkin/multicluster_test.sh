#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2034

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
set -u
set -o pipefail

# @setup profile=none
# @multicluster

# TODO: Remove this once we have a real multicluster test

echo "start multicluster test with KUBECONFIG=${KUBECONFIG}"

IFS=',' read -r -a CONFIGS <<< "${KUBECONFIG}"
for kcfg in "${CONFIGS[@]}"; do
  kubectl --kubeconfig="$kcfg" get pods -A
done

# @cleanup
set +e
echo "end multicluster test"