#!/usr/bin/env bash
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

source "content/en/docs/ambient/upgrade/helm/all-in-one/common.sh"
source "content/en/docs/ambient/upgrade/helm/all-in-one/snips.sh"

# @setup profile=none
_install_istio_ambient_helm_aio

snip_update_helm

_rewrite_helm_repo snip_upgrade_ambient_aio
_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

# @cleanup

_remove_istio_ambient_helm_aio
