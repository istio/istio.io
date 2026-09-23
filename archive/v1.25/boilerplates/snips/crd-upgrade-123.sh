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
#          boilerplates/crd-upgrade-123.md
####################################################################################################

bpsnip_crd_upgrade_123_adopt_legacy_crds() {
for crd in $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name)
do
   kubectl label "$crd" "app.kubernetes.io/managed-by=Helm"
   kubectl annotate "$crd" "meta.helm.sh/release-name=istio-base" # replace with actual Helm release name, if different from the documentation default
   kubectl annotate "$crd" "meta.helm.sh/release-namespace=istio-system" # replace with actual istio namespace
done
}
