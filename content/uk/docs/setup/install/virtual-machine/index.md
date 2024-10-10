---
title: Встановлення віртуальної машини
description: Розгорніть Istio та підключіть до нього робоче навантаження, що працює у віртуальній машині.
weight: 60
keywords:
- kubernetes
- virtual-machine
- gateways
- vms
owner: istio/wg-environments-maintainers
test: yes
---

Дотримуйтесь цього посібника, щоб розгорнути мережу Istio та підключити до неї віртуальну машину.

## Передумови {#prerequisites}

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/)
2. Виконайте необхідні [специфічні для платформи налаштування](/docs/setup/platform-setup/)
3. Перевірте вимоги [для Podʼів та сервісів](/docs/ops/deployment/application-requirements/)
4. Віртуальні машини повинні мати IP-зʼєднання з ingress gateway у зʼєднувальній сервісній мережі, а також, за бажанням, з кожним podʼом у мережі через L3-мережі, якщо потрібна підвищена продуктивність.
5. Ознайомтесь з [Архітектурою віртуальних машин](/docs/ops/deployment/vm-architecture/) для отримання загального уявлення про архітектуру інтеграції віртуальних машин в Istio.

## Підготовка середовища для посібника {#prepare-the-guide-environment}

1. Створіть віртуальну машину.
2. Встановіть змінні середовища `VM_APP`, `WORK_DIR`, `VM_NAMESPACE` та `SERVICE_ACCOUNT` на вашій машині, яку ви використовуєте для налаштування кластера. (наприклад, `WORK_DIR="${HOME}/vmintegration"`):

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Одна мережа" category-value="single" >}}

    {{< text bash >}}
    $ VM_APP="<назва застосунку, який буде працювати на цій ВМ>"
    $ VM_NAMESPACE="<назва вашого простору імен для сервісів>"
    $ WORK_DIR="<тека для сертифікатів>"
    $ SERVICE_ACCOUNT="<назва службового облікового запису Kubernetes, який ви хочете використовувати для вашої ВМ>"
    $ CLUSTER_NETWORK=""
    $ VM_NETWORK=""
    $ CLUSTER="Kubernetes"
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Кілька мереж" category-value="multiple" >}}

    {{< text bash >}}
    $ VM_APP="<назва застосунку, який буде працювати на цій ВМ>"
    $ VM_NAMESPACE="<назва вашого простору імен для сервісів>"
    $ WORK_DIR="<тека для сертифікатів>"
    $ SERVICE_ACCOUNT="<назва службового облікового запису Kubernetes, який ви хочете використовувати для вашої ВМ>"
    $ # Налаштуйте значення для мультикластерної/множинної мережі за потреби
    $ CLUSTER_NETWORK="kube-network"
    $ VM_NETWORK="vm-network"
    $ CLUSTER="cluster1"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

3. Створіть робочу теку на вашій машині для налаштування кластера:

    {{< text syntax=bash snip_id=setup_wd >}}
    $ mkdir -p "${WORK_DIR}"
    {{< /text >}}

## Встановлення панелі управління Istio {#install-the-istio-control-plane}

Якщо у вашому кластері вже є панель управління Istio, ви можете пропустити кроки встановлення, але вам все ще потрібно буде відкрити панель управління для доступу віртуальної машини.

Встановіть Istio та експонуйте панель управління в кластері, щоб ваша віртуальна машина могла отримати до неї доступ.

1. Створіть специфікацію `IstioOperator` для встановлення.

    {{< text syntax="bash yaml" snip_id=setup_iop >}}
    $ cat <<EOF > ./vm-cluster.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      name: istio
    spec:
      values:
        global:
          meshID: mesh1
          multiCluster:
            clusterName: "${CLUSTER}"
          network: "${CLUSTER_NETWORK}"
    EOF
    {{< /text >}}

2. Встановіть Istio.

    {{< tabset category-name="registration-mode" >}}

    {{< tab name="Стандартно" category-value="default" >}}

    {{< text bash >}}
    $ istioctl install -f vm-cluster.yaml
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Автоматичне створення WorkloadEntry" category-value="autoreg" >}}

    {{< boilerplate experimental >}}

    {{< text syntax=bash snip_id=install_istio >}}
    $ istioctl install -f vm-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS=true
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

