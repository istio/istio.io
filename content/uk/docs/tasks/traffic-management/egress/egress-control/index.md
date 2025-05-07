---
title: Доступ до зовнішніх сервісів
description: Описує, як налаштувати Istio для маршрутизації трафіку з сервісів в mesh до зовнішніх сервісів.
weight: 10
aliases:
    - /uk/docs/tasks/egress.html
    - /uk/docs/tasks/egress
keywords: [traffic-management,egress]
owner: istio/wg-networking-maintainers
test: yes
---

Оскільки весь вихідний трафік з podʼа, який використовує Istio, стандартно перенаправляється до його sidecar proxy, доступність URL-адрес за межами кластера залежить від конфігурації проксі. Типово Istio налаштовує проксі Envoy для пропуску запитів до невідомих сервісів. Попри те, що це зручний спосіб почати роботу з Istio, зазвичай бажано налаштовувати більш суворий контроль.

Це завдання показує, як отримати доступ до зовнішніх сервісів трьома різними способами:

1. Дозволити проксі Envoy пропускати запити до сервісів, які не налаштовані всередині mesh.
2. Налаштувати [service entries](/docs/reference/config/networking/service-entry/), щоб забезпечити контрольований доступ до зовнішніх сервісів.
3. Повністю оминути проксі Envoy для певного діапазону IP-адрес.

## Перш ніж розпочати {#before-you-begin}

*   Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/). Використовуйте [профіль конфігурації](/docs/setup/additional-setup/config-profiles/) `demo` або ж [увімкніть реєстрацію доступу Envoy](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging).

*   Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl), щоб використовувати його як тестове джерело для надсилання запитів. Якщо у вас увімкнено [автоматичну інʼєкцію sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), виконайте наступну команду для розгортання демонстраційного застосунку:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    Або ж вручну виконайте інʼєкцію sidecar перед розгортанням демонстраційного застосунку `curl` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Як тестове джерело ви можете використовувати будь-який pod з встановленим `curl`.
    {{< /tip >}}

*   В зміну оточення `SOURCE_POD` встановіть назву вашого podʼа джерела:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath='{.items..metadata.name}')
    {{< /text >}}

## Передача трафіку через Envoy до зовнішніх сервісів {#envoy-passthrough-to-external-services}

