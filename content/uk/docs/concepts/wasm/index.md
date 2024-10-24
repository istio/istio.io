---
title: Розширюваність
description: Описує систему втулків WebAssembly від Istio.
weight: 50
keywords: [wasm,webassembly,emscripten,extension,plugin,filter]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

WebAssembly є технологією ізоляції, яку можна використовувати для розширення проксі Istio (Envoy). API для пісочниці Proxy-Wasm замінює Mixer як основний механізм розширення в Istio.

Цілі використання пісочниці WebAssembly:

- **Ефективність** — розширення додає мінімальні затримки, навантаження на ЦП і використання пам’яті.
- **Функціональність** — розширення може забезпечувати виконання політики, збір телеметрії та виконання мутацій корисного навантаження.
- **Ізоляція** — помилка програмування або збій одного втулка не впливає на інші втулки.
- **Конфігурація** — втулки налаштовуються за допомогою API, яке узгоджується з іншими API Istio. Розширення можна налаштувати динамічно.
- **Оператор** — розширення можна випробувати в тестовому режимі, а також розгорнути з конфігурацією log-only, fail-open або fail-close.
- **Розробник розширень** — втулок можна написати кількома мовами програмування.

Ця [відеопрезентація](https://youtu.be/XdWmm_mtVXI) є вступом до архітектури інтеграції WebAssembly.

## Високорівнева архітектура {#high-level-architecture}

Розширення Istio (втулки Proxy-Wasm) мають кілька компонентів:

- **Інтерфейс постачальника фільтрів (SPI)** для створення втулків Proxy-Wasm для фільтрів.
- **Пісочниця** з V8 Wasm Runtime, вбудована в Envoy.
- **Host API** для роботи з заголовками, трейлерами та метаданими.
- **API викликів** для gRPC і HTTP запитів.
- **API статистики та ведення журналів** для збору метрик і моніторингу.

{{< image width="80%" link="./extending.svg" caption="Розширення Istio/Envoy" >}}

## Приклад {#example}

Приклад втулка Proxy-Wasm на C++ для фільтра можна знайти [тут](https://github.com/istio-ecosystem/wasm-extensions/tree/master/example). Ви можете слідувати [цьому посібнику](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md) для реалізації розширення Wasm за допомогою C++.

## Екосистема {#ecosystem}

- [Istio Ecosystem Wasm Extensions](https://github.com/istio-ecosystem/wasm-extensions)
- [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)
- [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)
- [WebAssembly Hub](https://webassemblyhub.io/)
- [WebAssembly Extensions For Network Proxies (відео)](https://www.youtube.com/watch?v=OIUPf8m7CGA)
