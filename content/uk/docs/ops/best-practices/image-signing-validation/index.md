---
title: Підписування та валідація образів
description: Описує, як використовувати підписи образів для перевірки походження образів Istio.
weight: 35
aliases: []
keywords: [install,signing]
owner: istio/wg-environments-maintainers
test: n/a
---

Ця сторінка описує, як використовувати [Cosign](https://github.com/sigstore/cosign) для валідації походження артефактів образів Istio.

Cosign — це інструмент, розроблений у рамках проєкту [sigstore](https://www.sigstore.dev), що спрощує підписування та валідацію підписаних артефактів Open Container Initiative (OCI), таких як контейнери.

Починаючи з Istio 1.12, ми підписуємо всі офіційно опубліковані образи контейнерів у рамках нашого процесу випуску нової версії. Кінцеві користувачі можуть перевіряти ці образи за допомогою процесу, описаного нижче.

Цей процес підходить як для ручного виконання, так і для інтеграції з конвеєрами збірки або розгортання для автоматизованої перевірки артефактів.

## Необхідні умови {#prerequisites}

Перш ніж почати, виконайте наступне:

1. Завантажте останню збірку [Cosign](https://github.com/sigstore/cosign/releases/latest) для вашої архітектури, а також її підпис.
1. Перевірте підпис бінарного файлу `cosign`:

   {{< text bash >}}
$ openssl dgst -sha256 \
    -verify <(curl -ssL https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub) \
    -signature <(cat /path/to/cosign.sig | base64 -d) \
    /path/to/cosign-binary
   {{< /text >}}

1. Зробіть бінарний файл виконуваним (`chmod +x`) і перемістіть його в теку, що знаходиться в `PATH`.

## Валідація образу {#validating-image}

Щоб перевірити образ контейнера, виконайте наступне:

{{< text bash >}}
$ ./cosign-binary verify --key "https://istio.io/misc/istio-key.pub" {{< istio_docker_image "pilot" >}}
{{< /text >}}

Цей процес працюватиме для будь-якого випущеного образу або кандидата на випуск, зібраного за допомогою інфраструктури збирання Istio.

Приклад з виводом:

{{< text bash >}}
$ cosign verify --key "https://istio.io/misc/istio-key.pub" gcr.io/istio-release/pilot:1.12.0


Verification for gcr.io/istio-release/pilot:1.12.0 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"gcr.io/istio-release/pilot"},"image":{"docker-manifest-digest":"sha256:c37fd83f6435ca0966d653dc6ac42c9fe5ac11d0d5d719dfe97de84acbf7a32d"},"type":"cosign container image signature"},"optional":null}]
{{< /text >}}
