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

snip_deploying_istio_with_kubernetes_ca_1() {
cat <<EOF > ./istio.yaml
  apiVersion: install.istio.io/v1alpha1
  kind: IstioOperator
  spec:
    components:
      pilot:
        k8s:
          env:
          # Indicate to Istiod that we use an Custom Certificate Authority
          - name: EXTERNAL_CA
            value: ISTIOD_RA_KUBERNETES_API
          # Tells Istiod to use the Kubernetes legacy CA Signer
          - name: K8S_SIGNER
            value: kubernetes.io/legacy-unknown
EOF
istioctl install --set profile=demo -f ./istio.yaml
}

snip_verify_that_the_certificates_installed_are_correct_1() {
ingress_pod="$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")"
istioctl pc secret "$ingress_pod".istio-system -o json | jq .dynamicActiveSecrets[1].secret.validationContext.trustedCa.inlineBytes | sed 's/\"//g' | base64 -d
}

snip_verify_that_the_certificates_installed_are_correct_2() {
secret="$(kubectl get secrets -n istio-system -o json | jq '.items[].metadata.name' | grep "account-token" | head -1 | sed 's/\"//g')"
kubectl get secret/"$secret" -n istio-system -o json | jq '.data."ca.crt"' | sed 's/\"//g' | base64 -d
}

snip_cleanup_part_1_1() {
kubectl delete ns istio-system
kubectl delete ns bookinfo
}

snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_1() {
kubectl apply -f local-ca.yaml
}

snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_2() {
kubectl get services -n signer-ca-system
}

! read -r -d '' snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_2_out <<\ENDSNIP
  NAME                                           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
  signer-ca-controller-manager-metrics-service   ClusterIP   10.8.9.25    none        8443/TCP   72s
ENDSNIP

snip_deploy_custom_ca_controller_in_the_kubernetes_cluster_3() {
kubectl get secrets signer-ca-5hff5h74hm -o json
}

snip_load_the_ca_root_certificate_into_a_secret_that_istiod_can_access_1() {
cat <<EOF > ./external-ca-secret.yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: external-ca-cert
    namespace: istio-system
  data:
  root-cert.pem: <tls.cert from the step above>
EOF
kubectl apply -f external-ca-secret.yaml
}

snip_deploying_istio_1() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    base:
      k8s:
        overlays:
          # Amend ClusterRole to add permission for istiod to approve certificate signing by custom signer
          - kind: ClusterRole
            name: istiod-istio-system
            patches:
              - path: rules[-1]
                value: |
                  apiGroups:
                  - certificates.k8s.io
                  resourceNames:
                  # Name of k8s external Signer in this example
                  - example.com/foo
                  resources:
                  - signers
                  verbs:
                  - approve
    pilot:
      k8s:
        env:
          # Indicate to Istiod that we use an external signer
          - name: EXTERNAL_CA
            value: ISTIOD_RA_KUBERNETES_API
          # Indicate to Istiod the external k8s Signer Name
          - name: K8S_SIGNER
            value: example.com/foo
        overlays:
        - kind: Deployment
          name: istiod
          patches:
            - path: spec.template.spec.containers[0].volumeMounts[-1]
              value: |
                # Mount external CA certificate into Istiod
                name: external-ca-cert
                mountPath: /etc/external-ca-cert
                readOnly: true
            - path: spec.template.spec.volumes[-1]
              value: |
                name: external-ca-cert
                secret:
                  secretName: external-ca-cert
                  optional: true
EOF
istioctl install --set profile=demo -f ./istio.yaml
}

snip_deploying_istio_2() {
kubectl create ns bookinfo
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
}

snip_verify_that_custom_ca_certificates_installed_are_correct_1() {
kubectl get pods -n bookinfo
}

snip_verify_that_custom_ca_certificates_installed_are_correct_2() {
istioctl pc secret <pod-name> -o json > proxy_secret
}

snip_cleanup_part_2_1() {
kubectl delete ns istio-system
kubectl delete ns bookinfo
}
