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
source "content/en/docs/setup/upgrade/helm/common.sh"
source "content/en/boilerplates/snips/args.sh"

set -e
set -u

set -o pipefail

# @setup profile=none

fullVersionRevision="${bpsnip_args_istio_full_version//./-}"
previousVersionRevision1="${bpsnip_args_istio_previous_version//./-}-1"

_install_istio_helm

snip_canary_upgrade_recommended_1
_rewrite_helm_repo snip_canary_upgrade_recommended_2
_wait_for_deployment istio-system istiod-canary

# shellcheck disable=SC2154
_verify_lines snip_canary_upgrade_recommended_3 "
+ default
+ canary
"

snip_canary_upgrade_recommended_6
_rewrite_helm_repo snip_canary_upgrade_recommended_7

_rewrite_helm_repo helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision="$previousVersionRevision1" -n istio-system | kubectl delete -f -
_rewrite_helm_repo helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-canary}" --set revision="$fullVersionRevision" -n istio-system | kubectl delete -f -
helm uninstall istiod-canary -n istio-system
_remove_istio_helm

# @cleanup
