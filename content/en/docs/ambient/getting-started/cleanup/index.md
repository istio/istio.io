
---
title: Cleanup
description: Delete Istio and associated resources.
weight: 6
---

If you no longer need Istio and associated resources, you can delete them by following the steps in this section.

## 1. Remove the ambient and waypoint labels

The label to instruct Istio to automatically include applications in the `default` namespace to an ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
$ kubectl label namespace default istio.io/use-waypoint-
{{< /text >}}

## 2. Remove waypoint proxies and uninstall Istio

To remove waypoint proxies, installed policies, and uninstall Istio, run the following commands:

{{< text bash >}}
$ istioctl x waypoint delete --all
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}


## 3. Remove the sample application

To delete the Bookinfo sample application and the `sleep` deployment, run the following:

{{< text bash >}}
$ kubectl delete -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f https://raw.githubusercontent.com/istio/istio/master/samples/sleep/sleep.yaml
{{< /text >}}

## 4. Remove the Kubernetes Gateway API CRDs

1If you installed the Gateway API CRDs, remove them:

{{< text bash >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
{{< /text >}}
