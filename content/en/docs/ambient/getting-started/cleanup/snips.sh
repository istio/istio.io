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
#          docs/ambient/getting-started/cleanup/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-remove-crds.sh"

snip_remove_the_ambient_and_waypoint_labels_1() {
kubectl label namespace default istio.io/dataplane-mode-
kubectl label namespace default istio.io/use-waypoint-
}

snip_remove_waypoint_proxies_1() {
istioctl waypoint delete --all
}

snip_remove_the_sample_application_1() {
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl delete -f samples/curl/curl.yaml
}
