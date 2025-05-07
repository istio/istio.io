---
title: Встановлення Istio CNI агента вузла
description: Встановіть і використовуйте Istio CNI агента вузла, що дозволяє операторам розгортати робочі навантаження з меншими привілеями.
weight: 70
aliases:
    - /uk/docs/setup/kubernetes/additional-setup/cni
    - /uk/docs/setup/additional-setup/cni
keywords: [cni]
owner: istio/wg-networking-maintainers
test: yes
---

Istio {{< gloss="cni" >}}CNI{{< /gloss >}} агент на вузлі використовується для налаштування перенаправлення трафіку для podʼів у mesh. Він працює як DaemonSet на кожному вузлі з підвищеними привілеями. CNI агент на вузлі використовується в обох режимах {{< gloss "панель даних" >}}панелі даних{{< /gloss >}} в Istio.

Для {{< gloss >}}sidecar{{< /gloss >}} режиму панелі даних, Istio CNI агент на вузлі є необов’язковим. Він усуває необхідність запуску привілейованих контейнерів ініціалізації у кожному podʼі в mesh, замінюючи цю модель одним привілейованим агентом на кожному Kubernetes вузлі.

Istio CNI агент на вузлі є **обов’язковим** в {{< gloss "ambient" >}}ambient{{< /gloss >}} режимі панелі даних.

Цей посібник зосереджений на використанні Istio CNI агента на вузлі як необов’язкової частини sidecar режиму панелі даних. Ознайомтеся з [документацією по ambient режиму](/docs/ambient/) для отримання інформації про використання ambient режиму панелі даних.

