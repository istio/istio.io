---
title: Встановлення мультикластера
description: Встановіть сервісну мережу Istio на декількох кластерах Kubernetes.
weight: 40
aliases:
    - /uk/docs/setup/kubernetes/multicluster-install/
    - /uk/docs/setup/kubernetes/multicluster/
    - /uk/docs/setup/kubernetes/install/multicluster/
    - /uk/docs/setup/install/multicluster/gateways/
    - /uk/docs/setup/install/multicluster/shared/
keywords: [kubernetes,multicluster]
simple_list: true
content_above: true
test: table-of-contents
owner: istio/wg-environments-maintainers
---
Слідуйте цьому посібнику для встановлення {{< gloss "сервісна мережа">}}сервісної мережі{{< /gloss >}} Istio, яка охоплює кілька {{< gloss "кластер" >}}кластерів{{< /gloss >}}.

Цей посібник охоплює деякі з найбільш поширених питань при створенні {{< gloss "мультикластер" >}}мультикластерної{{< /gloss >}} мережі:

- [Топологія мережі](/docs/ops/deployment/deployment-models#network-models):
  одна або дві мережі

- [Топологія панелі управління](/docs/ops/deployment/deployment-models#control-plane-models): кілька {{< gloss "основний кластер" >}}основних кластерів{{< /gloss >}}, один основний та {{< gloss "віддалений кластер" >}}віддалений кластер{{< /gloss >}}

{{< tip >}}
Для мереж, що охоплюють більше ніж два кластери, ви можете розширити кроки в цьому посібнику для налаштування складніших топологій.

Дивіться [моделі розгортання](/docs/ops/deployment/deployment-models) для отримання додаткової інформації.
{{< /tip >}}
