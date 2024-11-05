---
title: SPIRE
description: Як налаштувати Istio для інтеграції з SPIRE, щоб отримувати криптографічні ідентифікатори через SDS API Envoy.
weight: 31
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: yes
---

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) є готовою до використання реалізацією специфікації SPIFFE, яка виконує атестацію вузлів та навантажень для безпечної видачі криптографічних ідентифікаторів навантаженням, що працюють в гетерогенних середовищах. SPIRE можна налаштувати як джерело криптографічних ідентифікаторів для навантажень Istio через інтеграцію з [SDS API Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret). Istio може виявити існування UNIX Domain Socket, який реалізує Envoy SDS API на визначеному шляху до сокета, що дозволяє Envoy безпосередньо звʼязуватися та отримувати ідентифікатори з нього.

Ця інтеграція з SPIRE забезпечує гнучкі варіанти атестації, недоступні з типовим управлінням ідентифікацією в Istio, використовуючи потужне управління сервісами Istio. Наприклад, архітектура втулків SPIRE дозволяє використовувати різноманітні варіанти атестації навантажень за межами простору імен Kubernetes та облікових записів сервісів, що пропонуються Istio. Атестація вузлів SPIRE розширює атестацію на фізичне або віртуальне апаратне забезпечення, на якому працюють навантаження.

Для швидкого демонстраційного прикладу того, як працює інтеграція SPIRE з Istio, див. [Інтеграція SPIRE як CA через SDS API Envoy]({{< github_tree >}}/samples/security/spire).

## Встановлення SPIRE {#install-spire}

Рекомендуємо дотримуватись інструкцій з встановлення SPIRE та найкращих практик для розгортання SPIRE у промислових середовищах.