Istio має [опцію встановлення](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-OutboundTrafficPolicy-Mode), `meshConfig.outboundTrafficPolicy.mode`, яка налаштовує обробку sidecar зовнішніх сервісів, тобто тих, які не визначені у внутрішньому реєстрі сервісів Istio. Якщо ця опція встановлена в значення `ALLOW_ANY`, проксі Istio дозволяє проходити викликам до невідомих сервісів. Якщо ж опція встановлена в значення `REGISTRY_ONLY`, тоді проксі Istio блокує будь-який хост, якщо для нього не визначений HTTP-сервіс або service entry у mesh. Стандартне значенням — `ALLOW_ANY`, що дозволяє вам швидко почати працювати з Istio без контролю доступу до зовнішніх сервісів. Пізніше ви можете вирішити [налаштувати доступ до зовнішніх сервісів](#controlled-access-to-external-services).

1.  Щоб побачити цей підхід у дії, потрібно переконатися, що ваше встановлення Istio налаштоване з опцією `meshConfig.outboundTrafficPolicy.mode`, встановленою на `ALLOW_ANY`. Якщо ви явно не встановлювали режим `REGISTRY_ONLY` під час інсталяції Istio, ймовірно, що за стандартно увімкнений режим `ALLOW_ANY`.

    Якщо ви не впевнені, ви можете виконати наступну команду, щоб переглянути конфігурацію вашого mesh:

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml
    {{< /text >}}

    Якщо ви не бачите явного налаштування `meshConfig.outboundTrafficPolicy.mode` зі значенням `REGISTRY_ONLY`, ви можете бути впевнені, що опція встановлена на `ALLOW_ANY`, яке є єдиним іншим можливим значенням і є стандартним значенням.

    {{< tip >}}
    Якщо ви явно налаштували режим `REGISTRY_ONLY`, ви можете змінити його,
    повторно виконавши вашу оригінальну команду `istioctl install` із зміненим налаштуванням, наприклад:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY
    {{< /text >}}

    {{< /tip >}}

2.  Виконайте кілька запитів до зовнішніх HTTPS сервісів з `SOURCE_POD`, щоб підтвердити успішні відповіді `200`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

Вітаю! Ви успішно передали вихідний трафік з вашого mesh.

Цей простий підхід до доступу до зовнішніх сервісів має недолік, оскільки ви втрачаєте можливість моніторингу та контролю Istio для трафіку до зовнішніх сервісів. У наступному розділі показано, як моніторити та контролювати доступ вашого mesh до зовнішніх сервісів.

## Контрольований доступ до зовнішніх сервісів {#controlled-access-to-external-services}

Використовуючи конфігурації Istio `ServiceEntry`, ви можете отримати доступ до будь-якого загальнодоступного сервісу зсередини вашого Istio кластера. У цьому розділі показано, як налаштувати доступ до зовнішнього HTTP сервісу, [httpbin.org](http://httpbin.org), а також до зовнішнього HTTPS сервісу, [www.google.com](https://www.google.com), зберігаючи можливості моніторингу та контролю трафіку в Istio.

### Перехід на політику стандартного блокування{#change-to-the-blocking-by-default-policy}

Щоб продемонструвати контрольований спосіб увімкнення доступу до зовнішніх сервісів, вам потрібно змінити опцію `meshConfig.outboundTrafficPolicy.mode` з режиму `ALLOW_ANY` на режим `REGISTRY_ONLY`.

{{< tip >}}
Ви можете додати контрольований доступ до сервісів, які вже доступні в режимі `ALLOW_ANY`. Таким чином, ви можете почати використовувати функції Istio для деяких зовнішніх сервісів, не блокуючи інші. Після того як ви налаштуєте всі свої сервіси, ви можете переключити режим на `REGISTRY_ONLY`, щоб заблокувати будь-які інші непередбачені доступи.
{{< /tip >}}

1.  Змініть опцію `meshConfig.outboundTrafficPolicy.mode` на `REGISTRY_ONLY`.

    Якщо ви використовували конфігурацію `IstioOperator` для встановлення Istio, додайте наступне поле до вашої конфігурації:

    {{< text yaml >}}
    spec:
      meshConfig:
        outboundTrafficPolicy:
          mode: REGISTRY_ONLY
    {{< /text >}}

    В іншому випадку додайте відповідне налаштування до вашої оригінальної команди `istioctl install`, наприклад:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
    {{< /text >}}

1.  Виконайте кілька запитів до зовнішніх HTTPS сервісів з `SOURCE_POD`, щоб перевірити, що вони тепер заблоковані:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c curl -- curl -sI https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    Може знадобитися деякий час, щоб зміна конфігурації набрала сили, тому ви все ще можете отримувати успішні підключення. Почекайте кілька секунд, а потім повторіть останню команду.
    {{< /warning >}}

### Доступ до зовнішнього HTTP сервісу {#access-an-external-http-service}

1.  Створіть `ServiceEntry` для дозволу доступу до зовнішнього HTTP сервісу.

    {{< warning >}}
    У наведеному нижче service entry використовується розвʼязання `DNS` як захід безпеки. Встановлення значення розвʼязання в `NONE` відкриває можливість для атаки. Зловмисний клієнт може вдатись, що він звертається до `httpbin.org`, встановивши це в заголовку `HOST`, хоча насправді підключаючись до іншої IP-адреси (яка не пов’язана з `httpbin.org`). Sidecar проксі Istio довірятиме заголовку HOST і неправомірно дозволить трафік, навіть якщо він направляється до IP-адреси іншого хосту. Цей хост може бути шкідливим сайтом або легітимним сайтом, забороненим політиками безпеки mesh.

    При розвʼязані `DNS` проксі sidecar ігноруватиме початкову IP-адресу призначення та направлятиме трафік до `httpbin.org`, виконуючи DNS-запит для отримання IP-адреси `httpbin.org`.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

2.  Виконайте запит до зовнішнього HTTP сервісу з `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.org",
        ...
        "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
        ...
      }
    }
    {{< /text >}}

    Зверніть увагу на заголовки, додані sidecar проксі Istio: `X-Envoy-Decorator-Operation`.

3.  Перевірте журнал sidecar проксі для `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    Зверніть увагу на запис, що стосується вашого HTTP-запиту до `httpbin.org/headers`.

### Доступ до зовнішнього HTTPS-сервісу {#access-an-external-https-service}

1.  Створіть `ServiceEntry`, щоб дозволити доступ до зовнішнього HTTPS-сервісу.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Зробіть запит до зовнішнього HTTPS-сервісу з `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSI https://www.google.com | grep  "HTTP/"
    HTTP/2 200
    {{< /text >}}

2.  Перевірте ло sidecar проксі `SOURCE_POD`:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    Зверніть увагу на запис, повʼязаний з вашим HTTPS-запитом до `www.google.com`.

### Керування трафіком до зовнішніх сервісів {#manage-traffic-to-external-services}

Подібно до запитів між сервісами всередині кластера, правила маршрутизації можуть бути налаштовані й для зовнішніх сервісів, до яких здійснюється доступ за допомогою конфігурацій `ServiceEntry`. У цьому прикладі ви налаштуєте правило тайм-ауту для запитів до сервісу `httpbin.org`.

{{< boilerplate gateway-api-support >}}

1)  Зсередини podʼа, який використовується як тестове джерело, виконайте _curl_ запит до точки доступу `/delay` зовнішнього сервісу httpbin.org:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    200
    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    Запит має поеврнути 200 (OK) приблизно через 5 секунд.

2)  За допомогою `kubectl` встановіть таймаут у 3 секунди на виклики до зовнішнього сервісу `httpbin.org`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  http:
  - timeout: 3s
    route:
    - destination:
        host: httpbin.org
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin-ext
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-ext
  hostnames:
  - httpbin.org
  rules:
  - timeouts:
      request: 3s
    backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: httpbin.org
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Зачекайте кілька секунд, а потім повторіть запит _curl_ ще раз:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    504
    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    This time a 504 (Gateway Timeout) appears after 3 seconds.
    Although httpbin.org was waiting 5 seconds, Istio cut off the request at 3 seconds.

### Видалення контрольованого доступу до зовнішніх сервісів {#cleanup-the-controlled-access-to-external-services}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext
$ kubectl delete httproute httpbin-ext --ignore-not-found=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Прямий доступ до зовнішніх сервісів {#direct-access-to-external-services}

Якщо ви бажаєте повністю оминути Istio для певного діапазону IP-адрес, ви можете налаштувати sidecarʼи Envoy так, щоб вони не [перехоплювали](/docs/concepts/traffic-management/) зовнішні запити. Для налаштування оминання змініть параметри конфігурації `global.proxy.includeIPRanges` або `global.proxy.excludeIPRanges` та оновіть config map `istio-sidecar-injector`, використовуючи команду `kubectl apply`. Це також можна налаштувати на рівні podʼа за допомогою відповідних [анотацій](/docs/reference/config/annotations/), таких як `traffic.sidecar.istio.io/includeOutboundIPRanges`. Після оновлення конфігурації `istio-sidecar-injector` зміни впливатимуть на всі подальші розгортання podʼів застосунків.

{{< warning >}}
На відміну від [перенаправлення трафіку Envoy до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services), де використовується політика трафіку `ALLOW_ANY`, що дозволяє sidecar проксі Istio передавати виклики до невідомих сервісів, цей підхід повністю оминає проксі, фактично відключаючи всі функції Istio для зазначених IP-адрес. Ви не зможете поступово додавати service entry для конкретних напрямків, як це можливо з підходом `ALLOW_ANY`. Тому цей варіант конфігурації рекомендується лише в крайньому випадку, коли з міркувань продуктивності або з інших причин зовнішній доступ не може бути налаштований через sidecar.
{{< /warning >}}

Простий спосіб не включати всі зовнішні IP-адреси з перенаправлення до sidecar проксі — це налаштувати параметр конфігурації `global.proxy.includeIPRanges` на діапазон або діапазони IP-адрес, які використовуються для внутрішніх сервісів кластера. Значення цих діапазонів IP-адрес залежить від платформи, на якій працює ваш кластер.

### Визначте внутрішні діапазони IP для вашої платформи {#determine-the-internal-ip-ranges-for-your-platform}

Встановіть значення параметра `values.global.proxy.includeIPRanges` відповідно до вашого провайдера кластера.

#### IBM Cloud Private

1.  Отримайте свій `service_cluster_ip_range` з конфігураційного файлу IBM Cloud Private у файлі `cluster/config.yaml`:

    {{< text bash >}}
    $ grep service_cluster_ip_range cluster/config.yaml
    {{< /text >}}

    Нижче наведено приклад виводу:

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  Використовуйте `--set values.global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

Щоб побачити, який CIDR використовується у кластері, скористайтеся `ibmcloud ks cluster get -c <CLUSTER-NAME>` і знайдіть `Service Subnet`:

{{< text bash >}}
$ ibmcloud ks cluster get -c my-cluster | grep "Service Subnet"
Service Subnet:                 172.21.0.0/16
{{< /text >}}

Потім використовуйте `--set values.global.proxy.includeIPRanges="172.21.0.0/16"`

{{< warning >}}
На дуже старих кластерах це може не спрацювати, тому ви можете скористатися `--set values.global.proxy.includeIPRanges="172.30.0.0/16,172.21.0.0/16,10.10.0/24"` або `kubectl get svc -o wide -A`, щоб ще більше звузити значення CIDR для налаштування.
{{< /warning >}}

#### Google Kubernetes Engine (GKE)

Діапазони не фіксовані, тому вам потрібно буде виконати команду `gcloud container clusters describe`, щоб визначити діапазони для використання. Наприклад:

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

Використовуйте `--set values.global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Kubernetes Service (AKS)

##### Kubenet

Щоб побачити, які service CIDR і pod CIDR використовуються в кластері, скористайтеся командою `az aks show` і знайдіть `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep Cidr
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

Потім, `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"`

##### Azure CNI

Дотримуйтеся цих кроків, якщо ви використовуєте Azure CNI в режимі мережі non-overlay. Якщо ви використовуєте Azure CNI з мережею overlay, будь ласка, дотримуйтесь [інструкцій для Kubenet](#kubenet). Для отримання додаткової інформації перегляньте [документацію Azure CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay).

Щоб дізнатися, який CIDR використовується для сервісів у кластері, використовуйте команду `az aks show` і знайдіть параметр `serviceCidr`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep serviceCidr
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
{{< /text >}}

Щоб дізнатися, який CIDR використовується у кластері, скористайтеся `az` CLI для перевірки `vnet`:

{{< text bash >}}
$ az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep nodeResourceGroup
  "nodeResourceGroup": "MC_user-rg_user-cluster_region",
  "nodeResourceGroupProfile": null,
$ az network vnet list -g MC_user-rg_user-cluster_region | grep name
    "name": "aks-vnet-74242220",
        "name": "aks-subnet",
$ az network vnet show -g MC_user-rg_user-cluster_region -n aks-vnet-74242220 | grep addressPrefix
    "addressPrefixes": [
      "addressPrefix": "10.224.0.0/16",
{{< /text >}}

Пртім, `--set values.global.proxy.includeIPRanges="10.244.0.0/16\,10.0.0.0/16"`

#### Minikube, Docker For Desktop, Bare Metal

Стандартне значення `10.96.0.0/12`, але воно не фіксоване. Використовуйте наступну команду, щоб визначити ваше поточне значення:

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

Потім, `--set values.global.proxy.includeIPRanges="10.96.0.0/12"`

### Налаштування оминання проксі {#configuring-the-proxy-bypass}

{{< warning >}}
Видаліть service entry та virtual service, які були раніше розгорнуті в цьому посібнику.
{{< /warning >}}

Оновіть config map `istio-sidecar-injector`, використовуючи діапазони IP-адрес, специфічні для вашої платформи. Наприклад, якщо діапазон становить 10.0.0.1/24, використовуйте наступну команду:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set values.global.proxy.includeIPRanges="10.0.0.1/24"
{{< /text >}}

Використовуйте ту саму команду, що й для [встановлення Istio](/docs/setup/install/istioctl), додавши `--set values.global.proxy.includeIPRanges="10.0.0.1/24"`.

### Доступ до зовнішніх сервісів {#access-the-external-services}

Оскільки конфігурація оминання впливає тільки на нові розгортання, вам потрібно завершити роботу та повторно розгорнути застосунок `curl`, як описано в розділі [Перш ніж розпочати](#before-you-begin).

Після оновлення configmap `istio-sidecar-injector` і повторного розгортання застосунку `curl`, sidecar Istio перехоплюватиме та керуватиме лише внутрішніми запитами всередині кластера. Будь-які зовнішні запити будуть оминати sidecar і направлятися безпосередньо до відповідного пункту призначення. Наприклад:

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c curl -- curl -sS http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
  }
}
{{< /text >}}

На відміну від доступу до зовнішніх сервісів через HTTP або HTTPS, ви не побачите жодних заголовків, повʼязаних із sidecar Istio, і запити, надіслані до зовнішніх сервісів, не відображатимуться в журналах sidecar. Оминання sidecar Istio означає, що ви більше не зможете моніторити доступ до зовнішніх сервісів.

### Видаліть прямий доступ до зовнішніх сервісів {#cleanup-the-direct-access-to-external-services}

Оновіть конфігурацію, щоб припинити оминання sidecar проксі для низки IP-адрес:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio>
{{< /text >}}

## Розуміння того, що сталося {#understanding-what-happened}

У цьому завданні ви розглянули три способи виклику зовнішніх сервісів з Istio mesh:

1. Налаштування Envoy для дозволу доступу до будь-якого зовнішнього сервісу.

2. Використання service entry для реєстрації доступного зовнішнього сервісу всередині mesh. Це рекомендований підхід.

3. Налаштування sidecar Istio для виключення зовнішніх IP-адрес з його перевизначеної таблиці IP.

Перший підхід спрямовує трафік через проксі-сервер Istio, включаючи виклики до сервісів, які не визначені в mesh. Використовуючи цей підхід, ви не можете контролювати доступ до зовнішніх сервісів або використовувати функції керування трафіком Istio для них. Для легкого переходу до другого підходу для конкретних сервісів просто створіть service entries для цих зовнішніх сервісів. Цей процес дозволяє вам спочатку отримати доступ до будь-якого зовнішнього сервісу, а потім вирішити, чи слід контролювати доступ, увімкнути моніторинг трафіку та використовувати функції керування трафіком за потреби.

Другий підхід дозволяє використовувати всі ті ж самі функції Istio service mesh для викликів до сервісів як усередині, так і поза кластером. У цьому завданні ви дізналися, як моніторити доступ до зовнішніх сервісів і налаштувати правило тайм-ауту для викликів до зовнішнього сервісу.

Третій підхід оминає проксі-сервер Istio, надаючи вашим сервісам прямий доступ до будь-якого зовнішнього сервера. Однак конфігурація проксі таким чином вимагає знання специфічних для провайдера кластера налаштувань. Подібно до першого підходу, ви також втрачаєте можливість моніторингу доступу до зовнішніх сервісів і не можете застосовувати функції Istio до трафіку на зовнішні сервіси.

## Примітка з безпеки {#security-note}

{{< warning >}}
Зверніть увагу, що конфігураційні приклади в цьому завданні **не забезпечують безпечний контроль трафіку egress** в Istio. Зловмисний застосунок може оминути sidecar проксі Istio та отримати доступ до будь-якого зовнішнього сервісу без контролю Istio.
{{< /warning >}}

Щоб реалізувати контроль трафіку egress більш безпечним способом, потрібно
[направити трафік egress через egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/) і ознайомитися з питаннями безпеки, описаними в розділі [додаткові міркування щодо безпеки](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations).

## Очищення {#cleanup}

Зупиніть сервіс [curl]({{< github_tree >}}/samples/curl):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
