---
title: Як мігрувати існуючу функціональність Mixer?
weight: 30
---

Mixer був [видалений у випуску Istio 1.8](/news/releases/1.8.x/announcing-1.8/#deprecations). Міграція необхідна, якщо ви все ще покладаєтеся на вбудовані адаптери Mixer або будь-які зовнішні адаптери для розширення мережі.

Для вбудованих адаптерів надано кілька альтернатив:

* Інтеграції `Prometheus` і `Stackdriver` реалізовані як [розширення проксі](/docs/reference/config/proxy_extensions/). Налаштування телеметрії, створеної цими двома розширеннями, може бути досягнута через [класифікацію запитів](/docs/tasks/observability/metrics/classify-metrics/) та [налаштування метрик Prometheus](/docs/tasks/observability/metrics/customize-metrics/).
* Функціональність глобального та локального обмеження швидкості (`memquota` і `redisquota` адаптери) надається через [розвʼязання на основі Envoy для обмеження швидкості](/docs/tasks/policy-enforcement/rate-limit/).
* Адаптер `OPA` замінений на [розвʼязання на основі Envoy ext-authz](/docs/tasks/security/authorization/authz-custom/), яке підтримує [інтеграцію з агентом політики OPA](https://www.openpolicyagent.org/docs/latest/envoy-introduction/).

Для власних зовнішніх адаптерів рекомендується міграція до розширень на основі Wasm. Будь ласка, ознайомтеся з посібниками по [розробці модуля Wasm](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) та [розповсюдженню розширень](/docs/tasks/extensibility/wasm-module-distribution/). Як тимчасове рішення, ви можете [увімкнути підтримку Envoy ext-authz та gRPC доступу до API логів у Mixer](https://github.com/istio/istio/wiki/Enabling-Envoy-Authorization-Service-and-gRPC-Access-Log-Service-With-Mixer), що дозволяє вам оновити Istio до версій після 1.7, одночасно використовуючи 1.7 Mixer з зовнішніми адаптерами. Це дасть вам більше часу для міграції на розширення на основі Wasm. Зверніть увагу, що це тимчасове рішення не протестовано в бойових умовах і навряд чи отримає виправлення помилок, оскільки воно доступне тільки у гілці Istio 1.7, яка вийшла з терміну підтримки після лютого 2021 року.
