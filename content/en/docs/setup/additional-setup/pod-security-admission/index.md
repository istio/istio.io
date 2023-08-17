---
title: Install Istio with Pod Security Admission
description: Install and use Istio with the Pod Security admission controller.
weight: 70
aliases:
    - /docs/setup/kubernetes/install/pod-security-admission
    - /docs/setup/kubernetes/additional-setup/pod-security-admission
keywords: [psa]
owner: istio/wg-networking-maintainers
test: yes
---

Follow this guide to install, configure, and use an Istio mesh with the Pod Security admission controller
([PSA](https://kubernetes.io/docs/concepts/security/pod-security-admission/)) enforcing the `baseline` [policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/) on namespaces in the mesh.

By default Istio injects an init container, `istio-init`, in pods deployed in
the mesh. The `istio-init` requires the user or
service-account deploying pods to the mesh to have sufficient Kubernetes RBAC
permissions to deploy [containers with the `NET_ADMIN` and `NET_RAW` capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).

However, the `baseline` policy does not include `NET_ADMIN` or `NET_RAW` in its [allowed capabilities](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline). In order to avoid enforcing the `privileged` policy in all meshed namespaces, it is necessary to use Istio mesh with the [Istio Container Network Interface plugin](/docs/setup/additional-setup/cni/). The `istio-cni-node` DaemonSet in the `istio-system` namespace requires `hostPath` volumes to access local CNI directories. Since this is not allowed in the `baseline` policy, the namespace where the CNI DaemonSet will be deployed needs to enforce the `privileged` [policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged). By default, this namespace is `istio-system`.

{{< warning >}}
Namespaces in the mesh may also use the `restricted` [policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline). You will need to configure the `seccompProfile` for your applications according to the policy specifications.
{{< /warning >}}

## Install Istio with PSA

1. Create the `istio-system` namespace and label it to enforce the `privileged` policy.

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl label --overwrite ns istio-system \
        pod-security.kubernetes.io/enforce=privileged \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/istio-system labeled
    {{< /text >}}

1. [Install Istio with CNI](/docs/setup/additional-setup/cni/#install-cni) on a Kubernetes cluster version 1.25 or later.

    {{< text bash >}}
    $ istioctl install --set components.cni.enabled=true -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Ingress gateways installed
    ✔ CNI installed
    ✔ Installation complete
    {{< /text >}}

## Deploy the sample application

1.  Add a namespace label to enforce the `baseline` policy for the default namespace where the demo application will run:

    {{< text bash >}}
    $ kubectl label --overwrite ns default \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/default labeled
    {{< /text >}}

1. Deploy the sample application using the PSA enabled configuration resources:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-psa.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

1. Verify that the app is running inside the cluster and serving HTML pages by
    checking for the page title in the response:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Uninstall

1. Delete the sample application

    {{< text bash >}}
    $ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-psa.yaml
    {{< /text >}}

1. Delete the labels on the default namespace

    {{< text bash >}}
    $ kubectl label namespace default pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version-
    {{< /text >}}

1. Uninstall Istio

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    {{< /text >}}

1. Delete the `istio-system` namespace

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
