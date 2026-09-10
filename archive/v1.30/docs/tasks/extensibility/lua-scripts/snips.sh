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
#          docs/tasks/extensibility/lua-scripts/index.md
####################################################################################################

snip_apply_parity() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
}

snip_verify_parity_even() {
curl -s -o /dev/null -D - -H "x-number: 42" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
}

! IFS=$'\n' read -r -d '' snip_verify_parity_even_out <<\ENDSNIP
x-parity: even
ENDSNIP

snip_verify_parity_odd() {
curl -s -o /dev/null -D - -H "x-number: 7" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
}

! IFS=$'\n' read -r -d '' snip_verify_parity_odd_out <<\ENDSNIP
x-parity: odd
ENDSNIP

! IFS=$'\n' read -r -d '' snip_ordering_and_scoping_1 <<\ENDSNIP
spec:
  match:
  - mode: SERVER
    ports:
    - number: 8080
ENDSNIP

snip_clean_up() {
kubectl delete trafficextension -n istio-system parity
}
