---
title: k3d
description: Інструкції для налаштування k3d для Istio.
weight: 28
skip_seealso: true
keywords: [platform-setup,kubernetes,k3d,k3s]
owner: istio/wg-environments-maintainers
test: no
---

k3d є легкою обгорткою для запуску [k3s](https://github.com/rancher/k3s) (мінімального дистрибутиву Kubernetes від Rancher Lab) в Docker. k3d полегшує створення одновузлових та багатовузлових кластерів k3s у Docker, наприклад, для локальної розробки на Kubernetes.

## Попередні умови {#prerequisites}

- Для використання k3d вам також потрібно [встановити Docker](https://docs.docker.com/install/).
- Встановіть останню версію [k3d](https://k3d.io/v5.4.7/#installation).
- Для взаємодії з кластером Kubernetes встановіть [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
- (Необов’язково) [Helm](https://helm.sh/docs/intro/install/) — менеджер пакетів для Kubernetes.

## Встановлення {#installation}

1.  Створіть кластер і вимкніть `Traefik` за допомогою наступної команди:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1.  Щоб переглянути список кластерів k3d, скористайтеся наступною командою:

    {{< text bash >}}
    $ k3d cluster list
    k3s-default
    {{< /text >}}

1.  Щоб переглянути локальні контексти Kubernetes, скористайтеся наступною командою.

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         k3d-k3s-default      k3d-k3s-default      k3d-k3s-default
    {{< /text >}}

    {{< tip >}}
    `k3d-` додається до імені контексту та кластеру, наприклад: `k3d-k3s-default`.
    {{< /tip >}}

2.  Якщо ви запускаєте кілька кластерів, вам потрібно вибрати, з яким кластером буде взаємодіяти `kubectl`. Ви можете встановити стандартний кластер для `kubectl`, змінивши поточний контекст у файлі [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). Також ви можете виконати наступну команду, щоб встановити поточний контекст для `kubectl`.

    {{< text bash >}}
    $ kubectl config use-context k3d-k3s-default
    Switched to context "k3d-k3s-default".
    {{< /text >}}

## Налаштування Istio для k3d {#set-up-istio-for-k3d}

1.  Після налаштування кластера k3d ви можете перейти до [встановлення Istio за допомогою Helm 3](/docs/setup/install/helm/) на ньому.

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ helm install istio-base istio/base -n istio-system --wait
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1.  (Необов’язково) Встановіть ingress gateway:

    {{< text bash >}}
    $ helm install istio-ingressgateway istio/gateway -n istio-system --wait
    {{< /text >}}

## Налаштування Dashboard UI для k3d {#set-up-dashboard-ui-for-k3d}

k3d не має вбудованого Dashboard UI, як minikube. Але ви все ще можете налаштувати Dashboard, вебінтерфейс Kubernetes, для перегляду вашого кластера. Слідуйте цим інструкціям, щоб налаштувати Dashboard для k3d.

1.  Щоб розгорнути Dashboard, виконайте наступні команди:

    {{< text bash >}}
    $ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    $ helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
    {{< /text >}}

1.  Перевірте, що Dashboard розгорнуто та працює.

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-8c47d4b5d-dd2ks    1/1     Running   0          25s
    kubernetes-dashboard-67bd8fc546-4xfmm        1/1     Running   0          25s
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

    Перейдіть до [Kubernetes Dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard-web:web/proxy/) для перегляду ваших розгортань та сервісів.

    {{< warning >}}
    Ви повинні зберегти ваш токен, інакше вам доведеться виконувати крок номер 4 кожного разу, коли вам потрібен токен для входу в Dashboard.
    {{< /warning >}}

## Видалення {#uninstall}

1.  Коли ви закінчите експериментувати та захочете видалити поточний кластер, скористайтеся наступною командою:

    {{< text bash >}}
    $ k3d cluster delete k3s-default
    Deleting cluster "k3s-default" ...
    {{< /text >}}
