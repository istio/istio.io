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
#          docs/tasks/security/cert-management/custom-ca-k8s/index.md
####################################################################################################

snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_1() {
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set featureGates="ExperimentalCertificateSigningRequestControllers=true" --set installCRDs=true
}

snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_2() {
cat <<EOF > ./selfsigned-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-bar-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bar-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: bar
  secretName: bar-ca-selfsigned
  issuerRef:
    name: selfsigned-bar-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: bar
spec:
  ca:
    secretName: bar-ca-selfsigned
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-foo-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: foo-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: foo
  secretName: foo-ca-selfsigned
  issuerRef:
    name: selfsigned-foo-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: foo
spec:
  ca:
    secretName: foo-ca-selfsigned
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-istio-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: istio-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: istio-system
  secretName: istio-ca-selfsigned
  issuerRef:
    name: selfsigned-istio-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: istio-system
spec:
  ca:
    secretName: istio-ca-selfsigned
EOF
kubectl apply -f ./selfsigned-issuer.yaml
}

snip_export_root_certificates_for_each_cluster_issuer_1() {
export istioca=$(kubectl get clusterissuers istio-system -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
export fooca=$(kubectl get clusterissuers foo -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
export barca=$(kubectl get clusterissuers bar -o jsonpath='{.spec.ca.secretName}' | xargs kubectl get secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d)
}

snip_deploy_istio_with_default_certsigner_info_1() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_CERT_SIGNER: istio-system
    caCertificates:
    - pem: |
      $istioca
      certSigners:
      - clusterissuers.cert-manager.io/istio-system
    - pem: |
      $fooca
      certSigners:
      - clusterissuers.cert-manager.io/foo
    - pem: |
      $barca
      certSigners:
      - clusterissuers.cert-manager.io/bar
  components:
    pilot:
      k8s:
        env:
        - name: CERT_SIGNER_DOMAIN
          value: clusterissuers.cert-manager.io
        - name: EXTERNAL_CA
          value: ISTIOD_RA_KUBERNETES_API
        - name: PILOT_CERT_PROVIDER
          value: k8s.io/clusterissuers.cert-manager.io/istio-system
        overlays:
          - kind: ClusterRole
            name: istiod-clusterrole-istio-system
            patches:
              - path: rules[-1]
                value: |
                  apiGroups:
                  - certificates.k8s.io
                  resourceNames:
                  - clusterissuers.cert-manager.io/foo
                  - clusterissuers.cert-manager.io/bar
                  - clusterissuers.cert-manager.io/istio-system
                  resources:
                  - signers
                  verbs:
                  - approve
EOF
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f ./istio.yaml
}

snip_deploy_istio_with_default_certsigner_info_2() {
kubectl create ns bar
kubectl create ns foo
}

snip_deploy_istio_with_default_certsigner_info_3() {
cat <<EOF > ./proxyconfig-bar.yaml
apiVersion: networking.istio.io/v1beta1
kind: ProxyConfig
metadata:
  name: barpc
  namespace: bar
spec:
  environmentVariables:
    ISTIO_META_CERT_SIGNER: bar
EOF
kubectl apply  -f ./proxyconfig-bar.yaml
}

snip_deploy_istio_with_default_certsigner_info_4() {
cat <<EOF > ./proxyconfig-foo.yaml
apiVersion: networking.istio.io/v1beta1
kind: ProxyConfig
metadata:
  name: foopc
  namespace: foo
spec:
  environmentVariables:
    ISTIO_META_CERT_SIGNER: foo
EOF
kubectl apply  -f ./proxyconfig-foo.yaml
}

snip_deploy_istio_with_default_certsigner_info_5() {
kubectl label ns foo istio-injection=enabled
kubectl label ns bar istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n foo
kubectl apply -f samples/sleep/sleep.yaml -n foo
kubectl apply -f samples/httpbin/httpbin.yaml -n bar
}

snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_1() {
export SLEEP_POD_FOO=$(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name})
}

snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_2() {
kubectl exec $SLEEP_POD_FOO -n foo -c sleep -- curl http://httpbin.foo:8000/html
}

! read -r -d '' snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_2_out <<\ENDSNIP
<!DOCTYPE html>
<html>
  <head>
  </head>
  <body>
      <h1>Herman Melville - Moby-Dick</h1>

      <div>
        <p>
          Availing himself of the mild...
        </p>
      </div>
  </body>
ENDSNIP

snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_3() {
kubectl exec $SLEEP_POD_FOO -n foo -c sleep -- curl http://httpbin.bar:8000/html
}

! read -r -d '' snip_verify_the_network_connectivity_between_httpbin_and_sleep_within_the_same_namespace_3_out <<\ENDSNIP
upstream connect error or disconnect/reset before headers. reset reason: connection failure, transport failure reason: TLS error: 268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED
ENDSNIP

snip_cleanup_1() {
kubectl delete ns foo
kubectl delete ns bar
istioctl uninstall --purge -y
kubectl delete ns istio-system
helm delete -n cert-manager cert-manager
}
