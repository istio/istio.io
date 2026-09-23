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
#          docs/ambient/usage/extend-waypoint-lua/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl apply -f samples/curl/curl.yaml
}

snip_get_gateway() {
kubectl get gateway
}

! IFS=$'\n' read -r -d '' snip_get_gateway_out <<\ENDSNIP
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
ENDSNIP

snip_apply_lua_gateway() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: STATS
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

snip_test_gateway_parity() {
kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 4" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage" | grep x-parity
}

! IFS=$'\n' read -r -d '' snip_test_gateway_parity_out <<\ENDSNIP
x-parity: even
ENDSNIP

snip_create_waypoint() {
istioctl waypoint apply --enroll-namespace --wait
}

snip_verify_traffic() {
kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_out <<\ENDSNIP
200
ENDSNIP

snip_get_gateway_waypoint() {
kubectl get gateway
}

! IFS=$'\n' read -r -d '' snip_get_gateway_waypoint_out <<\ENDSNIP
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
ENDSNIP

snip_apply_lua_waypoint_all() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: STATS
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

snip_test_waypoint_parity() {
kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 7" http://productpage:9080/productpage | grep x-parity
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_parity_out <<\ENDSNIP
x-parity: odd
ENDSNIP

snip_remove_waypoint_parity() {
kubectl delete trafficextension parity-at-waypoint
}

snip_apply_lua_waypoint_service() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-for-reviews
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  match:
  - mode: SERVER
  phase: STATS
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

snip_test_waypoint_service_parity() {
kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 3" http://reviews:9080/reviews/1 | grep x-parity
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_service_parity_out <<\ENDSNIP
x-parity: odd
ENDSNIP

snip_remove_traffic_extensions() {
kubectl delete trafficextension parity-at-gateway parity-for-reviews
}
