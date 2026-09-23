---
title: Встановлення декількох панелей управління Istio в одному кластері
description: Встановлення декілька панелей управління Istio в одному кластері за допомогою revisions і discoverySelectors.
weight: 55
keywords: [multiple,control,istiod,local]
owner: istio/wg-environments-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

Цей посібник проведе вас через процес встановлення кількох панелей управління Istio в одному кластері та налаштування робочих навантажень для конкретних панелей управління. Ця модель розгортання передбачає наявність однієї панелі управління Kubernetes з кількома панелями управління та мережами Istio. Розмежування між мережами забезпечується за допомогою просторів імен Kubernetes та RBAC.

{{< image width="90%"
    link="single-cluster-multiple-istiods.svg"
    caption="Кілька мереж в одному кластері"
    >}}

Використовуючи `discoverySelectors`, ви можете обмежити ресурси Kubernetes у кластері до конкретних просторів імен, які управляються панеллю управління Istio. Це включає власні ресурси Istio (наприклад, Gateway, VirtualService, DestinationRule тощо), які використовуються для налаштування мережі. Крім того, `discoverySelectors` можна використовувати для налаштування того, які простори імен повинні містити config map `istio-ca-root-cert` для конкретної панелі управління Istio. Разом ці функції дозволяють операторам сервісної мережі вказати простори імен для певної панелі управління, що забезпечує мʼяку мультиорендність для кількох мереж на основі меж одного чи кількох просторів імен. Цей посібник використовує `discoverySelectors`, разом з можливостями ревізій Istio, щоб продемонструвати, як дві мережі можуть бути розгорнуті на одному кластері, кожна з яких працює з належним чином обмеженою підмножиною ресурсів кластера.

## Перед початком {#before-you-begin}

