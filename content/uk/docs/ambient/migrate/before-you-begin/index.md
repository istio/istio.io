---
title: Перед початком
description: Перевірте ваше середовище та підготуйтеся до міграції.
weight: 1
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate
next: /docs/ambient/migrate/install-ambient-components
---

Перед міграцією з sidecar у режим Ambient, перевірте, що ваше середовище відповідає вимогам, та створіть резервну копію вашої поточної конфігурації.

{{< warning >}}
**Якщо ваші робочі навантаження використовують політики L7, міграція не є простою і наразі має відомі обмеження:**

- Під час міграції існує вікно, де політики L7 можуть не застосовуватися, старі політики на основі селектора мають бути видалені, а нові еквіваленти на основі waypoint мають зайняти їхнє місце. Атомарної передачі між двома не існує.
- Поки деякі початкові робочі навантаження все ще в режимі sidecar, трафік від цих робочих навантажень обходить waypoints повністю. Політики L7 на waypoint не застосовуються для цього шляху трафіку, доки джерело також не буде мігроване.

**Міграція без простою з політиками L7 наразі не підтримується.** Плануйте технічне вікно. Це відоме обмеження, яке відстежується для покращення в майбутньому релізі.

Якщо ваші робочі навантаження використовують лише правила `AuthorizationPolicy` L4 (відповідність принципалу джерела, простору імен або IP, без методів HTTP, шляхів або заголовків), це не застосовується, і міграція не вимагає зміни політик.
{{< /warning >}}

## Контекст: як змінюється застосування політик {#background-how-policy-enforcement-changes}

Розуміння ключових відмінностей між застосуванням політик у режимах sidecar та Ambient допоможе вам зрозуміти кроки міграції та передбачити, де потрібні зміни.

**У режимі sidecar:**

- Політики використовують `selector` для цілеспрямування на podʼи за міткою.
- Проксі sidecar призначення застосовує як політики L4, так і L7.
- Один `AuthorizationPolicy` може відповідати принципалу джерела, методу HTTP, шляху або заголовку і бути застосованим на pod призначення.

**У режимі Ambient:**

- Застосування L4 обробляється **ztunnel**, який запускається на кожному вузлі.
- Застосування L7 вимагає **waypoint проксі**, розгорнутого на кожен простір імен або сервіс у режимі Ambient.
- Політики, що застосовуються waypoint, мають використовувати `targetRefs`, що вказують на `Service` або `Gateway`, а не pod `selector`. Ви не можете повторно використовувати селектор-базові політики L7 як є.
- `VirtualService` є Alpha в режимі ambient. Міграція на `HTTPRoute` обовʼязкова для стабільного керування трафіком L7.

## Вимоги {#requirements}

- [Підтримуваний реліз Istio](/docs/releases/supported-releases/)
- Kubernetes [підтримувана версія](/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}})
- CRDs Gateway API встановлені (обовʼязково для waypoint проксі)

Якщо у вас ще не встановлені CRDs Gateway API, встановіть їх зараз:

{{< boilerplate gateway-api-install-crds >}}

## Перевірка вашого поточного встановлення {#verify-your-current-installation}

Виконайте наступні команди для підтвердження стану вашого поточного встановлення sidecar:

{{< text syntax=bash snip_id=none >}}
$ istioctl version
$ kubectl get pods -n istio-system
$ kubectl get namespaces -l istio-injection=enabled
{{< /text >}}

Перевірте наявність встановлень на основі ревізій (якщо ви використовуєте мітки `istio.io/rev` замість `istio-injection`):

{{< text syntax=bash snip_id=none >}}
$ kubectl get namespaces -l 'istio.io/rev'
{{< /text >}}

## Аудит наявних ресурсів {#audit-existing-resources}

Перелічіть ресурси Istio, що використовуються у вашому кластері:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,envoyfilter,wasmplugin -A
{{< /text >}}

Перевірте, які ресурси `AuthorizationPolicy` містять правила L7. Цим знадобляться waypoint проксі для роботи в режимі ambient:

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Перевірте наявність ресурсів `PeerAuthentication` з `mode: DISABLE`, ці несумісні з режимом ambient:

{{< text syntax=bash snip_id=none >}}
$ kubectl get peerauthentication -A -o yaml | grep -A2 "mtls:"
{{< /text >}}

Будь-який `PeerAuthentication` з `mode: DISABLE` має бути видалений або змінений перед міграцією, оскільки режим ambient завжди примушує mTLS між робочими навантаженнями mesh.

Ресурси `PeerAuthentication` з `mode: STRICT` або `mode: PERMISSIVE` не є блокерами, але вони стають зайвими після міграції: режим ambient примушує mTLS через ztunnel незалежно від цих політик. Ви можете безпечно видалити їх після завершення міграції.

## Резервне копіювання вашої конфігурації {#back-up-your-configuration}

Перед внесенням будь-яких змін, експортуйте вашу поточну конфігурацію Istio:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,gateway,httproute,telemetry -A -o yaml > istio-config-backup.yaml
$ kubectl get namespaces -o yaml > namespace-backup.yaml
{{< /text >}}

Зберігайте ці резервні копії десь безпечно поза кластером.

## Налаштування моніторингу трафіку (опціонально) {#set-up-traffic-monitoring-optional}

Використовуйте Kiali або інший інструмент спостережовості для захоплення базового стану ваших поточних патернів трафіку перед внесенням змін. Див. [Kiali](/docs/ops/integrations/kiali/) для інструкцій з налаштування.

## Наступні кроки {#next-steps}

Перейдіть до [Встановлення компонентів ambient](/docs/ambient/migrate/install-ambient-components/).
