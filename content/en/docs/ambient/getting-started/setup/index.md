---
title: Setup
description: Download nad Install Istio in Ambient mode.
weight: 1
---


## 1. Download `istioctl` CLI

You'll use [Homebrew](https://brew.sh/) to download the `istioctl` CLI:

{{< text bash >}}
$ brew install istioctl
{{< /text >}}

If you don't have Homebrew, follow these instructions to download and the `istioctl` CLI:

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ export PATH=$PWD/bin:$PATH
{{< /text >}}


Verify the CLI is installed correctly by running the following command:

{{< text bash >}}
$ istioctl version
no ready Istio pods in "istio-system"
{{< istio_full_version >}}
{{< /text >}}


## 2. Install Istio onto your cluster

Assuming your cluster is prepared, you can install Istio using the ambient mode profile. Run the following command:

{{< text bash >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}


Note that it might take a minute for the Istio components to be installed. Once the installation completes you’ll get the following output that indicates all components have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}


You can verify the installed components using the following command:

{{< text bash >}}
$ istioctl verify-install

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
{{< /text >}}


## 3. Install the Kubernetes Gateway API CRDs

You need to install the Kubernetes Gateway API CRDs, which don’t come installed by default on most Kubernetes clusters:

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }
{{< /text >}}

You'll use the Kubernetes Gateway API to configure the gateway for your application.

## 4. Next steps

Congratulations! You've successfully installed Istio in ambient mode. Continue to the next step to [install the demo application and add it to the ambient mesh](/docs/ambient/getting-started/deploy-sample-app/).