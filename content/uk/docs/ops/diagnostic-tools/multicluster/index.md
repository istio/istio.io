---
title: Усунення проблем з мультикластерами
description: Описує інструменти та техніки для діагностики проблем з мультикластерними та мультимережевими установками.
weight: 90
keywords: [debug,multicluster,multi-network,envoy]
owner: istio/wg-environments-maintainers
test: no
---

Ця сторінка описує, як усувати проблеми з Istio, розгорнутим на кількох кластерах та/або мережах. Перед тим як читати це, слід виконати кроки, зазначені у [Встановлення мультикластера](/docs/setup/install/multicluster/) та ознайомитися з [Моделями розгортання](/docs/ops/deployment/deployment-models/).

## Балансування навантаження між кластерами {#cross-cluster-load-balancing}

Найпоширеніша, але також широкомасштабна проблема з багатомережевими установками — це непрацююче балансування навантаження між кластерами. Зазвичай це проявляється в тому, що ви бачите відповіді тільки від кластерної локального екземпляру сервісу:

{{< text bash >}}
$ for i in $(seq 10); do kubectl --context=$CTX_CLUSTER1 -n sample exec sleep-dd98b5f48-djwdw -c sleep -- curl -s helloworld:5000/hello; done
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
Hello version: v1, instance: helloworld-v1-578dd69f69-j69pf
...
{{< /text >}}

При дотриманні інструкцій для [перевірки установки мультикластера](/docs/setup/install/multicluster/verify/) ми очікували б відповіді від обох версій `v1` і `v2`, що свідчить про те, що трафік йде до обох кластерів.

Є безліч можливих причин цієї проблеми:

### Проблеми з підключенням і брандмауерами {#connectivity-and-firewall-issues}

У деяких середовищах може бути неочевидно, що брандмауер блокує трафік між вашими кластерами. Можливо, що `ICMP` (ping) трафік може успішно проходити, але HTTP та інші види трафіку — ні. Це може проявлятися як тайм-аут або, в деяких випадках, як більш заплутана помилка, така як:

{{< text plain >}}
upstream connect error or disconnect/reset before headers. reset reason: local reset, transport failure reason: TLS error: 268435612:SSL routines:OPENSSL_internal:HTTP_REQUEST
{{< /text >}}

Хоча Istio надає можливості виявлення сервісів для спрощення цього процесу, міжкластерний трафік все одно повинен бути успішним якщо podʼи в кожному кластері знаходяться в одній мережі без Istio. Щоб виключити проблеми з TLS/mTLS, ви можете провести ручне тестування трафіку, використовуючи pod без sidecarʼів Istio.

У кожному кластері створіть новий простір імен для цього тесту. Не вмикайте інʼєкції sidecar:

{{< text bash >}}
$ kubectl create --context="${CTX_CLUSTER1}" namespace uninjected-sample
$ kubectl create --context="${CTX_CLUSTER2}" namespace uninjected-sample
{{< /text >}}

Далі розгорніть ті ж самі застосунки, що і в [перевірці установки мультикластера](/docs/setup/install/multicluster/verify/):

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
$ kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/sleep/sleep.yaml -n uninjected-sample
{{< /text >}}

Перевірте, що є pod helloworld, що працює в `cluster2`, використовуючи прапорець `-o wide`, щоб отримати IP Pod:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" -n uninjected-sample get pod -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
helloworld-v2-54df5f84b-z28p5    1/1     Running   0          43s   10.100.0.1   node-1   <none>           <none>
sleep-557747455f-jdsd8           1/1     Running   0          41s   10.100.0.2   node-2   <none>           <none>
{{< /text >}}

Занотуйте стовпець `IP` для `helloworld`. У цьому випадку це `10.100.0.1`:

{{< text bash >}}
$ REMOTE_POD_IP=10.100.0.1
{{< /text >}}

Далі спробуйте надіслати трафік від podʼа `sleep` в `cluster1` безпосередньо на цей IP Pod:

{{< text bash >}}
$ kubectl exec --context="${CTX_CLUSTER1}" -n uninjected-sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n uninjected-sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS $REMOTE_POD_IP:5000/hello
Hello version: v2, instance: helloworld-v2-54df5f84b-z28p5
{{< /text >}}