3. Розгорніть шлюз east-west:

    {{< warning >}}
    Якщо панель управління було встановлено з ревізією, додайте прапорець `--revision rev` до команди `gen-eastwest-gateway.sh`.
    {{< /warning >}}

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Одна мережа" category-value="single" >}}

    {{< text syntax=bash snip_id=install_eastwest >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ --single-cluster | istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Кілька мереж" category-value="multiple" >}}

    {{< text bash >}}
    $ @samples/multicluster/gen-eastwest-gateway.sh@ \
        --network "${CLUSTER_NETWORK}" | \
        istioctl install -y -f -
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

4. Експонуйте сервіси всередині кластера через шлюз east-west:

    {{< tabset category-name="network-mode" >}}

    {{< tab name="Одна мережа" category-value="single" >}}

    Експонуйте панель управління:

    {{< text syntax=bash snip_id=expose_istio >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="Кілька мереж" category-value="multiple" >}}

    Експонуйте панель управління:

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-istiod.yaml@
    {{< /text >}}

    Експонуйте сервіси кластера:

    {{< text bash >}}
    $ kubectl apply -n istio-system -f @samples/multicluster/expose-services.yaml@
    {{< /text >}}

    Переконайтеся, що простір імен `istio-system` має мітку з визначеною мережею кластера:

    {{< text bash >}}
    $ kubectl label namespace istio-system topology.istio.io/network="${CLUSTER_NETWORK}"
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

## Налаштування простору імен для віртуальної машини {#configure-the-vm-namespace}

1. Створіть простір імен, який буде хостити віртуальну машину:

    {{< text syntax=bash snip_id=install_namespace >}}
    $ kubectl create namespace "${VM_NAMESPACE}"
    {{< /text >}}

2. Створіть службовий обліковий запис для віртуальної машини:

    {{< text syntax=bash snip_id=install_sa >}}
    $ kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"
    {{< /text >}}

## Створіть файли для передачі на віртуальну машину {#create-files-to-transfer-to-the-virtual-machine}

{{< tabset category-name="registration-mode" >}}

{{< tab name="Стандартно" category-value="default" >}}

Спочатку створіть шаблон `WorkloadGroup` для віртуальної машини:

{{< text bash >}}
$ cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Автоматизоване створення WorkloadEntry" category-value="autoreg" >}}

Спочатку створіть шаблон `WorkloadGroup` для віртуальної машини:

{{< boilerplate experimental >}}

{{< text syntax=bash snip_id=create_wg >}}
$ cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
{{< /text >}}

Щоб дозволити автоматичне створення `WorkloadEntry`, завантажте `WorkloadGroup` в кластер:

{{< text syntax=bash snip_id=apply_wg >}}
$ kubectl --namespace "${VM_NAMESPACE}" apply -f workloadgroup.yaml
{{< /text >}}

Для автоматичної реєстрації `WorkloadEntry` також доступні перевірки стану справності застосунку. Вони мають ті ж API та поведінку, що й [Kubernetes Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/).

Наприклад, для налаштування перевірки на точці доступу `/ready` вашого застосунку:

{{< text bash >}}
$ cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${NETWORK}"
  probe:
    periodSeconds: 5
    initialDelaySeconds: 1
    httpGet:
      port: 8080
      path: /ready
EOF
{{< /text >}}

З цією конфігурацією автоматично згенерований `WorkloadEntry` не буде позначений як "Ready", поки перевірка не пройде успішно.

{{< /tab >}}

{{< /tabset >}}

{{< warning >}}
Перед тим як переходити до генерації `istio-token` як частини `istioctl x workload entry`, слід перевірити, чи ввімкнено сторонні токени в кластері, дотримуючися кроків, описаних [тут](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens). Якщо сторонні токени не ввімкнені, потрібно додати параметр `--set values.global.jwtPolicy=first-party-jwt` до команд установки Istio.
{{< /warning >}}

Далі, використовуйте команду `istioctl x workload entry` для генерації:

* `cluster.env`: Містить метадані, які ідентифікують простір імен, службовий обліковий запис, CIDR мережі та (опціонально) порти вхідного трафіку, які слід захопити.
* `istio-token`: Токен Kubernetes, який використовується для отримання сертифікатів з CA.
* `mesh.yaml`: Надає `ProxyConfig` для налаштування `discoveryAddress`, перевірок стану справності та деяких опцій автентифікації.
* `root-cert.pem`: Кореневий сертифікат, що використовується для автентифікації.
* `hosts`: Доповнення до `/etc/hosts`, яке проксі використовуватиме для підключення до istiod для xDS.

{{< idea >}}
Складніший варіант включає налаштування DNS на віртуальній машині для посилання на зовнішній DNS сервер. Цей варіант виходить за межі цього посібника.
{{< /idea >}}

{{< tabset category-name="registration-mode" >}}

{{< tab name="Стандартно" category-value="default" >}}

{{< text bash >}}
$ istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Автоматизоване створення WorkloadEntry" category-value="autoreg" >}}

{{< boilerplate experimental >}}

{{< text syntax=bash snip_id=configure_wg >}}
$ istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}" --autoregister
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Налаштування віртуальної машини {#configure-the-virtual-machine}

Виконайте наступні команди на віртуальній машині, яку ви хочете додати до мережі Istio:

1. Виконайте захищену передачу файлів з `"${WORK_DIR}"` до віртуальної машини. Який спосіб ви виберете для передачі цих файлів, залежить від вашої політики інформаційної безпеки. Для зручності в цьому посібнику, передайте всі необхідні файли в `"${HOME}"` на віртуальній машині.

2. Встановіть кореневий сертифікат у `/etc/certs`:

    {{< text bash >}}
    $ sudo mkdir -p /etc/certs
    $ sudo cp "${HOME}"/root-cert.pem /etc/certs/root-cert.pem
    {{< /text >}}

3. Встановіть токен у `/var/run/secrets/tokens`:

    {{< text bash >}}
    $ sudo mkdir -p /var/run/secrets/tokens
    $ sudo cp "${HOME}"/istio-token /var/run/secrets/tokens/istio-token
    {{< /text >}}

4. Встановіть пакет, що містить середовище виконання інтеграції Istio для віртуальних машин:

    {{< tabset category-name="vm-os" >}}

    {{< tab name="Debian" category-value="debian" >}}

    {{< text syntax=bash snip_id=none >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/deb/istio-sidecar.deb
    $ sudo dpkg -i istio-sidecar.deb
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="CentOS" category-value="centos" >}}

    Примітка: наразі підтримується лише CentOS 8.

    {{< text syntax=bash snip_id=none >}}
    $ curl -LO https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/rpm/istio-sidecar.rpm
    $ sudo rpm -i istio-sidecar.rpm
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

5. Встановіть `cluster.env` в теку `/var/lib/istio/envoy/`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/cluster.env /var/lib/istio/envoy/cluster.env
    {{< /text >}}

6. Встановіть [Mesh Config](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) в `/etc/istio/config/mesh`:

    {{< text bash >}}
    $ sudo cp "${HOME}"/mesh.yaml /etc/istio/config/mesh
    {{< /text >}}

7. Додайте хост istiod до `/etc/hosts`:

    {{< text bash >}}
    $ sudo sh -c 'cat $(eval echo ~$SUDO_USER)/hosts >> /etc/hosts'
    {{< /text >}}

8. Передайте права власності на файли в `/etc/certs/` та `/var/lib/istio/envoy/` до проксі Istio:

    {{< text bash >}}
    $ sudo mkdir -p /etc/istio/proxy
    $ sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem
    {{< /text >}}

## Запуск Istio у віртуальній машині {#start-istio-within-the-virtual-machine}

1. Запустіть агента Istio:

    {{< text bash >}}
    $ sudo systemctl start istio
    {{< /text >}}

## Переконайтеся в успішності роботи Istio {#verify-istio-works-successfully}

1. Перевірте журнал `/var/log/istio/istio.log`. Ви повинні побачити записи, подібні до наведених нижче:

    {{< text bash >}}
    $ 2020-08-21T01:32:17.748413Z info sds resource:default pushed key/cert pair to proxy
    $ 2020-08-21T01:32:20.270073Z info sds resource:ROOTCA new connection
    $ 2020-08-21T01:32:20.270142Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.270279Z info cache adding watcher for file ./etc/certs/root-cert.pem
    $ 2020-08-21T01:32:20.270347Z info cache GenerateSecret from file ROOTCA
    $ 2020-08-21T01:32:20.270494Z info sds resource:ROOTCA pushed root cert to proxy
    $ 2020-08-21T01:32:20.270734Z info sds resource:default new connection
    $ 2020-08-21T01:32:20.270763Z info sds Skipping waiting for gateway secret
    $ 2020-08-21T01:32:20.695478Z info cache GenerateSecret default
    $ 2020-08-21T01:32:20.695595Z info sds resource:default pushed key/cert pair to proxy
    {{< /text >}}

1. Створіть простір імен для розгортання Service на основі Podʼів:

    {{< text bash >}}
    $ kubectl create namespace sample
    $ kubectl label namespace sample istio-injection=enabled
    {{< /text >}}

2. Розгорніть `HelloWorld` Service:

    {{< text bash >}}
    $ kubectl apply -n sample -f @samples/helloworld/helloworld.yaml@
    {{< /text >}}

3. Надсилайте запити з вашої віртуальної машини до Service:

    {{< text bash >}}
    $ curl helloworld.sample.svc:5000/hello
    Hello version: v1, instance: helloworld-v1-578dd69f69-fxwwk
    {{< /text >}}

## Наступні кроки {#next-steps}

Для отримання додаткової інформації про віртуальні машини:

* [Налагодження віртуальних машин](/docs/ops/diagnostic-tools/virtual-machines/) для усунення проблем із віртуальними машинами.
* [Bookinfo з віртуальною машиною](/docs/examples/virtual-machines/) для налаштування прикладу розгортання віртуальних машин.

## Видалення {#uninstall}

Зупиніть Istio у віртуальній машині:

{{< text bash >}}
$ sudo systemctl stop istio
{{< /text >}}

Потім видаліть пакет Istio-sidecar:

{{< tabset category-name="vm-os" >}}

{{< tab name="Debian" category-value="debian" >}}

{{< text bash >}}
$ sudo dpkg -r istio-sidecar
$ dpkg -s istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< tab name="CentOS" category-value="centos" >}}

{{< text bash >}}
$ sudo rpm -e istio-sidecar
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Щоб видалити Istio, виконайте наступну команду:

{{< text bash >}}
$ kubectl delete -n istio-system -f @samples/multicluster/expose-istiod.yaml@
$ istioctl uninstall -y --purge
{{< /text >}}

Простір імен контролера (наприклад, `istio-system`) стандартно не видаляється. Якщо він більше не потрібен, використовуйте наступну команду для його видалення:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
