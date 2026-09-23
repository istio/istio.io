---
---
Розглянемо кластер з двома встановленими ревізіями `{{< istio_previous_version_revision >}}-1` та `{{< istio_full_version_revision >}}`. Оператор кластера створює теґ ревізії `prod-stable`, який вказує на стару, стабільну `{{< istio_previous_version_revision >}}-1` версію, і теґ ревізії `prod-canary`, який вказує на новішу `{{< istio_full_version_revision >}}` ревізію. Цього стану можна досягти за допомогою наступних команд:
