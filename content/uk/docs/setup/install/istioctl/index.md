---
title: Встановлення за допомогою Istioctl
description: Встановіть та налаштуйте будь-який профіль конфігурації Istio для глибокої оцінки або використання в операційному середовищі.
weight: 10
keywords: [istioctl,kubernetes]
owner: istio/wg-environments-maintainers
test: no
---

Слідуйте цьому посібнику для встановлення та налаштування мережі Istio для глибокої оцінки або використання в операційному середовищі. Якщо ви новачок в Istio і просто хочете спробувати його, слідуйте [інструкціям для швидкого старту](/docs/setup/getting-started).

У цьому посібнику з встановлення використовується інструмент командного рядка [istioctl](/docs/reference/commands/istioctl/) для надання широких можливостей налаштування панелі управління Istio та sidecars для панелі даних Istio. У ньому є перевірка введених користувачем даних, щоб запобігти помилкам під час встановлення, а також опції налаштування, які дозволяють замінити будь-який аспект конфігурації.

Завдяки цим інструкціям ви можете вибрати будь-який з вбудованих [профілів конфігурації Istio](/docs/setup/additional-setup/config-profiles/) та подальше налаштування конфігурації відповідно до ваших конкретних потреб.

Команда `istioctl` підтримує повний [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/) через параметри командного рядка для окремих налаштувань або для передачі yaml-файлу, що містить `IstioOperator`
{{<gloss CRD>}}власний ресурс (CR){{</gloss>}}.

## Передумови {#prerequisites}

