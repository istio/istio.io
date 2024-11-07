---
title: Очищення
description: Видаліть Istio та повʼязані з ним ресурси.
weight: 6
owner: istio/wg-networking-maintainers
test: yes
---

Якщо вам більше не потрібні Istio та повʼязані ресурси, ви можете видалити їх, дотримуючись цих кроків.

## Видалення міток ambient і waypoint {#remove-ambient-waypoint-labels}

Мітка, що інструктує Istio автоматично включати застосунки в просторі `default` в ambient mesh, стандартно не видаляється. Якщо вона більше не потрібна, використовуйте наступну команду для її видалення:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
$ kubectl label namespace default istio.io/use-waypoint-
{{< /text >}}

## Видалення проксі waypoint {#remove-waypoint-proxies}

Щоб видалити проксі waypoint, встановлені політики та деінсталювати Istio, виконайте наступні команди:

{{< text bash >}}
$ istioctl waypoint delete --all
{{< /text >}}

## Видалення Istio {#uninstall-istio}

Щоб видалити Istio:

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## Видалення демонстраційного застосунку {#remove-the-sample-application}

Щоб видалити демонстраційний застосунок Bookinfo та deployment `curl`, виконайте наступне:

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f samples/curl/curl.yaml
{{< /text >}}

## Видалення CRD для Kubernetes Gateway API {#remove-gateway-api-crds}

{{< boilerplate gateway-api-remove-crds >}}
