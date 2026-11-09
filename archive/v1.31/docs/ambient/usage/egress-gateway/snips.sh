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
#          docs/ambient/usage/egress-gateway/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-install-crds.sh"

snip_deploy_curl() {
kubectl apply -f samples/curl/curl.yaml
}

snip_label_default_ambient() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

snip_create_egress_ns() {
kubectl create namespace istio-egress
kubectl label namespace istio-egress istio.io/dataplane-mode=ambient
}

snip_apply_egress_waypoint() {
istioctl waypoint apply --for service --enroll-namespace --namespace istio-egress
}

! IFS=$'\n' read -r -d '' snip_apply_egress_waypoint_out <<\ENDSNIP
✅ waypoint istio-egress/waypoint applied
✅ namespace istio-egress labeled with "istio.io/use-waypoint: waypoint"
ENDSNIP

snip_wait_egress_waypoint() {
istioctl waypoint list -n istio-egress
}

! IFS=$'\n' read -r -d '' snip_wait_egress_waypoint_out <<\ENDSNIP
NAME       REVISION  TRAFFIC TYPE  PROGRAMMED
waypoint   default   service       True
ENDSNIP

snip_apply_serviceentry() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
}

snip_verify_egress_traffic() {
kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
}

! IFS=$'\n' read -r -d '' snip_verify_egress_traffic_out <<\ENDSNIP
200
ENDSNIP

snip_check_waypoint_logs() {
kubectl exec -n istio-egress deploy/waypoint -c istio-proxy -- pilot-agent request GET stats | grep upstream_rq_total
}

snip_apply_authz_policy() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  targetRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-org
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get"]
EOF
}

snip_verify_allowed_request() {
kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
}

! IFS=$'\n' read -r -d '' snip_verify_allowed_request_out <<\ENDSNIP
200
ENDSNIP

snip_verify_denied_request() {
kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" -X POST http://httpbin.org/post
}

! IFS=$'\n' read -r -d '' snip_verify_denied_request_out <<\ENDSNIP
403
ENDSNIP

snip_apply_tls_origination() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: httpbin-org-tls
  namespace: istio-egress
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
EOF
}

snip_verify_tls_origination() {
kubectl exec deploy/curl -- curl -s http://httpbin.org/get | head -5
}

snip_apply_second_serviceentry() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: example-com
  namespace: istio-egress
spec:
  hosts:
  - example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
}

snip_verify_second_serviceentry() {
kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://example.com
}

! IFS=$'\n' read -r -d '' snip_verify_second_serviceentry_out <<\ENDSNIP
200
ENDSNIP

snip_cleanup() {
kubectl delete namespace istio-egress
kubectl delete -f samples/curl/curl.yaml
kubectl label namespace default istio.io/dataplane-mode-
}