Цей посібник вимагає наявності кластера Kubernetes з будь-якою з [підтримуваних версій Kubernetes:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

Цей кластер буде хостити дві панелі управління, встановлених у двох різних системних просторах імен. Робочі навантаження мережі застосунків будуть працювати в кількох просторах імен, кожен з яких буде асоційований з одною або іншою панеллю управління на основі конфігурацій ревізій та селекторів виявлення.

## Конфігурація кластера {#cluster-configuration}

### Розгортання кількох панелей управління {#deploying-multiple-control-planes}

Розгортання кількох панелей управління Istio в одному кластері може бути досягнуто шляхом використання різних системних просторів імен для кожної панелі управління. Для визначення ресурсів і робочих навантажень, які управляються кожною панеллю управління, використовуються ревізії Istio та `discoverySelectors`.

1. Створіть перший системний простір імен `usergroup-1` та розгорніть в ньому `istiod`:

    {{< text bash >}}
    $ kubectl create ns usergroup-1
    $ kubectl label ns usergroup-1 usergroup=usergroup-1
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-1
    spec:
      profile: minimal
      revision: usergroup-1
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-1
      values:
        global:
          istioNamespace: usergroup-1
    EOF
    {{< /text >}}

2. Створіть другий системний простір імен `usergroup-2` та розгорніть в ньому `istiod`:

    {{< text bash >}}
    $ kubectl create ns usergroup-2
    $ kubectl label ns usergroup-2 usergroup=usergroup-2
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-2
    spec:
      profile: minimal
      revision: usergroup-2
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-2
      values:
        global:
          istioNamespace: usergroup-2
    EOF
    {{< /text >}}

3. Розгорніть політику для робочих навантажень в просторі імен `usergroup-1`, щоб приймати лише трафік з взаємним TLS:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-1-peerauth"
      namespace: "usergroup-1"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

4. Розгорніть політику для робочих навантажень в просторі імен `usergroup-2`, щоб приймати лише трафік з взаємним TLS:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-2-peerauth"
      namespace: "usergroup-2"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

### Перевірка створення кількох панелей управління {#verify-the-multiple-control-plane-creation}

1. Перевірте мітки на системних просторах імен для кожної панелі управління

    {{< text bash >}}
    $ kubectl get ns usergroup-1 usergroup-2 --show-labels
    NAME              STATUS   AGE     LABELS
    usergroup-1       Active   13m     kubernetes.io/metadata.name=usergroup-1,usergroup=usergroup-1
    usergroup-2       Active   12m     kubernetes.io/metadata.name=usergroup-2,usergroup=usergroup-2
    {{< /text >}}

2. Перевірте, що панелі управління розгорнуті та працюють:

    {{< text bash >}}
    $ kubectl get pods -n usergroup-1
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-1   istiod-usergroup-1-5ccc849b5f-wnqd6      1/1     Running   0                12m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n usergroup-2
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-2   istiod-usergroup-2-658d6458f7-slpd9      1/1     Running   0                12m
    {{< /text >}}

    Ви побачите, що створено по одному розгортанню `istiod` для кожної групи користувачів у зазначених просторах імен.

3. Виконайте наступні команди для отримання списку встановлених вебхуків:

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration
    NAME                                      WEBHOOKS   AGE
    istio-validator-usergroup-1-usergroup-1   1          18m
    istio-validator-usergroup-2-usergroup-2   1          18m
    istiod-default-validator                  1          18m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration
    NAME                                             WEBHOOKS   AGE
    istio-revision-tag-default-usergroup-1           4          18m
    istio-sidecar-injector-usergroup-1-usergroup-1   2          19m
    istio-sidecar-injector-usergroup-2-usergroup-2   2          18m
    {{< /text >}}

    Зверніть увагу, що вивід включає `istiod-default-validator` та `istio-revision-tag-default-usergroup-1`, які є стандартними конфігураціями вебхуків, що використовуються для обробки запитів, які надходять з ресурсів, не повʼязаних з жодною ревізією. В повністю обмеженому середовищі, де кожна панель управління повʼязана зі своїми ресурсами через правильне маркування простору імен, ці стандартні конфігурації вебхуків не повинні викликатися.

### Розгортання навантажень застосунків для кожної групи користувачів {#deploy-application-workloads-per-usergroup}

1. Створіть три простори імен для застосунків:

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl create ns app-ns-2
    $ kubectl create ns app-ns-3
    {{< /text >}}

2. Промаркуйте кожен простір імен, щоб асоціювати їх з відповідними панелями управління:

    {{< text bash >}}
    $ kubectl label ns app-ns-1 usergroup=usergroup-1 istio.io/rev=usergroup-1
    $ kubectl label ns app-ns-2 usergroup=usergroup-2 istio.io/rev=usergroup-2
    $ kubectl label ns app-ns-3 usergroup=usergroup-2 istio.io/rev=usergroup-2
    {{< /text >}}

3. Розгорніть по одному застосунку `curl` та `httpbin` для кожного простору імен:

    {{< text bash >}}
    $ kubectl -n app-ns-1 apply -f samples/curl/curl.yaml
    $ kubectl -n app-ns-1 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-2 apply -f samples/curl/curl.yaml
    $ kubectl -n app-ns-2 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-3 apply -f samples/curl/curl.yaml
    $ kubectl -n app-ns-3 apply -f samples/httpbin/httpbin.yaml
    {{< /text >}}

4. Зачекайте кілька секунд, поки контейнери `httpbin` та `curl` запустяться з доданими sidecar контейнерами:

    {{< text bash >}}
    $ kubectl get pods -n app-ns-1
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-zc2v4   2/2     Running   0          115m
    curl-78ff5975c6-fml7c     2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-2
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-sd9ln   2/2     Running   0          115m
    curl-78ff5975c6-sz728     2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-3
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-8ll27   2/2     Running   0          115m
    curl-78ff5975c6-sg4tq     2/2     Running   0          115m
    {{< /text >}}

### Перевірка відповідності між застосунками та панелями управління {#verify-the-application-to-control-plane-mapping}

Тепер, коли застосунки розгорнуто, ви можете використовувати команду `istioctl ps`, щоб підтвердити, що навантаження застосунків управляються відповідними панелями управління. Наприклад, `app-ns-1` управляється `usergroup-1`, а `app-ns-2` та `app-ns-3` управляються `usergroup-2`:

{{< text bash >}}
$ istioctl ps -i usergroup-1
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-hccpf.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
curl-78ff5975c6-9zb77.app-ns-1       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

{{< text bash >}}
$ istioctl ps -i usergroup-2
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-vvcqj.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
httpbin-9dbd644c7-xzgfm.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
curl-78ff5975c6-fthmt.app-ns-2       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
curl-78ff5975c6-nxtth.app-ns-3       Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

### Перевірка доступності pfcnjceyrsd ТІЛЬКИ всередині відповідної групи користувачів {#verify-the-application-connectivity-is-only-within-the-respective-usergroup}

1. Надішліть запит з podʼа `curl` в `app-ns-1` у `usergroup-1` до сервісу `httpbin` у `app-ns-2` у `usergroup-2`. Такий запит повинен зазнати невдачі:

    {{< text bash >}}
    $ kubectl -n app-ns-1 exec "$(kubectl -n app-ns-1 get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sIL http://httpbin.app-ns-2.svc.cluster.local:8000
    HTTP/1.1 503 Service Unavailable
    content-length: 95
    content-type: text/plain
    date: Sat, 24 Dec 2022 06:54:54 GMT
    server: envoy
    {{< /text >}}

2. Надішліть запит з podʼа `curl` в `app-ns-2` у `usergroup-2` до сервісу `httpbin` у `app-ns-3` у `usergroup-2`. Такий запит повинен бути успішним:

    {{< text bash >}}
    $ kubectl -n app-ns-2 exec "$(kubectl -n app-ns-2 get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sIL http://httpbin.app-ns-3.svc.cluster.local:8000
    HTTP/1.1 200 OK
    server: envoy
    date: Thu, 22 Dec 2022 15:01:36 GMT
    content-type: text/html; charset=utf-8
    content-length: 9593
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3
    {{< /text >}}

## Очищення {#cleanup}

1. Вилучить першу групу користувачів:

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-1 --set values.global.istioNamespace=usergroup-1
    $ kubectl delete ns app-ns-1 usergroup-1
    {{< /text >}}

2. Вилучить другу групу користувачів:

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-2 --set values.global.istioNamespace=usergroup-2
    $ kubectl delete ns app-ns-2 app-ns-3 usergroup-2
    {{< /text >}}

{{< warning >}}
Адміністратор кластера повинен переконатися, що адміністратори мереж не мають дозволу на виконання глобальної команди `istioctl uninstall --purge`, оскільки це призведе до видалення всіх панелей управління в кластері.
{{< /warning >}}
