---
title: Kubernetes Gardener
description: Інструкції для налаштування кластера Gardener для використання з Istio.
weight: 35
aliases:
    - /uk/docs/setup/kubernetes/platform-setup/gardener/
skip_seealso: true
keywords: [platform-setup,kubernetes,gardener,sap]
owner: istio/wg-environments-maintainers
test: no
---

## Ініціалізація Gardener {#bootstrapping-gardener}

Щоб налаштувати власний [Gardener](https://gardener.cloud) для потреб вашої організації з Kubernetes-as-a-Service, дотримуйтесь
[документації](https://github.com/gardener/gardener/blob/master/docs/README.md). Для тестування ви можете налаштувати [Gardener на вашому ноутбуці](https://github.com/gardener/gardener/blob/master/docs/development/getting_started_locally.md), скопіювавши вихідний код репозиторію та просто виконавши команду `make kind-up gardener-up` (найпростіший спосіб для розробників перевірити Gardener!).

Альтернативно, компанія [`23 Technologies GmbH`](https://23technologies.cloud/) пропонує повністю керований сервіс Gardener, який зручно працює з усіма підтримуваними провайдерами хмарних послуг та має безкоштовну пробну версію: [`Okeanos`](https://okeanos.dev/). Аналогічно, провайдери хмарних послуг, такі як [`STACKIT`](https://stackit.de/), [`B'Nerd`](https://bnerd.com/), [`MetalStack`](https://metalstack.cloud/) та багато інших, використовують Gardener як свій Kubernetes Engine.

Щоб дізнатися більше про початок цього open source проєкту, прочитайте [Оновлення проєкту Gardener](https://kubernetes.io/blog/2019/12/02/gardener-project-update/) та [Gardener - The Kubernetes Botanist](https://kubernetes.io/blog/2018/05/17/gardener/) на [`kubernetes.io`](https://kubernetes.io/blog).

[Налаштуйте Gardener для використання з Istio, власними доменами та сертифікатами](https://gardener.cloud/docs/extensions/others/gardener-extension-shoot-cert-service/tutorials/tutorial-custom-domain-with-istio/) — це докладний посібник для кінцевого користувача Gardener.

### Встановлення та налаштування `kubectl` {#install-and-configure-kubectl}

1.  Якщо у вас вже є `kubectl` CLI, запустіть `kubectl version --short`, щоб перевірити версію. Вам потрібна актуальна версія, яка принаймні відповідає версії вашого Kubernetes кластера, який ви хочете замовити. Якщо ваш `kubectl` застарілий, виконайте наступний крок для встановлення новішої версії.

1.  [Встановіть CLI `kubectl`](https://kubernetes.io/docs/tasks/tools/).

### Доступ до Gardener {#access-gardener}

1.  Створіть проєкт в Gardener dashboard. Це фактично створить
    Kubernetes namespace з назвою `garden-<my-project>`.

1.  [Налаштуйте доступ до вашого проєкту в Gardener](https://gardener.cloud/docs/dashboard/usage/gardener-api/)
    за допомогою kubeconfig.

    {{< tip >}}
    Ви можете пропустити цей крок, якщо збираєтеся створювати та взаємодіяти зі своїм кластером за допомогою Gardener dashboard та вбудованого web-терміналу; цей крок необхідний лише для програмного доступу.
    {{< /tip >}}

    Якщо ви ще не є адміністратором Gardener, ви можете створити технічного користувача в Gardener dashboard: перейдіть до розділу "Members" і додайте службовий обліковий запис. Ви можете потім завантажити kubeconfig для вашого проєкту.  Переконайтеся, що ви виконуєте `export KUBECONFIG=garden-my-project.yaml` у вашій оболонці.

    ![Завантаження kubeconfig для Gardener](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/01-add-service-account.png "завантаження kubeconfig за допомогою облікового запису служби")

### Створення кластера Kubernetes {#creating-a-kubernetes-cluster}

Ви можете створити свій кластер, використовуючи `kubectl` CLI, надавши файл yaml зі специфікацією кластера. Приклад для GCP можна знайти [тут](https://github.com/gardener/gardener/blob/master/example/90-shoot.yaml). Переконайтеся, що namespace відповідає вашому проєкту. Потім застосуйте підготовлений так званий маніфест кластера "shoot" за допомогою `kubectl`:

{{< text bash >}}
$ kubectl apply --filename my-cluster.yaml
{{< /text >}}

Альтернативою є створення кластера, слідуючи майстру створення кластерів у Gardener dashboard:

![створення shoot кластера](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/dashboard-demo.gif "створення shoot через dashboard")

### Налаштування `kubectl` для вашого кластера {#configure-kubectl-for-your-cluster}

Тепер ви можете завантажити kubeconfig для щойно створеного кластера в Gardener dashboard або за допомогою CLI наступним чином:

{{< text bash >}}
$ kubectl --namespace shoot--my-project--my-cluster get secret kubecfg --output jsonpath={.data.kubeconfig} | base64 --decode > my-cluster.yaml
{{< /text >}}

Цей файл kubeconfig має повний адміністративний доступ до вашого кластера. Для будь-яких дій із кластером переконайтеся, що у вас встановлено `export KUBECONFIG=my-cluster.yaml`.

## Очищення {#cleaning-up}

Використовуйте Gardener dashboard, щоб видалити свій кластер, або виконайте наступні команди за допомогою `kubectl`, вказавши на ваш `garden-my-project.yaml` kubeconfig:

{{< text bash >}}
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project annotate shoot my-cluster confirmation.garden.sapcloud.io/deletion=true
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project delete shoot my-cluster
{{< /text >}}
