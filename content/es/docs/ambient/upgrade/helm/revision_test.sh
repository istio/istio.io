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

source "content/en/docs/ambient/upgrade/helm/common.sh"

# @setup profile=none
_install_istio_ambient_helm

export MYTAG=tagname

snip_list_revisions
snip_update_helm
snip_istioctl_precheck


_rewrite_helm_repo snip_upgrade_crds
_rewrite_helm_repo snip_upgrade_istiod_revisioned
_wait_for_deployment istio-system istiod-"$REVISION"
_rewrite_helm_repo snip_upgrade_ztunnel_revisioned
_wait_for_daemonset istio-system ztunnel
_rewrite_helm_repo snip_upgrade_cni
_wait_for_daemonset istio-system istio-cni-node
_rewrite_helm_repo snip_upgrade_gateway
_wait_for_deployment istio-ingress istio-ingress

snip_list_tags
_rewrite_helm_repo snip_upgrade_tag
_rewrite_helm_repo snip_rollback_tag

# @cleanup

# upgrading a tag creates an MWC, let's clean it up
export REVISION=istio-1-22-1
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{tagname}" --set revision="$OLD_REVISION" -n istio-system | kubectl delete -f -
helm delete istiod-"$REVISION" -n istio-system
snip_delete_old_revision
_remove_istio_ambient_helm
