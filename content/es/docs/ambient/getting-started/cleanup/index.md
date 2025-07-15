---
title: Limpieza
description: Elimina Istio y los recursos asociados.
weight: 6
owner: istio/wg-networking-maintainers
test: yes
next: /docs/ambient/install
---

Si ya no necesitas Istio y los recursos asociados, puedes eliminarlos siguiendo los pasos de esta sección.

## Eliminar proxies de waypoint

Para eliminar todos los proxies de waypoint, ejecuta los siguientes comandos:

{{< text bash >}}
$ kubectl label namespace default istio.io/use-waypoint-
$ istioctl waypoint delete --all
{{< /text >}}

## Eliminar el namespace del data plane ambient

La etiqueta que indica a Istio que incluya automáticamente las aplicaciones enel namespace `default` en la malla ambient no se elimina al desinstalar Istio. Utiliza el siguiente comando para eliminarla:

{{< text bash >}}
$ kubectl label namespace default istio.io/data plane-mode-
{{< /text >}}

Debes eliminar los workloads del data plane ambient antes de desinstalar Istio.

## Eliminar la aplicación de ejemplo

Para eliminar la aplicación de ejemplo Bookinfo y el despliegue de `curl`, ejecuta lo siguiente:

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete authorizationpolicy productpage-viewer
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
$ kubectl delete -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@

{{< /text >}}

## Desinstalar Istio

Para desinstalar Istio:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## Eliminar las CRD de la API de Gateway de Kubernetes

{{< boilerplate gateway-api-remove-crds >}}
