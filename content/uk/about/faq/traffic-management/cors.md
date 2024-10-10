---
title: Чому моя конфігурація CORS не працює?
weight: 40
---

Після застосування [конфігурації CORS](/docs/reference/config/networking/virtual-service/#CorsPolicy) ви можете помітити, що ніби нічого не змінилося, і запитати, що пішло не так. CORS є часто неправильно зрозумілим HTTP-концептом, що часто призводить до плутанини при конфігурації.

Щоб зрозуміти це, корисно зробити крок назад і подивитися на [що таке CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) і коли його слід використовувати. Стандартно оглядачі мають обмеження на "кросдоменні" запити, ініційовані скриптами. Це заважає, наприклад, вебсайту `attack.example.com` здійснити JavaScript-запит до `bank.example.com` і вкрасти чутливу інформацію користувача.

Щоб дозволити цей запит, `bank.example.com` має дозволити `attack.example.com` здійснювати кросдоменні запити. Ось де і зʼявляється CORS. Якби ми обслуговували `bank.example.com` у кластері з увімкненим Istio, ми могли б налаштувати `corsPolicy`, щоб дозволити це:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: bank
spec:
  hosts:
  - bank.example.com
  http:
  - corsPolicy:
      allowOrigins:
      - exact: https://attack.example.com
...
{{< /text >}}

У цьому випадку ми явно дозволяємо один орієнтир; маски часто використовуються для не чутливих сторінок.

Після цього поширена помилка — це надсилання запиту, наприклад `curl bank.example.com -H "Origin: https://attack.example.com"`, і очікування, що запит буде відхилено. Однак curl і багато інших клієнтів не побачать відхилення запиту, оскільки CORS є обмеженням оглядача. Конфігурація CORS просто додає заголовки `Access-Control-*` у відповідь; клієнт (оглядач) вирішує відхилити запит, якщо відповідь не є задовільною. В оглядачах це робиться за допомогою [Preflight запиту](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests).
