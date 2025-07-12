#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/ambient/upgrade/helm/index.md
####################################################################################################
source "content/en/boilerplates/snips/crd-upgrade-123.sh"

snip_istioctl_precheck() {
istioctl x precheck
}

! IFS=$'\n' read -r -d '' snip_istioctl_precheck_out <<\ENDSNIP
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
ENDSNIP

snip_update_helm() {
helm repo update istio
}

snip_list_revisions() {
kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
# Store your revision and new revision in variables:
export REVISION=istio-1-22-1
export OLD_REVISION=istio-1-21-2
}

snip_upgrade_crds() {
helm upgrade istio-base istio/base -n istio-system
}

snip_upgrade_istiod_inplace() {
helm upgrade istiod istio/istiod -n istio-system --wait
}

snip_upgrade_istiod_revisioned() {
helm install istiod-"$REVISION" istio/istiod -n istio-system --set revision="$REVISION" --set profile=ambient --wait
}

snip_upgrade_cni() {
helm upgrade istio-cni istio/cni -n istio-system
}

snip_upgrade_ztunnel_inplace() {
helm upgrade ztunnel istio/ztunnel -n istio-system --wait
}

snip_upgrade_ztunnel_revisioned() {
helm upgrade ztunnel istio/ztunnel -n istio-system --set revision="$REVISION" --wait
}

snip_list_tags() {
kubectl get mutatingwebhookconfigurations -l 'istio.io/tag' -L istio\.io/tag,istio\.io/rev
}

snip_upgrade_tag() {
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$REVISION" -n istio-system | kubectl apply -f -
}

snip_rollback_tag() {
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$OLD_REVISION" -n istio-system | kubectl apply -f -
}

snip_upgrade_gateway() {
helm upgrade istio-ingress istio/gateway -n istio-ingress
}

snip_delete_old_revision() {
helm delete istiod-"$OLD_REVISION" -n istio-system
}
