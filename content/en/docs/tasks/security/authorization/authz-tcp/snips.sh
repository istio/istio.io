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
#          docs/tasks/security/authorization/authz-tcp/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/tcp-echo/tcp-echo.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
}

snip_before_you_begin_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
hello port 9000
connection succeeded
ENDSNIP

snip_before_you_begin_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_before_you_begin_3_out <<\ENDSNIP
hello port 9001
connection succeeded
ENDSNIP

snip_before_you_begin_4() {
TCP_ECHO_IP=$(kubectl get pod "$(kubectl get pod -l app=tcp-echo -n foo -o jsonpath={.items..metadata.name})" -n foo -o jsonpath="{.status.podIP}")
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_before_you_begin_4_out <<\ENDSNIP
hello port 9002
connection succeeded
ENDSNIP

snip_configure_allow_authorization_policy_for_a_tcp_workload_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tcp-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      app: tcp-echo
  action: ALLOW
  rules:
  - to:
    - operation:
        ports: ["9000", "9001"]
EOF
}

snip_configure_allow_authorization_policy_for_a_tcp_workload_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_allow_authorization_policy_for_a_tcp_workload_2_out <<\ENDSNIP
hello port 9000
connection succeeded
ENDSNIP

snip_configure_allow_authorization_policy_for_a_tcp_workload_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_allow_authorization_policy_for_a_tcp_workload_3_out <<\ENDSNIP
hello port 9001
connection succeeded
ENDSNIP

snip_configure_allow_authorization_policy_for_a_tcp_workload_4() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_allow_authorization_policy_for_a_tcp_workload_4_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_allow_authorization_policy_for_a_tcp_workload_5() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tcp-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      app: tcp-echo
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        ports: ["9000"]
EOF
}

snip_configure_allow_authorization_policy_for_a_tcp_workload_6() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_allow_authorization_policy_for_a_tcp_workload_6_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_allow_authorization_policy_for_a_tcp_workload_7() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_allow_authorization_policy_for_a_tcp_workload_7_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_deny_authorization_policy_for_a_tcp_workload_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tcp-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      app: tcp-echo
  action: DENY
  rules:
  - to:
    - operation:
        methods: ["GET"]
EOF
}

snip_configure_deny_authorization_policy_for_a_tcp_workload_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_deny_authorization_policy_for_a_tcp_workload_2_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_deny_authorization_policy_for_a_tcp_workload_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_deny_authorization_policy_for_a_tcp_workload_3_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_deny_authorization_policy_for_a_tcp_workload_4() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: tcp-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      app: tcp-echo
  action: DENY
  rules:
  - to:
    - operation:
        methods: ["GET"]
        ports: ["9000"]
EOF
}

snip_configure_deny_authorization_policy_for_a_tcp_workload_5() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_deny_authorization_policy_for_a_tcp_workload_5_out <<\ENDSNIP
connection rejected
ENDSNIP

snip_configure_deny_authorization_policy_for_a_tcp_workload_6() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- sh -c 'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
}

! read -r -d '' snip_configure_deny_authorization_policy_for_a_tcp_workload_6_out <<\ENDSNIP
hello port 9001
connection succeeded
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}
