---
title: Очищення
description: Етапи очищення для балансування навантаження по локаціях.
weight: 30
keywords: [locality,load balancing]
test: yes
owner: istio/wg-networking-maintainers
---
Тепер, коли ви виконали завдання з балансування навантаження по локаціях, приберемось.

## Видаліть згенеровані файли {#remove-generated-files}

{{< text bash >}}
$ rm -f sample.yaml helloworld-region*.zone*.yaml
{{< /text >}}

## Видаліть простір імен `sample` {#remove-the-sample-namespace}

{{< text bash >}}
$ for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" delete ns sample --ignore-not-found=true; \
  done
{{< /text >}}

**Вітаємо! Ви успішно виконали завдання з балансування навантаження по локаціях!
