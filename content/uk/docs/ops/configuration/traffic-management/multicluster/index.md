---
title: Керування трафіком у мультикластерній мережі
description: Як налаштувати розподіл трафіку між кластерами в мережі.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

У межах мультикластерної mesh-мережі можуть бути бажаними правила трафіку, специфічні для топології кластерів. У цьому документі описані кілька способів керування трафіком у мультикластерній mesh-мережі. Перед тим, як прочитати цей посібник:

1. Прочитайте [Моделі розгортання](/docs/ops/deployment/deployment-models/#multiple-clusters).
2. Переконайтеся, що ваші розгорнуті сервіси відповідають концепції {{< gloss "Однаковість просторів імен" >}}однаковості просторів імен{{< /gloss >}}.

## Залишення трафіку в межах кластера {#keeping-traffic-in-cluster}

У деяких випадках стандартна поведінка балансування навантаження між кластерами може бути небажаною. Щоб залишити трафік "локальним для кластера" (тобто трафік, надісланий з `cluster-a`, досягатиме лише пунктів призначення в `cluster-a`), позначте імена хостів або шаблони як `clusterLocal`, використовуючи [`MeshConfig.serviceSettings`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings).

Наприклад, можна застосувати кластер-локальний трафік для окремого сервісу, всіх сервісів у певному просторі імен або глобально для всіх сервісів у мережі, як показано нижче:

{{< tabset category-name="meshconfig" >}}

{{< tab name="пер-сервіс" category-value="service" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "mysvc.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="пер-простір імен" category-value="namespace" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="глобальний" category-value="global" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Ви також можете обмежити доступ до сервісів, встановивши глобальне правило cluster-local і додавши явні винятки, які можуть бути конкретними або шаблонними. У наведеному нижче прикладі всі сервіси у кластері будуть локальними для кластера, окрім сервісів у просторі назв `myns`:

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
- settings:
    clusterLocal: false
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

## Розділення сервісів {#partitioning-services}

[`DestinationRule.subsets`](/docs/reference/config/networking/destination-rule/#Subset) дозволяє розділяти сервіс, вибираючи мітки. Ці мітки можуть бути взяті з метаданих Kubernetes або з [вбудованих міток](/docs/reference/config/labels/). Одна з таких вбудованих міток, `topology.istio.io/cluster`, у селекторі підмножин для `DestinationRule` дозволяє створювати підмножини для кожного кластера.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: mysvc-per-cluster-dr
spec:
  host: mysvc.myns.svc.cluster.local
  subsets:
  - name: cluster-1
    labels:
      topology.istio.io/cluster: cluster-1
  - name: cluster-2
    labels:
      topology.istio.io/cluster: cluster-2
{{< /text >}}

Використовуючи ці підмножини, можна створювати різні правила маршрутизації на основі кластера, наприклад, [дзеркалювання](/docs/tasks/traffic-management/mirroring/) або [перемикання трафіку](/docs/tasks/traffic-management/traffic-shifting/).

Це надає ще один варіант створення правил кластер-локального трафіку шляхом обмеження підмножини пункту призначення в `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: mysvc-cluster-local-vs
spec:
  hosts:
  - mysvc.myns.svc.cluster.local
  http:
  - name: "cluster-1-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-1"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-1
  - name: "cluster-2-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-2"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-2
{{< /text >}}

Використання маршрутизації на основі підмножин таким чином для контролю кластер-локального трафіку, на відміну від [`MeshConfig.serviceSettings`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings), має недолік змішування політики рівня сервісу з політикою рівня топології. Наприклад, правило, яке надсилає 10% трафіку на `v2` сервісу, вимагатиме вдвічі більше підмножин (наприклад, `cluster-1-v2`, `cluster-2-v2`). Цей підхід найкраще використовувати в ситуаціях, коли потрібен більш детальний контроль маршрутизації на основі кластера.
