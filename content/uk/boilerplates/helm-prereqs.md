---
---
## Попередні вимоги {#prerequisites}

1. Виконайте будь-яке необхідне [налаштування для вашої платформи](/docs/setup/platform-setup/).

1. Перевірте [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

1. [Встановіть клієнт Helm](https://helm.sh/docs/intro/install/), версії 3.6 або вище.

1. Налаштуйте репозиторій Helm:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
