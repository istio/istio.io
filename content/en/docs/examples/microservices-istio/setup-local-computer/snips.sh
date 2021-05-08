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
#          docs/examples/microservices-istio/setup-local-computer/index.md
####################################################################################################

snip__1() {
export KUBECONFIG="<the file you received or created in the previous module>"
}

snip__2() {
kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
}

! read -r -d '' snip__2_out <<\ENDSNIP
tutorial
ENDSNIP

snip__3() {
istioctl version
}

! read -r -d '' snip__3_out <<\ENDSNIP
client version: 1.7.0
control plane version: 1.7.0
data plane version: 1.7.0 (4 proxies)
ENDSNIP
