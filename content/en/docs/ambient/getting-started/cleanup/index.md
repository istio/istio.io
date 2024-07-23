---
title: Cleanup
description: Delete Istio and associated resources.
weight: 6
owner: istio/wg-networking-maintainers
test: yes
---

If you no longer need Istio and associated resources, you can delete them by following the steps in this section.

## Remove the ambient and waypoint labels

The label to instruct Istio to automatically include applications in the `default` namespace to an ambient mesh is not removed by default. If no longer needed, use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
$ kubectl label namespace default istio.io/use-waypoint-
{{< /text >}}

## Remove waypoint proxies

To remove waypoint proxies, installed policies, and uninstall Istio, run the following commands:

{{< text bash >}}
$ istioctl waypoint delete --all
{{< /text >}}

## Uninstall Istio

To uninstall Istio:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## Remove the sample application

To delete the Bookinfo sample application and the `sleep` deployment, run the following:

{{< text bash >}}
$ kubectl delete -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

## Remove the Kubernetes Gateway API CRDs

If you installed the Gateway API CRDs, remove them:

{{< text bash >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
{{< /text >}}
