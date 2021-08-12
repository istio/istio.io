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
#          docs/tasks/security/authorization/authz-td-migration/index.md
####################################################################################################

snip_before_you_begin_1() {
istioctl install --set profile=demo --set meshConfig.trustDomain=old-td
}

snip_before_you_begin_2() {
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml
kubectl apply -f samples/sleep/sleep.yaml
kubectl create namespace sleep-allow
kubectl label namespace sleep-allow istio-injection=enabled
kubectl apply -f samples/sleep/sleep.yaml -n sleep-allow
}

snip_before_you_begin_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: service-httpbin.default.svc.cluster.local
  namespace: default
spec:
  rules:
  - from:
    - source:
        principals:
        - old-td/ns/sleep-allow/sa/sleep
    to:
    - operation:
        methods:
        - GET
  selector:
    matchLabels:
      app: httpbin
---
EOF
}

snip_before_you_begin_4() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_4_out <<\ENDSNIP
403
ENDSNIP

snip_before_you_begin_5() {
kubectl exec "$(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_5_out <<\ENDSNIP
200
ENDSNIP

snip_migrate_trust_domain_without_trust_domain_aliases_1() {
istioctl install --set profile=demo --set meshConfig.trustDomain=new-td
}

snip_migrate_trust_domain_without_trust_domain_aliases_2() {
kubectl rollout restart deployment -n istio-system istiod
}

snip_migrate_trust_domain_without_trust_domain_aliases_3() {
kubectl delete pod --all
}

snip_migrate_trust_domain_without_trust_domain_aliases_4() {
kubectl delete pod --all -n sleep-allow
}

snip_migrate_trust_domain_without_trust_domain_aliases_5() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_migrate_trust_domain_without_trust_domain_aliases_5_out <<\ENDSNIP
403
ENDSNIP

snip_migrate_trust_domain_without_trust_domain_aliases_6() {
kubectl exec "$(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_migrate_trust_domain_without_trust_domain_aliases_6_out <<\ENDSNIP
403
ENDSNIP

snip_migrate_trust_domain_with_trust_domain_aliases_1() {
cat <<EOF > ./td-installation.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    trustDomain: new-td
    trustDomainAliases:
      - old-td
EOF
istioctl install --set profile=demo -f td-installation.yaml -y
}

snip_migrate_trust_domain_with_trust_domain_aliases_2() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_migrate_trust_domain_with_trust_domain_aliases_2_out <<\ENDSNIP
403
ENDSNIP

snip_migrate_trust_domain_with_trust_domain_aliases_3() {
kubectl exec "$(kubectl -n sleep-allow get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -n sleep-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_migrate_trust_domain_with_trust_domain_aliases_3_out <<\ENDSNIP
200
ENDSNIP

snip_clean_up_1() {
kubectl delete authorizationpolicy service-httpbin.default.svc.cluster.local
kubectl delete deploy httpbin; kubectl delete service httpbin; kubectl delete serviceaccount httpbin
kubectl delete deploy sleep; kubectl delete service sleep; kubectl delete serviceaccount sleep
istioctl x uninstall --purge
kubectl delete namespace sleep-allow istio-system
rm ./td-installation.yaml
}
