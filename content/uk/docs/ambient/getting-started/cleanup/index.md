---
title: Очищення
description: Видаліть Istio та повʼязані з ним ресурси.
weight: 6
owner: istio/wg-networking-maintainers
test: yes
---

Якщо вам більше не потрібні Istio та повʼязані ресурси, ви можете видалити їх, дотримуючись цих кроків.

## Видалення проксі waypoint {#remove-waypoint-proxies}

Щоб видалити всі проксі waypoint виконайте наступні команди:

{{< text bash >}}
$ kubectl label namespace default istio.io/use-waypoint-
$ istioctl waypoint delete --all
{{< /text >}}

## Видалення простору імен з панелі даних ambient {#remove-the-namespace-from-the-ambient-data-plane}

Мітка, що інструктує Istio автоматично включати застосунки в просторі `default` в ambient mesh, стандартно не видаляється Istio. Використовуйте наступну команду для її видалення:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

Ви маєте видалити всі робочі навантаження з панелі даних ambient перед видаленням Istio.

## Видалення демонстраційного застосунку {#remove-the-sample-application}

Щоб видалити демонстраційний застосунок Bookinfo та deployment `curl`, виконайте наступне:

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete authorizationpolicy productpage-viewer
$ kubectl delete -f samples/curl/curl.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
{{< /text >}}

## Видалення Istio {#uninstall-istio}

Щоб видалити Istio з вашого кластера:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## Видалення CRD для Kubernetes Gateway API {#remove-gateway-api-crds}

{{< boilerplate gateway-api-remove-crds >}}