Якщо успішно, мають бути відповіді тільки від `helloworld-v2`. Повторіть ці кроки, але надішліть трафік з `cluster2` до `cluster1`.

Якщо це успішно, можна виключити проблеми з підключенням. Якщо ні, причина проблеми може лежати поза вашою конфігурацією Istio.

### Балансування навантаження по локації {#locality-load-balancing}

[Балансування навантаження по локації](/docs/tasks/traffic-management/locality-load-balancing/failover/#configure-locality-failover) може використовуватися для того, щоб клієнти віддавали перевагу трафіку до найближчого призначення. Якщо кластери перебувають в різних локаціях (регіон/зона), балансування навантаження по локації віддасть перевагу локальному кластеру, і це працює як очікується. Якщо балансування навантаження по локації вимкнене або кластери знаходяться в одній локації, може бути інша проблема.

### Конфігурація довіри {#trust-configuration}

Трафік між кластерами, як і трафік всередині кластера, залежить від спільного кореня довіри між проксі. Стандартно Istio використовує свої власні індивідуально згенеровані сертифікати кореня. Для мультикластерних установок ми повинні вручну налаштувати спільний корінь довіри. Слідкуйте за підрозділом "Додавання сертифікатів" нижче або читайте [Моделі ідентичності та довіри](/docs/ops/deployment/deployment-models/#identity-and-trust-models), щоб дізнатися більше.

**Додавання сертифікатів:**

Щоб перевірити, чи сертифікати налаштовані правильно, ви можете порівняти кореневий сертифікат у кожному кластері:

{{< text bash >}}
$ diff \
   <(kubectl --context="${CTX_CLUSTER1}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}') \
   <(kubectl --context="${CTX_CLUSTER2}" -n istio-system get secret cacerts -ojsonpath='{.data.root-cert\.pem}')
{{< /text >}}

Якщо кореневі сертифікати не збігаються або секрет взагалі не існує, слід слідувати інструкціям з [Додавання сертифікатів CA](/docs/tasks/security/cert-management/plugin-ca-cert/), забезпечуючи виконання кроків для кожного кластера.

### Покрокова діагностика {#step-by-step-diagnosis}

Якщо ви пройшли через вищезазначені розділи та все ще стикаєтеся з проблемами, то час заглибитися трохи глибше.

Наступні кроки передбачають, що ви дотримуєтеся [перевірки HelloWorld](/docs/setup/install/multicluster/verify/). Перед тим як продовжити, переконайтеся, що як `helloworld`, так і `sleep` розгорнуті в кожному кластері.

З кожного кластера знайдіть точки доступу сервісу `sleep` для `helloworld`:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
{{< /text >}}

Інформація для усунення неполадок відрізняється залежно від того, який кластер є джерелом трафіку:

{{< tabset category-name="source-cluster" >}}

{{< tab name="Основний кластер" category-value="primary" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.0.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Показана тільки одна точка доступу, що вказує на те, що панель управління не може читати точки доступу з віддаленого кластера. Перевірте, чи правильно налаштовані віддалені секрети.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* Якщо секрет відсутній, створіть його.
* Якщо секрет присутній:
  * Перегляньте конфігурацію в секреті. Переконайтеся, що імʼя кластера використовується як ключ даних для віддаленого `kubeconfig`.
  * Якщо секрет виглядає правильно, перевірте журнали `istiod` на наявність проблем з підключенням або дозволами для досягнення віддаленого Kubernetes API сервера. Журнали можуть містити повідомлення `Failed to add remote cluster from secret` разом з причиною помилки.

{{< /tab >}}

{{< tab name="Віддалений кластер" category-value="remote" >}}

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER2 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.1.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

Показана тільки одна точка доступу, що вказує на те, що панель управління не може читати точки доступу з віддаленого кластера. Перевірте, чи правильно налаштовані віддалені секрети.

{{< text bash >}}
$ kubectl get secrets --context=$CTX_CLUSTER1 -n istio-system -l "istio/multiCluster=true"
{{< /text >}}

* Якщо секрет відсутній, створіть його.
* Якщо секрет присутній і точка доступу є Podʼом в **основному** кластері:
  * Перегляньте конфігурацію в секреті. Переконайтеся, що імʼя кластера використовується як ключ даних для віддаленого `kubeconfig`.
  * Якщо секрет виглядає правильно, перевірте журнали `istiod` на наявність проблем з підключенням або дозволами для досягнення віддаленого Kubernetes API сервера. Журнали можуть містити повідомлення `Failed to add remote cluster from secret` разом з причиною помилки.
* Якщо секрет присутній і точка доступу є Podʼом у **віддаленому** кластері:
  * Проксі читає конфігурацію з istiod всередині віддаленого кластера. Коли віддалений кластер має in-cluster istiod, це призначено лише для інʼєкції sidecarʼів та CA. Ви можете перевірити, чи це проблема, шукаючи службу з назвою `istiod-remote` в просторі імен `istio-system`. Якщо її немає, перевстановіть, переконавшись, що `values.global.remotePilotAddress` налаштований.

{{< /tab >}}

{{< tab name="Мультимережа" category-value="multi-primary" >}}

Кроки для Основного та Віддаленого кластерів все ще застосовуються для багатомережевих установок, хоча багатомережеве середовище має додатковий випадок:

{{< text bash >}}
$ istioctl --context $CTX_CLUSTER1 proxy-config endpoint sleep-dd98b5f48-djwdw.sample | grep helloworld
10.0.5.11:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
10.0.6.13:5000                   HEALTHY     OK                outbound|5000||helloworld.sample.svc.cluster.local
{{< /text >}}

У багатомережевих установках ми очікуємо, що одна з IP-адрес точок доступу відповідатиме публічній IP-адресі шлюза для віддаленої мережі. Наявність кількох IP-адрес Pod вказує на одну з двох речей:

* Адресу шлюза для віддаленої мережі не можна визначити.
* Мережа або клієнтського, або серверного podʼа не може бути визначена.

**Адресу шлюза для віддаленої мережі не можна визначити:**

У віддаленому кластері, якого не можна досягти, перевірте, чи служба має зовнішню IP-адресу:

{{< text bash >}}
$ kubectl -n istio-system get service -l "istio=eastwestgateway"
NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                                                           AGE
istio-eastwestgateway    LoadBalancer   10.8.17.119   <PENDING>        15021:31781/TCP,15443:30498/TCP,15012:30879/TCP,15017:30336/TCP   76m
{{< /text >}}

Якщо `EXTERNAL-IP` застряг у `<PENDING>`, середовище може не підтримувати служби `LoadBalancer`. У цьому випадку може бути необхідно налаштувати розділ `spec.externalIPs` сервісу вручну, щоб надати шлюзу IP-адресу, доступну ззовні кластеру.

Якщо зовнішня IP-адреса присутня, перевірте, чи сервіс включає мітку `topology.istio.io/network` з правильним значенням. Якщо це невірно, перевстановіть шлюз і переконайтеся, що ви встановили прапорець --network на скрипті генерації.

**Мережа або клієнтського, або серверного podʼа не може бути визначена:**

На podʼі-джерелі перевірте метадані проксі.

{{< text bash >}}
$ kubectl get pod $SLEEP_POD_NAME \
  -o jsonpath="{.spec.containers[*].env[?(@.name=='ISTIO_META_NETWORK')].value}"
{{< /text >}}

{{< text bash >}}
$ kubectl get pod $HELLOWORLD_POD_NAME \
  -o jsonpath="{.metadata.labels.topology\.istio\.io/network}"
{{< /text >}}

Якщо будь-яке з цих значень не встановлене або має неправильне значення, istiod може вважати джерело і клієнтські проксі в одній мережі та надсилати мережеві локальні точки доступу. Коли ці значення не встановлені, перевірте, чи `values.global.network` був правильно встановлений під час установки, або чи налаштовано webhook для інʼєкції правильно.

Istio визначає мережу podʼа за допомогою мітки `topology.istio.io/network`, яка встановлюється під час інʼєкції. Для podʼів без інʼєкції Istio покладається на мітку `topology.istio.io/network`, встановлену на системному просторі імен у кластері.

У кожному кластері перевірте мережу:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get ns istio-system -ojsonpath='{.metadata.labels.topology\.istio\.io/network}'
{{< /text >}}

Якщо наведена команда не виводить очікуване імʼя мережі, встановіть мітку:

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
