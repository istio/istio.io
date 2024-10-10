---
title: kind
description: Інструкції для налаштування kind для Istio.
weight: 30
skip_seealso: true
keywords: [platform-setup,kubernetes,kind]
owner: istio/wg-environments-maintainers
test: no
---

[kind](https://kind.sigs.k8s.io/) — це інструмент для запуску локальних кластерів Kubernetes за допомогою контейнерів Docker `nodes`. kind був переважно розроблений для тестування самого Kubernetes, але може використовуватися для локальної розробки або CI. Слідуйте цим інструкціям, щоб підготувати кластер kind для установки Istio.

## Попередні умови {#prerequisites}

- Будь ласка, використовуйте останню версію Go.
- Для використання kind вам також потрібно [встановити Docker](https://docs.docker.com/install/).
- Встановіть останню версію [kind](https://kind.sigs.k8s.io/docs/user/quick-start/).
- Збільшіть [ліміт памʼяті Docker](/docs/setup/platform-setup/docker/).

## Кроки установки {#installation-steps}

1.  Створіть кластер за допомогою наступної команди:

    {{< text bash >}}
    $ kind create cluster --name istio-testing
    {{< /text >}}

    `--name` використовується для присвоєння конкретної назви кластеру. Стандартно кластер отримає імʼя "kind".

1.  Щоб переглянути список кластерів kind, скористайтеся наступною командою:

    {{< text bash >}}
    $ kind get clusters
    istio-testing
    {{< /text >}}

1.  Щоб переглянути локальні контексти Kubernetes, скористайтеся наступною командою.

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         kind-istio-testing   kind-istio-testing   kind-istio-testing
              minikube             minikube             minikube
    {{< /text >}}

    {{< tip >}}
    `kind` додається до імені контексту та кластеру, наприклад: `kind-istio-testing`.
    {{< /tip >}}

2.  Якщо ви запускаєте кілька кластерів, вам потрібно вибрати, з яким кластером буде взаємодіяти `kubectl`. Ви можете встановити стандартний кластер в `kubectl`, змінивши поточний контекст у файлі [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). Також ви можете виконати наступну команду, щоб встановити поточний контекст для `kubectl`.

    {{< text bash >}}
    $ kubectl config use-context kind-istio-testing
    Switched to context "kind-istio-testing".
    {{< /text >}}

    Після налаштування кластера kind ви можете перейти до [встановлення Istio](/docs/setup/additional-setup/download-istio-release/) на ньому.

3.  Коли ви закінчите експериментувати та захочете видалити поточний кластер, скористайтеся наступною командою:

    {{< text bash >}}
    $ kind delete cluster --name istio-testing
    Deleting cluster "istio-testing" ...
    {{< /text >}}

## Налаштування MetalLB для kind {#setting-up-metallb-for-kind}

kind не має вбудованого способу надання IP-адрес для сервісів типу `Loadbalancer`. Щоб забезпечити призначення IP-адрес для сервісів `Gateway`, будь ласка, ознайомтеся з [цією інструкцією](https://kind.sigs.k8s.io/docs/user/loadbalancer/) для отримання додаткової інформації.

## Налаштування Dashboard UI для kind {#set-up-dashboard-ui-for-kind}

kind не має вбудованого Dashboard UI, як minikube. Але ви все ще можете налаштувати Dashboard, вебінтерфейс Kubernetes, для перегляду вашого кластера. Слідуйте цим інструкціям, щоб налаштувати Dashboard для kind.

1.  Щоб розгорнути Dashboard, виконайте наступну команду:

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    {{< /text >}}

1.  Перевірте, що Dashboard розгорнуто та працює.

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-76585494d8-zdb66   1/1     Running   0          39s
    kubernetes-dashboard-b7ffbc8cb-zl8zg         1/1     Running   0          39s
    {{< /text >}}

1.  Створіть `ServiceAccount` і `ClusterRoleBinding`, щоб надати адміністративний доступ до новоствореного кластера.

    {{< text bash >}}
    $ kubectl create serviceaccount -n kubernetes-dashboard admin-user
    $ kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
    {{< /text >}}

1.  Щоб увійти в Dashboard, вам потрібен Bearer Token. Використовуйте наступну команду, щоб зберегти токен у змінній.

    {{< text bash >}}
    $ token=$(kubectl -n kubernetes-dashboard create token admin-user)
    {{< /text >}}

    Виведіть токен за допомогою команди `echo` і скопіюйте його для входу в Dashboard.

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

1.  Ви можете отримати доступ до Dashboard, використовуючи командний рядок kubectl, виконавши наступну команду:

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    Перейдіть до [Kubernetes Dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) для перегляду ваших розгортань та сервісів.

    {{< warning >}}
    Ви повинні зберегти ваш токен, інакше вам доведеться виконувати крок номер 4 кожного разу, коли вам потрібен токен для входу в Dashboard.
    {{< /warning >}}
