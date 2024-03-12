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
#          docs/setup/upgrade/helm/index.md
####################################################################################################
source "content/en/boilerplates/snips/helm-prereqs.sh"
source "content/en/boilerplates/snips/revision-tags-middle.sh"
source "content/en/boilerplates/snips/revision-tags-prologue.sh"

snip_upgrade_steps_1() {
istioctl x precheck
}

! read -r -d '' snip_upgrade_steps_1_out <<\ENDSNIP
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
ENDSNIP

snip_canary_upgrade_recommended_1() {
kubectl apply -f manifests/charts/base/crds
}

snip_canary_upgrade_recommended_2() {
helm install istiod-canary istio/istiod \
    --set revision=canary \
    -n istio-system
}

snip_canary_upgrade_recommended_3() {
kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
}

! read -r -d '' snip_canary_upgrade_recommended_3_out <<\ENDSNIP
  NAME                            READY   STATUS    RESTARTS   AGE   REV
  istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
  istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
ENDSNIP

snip_canary_upgrade_recommended_4() {
helm install istio-ingress-canary istio/gateway \
    --set revision=canary \
    -n istio-ingress
}

snip_canary_upgrade_recommended_5() {
kubectl get pods -L istio.io/rev -n istio-ingress
}

! read -r -d '' snip_canary_upgrade_recommended_5_out <<\ENDSNIP
  NAME                                    READY   STATUS    RESTARTS   AGE     REV
  istio-ingress-754f55f7f6-6zg8n          1/1     Running   0          5m22s   default
  istio-ingress-canary-5d649bd644-4m8lp   1/1     Running   0          3m24s   canary
ENDSNIP

snip_canary_upgrade_recommended_6() {
helm delete istiod -n istio-system
}

snip_canary_upgrade_recommended_7() {
helm upgrade istio-base istio/base --set defaultRevision=canary -n istio-system --skip-crds
}

snip_usage_1() {
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision=1-18-1 -n istio-system | kubectl apply -f -
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-canary}" --set revision=1-19-4 -n istio-system | kubectl apply -f -
}

snip_usage_2() {
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{prod-stable}" --set revision=1-19-4 -n istio-system | kubectl apply -f -
}

snip_default_tag_1() {
helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{default}" --set revision=1-19-4 -n istio-system | kubectl apply -f -
}

snip_in_place_upgrade_1() {
kubectl apply -f manifests/charts/base/crds
}

snip_in_place_upgrade_2() {
helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
}

snip_in_place_upgrade_3() {
helm upgrade istiod istio/istiod -n istio-system
}

snip_in_place_upgrade_4() {
helm upgrade istio-ingress istio/gateway -n istio-ingress
}
