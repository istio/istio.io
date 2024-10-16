---
title: Політика витягування для модулів WebAssembly
description: Описує, як Istio визначає, чи слід витягувати модулі Wasm або використовувати кешовані версії.
weight: 10
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
status: Alpha
---

{{< boilerplate alpha >}}

API [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin) надає метод для [розповсюдження модулів Wasm](/docs/tasks/extensibility/wasm-module-distribution) на проксі. Оскільки кожен проксі буде витягувати модулі Wasm з віддаленого реєстру або HTTP-сервера, розуміння того, як Istio вибирає витягування модулів, важливо як з погляду зручності використання, так і продуктивності.

## Політика витягування образів та винятки {#image-pull-policy-and-exceptions}

Аналогічно до `ImagePullPolicy` у Kubernetes, [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin) також має поняття `IfNotPresent` та `Always`, що означає "використовувати кешований модуль" і "завжди витягувати модуль, не зважаючи на кеш" відповідно.

Користувачі явно налаштовують поведінку витягування модулів Wasm за допомогою поля `ImagePullPolicy`. Однак поведінка, надана користувачем, може бути перевизначена Istio в наступних сценаріях:

1. Якщо користувач встановлює `sha256` у [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin), незалежно від `ImagePullPolicy`, використовується політика `IfNotPresent`.
1. Якщо поле `url` вказує на OCI-образ і має суфікс digest (наприклад, `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`), використовується політика `IfNotPresent`.

Коли `ImagePullPolicy` не вказана для ресурсу, Istio стандартно використовує поведінку `IfNotPresent`. Однак, якщо вказане поле `url` містить OCI-образ з теґом `latest`, Istio використовує поведінку `Always`.

## Життєвий цикл кешованих модулів {#lifecycle-of-cached-modules}

Кожен проксі, хай то буде sidecar проксі або шлюз, кешує модулі Wasm. Тривалість кешованого модуля Wasm обмежена тривалістю відповідного podʼа. Крім того, існує механізм термінації для підтримання мінімального обсягу памʼяті проксі: якщо кешований модуль Wasm не використовується протягом певного часу, модуль видаляється.

Цю термінацію можна налаштувати через змінні середовища `WASM_MODULE_EXPIRY` і `WASM_PURGE_INTERVAL` [pilot-proxy](/docs/reference/commands/pilot-agent/#envvars), які відповідають за тривалість термінації та інтервал перевірки термінації відповідно.

## Значення "Always" {#the-meaning-of-always}

У Kubernetes, `ImagePullPolicy: Always` означає, що образ витягується безпосередньо з джерела щоразу, коли створюється pod. Кожного разу, коли новий pod запускається, Kubernetes витягує образ знову.

Для `WasmPlugin`, `ImagePullPolicy: Always` означає, що Istio буде витягувати образ безпосередньо з джерела щоразу, коли створюється або змінюється відповідний ресурс Kubernetes `WasmPlugin`. Зверніть увагу, що зміна не тільки в `spec`, але і в `metadata` викликає витягування модуля Wasm, коли використовується політика `Always`. Це може означати, що образ витягується з джерела кілька разів протягом життєвого циклу podʼа та протягом життєвого циклу окремого проксі.
