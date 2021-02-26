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
#          boilerplates/kubectl-multicluster-contexts.md
####################################################################################################

bpsnip_kubectl_multicluster_contexts__1() {
kubectl config get-contexts
}

! read -r -d '' bpsnip_kubectl_multicluster_contexts__1_out <<\ENDSNIP
CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
*         cluster1   cluster1   user@foo.com   default
          cluster2   cluster2   user@foo.com   default
ENDSNIP

bpsnip_kubectl_multicluster_contexts__2() {
export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')
echo "CTX_CLUSTER1 = ${CTX_CLUSTER1}, CTX_CLUSTER2 = ${CTX_CLUSTER2}"
}

! read -r -d '' bpsnip_kubectl_multicluster_contexts__2_out <<\ENDSNIP
CTX_CLUSTER1 = cluster1, CTX_CLUSTER2 = cluster2
ENDSNIP
