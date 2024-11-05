---
title: Встановлення Gateways
description: Встановлюйте та налаштовуйте шлюзи Istio.
weight: 40
keywords: [install,gateway,kubernetes]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
Якщо ви використовуєте Gateway API, вам не потрібно буде встановлювати та керувати `Deployment` gateway, як це описано в цьому документі. Стандартно, `Deployment` шлюза та `Service` автоматично надаються на основі конфігурації `Gateway`. Зверніться до [завдання Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) для отримання додаткових деталей.
{{< /tip >}}

Разом зі створенням сервісної мережі Istio дозволяє вам керувати [шлюзами](/docs/concepts/traffic-management/#gateways), які є проксі-серверами Envoy, що працюють на периметрі мережі, надаючи детальний контроль над трафіком, що входить та виходить з мережі.

Деякі з вбудованих [профілів конфігурації](/docs/setup/additional-setup/config-profiles/) Istio розгортають шлюзи під час установки. Наприклад, виклик `istioctl install` зі [стандартними налаштуваннями](/docs/setup/install/istioctl/#install-istio-using-the-default-profile) розгорне шлюз для вхідного трафіку разом з панеллю управління. Хоча це підходить для оцінки та простих випадків використання, таке налаштування повʼязує шлюз з панеллю управління, що ускладнює управління та оновлення. Для операційних розгортань Istio наполегливо рекомендується розʼєднати ці компоненти для забезпечення їх незалежної роботи.

Слідуйте цій інструкції, щоб окремо розгортати та керувати одним або кількома шлюзами в операційному розгортанні Istio.

## Передумови {#prerequisites}

Для продовження роботи відповідно до цієї інструкції, необхідно, щоб [панель управління Istio була встановлена](/docs/setup/install/).

{{< tip >}}
Ви можете використовувати профіль `minimal`, наприклад `istioctl install --set profile=minimal`, щоб запобігти розгортанню будь-яких шлюзів під час установки.
{{< /tip >}}

## Розгортання шлюзу {#deploying-a-gateway}

Використовуючи ті ж механізми, що й [інʼєкція sidecar Istio](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), конфігурація проксі Envoy для шлюзів також може бути автоматично додана.

Використання автоінʼєкції для розгортання шлюзів рекомендується, оскільки це дає розробникам повний контроль над розгортанням шлюзу, одночасно спрощуючи операційні процеси. Коли нове оновлення стає доступним або змінюється конфігурація, можна просто перезапустити podʼи шлюзів для їхнього оновлення. Це робить процес управління розгортанням шлюзу таким же, як і управління sidecar.

Для підтримки користувачів, які вже використовують інструменти розгортання, Istio надає кілька різних способів розгортання шлюзу. Кожен метод дасть однаковий результат. Виберіть метод, з яким ви найбільш знайомі.

{{< tip >}}
З міркувань безпеки рекомендується розгортати шлюз в іншому просторі імен, ніж панель управління.
{{< /tip >}}

Усі методи, наведені нижче, використовують [інʼєкцію](/docs/setup/additional-setup/sidecar-injection/), щоб додати додаткові налаштування podʼу під час виконання. Для підтримки цього, простір імен, в якому розгорнуто шлюз, не повинен мати мітку `istio-injection=disabled`. Якщо така мітка є, ви побачите, що podʼи не запускаються через спробу витягти образ `auto`, який є заповнювачем, призначеним для заміни під час створення podʼа.

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

Спочатку налаштуйте конфігураційний файл `IstioOperator`, який тут названо `ingress.yaml`:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: ingress
spec:
  profile: empty # Не встановлюйте CRD або панель управління
  components:
    ingressGateways:
    - name: istio-ingressgateway
      namespace: istio-ingress
      enabled: true
      label:
        # Встановіть унікальну мітку для шлюзу. Це необхідно, щоб забезпечити вибір цього робочого навантаження шлюзами.
        istio: ingressgateway
  values:
    gateways:
      istio-ingressgateway:
        # Увімкніть інжекцію шлюзу
        injectionTemplate: gateway
{{< /text >}}

Потім встановіть за допомогою стандартних команд `istioctl`:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ istioctl install -f ingress.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

Встановіть за допомогою стандартних команд `helm`:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ helm install istio-ingressgateway istio/gateway -n istio-ingress
{{< /text >}}

Щоб побачити можливі підтримувані значення конфігурації, виконайте `helm show values istio/gateway`. README репозиторію Helm [README](https://artifacthub.io/packages/helm/istio-official/gateway) містить додаткову інформацію про використання.

{{< tip >}}

При розгортанні шлюзу в кластері OpenShift використовуйте профіль `openshift`, щоб перевизначити стандартні значення, наприклад:

{{< text bash >}}
$ helm install istio-ingressgateway istio/gateway -n istio-ingress --set global.platform=openshift
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Kubernetes YAML" category-value="yaml" >}}

Спочатку налаштуйте конфігурацію Kubernetes, яка тут називається `ingress.yaml`:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  type: LoadBalancer
  selector:
    istio: ingressgateway
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        # Виберіть шаблон інʼєкції шлюзу (замість стандартного шаблону sidecar)
        inject.istio.io/templates: gateway
      labels:
        # Встановіть унікальну мітку для шлюзу. Це необхідно, щоб забезпечити вибір цього робочого навантаження шлюзами
        istio: ingressgateway
        # Увімкніть інʼєкцію шлюзу. Якщо підключаєтеся до панелі управління з revision, замініть на "istio.io/rev: імʼя-ревізії"
        sidecar.istio.io/inject: "true"
    spec:
      # Дозвольте привʼязку до всіх портів (таких як 80 і 443)
      securityContext:
        sysctls:
        - name: net.ipv4.ip_unprivileged_port_start
          value: "0"
      containers:
      - name: istio-proxy
        image: auto # Образ буде автоматично оновлюватися кожного разу під час запуску podʼа.
        # Відкиньте всі привілеї, дозволяючи запуск в якості non-root
        securityContext:
          capabilities:
            drop:
            - ALL
          runAsUser: 1337
          runAsGroup: 1337
---
# Налаштуйте ролі для дозволу читання облікових даних для TLS
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: istio-ingressgateway-sds
  namespace: istio-ingress
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: istio-ingressgateway-sds
subjects:
- kind: ServiceAccount
  name: default
{{< /text >}}

{{< warning >}}
Цей приклад показує мінімум, необхідний для запуску шлюзу. Для промислового використання рекомендується додаткова конфігурація, така як `HorizontalPodAutoscaler`, `PodDisruptionBudget`, та обмеження/запити ресурсів. Вони автоматично включені при використанні інших методів встановлення шлюзу.
{{< /warning >}}

{{< tip >}}
Мітка `sidecar.istio.io/inject` на podʼі використовується в цьому прикладі для увімкнення інʼєкції. Так само як і інʼєкція sidecar в застосунки, це можна контролювати на рівні простору імен. Дивіться [Контролювання політики інʼєкції](/docs/setup/additional-setup/sidecar-injection/#controlling-the-injection-policy) для отримання додаткової інформації.
{{< /tip >}}

Далі, застосуйте це до кластера:

{{< text bash >}}
$ kubectl create namespace istio-ingress
$ kubectl apply -f ingress.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Управління шлюзами {#managing-gateways}

Нижче описано, як керувати шлюзами після їх встановлення. Для отримання додаткової інформації про їх використання, слідуйте рекомендаціям з завдань [Ingress](/docs/tasks/traffic-management/ingress/) та [Egress](/docs/tasks/traffic-management/egress/).

### Селектори шлюзів {#gateway-selectors}

Мітки на podʼах розгортання шлюзу використовуються ресурсами конфігурації `Gateway`, тому важливо, щоб селектор вашого `Gateway` відповідав цим міткам.

Наприклад, у наведених вище розгортаннях, мітка `istio=ingressgateway` встановлена на podʼах шлюзу. Щоб застосувати `Gateway` до цих розгортань, вам потрібно вибрати ту ж мітку:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  selector:
    istio: ingressgateway
...
{{< /text >}}

### Топології розгортання шлюзу {#gateway-deployment-topologies}

Залежно від конфігурації вашої сервісної мережі та випадків використання, ви можете захотіти розгортати шлюзи різними способами. Нижче показано декілька різних шаблонів розгортання шлюзу. Зверніть увагу, що декілька з цих шаблонів можуть використовуватися в одному й тому ж кластері.

#### Спільний шлюз {#shared-gateway}

У цій моделі один централізований шлюз використовується багатьма застосунками, можливо, у багатьох просторах імен. Шлюзи у просторі імен `ingress` делегують управління маршрутами до простору імен застосунків, але зберігають контроль над конфігурацією TLS.

{{< image width="50%" link="shared-gateway.svg" caption="Спільний шлюз" >}}

Ця модель добре працює, коли у вас є багато застосунків, які ви хочете зробити доступними ззовні, оскільки вони можуть використовувати спільну інфраструктуру. Вона також підходить для випадків використання, коли багато застосунків використовують один і той же домен або TLS-сертифікати.

#### Виділений шлюз для застосунку {#dedicated-application-gateway}

У цій моделі простір імен застосунку має власне виділене розгортання шлюзу. Це дозволяє надати повний контроль та управління одному простору імен. Цей рівень ізоляції може бути корисним для критичних застосунків, які мають строгі вимоги до продуктивності або безпеки.

{{< image width="50%" link="user-gateway.svg" caption="Виділений шлюз для застосунку" >}}

Якщо перед Istio немає іншого балансувальника навантаження, це, як правило, означає, що кожен застосунок матиме свою власну IP-адресу, що може ускладнити налаштування DNS.

## Оновлення шлюзів {#upgrading-gateways}

### Оновлення на місці {#in-place-upgrade}

Оскільки шлюзи використовують інʼєкцію podʼів, нові podʼи шлюзу, які створюються, автоматично отримують останню конфігурацію, що включає версію.

Щоб застосувати зміни до конфігурації шлюзу, podʼи можна просто перезапустити, використовуючи такі команди, як `kubectl rollout restart deployment`.

Якщо ви хочете змінити [ревізію панелі управління](/docs/setup/upgrade/canary/), яку використовує шлюз, ви можете встановити мітку `istio.io/rev` на розгортанні шлюзу, що також викличе поступове перезапускання.

{{< image width="50%" link="inplace-upgrade.svg" caption="Оновлення на місці в процесі" >}}

### Канаркове оновлення (розширене) {#canary-upgrade}

{{< warning >}}
Цей метод оновлення залежить від ревізій панелі управління, тому його можна використовувати лише разом із [канарковим оновленням панелі управління](/docs/setup/upgrade/canary/).
{{< /warning >}}

Якщо ви хочете повільніше контролювати розгортання нової ревізії панелі управління, ви можете запустити кілька версій розгортання шлюзу. Наприклад, якщо ви хочете розгорнути нову ревізію `canary`, створіть копію свого розгортання шлюзу з встановленою міткою `istio.io/rev=canary`:

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway-canary
  namespace: istio-ingress
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      annotations:
        inject.istio.io/templates: gateway
      labels:
        istio: ingressgateway
        istio.io/rev: canary # Встановіть на ревізію панелі управління, яку ви хочете розгорнути
    spec:
      containers:
      - name: istio-proxy
        image: auto
{{< /text >}}

Коли це розгортання буде створено, ви матимете дві версії шлюзу, обидві з яких будуть вибрані тим самим сервісом:

{{< text bash >}}
$ kubectl get endpoints -n istio-ingress -o "custom-columns=NAME:.metadata.name,PODS:.subsets[*].addresses[*].targetRef.name"
NAME                   PODS
istio-ingressgateway   istio-ingressgateway-...,istio-ingressgateway-canary-...
{{< /text >}}

{{< image width="50%" link="canary-upgrade.svg" caption="Канаркове оновлення в процесі" >}}

На відміну від сервісів застосунків, розгорнутих усередині сервісної мережі, ви не можете використовувати [перемикання трафіку Istio](/docs/tasks/traffic-management/traffic-shifting/), щоб розподіляти трафік між версіями шлюзу, оскільки їх трафік надходить безпосередньо від зовнішніх клієнтів, які не контролюються Istio. Замість цього ви можете контролювати розподіл трафіку кількістю реплік кожного розгортання. Якщо ви використовуєте інший балансувальник навантаження перед Istio, ви також можете використовувати його для контролю розподілу трафіку.

{{< warning >}}
Оскільки інші методи встановлення включають шлюз `Service`, який керує його зовнішньою IP-адресою, разом із розгортанням шлюзу `Deployment`, тільки метод [Kubernetes YAML](/docs/setup/additional-setup/gateway/#tabset-docs-setup-additional-setup-gateway-1-2-tab) підтримується для цього методу оновлення.
{{< /warning >}}

### Канаркове оновлення із зовнішнім перемиканням трафіку (розширене) {#canary-upgrade-external-with-external-traffic-shifting-advanced}

Варіантом підходу [канаркового оновлення](#canary-upgrade) є перемикання трафіку між версіями, використовуючи високорівневу конструкцію поза Istio, наприклад, зовнішній балансувальник навантаження або DNS.

{{< image width="50%" link="high-level-canary.svg" caption="Канаркове оновлення в процесі із зовнішнім перемиканням трафіку" >}}

Це пропонує точний контроль, але може бути непридатним або занадто складним для налаштування в деяких середовищах.

## Очищення {#cleanup}

- Очищення Istio ingress шлюзу

    {{< text bash >}}
    $ istioctl uninstall --istioNamespace istio-ingress -y --purge
    $ kubectl delete ns istio-ingress
    {{< /text >}}
