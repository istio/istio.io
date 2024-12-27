#!/usr/bin/env bash
# shellcheck disable=SC2154
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
source "tests/util/samples.sh"
source "content/en/boilerplates/snips/args.sh"

set -e
set -u
set -o pipefail

# @setup profile=none

fullVersionRevision="${bpsnip_args_istio_full_version//./-}"
previousVersionRevision1="${bpsnip_args_istio_previous_version//./-}-1"

# setup two control plane revisions
snip_usage_1
_wait_for_deployment istio-system istiod-"$previousVersionRevision1"
_wait_for_deployment istio-system istiod-"$fullVersionRevision"

# tag the revisions
snip_usage_2

# deploy app namespaces and label them
snip_usage_3
snip_usage_4
_wait_for_deployment app-ns-1 sleep
_wait_for_deployment app-ns-2 sleep
_wait_for_deployment app-ns-3 sleep

# verify both the revisions are managing workloads
_verify_contains snip_usage_5 "istiod-$previousVersionRevision1"
_verify_contains snip_usage_5 "istiod-$fullVersionRevision"

# update the stable revision
snip_usage_6

# restart the older stable revision namespaces
snip_usage_7

# verify only the canary revision is managing workloads
_verify_not_contains snip_usage_8 "istiod-$previousVersionRevision1"
_verify_contains snip_usage_8 "istiod-$fullVersionRevision"

# @cleanup
snip_cleanup_1
istioctl uninstall --purge -y
snip_cleanup_3
kubectl get validatingwebhookconfiguration --no-headers=true | awk '/^istio/ {print $1}' | xargs kubectl delete validatingwebhookconfiguration
kubectl get mutatingwebhookconfiguration --no-headers=true | awk '/^istio/ {print $1}' | xargs kubectl delete mutatingwebhookconfiguration
