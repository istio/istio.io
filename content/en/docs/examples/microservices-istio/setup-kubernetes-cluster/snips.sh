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
#          docs/examples/microservices-istio/setup-kubernetes-cluster/index.md
####################################################################################################

snip__1() {
export NAMESPACE=tutorial
}

snip__2() {
kubectl create namespace "$NAMESPACE"
}

snip__3() {
kubectl apply -f samples/addons
}

snip__4() {
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: istio-system
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - host: my-istio-dashboard.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: grafana
          servicePort: 3000
  - host: my-istio-tracing.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: tracing
          servicePort: 9411
  - host: my-istio-logs-database.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: prometheus
          servicePort: 9090
  - host: my-kiali.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: kiali
          servicePort: 20001
EOF
}

snip__5() {
kubectl apply -f - <<EOF
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: istio-system-access
  namespace: istio-system
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["get", "list", "delete"]
EOF
}

snip__6() {
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${NAMESPACE}-user
  namespace: $NAMESPACE
EOF
}

snip__7() {
kubectl apply -f - <<EOF
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${NAMESPACE}-access
  namespace: $NAMESPACE
rules:
- apiGroups: ["", "extensions", "apps", "networking.k8s.io", "networking.istio.io", "authentication.istio.io",
              "rbac.istio.io", "config.istio.io", "security.istio.io"]
  resources: ["*"]
  verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${NAMESPACE}-access
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ${NAMESPACE}-user
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${NAMESPACE}-access
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${NAMESPACE}-istio-system-access
  namespace: istio-system
subjects:
- kind: ServiceAccount
  name: ${NAMESPACE}-user
  namespace: ${NAMESPACE}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-system-access
EOF
}

snip__8() {
cat <<EOF > ./${NAMESPACE}-user-config.yaml
apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $(kubectl get secret "$(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name})" -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')
    server: $(kubectl config view -o jsonpath="{.clusters[?(.name==\"$(kubectl config view -o jsonpath="{.contexts[?(.name==\"$(kubectl config current-context)\")].context.cluster}")\")].cluster.server}")
  name: ${CLUSTERNAME}

users:
- name: ${NAMESPACE}-user
  user:
    as-user-extra: {}
    client-key-data: $(kubectl get secret "$(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name})" -n ${NAMESPACE} -o jsonpath='{.data.ca\.crt}')
    token: $(kubectl get secret "$(kubectl get sa ${NAMESPACE}-user -n $NAMESPACE -o jsonpath={.secrets..name})" -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 --decode)

contexts:
- context:
    cluster: ${CLUSTERNAME}
    namespace: ${NAMESPACE}
    user: ${NAMESPACE}-user
  name: ${NAMESPACE}

current-context: ${NAMESPACE}
EOF
}

snip__9() {
export KUBECONFIG=$PWD/${NAMESPACE}-user-config.yaml
}

snip__10() {
kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
}

! read -r -d '' snip__10_out <<\ENDSNIP
tutorial
ENDSNIP
