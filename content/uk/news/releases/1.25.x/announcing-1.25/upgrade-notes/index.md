---
title: Примітки до оновлення Istio 1.25
description: Важливі зміни, на які слід звернути увагу при оновленні до Istio 1.25.0.
weight: 20
publishdate: 2025-03-03
---

При оновленні з Istio 1.24.x до Istio 1.25.x, будь ласка, зверніть увагу на зміни на цій сторінці. У цих примітках детально описано зміни, які цілеспрямовано порушують зворотну сумісність з Istio 1.24.x. У примітках також згадуються зміни, які зберігають зворотну сумісність, але запроваджують нову поведінку. Зміни включено лише у тому випадку, якщо нова поведінка буде неочікуваною для користувача Istio 1.24.x.

## Узгодження оновлення подів режиму ambient {#ambient-mode-pod-upgrade-reconciliation}

Під час запуску нового поду `istio-cni` `DaemonSet`-блоку він перевірить поди, які раніше було включено до ambient mesh, і оновить їхні правила in-pod iptables до поточного стану, якщо є розбіжності або дельта. Стандартно, починаючи з версії 1.25.0, цю опцію вимкнено, але згодом її буде увімкнено стандартно. Цю можливість можна увімкнути за допомогою `helm install cni --set ambient.reconcileIptablesOnStartup=true` (Helm) або `istioctl install --set values.cni.ambient.reconcileIptablesOnStartup=true` (istioctl).

## Трафік DNS (TCP і UDP) тепер враховує анотації виключення трафіку {#dns-traffic-tcp-and-udp-now-respects-traffic-exclusion-annotations}

Трафік DNS (UDP і TCP) тепер враховує анотації трафіку на рівні под, такі як `traffic.sidecar.istio.io/excludeOutboundIPRanges` і `traffic.sidecar.istio.io/excludeOutboundPorts`. Раніше UDP/DNS трафік однозначно ігнорував ці анотації трафіку, навіть якщо був вказаний порт DNS, через структуру правил. Ця зміна поведінки фактично відбулася в серії випусків 1.23, але була залишена поза увагою в примітках до випуску 1.23.

## Захоплення DNS у режимі ambient mode стандартно увімкнено {#ambient-mode-dns-capture-on-by-default}

У цьому випуску проксіювання DNS стандартно увімкнено для робочих навантажень у режимі ambient. Зауважте, що DNS буде увімкнено лише для нових подів: наявні поди не перехоплюватимуть DNS-трафік. Щоб увімкнути цю функцію для наявних подів, їх слід або перезапустити вручну, або увімкнути функцію узгодження iptables під час оновлення `istio-cni` за допомогою `--set cni.ambient.reconcileIptablesOnStartup=true`. Це призведе до автоматичного узгодження наявних подів під час оновлення.

Окремі поди можуть відмовитися від глобального захоплення DNS у режимі ambient, застосувавши анотацію `ambient.istio.io/dns-capture=false`.

## Зміни в дашборді Grafana {#grafana-dashboard-changes}

Для роботи дашбордів, що постачаються з Istio 1.25, потрібна версія Grafana 7.2 або новіша.

## Вилучено підтримку OpenCensus {#opencensus-support-has-been-removed}

Оскільки Envoy [вилучив розширення для трасування OpenCensus](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.33/v1.33.0.html#incompatible-behavior-changes), ми вилучили підтримку OpenCensus з Istio. Якщо ви використовуєте OpenCensus, вам слід перейти на OpenTelemetry. [Дізнайтеся більше про застарівання OpenCensus](https://opentelemetry.io/blog/2023/sunsetting-opencensus/).

## Зміни у чарті ztunnel Helm {#ztunnel-helm-chart-changes-changes}

У попередніх випусках ресурси у чарті ztunnel Helm завжди мали назву `ztunnel`. У цьому випуску вони тепер мають назву у `.Resource.Name`.

Якщо ви встановлюєте чарт з назвою випуску, відмінною від `ztunnel`, назви ресурсів буде змінено, що призведе до простою. У цьому випадку рекомендується встановити `--set resourceName=ztunnel`, щоб повернути попередні стандартні значення.
