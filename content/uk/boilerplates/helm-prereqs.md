---
---
## Попередні вимоги {#prerequisites}

1. Виконайте будь-яке необхідне [налаштування для вашої платформи](/docs/setup/platform-setup/).

1. Перевірте [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

1. [Встановіть останню версію клієнта Helm](https://helm.sh/docs/intro/install/). Версії Helm, випущені до [найстарішого поточного підтримуваного випуску Istio](docs/releases/supported-releases/#support-status-of-istio-releases), не тестуються, не підтримуються і не рекомендуються.

1. Налаштуйте репозиторій Helm:

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}
