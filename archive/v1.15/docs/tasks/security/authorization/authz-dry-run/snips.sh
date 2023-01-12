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
#          docs/tasks/security/authorization/authz-dry-run/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl label ns foo istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n foo
kubectl apply -f samples/sleep/sleep.yaml -n foo
}

snip_before_you_begin_2() {
istioctl proxy-config log deploy/httpbin.foo --level "rbac:debug" | grep rbac
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
rbac: debug
ENDSNIP

snip_before_you_begin_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_3_out <<\ENDSNIP
200
ENDSNIP

snip_create_dryrun_policy_1() {
kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-path-headers
  annotations:
    "istio.io/dry-run": "true"
spec:
  selector:
    matchLabels:
      app: httpbin
  action: DENY
  rules:
  - to:
    - operation:
        paths: ["/headers"]
EOF
}

snip_create_dryrun_policy_2() {
kubectl annotate --overwrite authorizationpolicies deny-path-headers -n foo istio.io/dry-run='true'
}

snip_create_dryrun_policy_3() {
for i in {1..20}; do kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s -o /dev/null -w "%{http_code}\n"; done
}

! read -r -d '' snip_create_dryrun_policy_3_out <<\ENDSNIP
200
200
200
...
ENDSNIP

snip_check_dryrun_result_in_proxy_log_1() {
kubectl logs "$(kubectl -n foo -l app=httpbin get pods -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo | grep "shadow denied"
}

! read -r -d '' snip_check_dryrun_result_in_proxy_log_1_out <<\ENDSNIP
2021-11-19T20:20:48.733099Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:21:45.502199Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
2021-11-19T20:22:33.065348Z debug envoy rbac shadow denied, matched policy ns[foo]-policy[deny-path-headers]-rule[0]
...
ENDSNIP

snip_check_dryrun_result_in_metric_using_prometheus_1() {
istioctl dashboard prometheus
}

! read -r -d '' snip_check_dryrun_result_in_metric_using_prometheus_2 <<\ENDSNIP
envoy_http_inbound_0_0_0_0_80_rbac{authz_dry_run_action="deny",authz_dry_run_result="denied"}
ENDSNIP

! read -r -d '' snip_check_dryrun_result_in_metric_using_prometheus_3 <<\ENDSNIP
envoy_http_inbound_0_0_0_0_80_rbac{app="httpbin",authz_dry_run_action="deny",authz_dry_run_result="denied",instance="10.44.1.11:15020",istio_io_rev="default",job="kubernetes-pods",kubernetes_namespace="foo",kubernetes_pod_name="httpbin-74fb669cc6-95qm8",pod_template_hash="74fb669cc6",security_istio_io_tlsMode="istio",service_istio_io_canonical_name="httpbin",service_istio_io_canonical_revision="v1",version="v1"}  20
ENDSNIP

snip_check_dryrun_result_in_tracing_using_zipkin_1() {
istioctl dashboard zipkin
}

! read -r -d '' snip_check_dryrun_result_in_tracing_using_zipkin_2 <<\ENDSNIP
istio.authorization.dry_run.deny_policy.name: ns[foo]-policy[deny-path-headers]-rule[0]
istio.authorization.dry_run.deny_policy.result: denied
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}
