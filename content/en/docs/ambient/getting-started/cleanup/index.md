---
title: Clean up
description: Delete Istio and associated resources.
weight: 6
owner: istio/wg-networking-maintainers
test: yes
---

If you no longer need Istio and associated resources, you can delete them by following the steps in this section.

## Remove waypoint proxies

To remove all waypoint proxies run the following commands:

{{< text bash >}}
$ kubectl label namespace default istio.io/use-waypoint-
$ istioctl waypoint delete --all
{{< /text >}}

## Remove the namespace from the ambient data plane

The label that instructs Istio to automatically include applications in the `default` namespace to the ambient mesh is not removed when you remove Istio. Use the following command to remove it:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

You must remove workloads from the ambient data plane before uninstalling Istio.

## Remove the sample application

To delete the Bookinfo sample application and the `curl` deployment, run the following:

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete authorizationpolicy productpage-viewer
$ kubectl delete -f samples/curl/curl.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml

{{< /text >}}

## Uninstall Istio

To uninstall Istio:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## Remove the Kubernetes Gateway API CRDs

{{< boilerplate gateway-api-remove-crds >}}
