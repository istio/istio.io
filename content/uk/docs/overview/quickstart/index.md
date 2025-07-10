---
title: "Швидкий початок роботи з Istio"
description: Дізнайтеся, як почати роботу з простим прикладом установки.
weight: 50
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
skip_seealso: true
test: n/a
---

Дякуємо за ваш інтерес до Istio!

Istio має два основних режими: **ambient mode** та **sidecar mode**.

* Режим [Ambient](/docs/overview/dataplane-modes/#ambient-mode) — це нова та вдосконалена модель, створена для усунення недоліків режиму sidecar. У режимі ambient на кожному вузлі встановлюється захищений тунель, і ви можете вибрати повний набір функцій з проксі-серверами, які ви встановлюєте (зазвичай) на рівні простору імен.
* Режим [Sidecar](/docs/overview/dataplane-modes/#sidecar-mode) — це традиційна модель сервісної мережі, започаткована Istio у 2017 році. У режимі sidecar проксі-сервер розгортається разом з кожним подом Kubernetes або іншим навантаженням.

Більшість зусиль у спільноті Istio спрямовані на вдосконалення режиму ambient, хоча режим sidecar залишається повністю підтримуваним. Будь-яка нова велика функція, внесена до проєкту, повинна працювати в обох режимах.

В цілому, **ми рекомендуємо новим користувачам почати з режиму ambient**. Він швидший, менш вимогливий до ресурсів (дешевший) і простіший в управлінні. Є [розширені випадки використання](/docs/overview/dataplane-modes/#unsupported-features), які все ще вимагають використання режиму sidecar, але закриття цих прогалин заплановано на нашій дорожній карті на 2025 рік.

<div style="text-align: center;">
  <div style="display: inline-block;">
    <a href="/uk/docs/ambient/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-ambient">Розпочати роботу з режимом ambient</a>
    <a href="/uk/docs/setup/getting-started"
       style="display: inline-block; min-width: 18em; margin: 0.5em;"
       class="btn btn--secondary"
       id="get-started-sidecar">Розпочати роботу з режимом sidecar</a>
  </div>
</div>
