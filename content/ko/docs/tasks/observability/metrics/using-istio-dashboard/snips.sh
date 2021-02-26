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
#          docs/tasks/observability/metrics/using-istio-dashboard/index.md
####################################################################################################
source "content/en/boilerplates/snips/trace-generation.sh"

snip_viewing_the_istio_dashboard_1() {
kubectl -n istio-system get svc prometheus
}

! read -r -d '' snip_viewing_the_istio_dashboard_1_out <<\ENDSNIP
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
prometheus   ClusterIP   10.100.250.202   <none>        9090/TCP   103s
ENDSNIP

snip_viewing_the_istio_dashboard_2() {
kubectl -n istio-system get svc grafana
}

! read -r -d '' snip_viewing_the_istio_dashboard_2_out <<\ENDSNIP
NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
grafana   ClusterIP   10.103.244.103   <none>        3000/TCP   2m25s
ENDSNIP

snip_viewing_the_istio_dashboard_3() {
istioctl dashboard grafana
}

snip_cleanup_1() {
killall kubectl
}