{{< tip >}}
Примітка: Istio CNI агент на вузлі _не замінює_ наявний у вашому кластері {{< gloss="cni" >}}CNI{{< /gloss >}}. Серед іншого, він встановлює _ланцюговий_ CNI втулок, який розрахований на накладення на інший, раніше встановлений основний інтерфейс CNI, наприклад, [Calico](https://docs.projectcalico.org), або CNI кластера, який використовує ваш хмарний провайдер. Дивіться [сумісність з іншими CNI](/docs/setup/additional-setup/cni/#compatibility-with-other-cnis) для отримання додаткової інформації.
{{< /tip >}}

Слідуйте цьому посібнику, щоб встановити, налаштувати та використовувати Istio CNI агент на вузлі разом з sidecar режимом панелі даних.

## Як працює перенаправлення трафіку для sidecar {#how-sidecar-traffic-redirection-works}

### Використання ініціалізуючого контейнера (без Istio CNI агента на вузлі) {#using-the-init-container-without-the-istio-cni-node-agent}

Стандартно Istio виконує інʼєкцію контейнера ініціалізації `istio-init` в podʼи, розгорнуті в mesh. Контейнер `istio-init` налаштовує перенаправлення мережевого трафіку podʼа до/з Istio sidecar проксі. Це вимагає, щоб користувач або службовий обліковий запис, який розгортає podʼи в mesh, мав достатньо дозволів Kubernetes RBAC для розгортання [контейнерів з можливостями `NET_ADMIN` і `NET_RAW`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).

### Використання Istio CNI агента на вузлі {#using-the-istio-cni-node-agent}

Необхідність у користувачів Istio мати підвищені дозволи Kubernetes RBAC є проблематичною для дотримання вимог безпеки деяких організацій, як і вимога розгортання привілейованих контейнерів ініціалізації з кожним робочим навантаженням.

`istio-cni` агент на вузлі фактично замінює контейнер `istio-init`, що забезпечує таку ж мережеву функціональність, але без необхідності використання або розгортання привілейованих init контейнерів з кожним робочим навантаженням. Натомість `istio-cni` працює як єдиний привілейований pod на вузлі. Він використовує цей привілей для встановлення [ланцюгового CNI втулка](https://www.cni.dev/docs/spec/#section-2-execution-protocol) на вузлі, який викликається після вашого "primary" інтерфейсу CNI втулка. CNI втулки динамічно викликаються Kubernetes як привілейований процес на вузлі хосту щоразу, коли створюється новий pod, і можуть налаштовувати мережу podʼа.

Istio ланцюговий CNI втулок завжди запускається після основних інтерфейсних втулків, ідентифікує застосунки користувачів в podʼах з sidecarʼами, які потребують перенаправлення трафіку, і налаштовує перенаправлення на етапі налаштування мережі в життєвому циклі podʼа Kubernetes, що усуває потребу в привілейованих init контейнерах, а також [вимогу для можливостей `NET_ADMIN` і `NET_RAW`](/docs/ops/deployment/application-requirements/) для користувачів і розгортання podʼів.

{{< image width="60%" link="./cni.svg" caption="Istio CNI" >}}

## Попередні умови для використання {#prerequisites-for-use}

1. Встановіть Kubernetes з правильно налаштованим втулком primary інтерфейсу CNI.Оскільки [підтримка CNI втулків є обов’язковою для реалізації мережевої моделі Kubernetes](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/), ймовірно, у вас це вже є, якщо у вас є досить сучасний кластер Kubernetes з функціональною мережею podʼів.
    * Кластери AWS EKS, Azure AKS та IBM Cloud IKS мають цю можливість.
    * Кластери Google Cloud GKE мають увімкнений CNI, коли будь-яка з наступних функцій увімкнена:
       [мережева політика](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy),
       [видимість усередині вузла](https://cloud.google.com/kubernetes-engine/docs/how-to/intranode-visibility),
       [ідентифікація робочих навантажень](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity),
       [політика безпеки podʼів](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#overview),
       або [dataplane v2](https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2).
    * Kind має стандартно увімкнений CNI.
    * OpenShift має стандартно увімкнений CNI.

2. Встановіть Kubernetes з увімкненим [ServiceAccount admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#serviceaccount).
    * Документація Kubernetes наполегливо рекомендує це для всіх установок Kubernetes, де використовуються `ServiceAccounts`.

## Встановлення CNI агента на вузлі {#installing-the-cni-node-agent}

### Встановлення Istio з компонентом `istio-cni` {#install-istio-with-the-istio-cni-component}

У більшості середовищ базовий кластер Istio з увімкненим компонентом `istio-cni` можна встановити за допомогою наступних команд:

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text syntax=bash snip_id=cni_agent_operator_install >}}
$ cat <<EOF > istio-cni.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    cni:
      namespace: istio-system
      enabled: true
EOF
$ istioctl install -f istio-cni.yaml -y
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text syntax=bash snip_id=cni_agent_helm_install >}}
$ helm install istio-cni istio/cni -n istio-system --wait
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Це розгорне DaemonSet `istio-cni` у кластері, який створить один Pod на кожному активному вузлі, розгорне виконуваний файл втулка Istio CNI на кожному вузлі та налаштує необхідну конфігурацію на рівні вузла для цього втулка. DaemonSet CNI працює з [`system-node-critical`](https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/) `PriorityClass`. Це пов’язано з тим, що це єдиний спосіб насправді переналаштувати мережу podʼа, щоб додати їх до mesh Istio.

{{< tip >}}
Ви можете встановити `istio-cni` у будь-який простір імен Kubernetes, але цей простір імен має дозволяти планування podʼів з `system-node-critical` PriorityClass. Деякі хмарні провайдери (зокрема GKE) стандартно забороняють планування podʼів `system-node-critical` у будь-якому просторі імен, крім специфічних, таких як `kube-system`.

Ви можете або встановити `istio-cni` у `kube-system`, або (рекомендується) визначити ResourceQuota для вашого кластера GKE, яка дозволяє використовувати podʼи з `system-node-critical` у просторі імен `istio-system`. Дивіться [тут](/docs/ambient/install/platform-prerequisites#google-kubernetes-engine-gke) для отримання додаткових деталей.
{{< /tip >}}

Зверніть увагу, що при встановленні `istiod` за допомогою Helm chart відповідно до [посібника з встановлення за допомогою Helm](/docs/setup/install/helm/#installation-steps), необхідно встановити `istiod` із наступним додатковим значенням override, щоб вимкнути виконання інʼєкції привілейованого контейнера ініціалізації:

{{< text syntax=bash snip_id=cni_agent_helm_istiod_install >}}
$ helm install istiod istio/istiod -n istio-system --set pilot.cni.enabled=true --wait
{{< /text >}}

### Додаткова конфігурація {#additional-configuration}

На додаток до наведеної вище базової конфігурації, є додаткові прапорці конфігурації, які можна налаштувати:

* `values.cni.cniBinDir` та `values.cni.cniConfDir` налаштовують шляхи до тек для встановлення виконуваного файлу втулка та створення конфігурації втулка.
* `values.cni.cniConfFileName` налаштовує ім’я конфігураційного файлу втулка.
* `values.cni.chained` керує тим, чи налаштовувати втулок як ланцюговий CNI втулок.

Зазвичай ці параметри не потребують змін, але деякі платформи можуть використовувати нестандартні шляхи. Будь ласка, ознайомтеся з рекомендаціями для вашої конкретної платформи, якщо такі є, [тут](/docs/ambient/install/platform-prerequisites).

{{< tip >}}
Існує проміжок часу між моментом, коли вузол стає доступним для планування, і моментом, коли втулок Istio CNI стає готовим на цьому вузлі. Якщо pod застосунку запускається під час цього періоду, можливо, що перенаправлення трафіку не буде належним чином налаштоване, і трафік зможе обійти Istio sidecar.

Цей стан перегонів пом’якшується для режиму панелі даних sidecar методом "detect and repair". Будь ласка, ознайомтеся з розділом [стан перегонів та пом’якшення його наслідків](/docs/setup/additional-setup/cni/#race-condition--mitigation), щоб зрозуміти наслідки цього пом’якшення, а також отримати інструкції щодо налаштування.
{{< /tip >}}

### Обробка інʼєкції контейнера ініціалізації для ревізій {#handling-init-container-injection-for-revisions}

Під час встановлення панелей управління з ревізіями з увімкненим компонентом CNI,
параметр `values.pilot.cni.enabled=true` необхідно встановити для кожної встановленої ревізії, щоб інжектор sidecar не намагався додати контейнер ініціалізації `istio-init` для цієї ревізії.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  revision: REVISION_NAME
  ...
  values:
    pilot:
      cni:
        enabled: true
  ...
{{< /text >}}

CNI втулок версії `1.x` сумісний із панелями управління версій `1.x-1`, `1.x` та `1.x+1`, що означає, що CNI та панель управління можуть оновлюватися в будь-якому порядку, якщо різниця у версіях не перевищує одну мінорну версію.

## Керування кластерами з встановленим CNI агентом вузла {#operating-clusters-with-the-cni-node-agent-installed}

### Оновлення {#upgrading}

Під час оновлення Istio за допомогою [оновлення на місці](/docs/setup/upgrade/in-place/), компонент CNI можна оновити разом з панеллю управління, використовуючи один ресурс `IstioOperator`.

Під час оновлення Istio за допомогою [канаркового оновлення](/docs/setup/upgrade/canary/), оскільки компонент CNI працює як одиничний елемент кластера, рекомендується управляти та оновлювати компонент CNI окремо від панелі управління з ревізією.

Наступний `IstioOperator` можна використовувати для незалежного оновлення компонента CNI.

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty # Не включати інші компоненти
  components:
    cni:
      enabled: true
  values:
    cni:
      excludeNamespaces:
        - istio-system
{{< /text >}}

Це не є проблемою для Helm, оскільки istio-cni встановлюється окремо і може бути оновлений через Helm:

{{< text syntax=bash snip_id=cni_agent_helm_upgrade >}}
$ helm upgrade istio-cni istio/cni -n istio-system --wait
{{< /text >}}

### Стан перегонів та зменшення його впливу {#race-condition--mitigation}

DaemonSet Istio CNI встановлює мережевий втулок CNI на кожному вузлі. Однак, існує проміжок часу між тим, коли Pod DaemonSet запланований на вузол, і коли втулок CNI встановлений та готовий до використання. Існує ймовірність, що під час цього проміжку часу запускатиметься pod застосунку, і `kubelet` не буде знати про втулок Istio CNI. Як результат, pod застосунку запускається без перенаправлення трафіку Istio та обходить sidecar контейнер Istio.

Щоб зменшити вплив перегонів між podʼом застосунку та DaemonSet Istio CNI, як частина інʼєкції sidecar контейнера додається контейнер ініціалізації `istio-validation`, який перевіряє, чи правильно налаштовано перенаправлення трафіку, і блокує запуск podʼа, якщо ні. DaemonSet CNI виявить і обробить будь-який pod, який застряг у такому стані; те, як pod обробляється, залежить від конфігурації, описаної нижче. Це зменшення впливу стандартно увімкнено і може бути вимкнено, встановленням значення `values.cni.repair.enabled` у false.

Ця можливість відновлення може бути додатково налаштована за допомогою різних дозволів RBAC для допомоги в помʼякшенні теоретичного вектора атаки, описаного у [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005/). Встановивши поля нижче в true/false за необхідністю, ви можете вибрати дозволи RBAC Kubernetes, надані Istio CNI.

|Конфігурація                      | Ролі        | Поведінка при помилці                                                                                                                         | Примітки
|----------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|--------
|`values.cni.repair.deletePods`    | DELETE pods | Podʼі видаляються, при переплануванні вони отримають правильну конфігурацію.                                                                    | Стандартно у версіях 1.20 і старіших
|`values.cni.repair.labelPods`     | UPDATE pods | Podʼі тільки позначаються мітками. Користувач повинен буде вручну вжити заходів для розвʼязання проблеми.                                                     |
|`values.cni.repair.repairPods`    | Немає       | Podʼі динамічно переналаштовуються для отримання відповідної конфігурації. При перезапуску контейнера pod продовжить нормальне виконання.       | Стандартно у версіях 1.21 і новіших

### Параметри перенаправлення трафіку {#traffic-redirection-parameters}

Щоб перенаправити трафік у мережевому просторі імен podʼа застосунка до/з sidecar контейнера-проксі Istio, втулок Istio CNI налаштовує `iptables` у просторі імен. Ви можете налаштувати параметри перенаправлення трафіку, використовуючи ті самі анотації podʼа, що й зазвичай, такі як порти та IP-діапазони, які потрібно включити або виключити з перенаправлення. Дивіться [ресурсні анотації](/docs/reference/config/annotations) для доступних параметрів.

### Сумісність з контейнерами ініціалізації застосунків{#compatibility-with-application-init-containers}

Втулок Istio CNI може спричинити проблеми з підключенням до мережі для будь-яких контейнерів ініціалізації застосунків у режимі панелі даних sidecar контейнера. При використанні Istio CNI `kubelet` запускає pod виконуючи наступні кроки:

1. Стандартний втулок CNI налаштовує мережеві інтерфейси podʼа та призначає IP-адреси podʼа.
2. Втулок Istio CNI налаштовує перенаправлення трафіку до sidecar проксі Istio у podʼі.
3. Всі контейнери ініціалізації виконуються та успішно завершуються.
4. Sidecar проксі Istio запускається в podʼі разом з іншими контейнерами podʼа.

Контейнери фнфціалізації виконуються перед запуском sidecar проксі, що може призвести до втрати трафіку під час їх виконання. Уникайте цієї втрати трафіку, використовуючи одне з наступних налаштувань:

1. Встановіть `uid` контейнера ініціалізації на `1337`, використовуючи `runAsUser`. `1337` це [`uid`, який використовується sidecar проксі](/docs/ops/deployment/application-requirements/#pod-requirements). Трафік, надісланий цим `uid`, не перехоплюється правилом `iptables` Istio. Трафік контейнера застосунку все ще буде перехоплюватися, як зазвичай.
2. Встановіть анотацію `traffic.sidecar.istio.io/excludeOutboundIPRanges`, щоб вимкнути перенаправлення трафіку до будь-яких CIDR, з якими контейнери ініціалізації взаємодіють.
3. Встановіть анотацію `traffic.sidecar.istio.io/excludeOutboundPorts`, щоб вимкнути перенаправлення трафіку до конкретних вихідних портів, які використовують контейнери ініціалізації.

{{< tip >}}
Ви повинні використовувати обхід `runAsUser 1337`, якщо ввімкнено [DNS-проксіювання](/docs/ops/configuration/traffic-management/dns-proxy/), а контейнер ініціалізації надсилає трафік на імʼя хосту, яке вимагає резолюції DNS.
{{< /tip >}}

{{< tip >}}
Деякі платформи (наприклад, OpenShift) не використовують `1337` як `uid` sidecar контейнера і натомість використовують псевдовипадковий номер, який відомий лише під час виконання. У таких випадках ви можете інструктувати проксі працювати з попередньо визначеним `uid`, скориставшись [функцією власної інʼєкції](/docs/setup/additional-setup/sidecar-injection/#customizing-injection), і використовувати той самий `uid` для контейнера ініціалізації.
{{< /tip >}}

{{< warning >}}
Будь ласка, використовуйте виключення захоплення трафіку з обережністю, оскільки анотації виключення IP/порту застосовуються не тільки до трафіку контейнера ініціалізації, але й до трафіку контейнера застосунку. Тобто трафік застосунку, надісланий на налаштований IP/порт, обійде sidecar контейнер Istio.
{{< /warning >}}

### Сумісність з іншими CNI {#compatibility-with-other-cnis}

Втулок Istio CNI дотримується [специфікації CNI](https://www.cni.dev/docs/spec/#container-network-interface-cni-specification) та повинен бути сумісний з будь-яким CNI, середовищем виконання контейнерів або іншим втулком, який також дотримується цієї специфікації.

Втулок Istio CNI працює як ланцюговий втулок CNI. Це означає, що його конфігурація додається до списку наявних конфігурацій втулків CNI. Дивіться [довідку зі специфікацією CNI](https://www.cni.dev/docs/spec/#section-1-network-configuration-format) для отримання додаткової інформації.

Коли pod створюється або видаляється, середовище виконання контейнерів викликає кожен втулок у списку по черзі.

Втулок Istio CNI виконує дії для налаштування перенаправлення трафіку podʼа застосунку — в режимі даних sidecar контейнера це означає застосування правил `iptables` у просторі імен мережі podʼа для перенаправлення внутрішньго трафіку podʼа на вбудований sidecar контейнер-проксі Istio.
