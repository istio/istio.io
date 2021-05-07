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
#          docs/tasks/observability/kiali/index.md
####################################################################################################

snip_generating_a_service_graph_1() {
kubectl -n istio-system get svc kiali
}

snip_generating_a_service_graph_2() {
curl "http://$GATEWAY_URL/productpage"
}

snip_generating_a_service_graph_3() {
watch -n 1 curl -o /dev/null -s -w "%{http_code}" "$GATEWAY_URL/productpage"
}

snip_generating_a_service_graph_4() {
istioctl dashboard kiali
}

snip_creating_weighted_routes_1() {
watch -n 1 curl -o /dev/null -s -w "%{http_code}" "$GATEWAY_URL/productpage"
}

snip_validating_istio_configuration_1() {
kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"foo"}]'
}

snip_validating_istio_configuration_2() {
kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
}

snip_viewing_and_editing_istio_configuration_yaml_1() {
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
}

snip_viewing_and_editing_istio_configuration_yaml_2() {
kubectl delete -f samples/bookinfo/networking/destination-rule-all.yaml
}

snip_cleanup_1() {
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.10/samples/addons/kiali.yaml
}
