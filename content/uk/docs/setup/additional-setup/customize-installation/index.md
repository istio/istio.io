---
title: Налаштування конфігурації встановлення
description: Описує, як налаштувати параметри конфігурації встановлення.
weight: 50
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

### Передумови {#prerequisites}

Перш ніж почати, перевірте наступні передумови:

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/).
2. Виконайте всі необхідні [налаштування для вашої платформи](/docs/setup/platform-setup/).
3. Перевірте [вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

Окрім встановлення будь-якого з вбудованих [профілів конфігурації Istio](/docs/setup/additional-setup/config-profiles/), `istioctl install` надає повний API для налаштування конфігурації.

- [API `IstioOperator`](/docs/reference/config/istio.operator.v1alpha1/)

Параметри конфігурації в цьому API можна встановлювати індивідуально за допомогою параметрів `--set` у командному рядку. Наприклад, щоб увімкнути ведення логів у режимі налагодження в стандартному профілі конфігурації, використовуйте таку команду:

{{< text bash >}}
$ istioctl install --set values.global.logging.level=debug
{{< /text >}}

Альтернативно, конфігурацію `IstioOperator` можна задати у YAML-файлі та передати до `istioctl` за допомогою параметра `-f`:

{{< text bash >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

{{< tip >}}
Для зворотної сумісності попередні [опції встановлення Helm](https://archive.istio.io/v1.4/docs/reference/config/installation-options/), за винятком налаштувань ресурсів Kubernetes, також повністю підтримуються. Щоб встановити їх у командному рядку, додайте перед назвою опції префікс "`values.`". Наприклад, наступна команда перевизначає параметр конфігурації `pilot.traceSampling` в Helm:

{{< text bash >}}
$ istioctl install --set values.pilot.traceSampling=0.1
{{< /text >}}

Значення Helm також можна задати в CR `IstioOperator` (YAML-файл), як описано в розділі [Налаштування параметрів Istio за допомогою Helm API](/docs/setup/additional-setup/customize-installation/#customize-istio-settings-using-the-helm-api), нижче.

Якщо ви хочете налаштувати параметри ресурсів Kubernetes, використовуйте API `IstioOperator`, як описано в розділі [Налаштування параметрів Kubernetes](/docs/setup/additional-setup/customize-installation/#customize-kubernetes-settings).
{{< /tip >}}

### Визначення компонента Istio {#identify-istio-component}

API `IstioOperator` визначає компоненти, як показано в таблиці нижче:

| Компоненти |
| ------------|
`base` |
`pilot` |
`ingressGateways` |
`egressGateways` |
`cni` |
`istiodRemote` |

Налаштування для кожного з цих компонентів доступні в API в `components.<назва компоненту>`. Наприклад, щоб змінити (на false) налаштування `enabled` для компонента `pilot`, використовуйте команду `--set components.pilot.enabled=false` або задайте це в ресурсі `IstioOperator` таким чином:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      enabled: false
{{< /text >}}

Усі компоненти також мають спільний API для зміни налаштувань, специфічних для Kubernetes, в `components.<назва компоненту>.k8s`, як описано в наступному розділі.

### Налаштування параметрів Kubernetes {#customize-kubernetes-settings}

API `IstioOperator` дозволяє налаштовувати параметри Kubernetes для кожного компоненту у відповідний спосіб.

Кожен компонент має [`KubernetesResourceSpec`](/docs/reference/config/istio.operator.v1alpha1/#KubernetesResourcesSpec), який дозволяє змінювати наступні параметри. Використовуйте цей список, щоб визначити налаштування для зміни:

1. [Ресурси](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#resource-requests-and-limits-of-pod-and-container)
2. [Проби готовності](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)
3. [Кількість реплік](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
4. [`HorizontalPodAutoscaler`](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
5. [`PodDisruptionBudget`](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#how-disruption-budgets-work)
6. [Анотації Podʼів](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
7. [Анотації сервісів](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
8. [`ImagePullPolicy`](https://kubernetes.io/docs/concepts/containers/images/)
9. [Priority class name](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass)
10. [Node selector](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#nodeselector)
11. [Affinity та anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity)
12. [Сервіс](https://kubernetes.io/docs/concepts/services-networking/service/)
13. [Toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
14. [Стратегія](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
15. [Env](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
16. [Security context Podʼів](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod)
17. [Volumes та volume mounts](https://kubernetes.io/docs/concepts/storage/volumes/)

Усі ці налаштування Kubernetes використовують визначення API Kubernetes, тому [документація Kubernetes](https://kubernetes.io/docs/concepts/) може бути використана як довідник.

Наступний приклад файлу overlay налаштовує ресурси та параметри горизонтального масштабування podʼів для Pilot:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    pilot:
      k8s:
        resources:
          requests:
            cpu: 1000m # перевизначення з 500m стандартно
            memory: 4096Mi # ... з 2048Mi стандартно
        hpaSpec:
          maxReplicas: 10 # ... з 5 стандартно
          minReplicas: 2  # ... з 1 стандартно
{{< /text >}}

Використовуйте `istioctl install`, щоб застосувати змінені налаштування до кластера:

{{< text syntax="bash" repo="operator" >}}
$ istioctl install -f samples/operator/pilot-k8s.yaml
{{< /text >}}

### Налаштування параметрів Istio за допомогою Helm API {#customize-istio-settings-using-the-helm-api}

API `IstioOperator` включає інтерфейс для доступу до [Helm API](https://archive.istio.io/v1.4/docs/reference/config/installation-options/) за допомогою поля `values`.

Наступний YAML-файл налаштовує глобальні параметри та параметри Pilot за допомогою Helm API:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      traceSampling: 0.1 # перевизначення з 1.0
    global:
      monitoringPort: 15014
{{< /text >}}

Деякі параметри тимчасово існують у Helm API та `IstioOperator` API одночасно, включаючи ресурси Kubernetes, імена просторів і налаштування ввімкнення. Спільнота Istio рекомендує використовувати API `IstioOperator`, оскільки він більш послідовний, перевіряється і відповідає [процесу просування функцій у спільноті](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE-CHECKLIST.md#feature-lifecycle-checklist).

### Налаштування шлюзів {#configure-gateways}

Шлюзи є особливим типом компонента, оскільки можна визначити кілька шлюзів для вхідного та вихідного трафіку. В [API `IstioOperator`](/docs/reference/config/istio.operator.v1alpha1/) шлюзи визначаються як список. Профіль `default` встановлює один шлюз для вхідного трафіку, названий `istio-ingressgateway`. Ви можете перевірити стандартне значення для цього шлюзу:

{{< text bash >}}
$ istioctl profile dump --config-path components.ingressGateways
$ istioctl profile dump --config-path values.gateways.istio-ingressgateway
{{< /text >}}

Ці команди покажуть як налаштування `IstioOperator`, так і Helm для шлюзу, які використовуються разом для визначення згенерованих ресурсів шлюзу. Вбудовані шлюзи можна налаштовувати так само як і будь-який інший компонент.

{{< warning >}}
З версії 1.7 і пізніше імʼя шлюзу завжди повинно бути зазначене при накладанні. Відсутність імені більше не призводить до стандартного використання `istio-ingressgateway` або `istio-egressgateway`.
{{< /warning >}}

Новий шлюз для користувача можна створити, додавши новий елемент у список:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
      - namespace: user-ingressgateway-ns
        name: ilb-gateway
        enabled: true
        k8s:
          resources:
            requests:
              cpu: 200m
          serviceAnnotations:
            cloud.google.com/load-balancer-type: "internal"
          service:
            ports:
            - port: 8060
              targetPort: 8060
              name: tcp-citadel-grpc-tls
            - port: 5353
              name: tcp-dns
{{< /text >}}

Зверніть увагу, що значення Helm (`spec.values.gateways.istio-ingressgateway/egressgateway`) спільні для всіх шлюзів вхідного/вихідного трафіку. Якщо ці значення потрібно налаштувати окремо для кожного шлюзу, рекомендується використовувати окремий CR `IstioOperator` для створення маніфесту для шлюзів користувача, окремо від основної установки Istio:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
      - name: ilb-gateway
        namespace: user-ingressgateway-ns
        enabled: true
        # Копіюйте налаштування з istio-ingressgateway за потреби.
  values:
    gateways:
      istio-ingressgateway:
        debug: error
{{< /text >}}

## Розширене налаштування встановлення {#advanced-install-customization}

### Налаштування зовнішніх чартів і профілів {#customizing-external-charts-and-profiles}

Команди `istioctl install`, `manifest generate` і `profile` можуть використовувати будь-яке з наступних джерел для чартів і профілів:

- Вбудовані чарт-файли. Це стандартне значення, якщо не вказано опцію `--manifests`. Вбудовані чарт-файли такі ж, як і ті, що в теці `manifests/` релізу Istio `.tgz`.
- Чарти у локальній файловій системі, наприклад, `istioctl install --manifests istio-{{< istio_full_version >}}/manifests`.

Чарти та профілі у локальній файловій системі можна налаштовувати, редагуючи файли в `manifests/`. Для великих змін рекомендується створити копію теки `manifests` і вносити зміни там. Зверніть увагу, що макет вмісту в теки `manifests` повинен бути збережений.

Профілі, що знаходяться в `manifests/profiles/`, можна редагувати та додавати нові, створюючи нові файли з потрібним імʼям профілю та розширенням `.yaml`. `istioctl` сканує підтеку `profiles`, і всі профілі, що знаходяться там, можна використовувати за іменем у полі профілю `IstioOperatorSpec`. Вбудовані профілі стандартно накладаються на YAML-файл профілю перед застосуванням накладок користувача. Наприклад, ви можете створити новий файл профілю з назвою `custom1.yaml`, який змінює деякі налаштування з профілю `default`, а потім застосувати накладку користувача поверх цього:

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ --set profile=custom1 -f path-to-user-overlay.yaml
{{< /text >}}

У цьому випадку файли `custom1.yaml` і `user-overlay.yaml` будуть накладені на `default.yaml`, щоб отримати остаточні значення, які використовуються як вхідні дані для генерації маніфесту.

Загалом, створення нових профілів не є обовʼязковим, оскільки подібний результат можна досягти, передавши кілька накладок користувача. Наприклад, команда вище є еквівалентною передачі двох файлів накладки користувача:

{{< text bash >}}
$ istioctl manifest generate --manifests mycharts/ -f manifests/profiles/custom1.yaml -f path-to-user-overlay.yaml
{{< /text >}}

Створення власного профілю необхідне тільки якщо ви повинні посилатися на профіль за іменем через `IstioOperatorSpec`.

### Накладання патча на вихідний маніфест {#patching-the-output-manifest}

CR `IstioOperator`, вхідний для `istioctl`, використовується для генерації вихідного маніфесту, що містить ресурси Kubernetes, які потрібно застосувати до кластера. Вихідний маніфест можна додатково налаштувати для додавання, модифікації або видалення ресурсів через API [overlays IstioOperator](/docs/reference/config/istio.operator.v1alpha1/#K8sObjectOverlay) після його генерації, але перед застосуванням до кластера.

Наступний приклад файлу накладки (`patch.yaml`) демонструє тип вихідного маніфесту, який можна отримати:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  hub: docker.io/istio
  tag: 1.1.6
  components:
    pilot:
      enabled: true
      namespace: istio-control
      k8s:
        overlays:
          - kind: Deployment
            name: istiod
            patches:
              # Вибір елемента списку за значенням
              - path: spec.template.spec.containers.[name:discovery].args.[30m]
                value: "60m" # перевизначено з 30m
              # Вибір елемента списку за ключем:значенням
              - path: spec.template.spec.containers.[name:discovery].ports.[containerPort:8080].containerPort
                value: 1234
              # Перевизначення з об'єктом (зверніть увагу на | у значенні: перший рядок)
              - path: spec.template.spec.containers.[name:discovery].env.[name:POD_NAMESPACE].valueFrom
                value: |
                  fieldRef:
                    apiVersion: v2
                    fieldPath: metadata.myPath
              # Видалення елемента списку
              - path: spec.template.spec.containers.[name:discovery].env.[name:REVISION]
              # Видалення елемента мапи
              - path: spec.template.spec.containers.[name:discovery].securityContext
          - kind: Service
            name: istiod
            patches:
              - path: spec.ports.[name:https-dns].port
                value: 11111 # ПЕРЕВИЗНАЧЕНО
{{< /text >}}

Передача файлу до `istioctl manifest generate -f patch.yaml` застосовує ці патчі до вихідного маніфесту стандартного профілю. Два змінені ресурси будуть модифіковані, як показано нижче (деякі частини ресурсів опущено для стислості):

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istiod
spec:
  template:
    spec:
      containers:
      - args:
        - 60m
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v2
              fieldPath: metadata.myPath
        name: discovery
        ports:
        - containerPort: 1234
        ---
apiVersion: v1
kind: Service
metadata:
  name: istiod
spec:
  ports:
  - name: https-dns
    port: 11111
---
{{< /text >}}

Зверніть увагу, що патчі застосовуються в зазначеному порядку. Кожен патч застосовується на вивід з попереднього патчу. Шляхи в патчах, які не існують у вихідному маніфесті, будуть створені.

### Вибір елемента списку {#list-item-path-selection}

Як `istioctl --set`, так і поле `k8s.overlays` у CR `IstioOperator` підтримують вибір елемента списку за `[index]`, `[value]` або за `[key:value]`. Прапорець `--set` також створює будь-які проміжні вузли в шляху, які відсутні в ресурсі.
