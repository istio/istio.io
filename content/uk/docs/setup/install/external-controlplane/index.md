---
title: Встановлення Istio із зовнішньою панеллю управління
description: Встановіть Istio із зовнішньою панеллю управління та віддаленою панеллю даних кластера.
weight: 50
aliases:
    - /uk/docs/setup/additional-setup/external-controlplane/
    - /latest/uk/docs/setup/additional-setup/external-controlplane/
keywords: [external,control,istiod,remote]
owner: istio/wg-environments-maintainers
test: yes
---

Цей посібник проведе вас через процес встановлення {{< gloss "зовнішня панель управління" >}}зовнішньої панелі управління{{< /gloss >}} та зʼєднання одного або кількох {{< gloss "віддалений кластер" >}}віддалених кластерів{{< /gloss >}} з нею. [Модель розгортання](/docs/ops/deployment/deployment-models/#control-plane-models) зовнішньої панелі управління дозволяє оператору мережі встановлювати та керувати панеллю управління у зовнішньому кластері, відокремленому від кластера даних (або кількох кластерів), які складають мережу. Ця модель розгортання забезпечує чітке розмежування між операторами мережі та адміністраторами мережі. Оператори мережі встановлюють та керують панелями управління Istio, тоді як адміністратори мережі лише конфігурують мережу.

{{< image width="75%"
    link="external-controlplane.svg"
    caption="Зовнішній кластер панелі управління та віддалений кластер"
    >}}

Проксі Envoy (sidecars та шлюзи), що працюють у віддаленому кластері, отримують доступ до зовнішнього istiod через шлюз вхідного трафіку, який відкриває точки доступу, необхідні для виявлення, CA, інʼєкції та валідації.

Хоча конфігурація та управління зовнішньою панеллю управління здійснюється оператором мережі у зовнішньому кластері, перший віддалений кластер, підключений до зовнішньої панелі управління, служить конфігураційним кластером для самої мережі. Адміністратор мережі використовуватиме конфігураційний кластер для налаштування ресурсів мережі (шлюзи, віртуальні сервіси тощо), а також для мережевих служб самої мережі. Зовнішня панель управління віддалено отримуватиме цю конфігурацію з API-сервера Kubernetes, як показано на діаграмі вище.

## Перед початком {#before-you-begin}

### Кластери {#clusters}

Цей посібник передбачає наявність двох кластерів Kubernetes з будь-якою з [підтримуваною версією Kubernetes:](/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}.

Перший кластер буде хостити {{< gloss "зовнішня панель управління" >}}зовнішню панель управління{{< /gloss >}}, встановлену в просторі імен `external-istiod`. Також буде встановлено ingress gateway в просторі імен `istio-system`, щоб забезпечити доступ до зовнішньої панелі управління з інших кластерів.

Другий кластер є {{< gloss "віддалений кластер" >}}віддаленим кластером{{< /gloss >}}, який буде запускати робочі навантаження мережі. Його API-сервер Kubernetes також надає конфігурацію мережі, яку використовує зовнішня панель управління (istiod) для налаштування проксі-серверів навантаження.

### Доступ до API-сервера {#api-server-access}

API-сервер Kubernetes у віддаленому кластері має бути доступний для зовнішньої панелі управління. Багато постачальників хмарних послуг роблять API-сервери публічно доступними через мережеві балансувальники навантаження (NLB). Якщо API-сервер недоступний безпосередньо, вам потрібно буде змінити процедуру встановлення для забезпечення доступу. Наприклад, шлюз [east-west](https://en.wikipedia.org/wiki/East-west_traffic), який використовується в [мультикластерній конфігурації](#adding-clusters), також можна використовувати для надання доступу до API-сервера.

### Змінні середовища {#environment-variables}

У цьому посібнику будуть використовуватися наступні змінні середовища для спрощення інструкцій:

| Змінна                   | Опис                                                                 |
|--------------------------|----------------------------------------------------------------------|
| `CTX_EXTERNAL_CLUSTER`   | Імʼя контексту у файлі [конфігурації Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/), який використовується для доступу до зовнішнього кластера управління. |
| `CTX_REMOTE_CLUSTER`     | Імʼя контексту у файлі [конфігурації Kubernetes](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/), який використовується для доступу до віддаленого кластера. |
| `REMOTE_CLUSTER_NAME`    | Імʼя віддаленого кластера.                                            |
| `EXTERNAL_ISTIOD_ADDR`   | Імʼя хосту для шлюзу доступу у кластері зовнішнього управління. Використовується віддаленим кластером для доступу до зовнішнього контролера. |
| `SSL_SECRET_NAME`        | Імʼя секрету, що містить TLS сертифікати для шлюзу доступу у кластері зовнішнього управління. |

Налаштуйте змінні `CTX_EXTERNAL_CLUSTER`, `CTX_REMOTE_CLUSTER` та `REMOTE_CLUSTER_NAME` зараз. Інші змінні будуть налаштовані пізніше.

{{< text syntax=bash snip_id=none >}}
$ export CTX_EXTERNAL_CLUSTER=<your external cluster context>
$ export CTX_REMOTE_CLUSTER=<your remote cluster context>
$ export REMOTE_CLUSTER_NAME=<your remote cluster name>
{{< /text >}}

## Конфігурація кластерів {#cluster-configuration}

### Кроки для оператора сервісної мережі {#mesh-operator-steps}

Оператор мережі відповідає за встановлення та управління зовнішньою панеллю управління Istio на зовнішньому кластері. Це включає в себе: конфігурацію ingress gateway у зовнішньому кластері, що дозволяє віддаленому кластеру отримати доступ до панелі управління; встановлення конфігурації веб-хука інжектора sidecar на віддаленому кластері, щоб він використовував зовнішню панель управління.

#### Налаштування шлюзу у зовнішньому кластері {#set-up-a-gateway-in-the-external-cluster}

1. Створіть конфігураційний файл для установки шлюзу доступу (ingress gateway), який відкриє порти панелі управління для інших кластерів:

    {{< text bash >}}
    $ cat <<EOF > controlplane-gateway.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            k8s:
              service:
                ports:
                  - port: 15021
                    targetPort: 15021
                    name: status-port
                  - port: 15012
                    targetPort: 15012
                    name: tls-xds
                  - port: 15017
                    targetPort: 15017
                    name: tls-webhook
    EOF
    {{< /text >}}

    Потім встановіть шлюз у просторі імен `istio-system` на зовнішньому кластері:

    {{< text bash >}}
    $ istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

2. Виконайте наступну команду, щоб підтвердити, що шлюз доступу працює:

    {{< text bash >}}
    $ kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                                   READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-9d4c7f5c7-7qpzz   1/1     Running   0          29s
    istiod-68488cd797-mq8dn                1/1     Running   0          38s
    {{< /text >}}

    Ви помітите, що також створено розгортання `istiod` у просторі імен `istio-system`. Це використовується для конфігурації шлюзу доступу і НЕ є панеллю управління, яку використовують віддалені кластери.

    {{< tip >}}
    Цей шлюз доступу може бути налаштований для розміщення кількох зовнішніх панелей управління в різних просторах імен на зовнішньому кластері,
    хоча в цьому прикладі ви розгорнете тільки одну зовнішню панель управління `istiod` у просторі імен `external-istiod`.
    {{< /tip >}}

3. Налаштуйте своє середовище для експонування сервісу ingress gateway Istio за допомогою публічного імені хосту з TLS.

    Встановіть змінну середовища `EXTERNAL_ISTIOD_ADDR` на імʼя хосту та `SSL_SECRET_NAME` на секрет, що містить TLS сертифікати:

    {{< text bash >}}
    $ export EXTERNAL_ISTIOD_ADDR=<your external istiod host>
    $ export SSL_SECRET_NAME=<your external istiod secret>
    {{< /text >}}

    Ці інструкції припускають, що ви відкриваєте шлюз зовнішнього кластеру, використовуючи імʼя хоста з правильно підписаними сертифікатами DNS, оскільки це рекомендований підхід в операцінойму середовищі. Ознайомтеся з [завданням secure ingress](/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-tls-ingress-gateway-for-a-single-host) для отримання додаткової інформації про відкриття secure gateway.

    Ваші змінні середовища можуть виглядати так:

    {{< text bash >}}
    $ echo "$EXTERNAL_ISTIOD_ADDR" "$SSL_SECRET_NAME"
    myhost.example.com myhost-example-credential
    {{< /text >}}

    {{< tip >}}
    Якщо у вас немає DNS імені, але ви хочете експериментувати із зовнішньою панеллю управління в тестовому середовищі, ви можете отримати доступ до шлюзу, використовуючи IP-адресу зовнішнього балансувальника навантаження:

    {{< text bash >}}
    $ export EXTERNAL_ISTIOD_ADDR=$(kubectl -n istio-system --context="${CTX_EXTERNAL_CLUSTER}" get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export SSL_SECRET_NAME=NONE
    {{< /text >}}

    Це також вимагатиме кількох інших змін у конфігурації. Переконайтеся, що ви дотримуєтеся всіх відповідних кроків з наведених нижче інструкціях.
    {{< /tip >}}

#### Налаштування віддаленого кластера конфігурації {#set-up-the-remote-config-cluster}

1. Використовуйте профіль `remote`, щоб налаштувати установку Istio на віддаленому кластері. Це встановлює вебхук інʼєкції, який використовує інжектор зовнішньої панелі управління замість локального. Оскільки цей кластер також буде служити кластером конфігурації, CRD Istio та інші ресурси, які знадобляться на віддаленому кластері, також встановлюються за допомогою встановлення `global.configCluster` та `pilot.configMap` на `true`:

    {{< text syntax=bash snip_id=get_remote_config_cluster_iop >}}
    $ cat <<EOF > remote-config-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: remote
      values:
        global:
          istioNamespace: external-istiod
          configCluster: true
        pilot:
          configMap: true
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/cluster/${REMOTE_CLUSTER_NAME}/net/network1
        base:
          validationURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/validate
    EOF
    {{< /text >}}

    {{< tip >}}
    Якщо імʼя вашого кластера містить символи `/` (слеші), замініть їх на `--slash--` у полі `injectionURL`, наприклад, `injectionURL: https://1.2.3.4:15017/inject/cluster/`<mark>`cluster--slash--1`</mark>`/net/network1`.
    {{< /tip >}}

2. Якщо ви використовуєте IP-адресу для `EXTERNAL_ISTIOD_ADDR` замість правильного DNS імені хоста, змініть конфігурацію, щоб вказати адресу виявлення та шляхи замість URL-адрес:

    {{< warning >}}
    Це не рекомендується в операційному середовищі.
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e "s|injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017|injectionPath: |" \
      -e "/istioNamespace:/a\\
          remotePilotAddress: ${EXTERNAL_ISTIOD_ADDR}" \
      -e '/base:/,+1d' \
      remote-config-cluster.yaml; rm remote-config-cluster.yaml.bk
    {{< /text >}}

3. Встановіть конфігурацію у віддаленому кластері:

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"
    $ istioctl install -f remote-config-cluster.yaml --set values.defaultRevision=default --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

4. Підтвердіть, що конфігурація вебхука інʼєкції для віддаленого кластера була встановлена:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
    NAME                                         WEBHOOKS   AGE
    istio-revision-tag-default-external-istiod   4          2m2s
    istio-sidecar-injector-external-istiod       4          2m5s
    {{< /text >}}

5. Підтвердіть, що конфігурації вебхуків для валідації на віддаленому кластері були встановлені:

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
    NAME                              WEBHOOKS   AGE
    istio-validator-external-istiod   1          6m53s
    istiod-default-validator          1          6m53s
    {{< /text >}}

#### Налаштування панелі управління у зовнішньому кластері {#set-up-the-control-plane-in-the-external-cluster}

1. Створіть простір імен `external-istiod`, який буде використовуватися для розміщення зовнішньої панелі управління:

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

2. Панелі управління в зовнішньому кластері потрібен доступ до віддаленого кластера для виявлення сервісів, точок доступу та атрибутів podʼів. Створіть секрет із обліковими даними для доступу до `kube-apiserver` віддаленого кластера та встановіть його у зовнішньому кластері:

    {{< text bash >}}
    $ istioctl create-remote-secret \
      --context="${CTX_REMOTE_CLUSTER}" \
      --type=config \
      --namespace=external-istiod \
      --service-account=istiod \
      --create-service-account=false | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

3. Створіть конфігурацію Istio для встановлення панелі управління у просторі імен `external-istiod` у зовнішньому кластері. Зверніть увагу, що `istiod` налаштований на використання локально змонтованого configmap `istio`, а змінна середовища `SHARED_MESH_CONFIG` має значення `istio`. Це вказує `istiod` обʼєднати значення, встановлені адміністратором сервісної мережі в configmap кластера конфігурації, із значеннями у локальному configmap, встановленому оператором сервісної мережі, які матимуть пріоритет у разі конфліктів:

    {{< text syntax=bash snip_id=get_external_istiod_iop >}}
    $ cat <<EOF > external-istiod.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: empty
      meshConfig:
        rootNamespace: external-istiod
        defaultConfig:
          discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
          proxyMetadata:
            XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
            CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
      components:
        pilot:
          enabled: true
          k8s:
            overlays:
            - kind: Deployment
              name: istiod
              patches:
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: config-volume
                  configMap:
                    name: istio
              - path: spec.template.spec.volumes[100]
                value: |-
                  name: inject-volume
                  configMap:
                    name: istio-sidecar-injector
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: config-volume
                  mountPath: /etc/istio/config
              - path: spec.template.spec.containers[0].volumeMounts[100]
                value: |-
                  name: inject-volume
                  mountPath: /var/lib/istio/inject
            env:
            - name: INJECTION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: VALIDATION_WEBHOOK_CONFIG_NAME
              value: ""
            - name: EXTERNAL_ISTIOD
              value: "true"
            - name: LOCAL_CLUSTER_SECRET_WATCHER
              value: "true"
            - name: CLUSTER_ID
              value: ${REMOTE_CLUSTER_NAME}
            - name: SHARED_MESH_CONFIG
              value: istio
      values:
        global:
          externalIstiod: true
          caAddress: $EXTERNAL_ISTIOD_ADDR:15012
          istioNamespace: external-istiod
          operatorManageWebhooks: true
          configValidation: false
          meshID: mesh1
          multiCluster:
            clusterName: ${REMOTE_CLUSTER_NAME}
          network: network1
    EOF
    {{< /text >}}

4. Якщо ви використовуєте IP-адресу для `EXTERNAL_ISTIOD_ADDR` замість правильного DNS імені хоста, видаліть метадані проксі та оновіть змінні середовища конфігурації вебхука в конфігурації:

    {{< warning >}}
    Це не рекомендується в операційному середовищі.
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e '/proxyMetadata:/,+2d' \
      -e '/INJECTION_WEBHOOK_CONFIG_NAME/{n;s/value: ""/value: istio-sidecar-injector-external-istiod/;}' \
      -e '/VALIDATION_WEBHOOK_CONFIG_NAME/{n;s/value: ""/value: istio-validator-external-istiod/;}' \
      external-istiod.yaml ; rm external-istiod.yaml.bk
    {{< /text >}}

5. Застосуйте конфігурацію Istio у зовнішньому кластері:

    {{< text bash >}}
    $ istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

6. Підтвердіть, що зовнішній `istiod` був успішно розгорнутий:

    {{< text bash >}}
    $ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                      READY   STATUS    RESTARTS   AGE
    istiod-779bd6fdcf-bd6rg   1/1     Running   0          70s
    {{< /text >}}

7. Створіть конфігурації Istio `Gateway`, `VirtualService` та `DestinationRule` для маршрутизації трафіку від шлюзу ingress до зовнішньої панелі управління:

    {{< text syntax=bash snip_id=get_external_istiod_gateway_config >}}
    $ cat <<EOF > external-istiod-gw.yaml
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: external-istiod-gw
      namespace: external-istiod
    spec:
      selector:
        istio: ingressgateway
      servers:
        - port:
            number: 15012
            protocol: https
            name: https-XDS
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
        - port:
            number: 15017
            protocol: https
            name: https-WEBHOOK
          tls:
            mode: SIMPLE
            credentialName: $SSL_SECRET_NAME
          hosts:
          - $EXTERNAL_ISTIOD_ADDR
    ---
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
       name: external-istiod-vs
       namespace: external-istiod
    spec:
        hosts:
        - $EXTERNAL_ISTIOD_ADDR
        gateways:
        - external-istiod-gw
        http:
        - match:
          - port: 15012
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 15012
        - match:
          - port: 15017
          route:
          - destination:
              host: istiod.external-istiod.svc.cluster.local
              port:
                number: 443
    ---
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: external-istiod-dr
      namespace: external-istiod
    spec:
      host: istiod.external-istiod.svc.cluster.local
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 15012
          tls:
            mode: SIMPLE
          connectionPool:
            http:
              h2UpgradePolicy: UPGRADE
        - port:
            number: 443
          tls:
            mode: SIMPLE
    EOF
    {{< /text >}}

8. Якщо ви використовуєте IP-адресу для `EXTERNAL_ISTIOD_ADDR` замість правильного DNS імені хоста, змініть конфігурацію. Видаліть `DestinationRule`, не завершуйте TLS у `Gateway` та використовуйте маршрутизацію TLS у `VirtualService`:

    {{< warning >}}
    Це не рекомендується в операційному середовищі.
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e '55,$d' \
      -e 's/mode: SIMPLE/mode: PASSTHROUGH/' -e '/credentialName:/d' -e "s/${EXTERNAL_ISTIOD_ADDR}/\"*\"/" \
      -e 's/http:/tls:/' -e 's/https/tls/' -e '/route:/i\
            sniHosts:\
            - "*"' \
      external-istiod-gw.yaml; rm external-istiod-gw.yaml.bk
    {{< /text >}}

9. Застосуйте конфігурацію у зовнішньому кластері:

    {{< text bash >}}
    $ kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

### Кроки для адміністратора сервісної мережі {#mesh-admin-steps}

Тепер, коли Istio успішно розгорнуто, адміністратору сервісної мережі залишається лише розгорнути та налаштувати сервіси в мережі, включаючи шлюзи за потреби.

{{< tip >}}
Деякі команди CLI `istioctl` не будуть стандартно працювати на віддаленому кластері, але ви можете легко налаштувати `istioctl`, щоб зробити його повністю функціональним. Докладніше дивіться у проєкті [Istioctl-proxy Ecosystem](https://github.com/istio-ecosystem/istioctl-proxy-sample).
{{< /tip >}}

#### Розгортання демонстраційного застосунку {#deploy-a-sample-application}

1. Створіть та позначте для інʼєкції простір імен `sample` на віддаленому кластері:

    {{< text bash >}}
    $ kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

2. Розгорніть зразки `helloworld` (версія `v1`) та `curl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
    $ kubectl apply -f @samples/curl/curl.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
    {{< /text >}}

3. Зачекайте кілька секунд, поки podʼи `helloworld` та `curl` запустяться з інтегрованими sidecar контейнерами:

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
    NAME                             READY   STATUS    RESTARTS   AGE
    curl-64d7d56698-wqjnm            2/2     Running   0          9s
    helloworld-v1-776f57d5f6-s7zfc   2/2     Running   0          10s
    {{< /text >}}

4. Надішліть запит з podʼа `curl` до сервіса `helloworld`:

    {{< text bash >}}
    $ kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c curl \
        "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=curl -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

#### Увімкнення шлюзів {#enable-gateways}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
Якщо ви використовуєте Gateway API, вам не потрібно буде встановлювати жодних компонентів шлюзу. Ви можете пропустити наступні інструкції та перейти безпосередньо до [налаштування та тестування ingress gateway](#configure-and-test-an-ingress-gateway).
{{< /tip >}}

Увімкніть шлюз ingress у віддаленому кластері:

{{< tabset category-name="ingress-gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ cat <<EOF > istio-ingressgateway.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: ingress-install
spec:
  profile: empty
  components:
    ingressGateways:
    - namespace: external-istiod
      name: istio-ingressgateway
      enabled: true
  values:
    gateways:
      istio-ingressgateway:
        injectionTemplate: gateway
EOF
$ istioctl install -f istio-ingressgateway.yaml --set values.global.istioNamespace=external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text bash >}}
$ helm install istio-ingressgateway istio/gateway -n external-istiod --kube-context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

Дивіться [Встановлення шлюзів](/docs/setup/additional-setup/gateway/) для детальної документації щодо встановлення шлюзів.

{{< /tab >}}
{{< /tabset >}}

Ви також можете опціонально увімкнути інші шлюзи. Наприклад, шлюз egress:

{{< tabset category-name="egress-gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ cat <<EOF > istio-egressgateway.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: egress-install
spec:
  profile: empty
  components:
    egressGateways:
    - namespace: external-istiod
      name: istio-egressgateway
      enabled: true
  values:
    gateways:
      istio-egressgateway:
        injectionTemplate: gateway
EOF
$ istioctl install -f istio-egressgateway.yaml --set values.global.istioNamespace=external-istiod --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text bash >}}
$ helm install istio-egressgateway istio/gateway -n external-istiod --kube-context="${CTX_REMOTE_CLUSTER}" --set service.type=ClusterIP
{{< /text >}}

Дивіться [Встановлення шлюзів](/docs/setup/additional-setup/gateway/) для детальної документації щодо встановлення шлюзів.

{{< /tab >}}
{{< /tabset >}}

#### Налаштування та тестування ingress gateway {#configure-and-test-an-ingress-gateway}

{{< tip >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

1) Переконайтеся, що кластер готовий до налаштування шлюзу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Підтвердіть, що шлюз Istio ingress працює:

{{< text bash >}}
$ kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-7bcd5c6bbd-kmtl4   1/1     Running   0          8m4s
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

CRD Gateway API Kubernetes зазвичай стандартно не встановлюються у більшості кластерів Kubernetes, тому переконайтеся, що вони встановлені перед використанням Gateway API:

{{< text syntax=bash snip_id=install_crds >}}
$ kubectl get crd gateways.gateway.networking.k8s.io --context="${CTX_REMOTE_CLUSTER}" &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f - --context="${CTX_REMOTE_CLUSTER}"; }
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) Експонуйте застосунок `helloworld` через шлюз ingress:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/helloworld/helloworld-gateway.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/helloworld/gateway-api/helloworld-gateway.yaml@ -n sample --context="${CTX_REMOTE_CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Встановіть змінну середовища `GATEWAY_URL` (дивіться [визначення IP та портів ingress](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) для деталей):

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl -n sample --context="${CTX_REMOTE_CLUSTER}" wait --for=condition=programmed gtw helloworld-gateway
$ export INGRESS_HOST=$(kubectl -n sample --context="${CTX_REMOTE_CLUSTER}" get gtw helloworld-gateway -o jsonpath='{.status.addresses[0].value}')
$ export GATEWAY_URL=$INGRESS_HOST:80
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Підтвердіть, що ви можете отримати доступ до застосунку `helloworld` через шлюз ingress:

    {{< text bash >}}
    $ curl -s "http://${GATEWAY_URL}/hello"
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    {{< /text >}}

## Додавання кластерів до mesh (необовʼязково) {#adding-clusters}

У цьому розділі показано, як розширити існуючу сервісну мережу із зовнішньою панеллю управління до мультикластера, додавши ще один віддалений кластер. Це дозволяє легко розподіляти сервіси та використовувати [маршрутизацію з урахуванням місцезнаходження та аварійне перемикання](/docs/tasks/traffic-management/locality-load-balancing/) для підтримки високої доступності вашого застосунку.

{{< image width="75%"
    link="external-multicluster.svg"
    caption="Зовнішня панель управління з кількома віддаленими кластерами"
    >}}

На відміну від першого віддаленого кластера, другий та наступні кластери, додані до тієї ж зовнішньої панелі управління, не надають конфігурацію mesh, а натомість є лише джерелами конфігурації точок доступу, як і віддалені кластери в конфігурації мультикластера Istio типу [primary-remote](/docs/setup/install/multicluster/primary-remote_multi-network/).

Щоб продовжити, вам знадобиться ще один кластер Kubernetes для другого віддаленого кластера mesh. Встановіть наступні змінні середовища для імені контексту та імені кластера:

{{< text syntax=bash snip_id=none >}}
$ export CTX_SECOND_CLUSTER=<your second remote cluster context>
$ export SECOND_CLUSTER_NAME=<your second remote cluster name>
{{< /text >}}

### Реєстрація нового кластера {#register-the-new-cluster}

1. Створіть конфігурацію для встановлення Istio на віддаленому кластері, яка встановлює веб-хук інʼєкції, що використовує інжектор зовнішньої панелі управілння, замість локальної:

    {{< text syntax=bash snip_id=get_second_remote_cluster_iop >}}
    $ cat <<EOF > second-remote-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: external-istiod
    spec:
      profile: remote
      values:
        global:
          istioNamespace: external-istiod
        istiodRemote:
          injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/cluster/${SECOND_CLUSTER_NAME}/net/network2
    EOF
    {{< /text >}}

2. Якщо ви використовуєте IP-адресу для `EXTERNAL_ISTIOD_ADDR` замість правильного DNS-імені, змініть конфігурацію, щоб вказати адресу виявлення та шлях замість URL для інʼєкції:

    {{< warning >}}
    Це не рекомендується в операційному середовищі.
    {{< /warning >}}

    {{< text bash >}}
    $ sed  -i'.bk' \
      -e "s|injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017|injectionPath: |" \
      -e "/istioNamespace:/a\\
          remotePilotAddress: ${EXTERNAL_ISTIOD_ADDR}" \
      second-remote-cluster.yaml; rm second-remote-cluster.yaml.bk
    {{< /text >}}

3. Створіть і додайте анотацію до системного простору імен у віддаленому кластері:

    {{< text bash >}}
    $ kubectl create namespace external-istiod --context="${CTX_SECOND_CLUSTER}"
    $ kubectl annotate namespace external-istiod "topology.istio.io/controlPlaneClusters=${REMOTE_CLUSTER_NAME}" --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

    Анотація `topology.istio.io/controlPlaneClusters` вказує ID кластера зовнішньої панелі управілння, яка повинна керувати цим віддаленим кластером. Зверніть увагу, що це імʼя першого віддаленого (конфігураційного) кластера, яке було використано для встановлення ID кластера зовнішньої панелі управління під час його встановлення у зовнішньому кластері раніше.

4. Встановіть конфігурацію у віддаленому кластері:

    {{< text bash >}}
    $ istioctl install -f second-remote-cluster.yaml --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

5. Переконайтеся, що конфігурація веб-хука інʼєкції у віддаленому кластері була встановлена:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration --context="${CTX_SECOND_CLUSTER}"
    NAME                                     WEBHOOKS   AGE
    istio-sidecar-injector-external-istiod   4          4m13s
    {{< /text >}}

6. Створіть секрет із обліковими даними, щоб дозволити панелі управління отримувати доступ до точок доступу у другому віддаленому кластері, і встановіть його:

    {{< text bash >}}
    $ istioctl create-remote-secret \
      --context="${CTX_SECOND_CLUSTER}" \
      --name="${SECOND_CLUSTER_NAME}" \
      --type=remote \
      --namespace=external-istiod \
      --create-service-account=false | \
      kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

    Зауважте, що на відміну від першого віддаленого кластера mesh, який також служить конфігураційним кластером, цього разу аргумент `--type` встановлено як `remote`, замість `config`.

### Налаштування шлюзів між кластерами (east-west gateways) {#setup-east-west-gateways}

1. Розгорніть шлюзи між кластерами на обох віддалених кластерах:

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --network network1 > eastwest-gateway-1.yaml
    $ istioctl manifest generate -f eastwest-gateway-1.yaml \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
    {{< /text >}}

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --network network2 > eastwest-gateway-2.yaml
    $ istioctl manifest generate -f eastwest-gateway-2.yaml \
        --set values.global.istioNamespace=external-istiod | \
        kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
    {{< /text >}}

1. Зачекайте, поки шлюзи між кластерами отримають зовнішні IP-адреси:

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl --context="${CTX_SECOND_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
    NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
    istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.99   ...       51s
    {{< /text >}}

1. Експонуйте сервіси через шлюзи між кластерами:

    {{< text bash >}}
    $ kubectl --context="${CTX_REMOTE_CLUSTER}" apply -n external-istiod -f \
        @samples/multicluster/expose-services.yaml@
    {{< /text >}}

### Перевірка установки {#validate-the-installation}

1. Створіть та позначте для інʼєкції простір імен `sample` на віддаленому кластері:

    {{< text bash >}}
    $ kubectl create --context="${CTX_SECOND_CLUSTER}" namespace sample
    $ kubectl label --context="${CTX_SECOND_CLUSTER}" namespace sample istio-injection=enabled
    {{< /text >}}

1. Розгорніть зразки `helloworld` (`v2`) та `curl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v2 -n sample --context="${CTX_SECOND_CLUSTER}"
    $ kubectl apply -f @samples/curl/curl.yaml@ -n sample --context="${CTX_SECOND_CLUSTER}"
    {{< /text >}}

1. Зачекайте кілька секунд, поки контейнери `helloworld` та `curl` запустяться з впровадженими sidecar контейнерами:

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_SECOND_CLUSTER}"
    NAME                            READY   STATUS    RESTARTS   AGE
    curl-557747455f-wtdbr           2/2     Running   0          9s
    helloworld-v2-54df5f84b-9hxgw   2/2     Running   0          10s
    {{< /text >}}

1. Надішліть запит з контейнера `curl` до сервісу `helloworld`:

    {{< text bash >}}
    $ kubectl exec --context="${CTX_SECOND_CLUSTER}" -n sample -c curl \
        "$(kubectl get pod --context="${CTX_SECOND_CLUSTER}" -n sample -l app=curl -o jsonpath='{.items[0].metadata.name}')" \
        -- curl -sS helloworld.sample:5000/hello
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    {{< /text >}}

1. Підтвердіть, що при доступі до застосунку `helloworld` кілька разів через шлюз входу обидві версії `v1` та `v2` тепер викликаються:

    {{< text bash >}}
    $ for i in {1..10}; do curl -s "http://${GATEWAY_URL}/hello"; done
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
    Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
    ...
    {{< /text >}}

## Очистка {#cleanup}

Очистіть кластер зовнішньої панелі управління:

{{< text bash >}}
$ kubectl delete -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
$ istioctl uninstall -y --purge -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
$ kubectl delete ns istio-system external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
$ rm controlplane-gateway.yaml external-istiod.yaml external-istiod-gw.yaml
{{< /text >}}

Очистіть кластер конфігурації віддаленого управління:

{{< text bash >}}
$ kubectl delete ns sample --context="${CTX_REMOTE_CLUSTER}"
$ istioctl uninstall -y --purge -f remote-config-cluster.yaml --set values.defaultRevision=default --context="${CTX_REMOTE_CLUSTER}"
$ kubectl delete ns external-istiod --context="${CTX_REMOTE_CLUSTER}"
$ rm remote-config-cluster.yaml istio-ingressgateway.yaml
$ rm istio-egressgateway.yaml eastwest-gateway-1.yaml || true
{{< /text >}}

Очистіть необовʼязковий другий віддалений кластер, якщо ви його встановлювали:

{{< text bash >}}
$ kubectl delete ns sample --context="${CTX_SECOND_CLUSTER}"
$ istioctl uninstall -y --purge -f second-remote-cluster.yaml --context="${CTX_SECOND_CLUSTER}"
$ kubectl delete ns external-istiod --context="${CTX_SECOND_CLUSTER}"
$ rm second-remote-cluster.yaml eastwest-gateway-2.yaml
{{< /text >}}