Перед початком перевірте наступні вимоги:

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/).
1. Виконайте будь-яке необхідне [налаштування для вашої платформи](/docs/setup/platform-setup/).
1. Перевірте [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

## Встановлення Istio за допомогою стандартного профілю {#install-istio-using-the-default-profile}

Найпростіший варіант — це встановити `default` [профіль конфігурації](/docs/setup/additional-setup/config-profiles/) Istio за допомогою наступної команди:

{{< text bash >}}
$ istioctl install
{{< /text >}}

Ця команда встановлює профіль `default` в кластер, визначений вашою конфігурацією Kubernetes. Профіль `default` є хорошою відправною точкою для створення операційного середовища, на відміну від більшого профілю `demo`, який призначений для оцінки широкого набору можливостей Istio.

Для зміни інсталяцій можна налаштувати різні параметри. Наприклад, увімкнути журнали доступу:

{{< text bash >}}
$ istioctl install --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

{{< tip >}}
Багато прикладів на цій сторінці та в іншій документації написані з використанням `--set` для зміни параметрів встановлення, а не передачі конфігураційного файлу з `-f`. Це зроблено для спрощення прикладів. Обидва методи еквівалентні, але `-f` наполегливо рекомендується для операційного середовища. Вищенаведену команду можна переписати наступним чином, використовуючи `-f`:

{{< text bash >}}
$ cat <<EOF > ./my-config.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
EOF
$ istioctl install -f my-config.yaml
{{< /text >}}

{{< /tip >}}

{{< tip >}}
Повний API документовано в [довідці `IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/). Загалом, ви можете використовувати прапорець `--set` в `istioctl`, як це робиться в Helm, а API Helm `values.yaml` наразі підтримується для зворотної сумісності. Єдина відмінність у тому, що ви повинні додавати `values.` до застарілих шляхів `values.yaml`, оскільки це префікс для API передачі Helm.
{{< /tip >}}

## Встановлення з зовнішніх чартів {#install-from-external-charts}

Стандартно, `istioctl` використовує вбудовані чарти для генерації маніфесту встановлення. Ці чарти випускаються разом з `istioctl` для аудиту та налаштувань, їх можна знайти в архіві релізу в теці `manifests`. `istioctl` також може використовувати зовнішні чарти замість вбудованих. Щоб вибрати зовнішні чарти, встановіть в прапорець `manifests` шлях до локальної файлової системи:

{{< text bash >}}
$ istioctl install --manifests=manifests/
{{< /text >}}

Якщо використовувати бінарний файл `istioctl` {{< istio_full_version >}}, ця команда призведе до тієї ж установки, що й `istioctl install` самостійно, оскільки вона вказує на ті ж чарти, що й вбудовані. Окрім експериментування або тестування нових функцій, рекомендується використовувати вбудовані чарти, а не зовнішні, для забезпечення сумісності бінарного файлу `istioctl` з чартами.

## Встановлення іншого профілю {#install-a-different-profile}

Інші профілі конфігурації Istio можна встановити в кластер, передавши назву профілю в командному рядку. Наприклад, для встановлення профілю `demo` можна використовувати наступну команду:

{{< text bash >}}
$ istioctl install --set profile=demo
{{< /text >}}

## Показ переліку доступних профілів {#display-the-list-of-available-profiles}

Ви можете показати імена профілів конфігурації Istio, які доступні для `istioctl`, використовуючи цю команду:

{{< text bash >}}
$ istioctl profile list
Istio configuration profiles:
    default
    demo
    empty
    minimal
    openshift
    preview
    remote
{{< /text >}}

## Показ конфігурації профілю {#display-the-configurations-of-a-profile}

Ви можете переглянути налаштування конфігурації профілю. Наприклад, щоб переглянути налаштування для профілю `demo`, виконайте наступну команду:

{{< text bash >}}
$ istioctl profile dump demo
components:
  egressGateways:
  - enabled: true
    k8s:
      resources:
        requests:
          cpu: 10m
          memory: 40Mi
    name: istio-egressgateway

...
{{< /text >}}

Щоб переглянути підмножину всієї конфігурації, можна використовувати прапорець `--config-path`, який вибирає тільки ту частину конфігурації, що знаходиться в заданім шляху:

{{< text bash >}}
$ istioctl profile dump --config-path components.pilot demo
enabled: true
k8s:
  env:
  - name: PILOT_TRACE_SAMPLING
    value: "100"
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
{{< /text >}}

## Показати відмінності між профілями {#show-differences-in-profiles}

Підкоманда `profile diff` може бути використана для показу відмінностей між профілями, що корисно для перевірки ефектів налаштування перед застосуванням змін до кластера.

Ви можете показати відмінності між профілями `default` та `demo`, використовуючи ці команди:

{{< text bash >}}
$ istioctl profile diff default demo
 gateways:
   egressGateways:
-  - enabled: false
+  - enabled: true
...
     k8s:
        requests:
-          cpu: 100m
-          memory: 128Mi
+          cpu: 10m
+          memory: 40Mi
       strategy:
...
{{< /text >}}

## Створення маніфесту перед встановленням {#generate-a-manifest-before-installation}

Ви можете згенерувати маніфест перед встановленням Istio, використовуючи підкоманду `manifest generate`. Наприклад, використовуйте наступну команду для генерації маніфесту для профілю `default`:

{{< text bash >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

Згенерований маніфест можна використовувати для перевірки того, що саме буде встановлено, а також для відстеження змін у маніфесті з часом. Хоча `IstioOperator` CR представляє повну конфігурацію користувача і достатній для її відстеження, вихідні дані з `manifest generate` також відображають можливі зміни в основних чартах і тому можуть бути використані для відстеження фактично встановлених ресурсів.

Вихідні дані з `manifest generate` також можуть бути використані для встановлення Istio за допомогою `kubectl apply` або еквіваленту. Однак ці альтернативні методи встановлення можуть не застосовувати ресурси в тому ж порядку залежностей, як `istioctl install`, і не тестуються в релізі Istio.

{{< warning >}}
Якщо ви намагаєтеся встановити та управляти Istio за допомогою `istioctl manifest generate`, зверніть увагу на наступні застереження:

1. Простір імен Istio (`istio-system` стандартний) повинен бути створений вручну.

2. Перевірка Istio не буде стандартно увімкнена. На відміну від `istioctl install`, команда `manifest generate` не створює конфігурацію валідуючого вебхука `istiod-default-validator`, якщо не встановлено `values.defaultRevision`:

    {{< text bash >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

3. Хоча `istioctl install` автоматично виявляє специфічні налаштування середовища з вашого контексту Kubernetes, `manifest generate` не може цього зробити, оскільки вона працює офлайн, що може призвести до неочікуваних результатів. Особливо, ви повинні переконатися, що дотримуєтеся [цих кроків](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens), якщо ваше середовище Kubernetes не підтримує токени облікових записів сервісів третьої сторони.

4. `kubectl apply` зі згенерованим маніфестом може показувати тимчасові помилки через недоступність ресурсів у кластері в правильному порядку.

5. `istioctl install` автоматично очищає будь-які ресурси, які повинні бути видалені при зміні конфігурації (наприклад, якщо ви видаляєте шлюз). Це не відбувається при використанні `istio manifest generate` з `kubectl`, і ці ресурси повинні бути видалені вручну.

{{< /warning >}}

## Показати відмінності в маніфестах {#show-differences-in-manifests}

Ви можете показати відмінності в згенерованих маніфестах у форматі YAML, порівнюючи стандартний профіль і власне встановлення, використовуючи ці команди:

{{< text bash >}}
$ istioctl manifest generate > 1.yaml
$ istioctl manifest generate -f samples/operator/pilot-k8s.yaml > 2.yaml
$ istioctl manifest diff 1.yaml 2.yaml
Відмінності в маніфестах:

Обʼєкт Deployment:istio-system:istiod має відмінності:

spec:
  template:
    spec:
      containers:
        '[#0]':
          resources:
            requests:
              cpu: 500m -> 1000m
              memory: 2048Mi -> 4096Mi

Обʼєкт HorizontalPodAutoscaler:istio-system:istiod має відмінності:

spec:
  maxReplicas: 5 -> 10
  minReplicas: 1 -> 2
{{< /text >}}

## Перевірка успішності встановлення {#verify-a-successful-installation}

Ви можете перевірити, чи вдалася установка Istio, використовуючи команду `verify-install`, яка порівнює встановлення у вашому кластері з маніфестом, який ви вказали.

Якщо ви не згенерували свій маніфест перед розгортанням, виконайте наступну команду, щоб згенерувати його зараз:

{{< text bash >}}
$ istioctl manifest generate <ваші початкові параметри встановлення> > $HOME/generated-manifest.yaml
{{< /text >}}

Потім виконайте наступну команду `verify-install`, щоб перевірити, чи було встановлення успішним:

{{< text bash >}}
$ istioctl verify-install -f $HOME/generated-manifest.yaml
{{< /text >}}

Дивіться [Налаштування конфігурації встановлення](/docs/setup/additional-setup/customize-installation/) для отримання додаткової інформації про налаштування встановлення.

## Видалення Istio {#uninstall-istio}

Щоб повністю видалити Istio з кластера, виконайте наступну команду:

{{< text bash >}}
$ istioctl uninstall --purge
{{< /text >}}

{{< warning >}}
Необовʼязковий прапорець `--purge` видалить всі ресурси Istio, включаючи ресурси, які можуть бути спільними з іншими панелями управління Istio.
{{< /warning >}}

Альтернативно, щоб видалити тільки певну панель управління Istio, виконайте наступну команду:

{{< text bash >}}
$ istioctl uninstall <ваші початкові параметри встановлення>
{{< /text >}}

або

{{< text bash >}}
$ istioctl manifest generate <ваші початкові параметри встановлення> | kubectl delete --ignore-not-found=true -f -
{{< /text >}}

Простір імен панелі управління (наприклад, `istio-system`) стандартно не видаляється. Якщо більше не потрібен, використовуйте наступну команду для його видалення:

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}
