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
#          docs/ambient/getting-started/setup/index.md
####################################################################################################

snip_1_download_istio_cli_1() {
brew install istioctl
}

snip_install_ambient() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --skip-confirmation
}

snip_verify_install() {
istioctl verify-install
}

! IFS=$'\n' read -r -d '' snip_verify_install_out <<\ENDSNIP

1 Istio control planes detected, checking --revision "default" only
✔ Deployment: istiod.istio-system checked successfully
✔ DaemonSet: istio-cni-node.istio-system checked successfully
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ Service: istiod.istio-system checked successfully
✔ ConfigMap: istio.istio-system checked successfully
✔ ConfigMap: istio-cni-config.istio-system checked successfully
✔ ConfigMap: istio-sidecar-injector.istio-system checked successfully
✔ Pod: istiod-5888647857-wkgcl.istio-system checked successfully
✔ ServiceAccount: istio-cni.istio-system checked successfully
✔ ServiceAccount: istio-reader-service-account.istio-system checked successfully
✔ ServiceAccount: istiod.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
✔ RoleBinding: istiod.istio-system checked successfully
✔ Role: istiod.istio-system checked successfully
✔ PodDisruptionBudget: istiod.istio-system checked successfully
✔ HorizontalPodAutoscaler: istiod.istio-system checked successfully
✔ MutatingWebhookConfiguration: istio-revision-tag-default.istio-system checked successfully
✔ MutatingWebhookConfiguration: istio-sidecar-injector.istio-system checked successfully
✔ ValidatingWebhookConfiguration: istio-validator-istio-system.istio-system checked successfully
✔ ValidatingWebhookConfiguration: istiod-default-validator.istio-system checked successfully
✔ ClusterRole: istio-cni.istio-system checked successfully
✔ ClusterRole: istio-cni-ambient.istio-system checked successfully
✔ ClusterRole: istio-cni-repair-role.istio-system checked successfully
✔ ClusterRole: istio-reader-clusterrole-istio-system.istio-system checked successfully
✔ ClusterRole: istiod-clusterrole-istio-system.istio-system checked successfully
✔ ClusterRole: istiod-gateway-controller-istio-system.istio-system checked successfully
✔ ClusterRoleBinding: istio-cni.istio-system checked successfully
✔ ClusterRoleBinding: istio-cni-ambient.istio-system checked successfully
✔ ClusterRoleBinding: istio-cni-repair-rolebinding.istio-system checked successfully
✔ ClusterRoleBinding: istio-reader-clusterrole-istio-system.istio-system checked successfully
✔ ClusterRoleBinding: istiod-clusterrole-istio-system.istio-system checked successfully
✔ ClusterRoleBinding: istiod-gateway-controller-istio-system.istio-system checked successfully
✔ CustomResourceDefinition: authorizationpolicies.security.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: destinationrules.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: envoyfilters.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: gateways.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: peerauthentications.security.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: proxyconfigs.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: requestauthentications.security.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: serviceentries.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: sidecars.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: telemetries.telemetry.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: virtualservices.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: wasmplugins.extensions.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: workloadentries.networking.istio.io.istio-system checked successfully
✔ CustomResourceDefinition: workloadgroups.networking.istio.io.istio-system checked successfully
Checked 14 custom resource definitions
Checked 1 Istio Deployments
Checked 2 Istio Daemonsets
✔ Istio is installed and verified successfully
ENDSNIP

snip_install_k8s_gateway_api() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }
}
