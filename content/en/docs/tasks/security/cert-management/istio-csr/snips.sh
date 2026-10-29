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
#          docs/tasks/security/cert-management/istio-csr/index.md
####################################################################################################

snip_installing_certmanager_and_istiocsr_1() {
kubectl create ns cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
 cert-manager jetstack/cert-manager \
 --namespace cert-manager \
 --set installCRDs=true
}

snip_installing_certmanager_and_istiocsr_2() {
kubectl get pods -n cert-manager
}

! read -r -d '' snip_installing_certmanager_and_istiocsr_2_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-756bb56c5-8csd8               1/1     Running   0          60s
cert-manager-cainjector-86bc6dc648-d7bhd   1/1     Running   0          60s
cert-manager-webhook-66b555bb5-wwsgw       1/1     Running   0          60s
ENDSNIP

snip_installing_certmanager_and_istiocsr_3() {
kubectl create ns istio-system
kubectl apply -n istio-system -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cert-manager-istio-ca
spec:
  isCA: true
  duration: 2160h # 90d
  secretName: cert-manager-istio-ca
  commonName: cert-manager-istio-ca
  subject:
    organizations:
    - cert-manager
  issuerRef:
    name: selfsigned
    kind: Issuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cert-manager-istio-ca
spec:
  ca:
    secretName: cert-manager-istio-ca
EOF
}

snip_installing_certmanager_and_istiocsr_4() {
kubectl get issuers -n istio-system
}

! read -r -d '' snip_installing_certmanager_and_istiocsr_4_out <<\ENDSNIP
NAME         READY   AGE
istio-ca     True    17s
ENDSNIP

snip_installing_certmanager_and_istiocsr_5() {
helm install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr \
--set certificate.name=cert-manager-istio-ca # --set certificate.rootCA="Issuer root CA"
}

snip_installing_certmanager_and_istiocsr_6() {
kubectl get pods -n cert-manager
}

! read -r -d '' snip_installing_certmanager_and_istiocsr_6_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-756bb56c5-8csd8               1/1     Running   0          5m3s
cert-manager-cainjector-86bc6dc648-d7bhd   1/1     Running   0          5m3s
cert-manager-istio-csr-696954b7c7-8d9gg    1/1     Running   0          54s
cert-manager-webhook-66b555bb5-wwsgw       1/1     Running   0          5m3s
ENDSNIP

snip_installing_certmanager_and_istiocsr_7() {
kc get certs -n istio-system
}

! read -r -d '' snip_installing_certmanager_and_istiocsr_7_out <<\ENDSNIP
NAME                    READY   SECRET                  AGE
istiod                  True    istiod-tls              68s
ENDSNIP

snip_deploy_istio_1() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  profile: "demo"
  values:
    global:
      # Change certificate provider to cert-manager istio agent for istio agent
      caAddress: cert-manager-istio-csr.cert-manager.svc:443
  components:
    pilot:
      k8s:
        env:
          # Disable istiod CA Sever functionality
        - name: ENABLE_CA_SERVER
          value: "false"
        overlays:
        - apiVersion: apps/v1
          kind: Deployment
          name: istiod
          patches:

            # Mount istiod serving and webhook certificate from Secret mount
          - path: spec.template.spec.containers.[name:discovery].args[7]
            value: "--tlsCertFile=/etc/cert-manager/tls/tls.crt"
          - path: spec.template.spec.containers.[name:discovery].args[8]
            value: "--tlsKeyFile=/etc/cert-manager/tls/tls.key"
          - path: spec.template.spec.containers.[name:discovery].args[9]
            value: "--caCertFile=/etc/cert-manager/ca/root-cert.pem"

          - path: spec.template.spec.containers.[name:discovery].volumeMounts[6]
            value:
              name: cert-manager
              mountPath: "/etc/cert-manager/tls"
              readOnly: true
          - path: spec.template.spec.containers.[name:discovery].volumeMounts[7]
            value:
              name: ca-root-cert
              mountPath: "/etc/cert-manager/ca"
              readOnly: true

          - path: spec.template.spec.volumes[6]
            value:
              name: cert-manager
              secret:
                secretName: istiod-tls
          - path: spec.template.spec.volumes[7]
            value:
              name: ca-root-cert
              configMap:
                secretName: istiod-tls
                defaultMode: 420
                name: istio-ca-root-cert
EOF
istioctl install --set profile=demo -f ./istio.yaml
}

snip_deploy_istio_2() {
kubectl create ns bookinfo
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
}

snip_verify_that_custom_ca_certificates_installed_are_correct_1() {
kubectl get pods -n bookinfo
}

snip_verify_that_custom_ca_certificates_installed_are_correct_2() {
istioctl pc secret -n bookinfo <pod-name> -o json > proxy_secret
}

snip_cleanup_1() {
kubectl delete ns bookinfo
istioctl x uninstall --purge
}

snip_cleanup_2() {
helm uninstall -n cert-manager cert-manager-istio-csr
helm uninstall -n cert-manager cert-manager
}
