---
title: OpenShift
description: Інструкції для налаштування кластера OpenShift для використання з Istio.
weight: 55
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/openshift/
    - /uk/docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
owner: istio/wg-environments-maintainers
test: no
---

Виконайте ці інструкції, щоб підготувати кластер OpenShift для встановлення Istio.

Встановіть Istio, використовуючи профіль OpenShift:

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

Після завершення встановлення, створіть маршрут OpenShift для ingress gateway:

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=http2
{{< /text >}}
