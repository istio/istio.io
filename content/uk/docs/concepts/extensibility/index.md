---
title: Розширюваність
description: Описує механізми розширення проксі Istio, включаючи фільтри WebAssembly та Lua.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter,lua,TrafficExtension]
aliases:
  - /docs/concepts/wasm/
  - /latest/docs/concepts/wasm/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio надає два основних механізми розширення: розширення Envoy, описані нижче, та [постачальники розширень](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-extension_providers).

## Розширення проксі Envoy {#extending-envoy-proxies}

Istio надає два механізми для розширення проксі на основі Envoy: WebAssembly (Wasm) та Lua. Обидва налаштовуються за допомогою API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/), який надає уніфікований спосіб приєднання розширень до робочих навантажень із узгодженим націлюванням та впорядкуванням за фазою/пріоритетом.

### Вибір типу фільтра {#choosing-a-filter-type}

| | WebAssembly | Lua |
|---|---|---|
| **Мови** | C++, Rust, Go, AssemblyScript та інші | Тільки Lua |
| **Розповсюдження** | Завантажується з OCI-реєстрів, HTTP-URL або локальних файлів | Вбудовується безпосередньо в ресурс |
| **Памʼять** | Вища&nbsp;— кожен втулок працює у власній пісочниці | Приблизно в 10 разів нижча, ніж у WebAssembly |
| **Ізоляція** | Повна VM-пісочниця&nbsp;— збій обмежується втулком | Працює в процесі; збій може зупинити робочий потік |
| **Політика відмов** | Налаштовується&nbsp;— за замовчуванням fail-closed | Тільки fail-open&nbsp;— без опції конфігурації |
| **SDLC** | Повна екосистема: юніт-тести, CI, версіоновані релізи | Обмежена&nbsp;— скрипт живе в самому ресурсі |
| **Найкраще підходить для** | Складної логіки, багаторазових втулків, промислових розширень | Простих одноразових перетворень, тимчасових обхідних рішень |

Загалом, для промислових розширень, які потребують тестування, версіонування та повторного використання, віддавайте перевагу WebAssembly. Для легких, локальних змін, де простота вбудованого коду переважає відсутність інструментів, віддавайте перевагу Lua.

### Втулки WebAssembly {#webassembly-plugins}

WebAssembly є технологією ізоляції для складніших розширень. API для пісочниці Proxy-Wasm замінює Mixer як основний механізм розширення в Istio.

Цілі використання пісочниці WebAssembly:

- **Ефективність**&nbsp;— розширення додає мінімальні затримки, навантаження на ЦП і використання памʼяті.
- **Функціональність**&nbsp;— розширення може забезпечувати виконання політики, збір телеметрії та виконання мутацій корисного навантаження.
- **Ізоляція**&nbsp;— помилка програмування або збій одного втулка не впливає на інші втулки.
- **Конфігурація**&nbsp;— втулки налаштовуються за допомогою API, яке узгоджується з іншими API Istio. Розширення можна налаштувати динамічно.
- **Оператор**&nbsp;— розширення можна випробувати в тестовому режимі, а також розгорнути з конфігурацією log-only, fail-open або fail-close.
- **Розробник розширень**&nbsp;— втулок можна написати кількома мовами програмування.

Ця [відеопрезентація](https://youtu.be/XdWmm_mtVXI) є вступом до архітектури інтеграції WebAssembly.

#### Високорівнева архітектура {#high-level-architecture}

Розширення Istio (втулки Proxy-Wasm) мають кілька компонентів:

- **Інтерфейс постачальника фільтрів (SPI)** для створення втулків Proxy-Wasm для фільтрів.
- **Пісочниця** з V8 Wasm Runtime, вбудована в Envoy.
- **Host API** для роботи з заголовками, трейлерами та метаданими.
- **API викликів** для gRPC і HTTP запитів.
- **API статистики та ведення журналів** для збору метрик і моніторингу.

{{< image width="80%" link="extending.svg" caption="Розширення Istio/Envoy" >}}

#### Приклад {#example}

Приклад втулка Proxy-Wasm на C++ для фільтра можна знайти [тут](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example). Ви можете слідувати [цьому посібнику](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) для реалізації розширення Wasm за допомогою C++.

#### Екосистема {#ecosystem}

- [Istio Ecosystem Wasm Extensions](https://github.com/istio-ecosystem/wasm-extensions)
- [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Go SDK](https://github.com/proxy-wasm/proxy-wasm-go-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [WebAssembly Extensions For Network Proxies (відео)](https://www.youtube.com/watch?v=OIUPf8m7CGA)

### Скрипти Lua {#lua-scripts}

Фільтри Lua забезпечують легкий підхід із вбудованими скриптами для простих перетворень запитів і відповідей. Код Lua вбудовується безпосередньо в ресурс `TrafficExtension` і виконується в проксі Envoy, без необхідності розповсюдження модулів. Фільтри Lua найкраще підходять для простого маніпулювання заголовками, ведення журналів або умовної логіки. Для складнішої обробки рекомендуються фільтри WebAssembly.

Обсяг памʼяті Lua значно менший, ніж у WebAssembly. [Результати тестів](https://github.com/liamawhite/lua-vs-wasm-envoy) показують, що Lua споживає приблизно 20–26 MiB незалежно від паралельності, тоді як WebAssembly коливається від ~110 MiB за низької паралельності до ~290 MiB за високої:

| Паралельність | Lua (MiB) | Wasm (MiB) |
|---|---|---|
| 1 | 19.79 | 117.7 |
| 2 | 23.07 | 132.5 |
| 4 | 22.63 | 152.0 |
| 8 | 23.97 | 190.9 |
| 16 | 25.66 | 291.8 |
