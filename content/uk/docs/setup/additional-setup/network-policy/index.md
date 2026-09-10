---
title: NetworkPolicy
description: Розгортання додаткових ресурсів Kubernetes NetworkPolicy для компонентів Istio.
weight: 75
keywords: [networkpolicy,security,helm]
owner: istio/wg-networking-maintainers
test: no
---

Istio може за бажанням розгортати ресурси Kubernetes [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/) для своїх компонентів. Це корисно в кластерах, які застосовують мережеву політику default-deny, що є поширеною вимогою в захищених середовищах.

Коли цю функцію увімкнено, ресурси `NetworkPolicy` створюються для istiod, istio-cni, ztunnel та шлюзів, встановлених через Helm, визначаючи вхідні порти, необхідні кожному компоненту. Весь вихідний трафік типово дозволений, оскільки таким компонентам, як istiod, потрібно підключатися до визначених користувачем точок доступу (наприклад, JWKS URL). Шлюзова `NetworkPolicy` автоматично включає службові порти, налаштовані у Helm-значеннях шлюзу.

{{< warning >}}
Шлюзи, створені через Kubernetes Gateway API або [інʼєкцію шлюзу](/docs/setup/additional-setup/gateway/#deploying-a-gateway), waypoint-проксі та sidecar **не** покриваються вбудованою `NetworkPolicy` від Istio&nbsp;— для них потрібно створювати та керувати ресурсами `NetworkPolicy` окремо. Це зроблено навмисно: автоматичне керування `NetworkPolicy` для цих проксі вимагало б надання istiod дозволів на створення та зміну ресурсів `NetworkPolicy` у всьому кластері, що негативно вплинуло б на рівень безпеки панелі управління.
{{< /warning >}}

{{< tip >}}
Інформацію про те, як режим ambient взаємодіє з `NetworkPolicy` в podʼах вашого застосунку, див. у розділі [Ambient та Kubernetes NetworkPolicy](/docs/ambient/usage/networkpolicy/).
{{< /tip >}}

## Увімкнення NetworkPolicy {#enabling-networkpolicy}

Щоб увімкнути `NetworkPolicy`, встановіть `global.networkPolicy.enabled=true` під час інсталяції.

За допомогою `istioctl`:

{{< text bash >}}
$ istioctl install --set values.global.networkPolicy.enabled=true
{{< /text >}}

З Helm передайте налаштування кожному чарту:

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true
$ helm install ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.networkPolicy.enabled=true
{{< /text >}}

## Перегляд згенерованих політик {#reviewing-the-generated-policies}

`NetworkPolicy` кожного компонента дозволяє вхідний трафік на конкретних портах, необхідних цьому компоненту, і дозволяє весь вихідний трафік (оскільки таким компонентам, як istiod, потрібно підключатися до визначених користувачем точок доступу, таких як JWKS URL).

Ви можете переглянути точні ресурси `NetworkPolicy`, які будуть створені, за допомогою `helm template`:

{{< text bash >}}
$ helm template istiod istio/istiod -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template istio-cni istio/cni -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

{{< text bash >}}
$ helm template ztunnel istio/ztunnel -n istio-system --set global.networkPolicy.enabled=true -s templates/networkpolicy.yaml
{{< /text >}}

Щоб переглянути політики після інсталяції:

{{< text bash >}}
$ kubectl get networkpolicy -n istio-system
{{< /text >}}

## Налаштування NetworkPolicy {#customizing-networkpolicy}

Ресурси `NetworkPolicy`, створені Istio, навмисно широкі&nbsp;— правила вхідного трафіку використовують порожні селектори `from`, тобто трафік дозволений з будь-якого джерела на вказаних портах. Це тому, що джерело легітимного трафіку (наприклад, kube-apiserver, Prometheus, podʼи застосунків) відрізняється між кластерами.

Якщо вам потрібні суворіші політики, ви можете вимкнути вбудовану `NetworkPolicy` від Istio та створити власні, використовуючи вихідні дані `helm template` як відправну точку.
