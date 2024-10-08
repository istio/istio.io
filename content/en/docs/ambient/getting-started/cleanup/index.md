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

To delete the Bookinfo sample application and the `curl` deployment, run the following:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f samples/curl/curl.yaml
{{< /text >}}

## Remove the Kubernetes Gateway API CRDs

{{< boilerplate gateway-api-remove-crds >}}
