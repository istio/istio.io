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
#          docs/ops/configuration/security/security-policy-examples/index.md
####################################################################################################

! read -r -d '' snip_require_different_jwt_issuer_per_host_1 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-per-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        # the JWT token must have issuer with suffix "@example.com"
        requestPrincipals: ["*@example.com"]
    to:
    - operation:
        hosts: ["example.com", "*.example.com"]
  - from:
    - source:
        # the JWT token must have issuer with suffix "@another.org"
        requestPrincipals: ["*@another.org"]
    to:
    - operation:
        hosts: [".another.org", "*.another.org"]
ENDSNIP

! read -r -d '' snip_namespace_isolation_1 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: foo-isolation
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
ENDSNIP

! read -r -d '' snip_namespace_isolation_with_ingress_exception_1 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
ENDSNIP

! read -r -d '' snip_require_mtls_in_authorization_layer_defense_in_depth_1 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["*"]
ENDSNIP

! read -r -d '' snip_require_mandatory_authorization_check_with_deny_policy_1 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
ENDSNIP

! read -r -d '' snip_require_mandatory_authorization_check_with_deny_policy_2 <<\ENDSNIP
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        notPrincipals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
ENDSNIP
