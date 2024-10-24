---
title: Docker Desktop
description: Інструкції для налаштування Docker Desktop для Istio.
weight: 15
skip_seealso: true
aliases:
    - /uk/docs/setup/kubernetes/prepare/platform-setup/docker-for-desktop/
    - /uk/docs/setup/kubernetes/prepare/platform-setup/docker/
    - /uk/docs/setup/kubernetes/platform-setup/docker/
keywords: [platform-setup,kubernetes,docker-desktop]
owner: istio/wg-environments-maintainers
test: no
---

1. Щоб запустити Istio з Docker Desktop, встановіть версію, яка містить [підтримувану версію Kubernetes](/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}}).

1. Якщо ви хочете запустити Istio під управлінням вбудованого Kubernetes Docker Desktop, потрібно збільшити обмеження пам’яті Docker в панелі *Resources->Advanced* налаштувань Docker Desktop. Встановіть ресурси не менше ніж 8.0 `GB` пам’яті та 4 `CPUs`.

    {{< image width="60%" link="./dockerprefs.png" caption="Налаштування Docker" >}}

    {{< warning >}}
    Мінімальні вимоги до пам’яті можуть варіюватися. 8 `GB` є достатнім для запуску Istio та Bookinfo. Якщо у вас недостатньо пам’яті, виділеної в Docker Desktop, можуть виникнути наступні помилки:

    - збої при завантаженні образів
    - тайм-аути перевірки стану
    - збої kubectl на хості
    - загальна нестабільність мережі гіпервізора

    Додаткові ресурси Docker Desktop можна звільнити за допомогою:

    {{< text bash >}}
    $ docker system prune
    {{< /text >}}

    {{< /warning >}}