Для прикладів у цьому посібнику використовуватимуться [Helm чарти SPIRE](https://artifacthub.io/packages/helm/spiffe/spire) з типовими налаштуваннями, щоб зосередитися лише на конфігурації, необхідній для інтеграції SPIRE та Istio.

{{< text syntax=bash snip_id=install_spire_crds >}}
$ helm upgrade --install -n spire-server spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace
{{< /text >}}

{{< text syntax=bash snip_id=install_spire_istio_overrides >}}
$ helm upgrade --install -n spire-server spire spire --repo https://spiffe.github.io/helm-charts-hardened/ --wait --set global.spire.trustDomain="example.org"
{{< /text >}}

{{< tip >}}
Дивіться документацію [Helm чарта SPIRE](https://artifacthub.io/packages/helm/spiffe/spire) для інших значень, які можна налаштувати для вашого розгортання.

Важливо, щоб SPIRE та Istio були налаштовані з однаковим доменом довіри, щоб уникнути помилок автентифікації та авторизації, і щоб [SPIFFE CSI драйвер](https://github.com/spiffe/spiffe-csi) був увімкнений і встановлений.
{{< /tip >}}

Вище також буде встановлено:

- [SPIFFE CSI драйвер](https://github.com/spiffe/spiffe-csi), який використовується для монтування SDS сокетів, сумісних з Envoy, у проксі. Використання SPIFFE CSI драйвера для монтування SDS сокетів наполегливо рекомендується як Istio, так і SPIRE, оскільки `hostMounts` є більшим ризиком безпеки та створюють оперативні труднощі. Цей посібник припускає використання SPIFFE CSI драйвера.

- [SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager), який спрощує створення реєстрацій SPIFFE для навантажень.

## Реєстрація навантажень {#register-workloads}

За задумом, SPIRE надає ідентифікатори тільки навантаженням, які були зареєстровані на сервері SPIRE; це включає навантаження користувача, а також компоненти Istio. Sidecar Istio та шлюзи Istio, після налаштування інтеграції з SPIRE, не можуть отримати ідентифікатори а, отже, не можуть досягти статусу READY, якщо заздалегідь не було створено відповідну реєстрацію SPIRE.

Дивіться [документацію SPIRE про реєстрацію навантажень](https://spiffe.io/docs/latest/deploying/registering/) для отримання додаткової інформації про використання кількох селекторів для зміцнення критеріїв атестації та доступних селекторів.

Цей розділ описує варіанти, доступні для реєстрації навантажень Istio на сервері SPIRE, і наводить приклади реєстрацій навантажень.

{{< warning >}}
Istio зараз вимагає конкретний формат SPIFFE ID для навантажень. Усі реєстрації повинні слідувати шаблону SPIFFE ID для Istio: `spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

### Варіант 1: Автоматична реєстрація за допомогою SPIRE Controller Manager {#option-1-auto-registration-using-the-spire-controller-manager}

Нові записи будуть автоматично реєструватися для кожного нового podʼа, що відповідає селектору, визначеному в [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) користувацькому ресурсі.

Sidecar Istio та шлюзи Istio повинні бути зареєстровані з SPIRE, щоб вони могли запитувати ідентифікатори.

#### Istio Gateway `ClusterSPIFFEID` {#istio-gateway-clusterspiffeid}

Наступне створить `ClusterSPIFFEID`, який автоматично зареєструє будь-який Istio Ingress gateway pod з SPIRE, якщо він розгорнутий у просторі імен `istio-system` і має обліковий запис сервісу з імʼям `istio-ingressgateway-service-account`. Ці селектори використовуються як простий приклад; зверніться до [документації SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) для отримання більш детальної інформації.

{{< text syntax=bash snip_id=spire_csid_istio_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-ingressgateway-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  workloadSelectorTemplates:
    - "k8s:ns:istio-system"
    - "k8s:sa:istio-ingressgateway-service-account"
EOF
{{< /text >}}

#### Istio Sidecar `ClusterSPIFFEID` {#istio-sidecar-clusterspiffeid}

Наступне створить `ClusterSPIFFEID`, який автоматично зареєструє будь-який pod з міткою `spiffe.io/spire-managed-identity: true`, що розгорнутий у просторі імен `default`, з SPIRE. Ці селектори використовуються як простий приклад; зверніться до [документації SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) для отримання більш детальної інформації.

{{< text syntax=bash snip_id=spire_csid_istio_sidecar >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-sidecar-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels:
      spiffe.io/spire-managed-identity: "true"
  workloadSelectorTemplates:
    - "k8s:ns:default"
EOF
{{< /text >}}

### Варіант 2: Ручна реєстрація {#option-2-manual-registration}

Якщо ви бажаєте вручну створити ваші реєстрації SPIRE, а не використовувати SPIRE Controller Manager, згаданий в [рекомендованому варіанті](#option-1-auto-registration-using-the-spire-controller-manager), зверніться до [документації SPIRE з ручної реєстрації](https://spiffe.io/docs/latest/deploying/registering/).

Нижче наведені еквівалентні ручні реєстрації на основі автоматичних реєстрацій в [Варіанті 1](#option-1-auto-registration-using-the-spire-controller-manager). Наступні кроки припускають, що ви [вже виконали інструкції SPIRE для ручної реєстрації вашого агента SPIRE та атестації вузлів](https://spiffe.io/docs/latest/deploying/registering/#1-defining-the-spiffe-id-of-the-agent) і що ваш агент SPIRE був зареєстрований з ідентифікатором SPIFFE `spiffe://example.org/ns/spire/sa/spire-agent`.

1. Отримайте pod `spire-server`:

    {{< text syntax=bash snip_id=set_spire_server_pod_name_var >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l statefulset.kubernetes.io/pod-name=spire-server-0 -n spire-server -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Зареєструйте запис для podʼа шлюзу Istio Ingress:

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:sa:istio-ingressgateway-service-account \
        -selector k8s:ns:istio-system \
        -socketPath /run/spire/sockets/server.sock

    Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
    SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
    Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Revision         : 0
    TTL              : default
    Selector         : k8s:ns:istio-system
    Selector         : k8s:sa:istio-ingressgateway-service-account
    {{< /text >}}

1. Зареєструйте запис для навантажень, в які вставлено sidecar Istio:

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/sleep \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-label:spiffe.io/spire-managed-identity:true \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

## Встановлення Istio {#install-istio}

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/).

1. Створіть конфігурацію Istio з власними патчами для Ingress Gateway і `istio-proxy`. Компонент Ingress Gateway включає мітку `spiffe.io/spire-managed-identity: "true"`.

    {{< text syntax=bash snip_id=define_istio_operator_for_auto_registration >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      profile: default
      meshConfig:
        trustDomain: example.org
      values:
        global:
        # Це використовується для налаштування шаблону sidecar.
        # Додає як мітку, щоб вказати, що SPIRE повинен керувати
        # ідентичністю цього pod, так і монтуванням драйвера CSI.
        sidecarInjectorWebhook:
          templates:
            spire: |
              labels:
                spiffe.io/spire-managed-identity: "true"
              spec:
                containers:
                - name: istio-proxy
                  volumeMounts:
                  - name: workload-socket
                    mountPath: /run/secrets/workload-spiffe-uds
                    readOnly: true
                volumes:
                  - name: workload-socket
                    csi:
                      driver: "csi.spiffe.io"
                      readOnly: true
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            label:
              istio: ingressgateway
            k8s:
              overlays:
                # Це використовується для налаштування шаблону ingress gateway.
                # Додає монтування драйвера CSI, а також контейнер ініціалізації
                # для затримки запуску gateway до тих пір, поки драйвер CSI не змонтує сокет.
                - apiVersion: apps/v1
                  kind: Deployment
                  name: istio-ingressgateway
                  patches:
                    - path: spec.template.spec.volumes.[name:workload-socket]
                      value:
                        name: workload-socket
                        csi:
                          driver: "csi.spiffe.io"
                          readOnly: true
                    - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                      value:
                        name: workload-socket
                        mountPath: "/run/secrets/workload-spiffe-uds"
                        readOnly: true
                    - path: spec.template.spec.initContainers
                      value:
                        - name: wait-for-spire-socket
                          image: busybox:1.36
                          volumeMounts:
                            - name: workload-socket
                              mountPath: /run/secrets/workload-spiffe-uds
                              readOnly: true
                          env:
                            - name: CHECK_FILE
                              value: /run/secrets/workload-spiffe-uds/socket
                          command:
                            - sh
                            - "-c"
                            - |-
                              echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                              while [[ ! -e ${CHECK_FILE} ]] ; do
                                echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                                sleep 15
                              done
                              ls -l ${CHECK_FILE}
    EOF
    {{< /text >}}

1. Застосуйте конфігурацію:

    {{< text syntax=bash snip_id=apply_istio_operator_configuration >}}
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. Перевірте стан podʼа Ingress Gateway:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

    Pod Ingress Gateway знаходиться в статусі `Ready`, оскільки відповідний запис реєстрації автоматично створюється для нього на сервері SPIRE. Envoy може отримувати криптографічні ідентичності з SPIRE.

    Ця конфігурація також додає `initContainer` до шлюзу, який буде чекати, поки SPIRE створить UNIX Domain Socket, перш ніж запустити `istio-proxy`. Якщо агент SPIRE не готовий або не був належним чином налаштований з тим же шляхом сокета, `initContainer` Ingress Gateway буде чекати вічно.

1. Розгорніть приклад навантаження:

    {{< text syntax=bash snip_id=apply_sleep >}}
    $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    Окрім необхідності мітки `spiffe.io/spire-managed-identity`, навантаження потребуватиме тому SPIFFE CSI Driver для доступу до сокета агента SPIRE. Для цього ви можете скористатися шаблоном анотації podʼа `spire` з розділу [Встановлення Istio](#install-istio) або додати том CSI до специфікації розгортання вашого навантаження. Обидва ці варіанти виділені в наступному прикладі:

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      selector:
          matchLabels:
            app: sleep
      template:
          metadata:
            labels:
              app: sleep
            # Впроваджує власний шаблон користувача sidecar
            annotations:
                inject.istio.io/templates: "sidecar,spire"
          spec:
            terminationGracePeriodSeconds: 0
            serviceAccountName: sleep
            containers:
            - name: sleep
              image: curlimages/curl
              command: ["/bin/sleep", "3650d"]
              imagePullPolicy: IfNotPresent
              volumeMounts:
                - name: tmp
                  mountPath: /tmp
              securityContext:
                runAsUser: 1000
            volumes:
              - name: tmp
                emptyDir: {}
              # Обсяг CSI
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
    {{< /text >}}

Конфігурація Istio ділиться `spiffe-csi-driver` між Ingress Gateway і sidecarʼами, які будуть впроваджені на podʼах навантаження, надаючи їм доступ до UNIX Domain Socket агента SPIRE.

Дивіться [Перевірка, що ідентичності були створені для навантажень](#verifying-that-identities-were-created-for-workloads) для перевірки виданих ідентичностей.

## Перевірка створення ідентичностей для навантажень {#verifying-that-identities-were-created-for-workloads}

Використовуйте наступну команду, щоб підтвердити, що ідентичності були створені для навантажень:

{{< text syntax=bash snip_id=none >}}
$ kubectl exec -t "$SPIRE_SERVER_POD" -n spire-server -c spire-server -- ./bin/spire-server entry show
Found 2 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
{{< /text >}}

Перевірте стан pod Ingress Gateway:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
{{< /text >}}

Після реєстрації запису для pod Ingress Gateway, Envoy отримує ідентичність, видану SPIRE, і використовує її для всіх TLS і mTLS комунікацій.

### Перевірка, що ідентичність навантаження була видана SPIRE {#check-that-the-workload-identity-was-issued-by-spire}

1. Отримайте інформацію про pod:

    {{< text syntax=bash snip_id=set_sleep_pod_var >}}
    $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Отримайте документ ідентичності SVID для `sleep` за допомогою команди istioctl proxy-config secret:

    {{< text syntax=bash snip_id=get_sleep_svid >}}
    $ istioctl proxy-config secret "$SLEEP_POD" -o json | jq -r \
    ʼ.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytesʼ | base64 --decode > chain.pem
    {{< /text >}}

1. Перевірте сертифікат і підтвердіть, що SPIRE є видавцем:

    {{< text syntax=bash snip_id=get_svid_subject >}}
    $ openssl x509 -in chain.pem -text | grep SPIRE
        Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
    {{< /text >}}

## Федерація SPIFFE {#spiffe-federation}

Сервери SPIRE можуть автентифікувати ідентичності SPIFFE, які походять з різних доменів довіри. Це відомо як федерація SPIFFE.

SPIRE Agent можна налаштувати на передачу обʼєднаних пакетів до Envoy через API Envoy SDS, що дозволяє Envoy використовувати [контекст перевірки](https://spiffe.io/docs/latest/microservices/envoy/#validation-context) для перевірки однорангових сертифікатів і довіри робочому навантаженню з іншого домену довіри. Щоб дозволити Istio федерацію ідентичностей SPIFFE через інтеграцію SPIRE, ознайомтеся з [конфігурацією SPIRE Agent SDS](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration) та встановіть наступні значення конфігурації SDS у вашому конфігураційному файлі SPIRE Agent.

| Конфігурація              | Опис                                                                                             | Назва ресурсу |
|---------------------------|--------------------------------------------------------------------------------------------------|---------------|
| `default_svid_name`       | Назва ресурсу сертифіката TLS для використання як стандартного `X509-SVID` з Envoy SDS      | default       |
| `default_bundle_name`     | Назва ресурсу контексту перевірки для використання як стандартного X.509 пакет з Envoy SDS  | null          |
| `default_all_bundles_name`| Назва ресурсу контексту перевірки для всіх пакетів (включаючи федеративні) з Envoy SDS         | ROOTCA        |

Це дозволить Envoy отримувати федеративні пакети безпосередньо з SPIRE.

### Створення федеративних записів реєстрації {#create-federated-registration-entries}

- Якщо ви використовуєте SPIRE Controller Manager, створіть федеративні записи для навантажень, встановивши поле `federatesWith` у [ClusterSPIFFEID CR](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) на домени довіри, з якими pod повинен федеративно з’єднуватися:

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: spire.spiffe.io/v1alpha1
    kind: ClusterSPIFFEID
    metadata:
      name: federation
    spec:
      spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
      podSelector:
        matchLabels:
          spiffe.io/spire-managed-identity: "true"
      federatesWith: ["example.io", "example.ai"]
    {{< /text >}}

- Для ручної реєстрації дивіться [Створення записів реєстрації для федерації](https://spiffe.io/docs/latest/architecture/federation/readme/#create-registration-entries-for-federation).

## Очищення SPIRE {#cleanup-spire}

Видаліть SPIRE, видаливши його Helm-чарти:

{{< text syntax=bash snip_id=uninstall_spire >}}
$ helm delete -n spire-server spire
{{< /text >}}

{{< text syntax=bash snip_id=uninstall_spire_crds >}}
$ helm delete -n spire-server spire-crds
{{< /text >}}
