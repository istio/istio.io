---
title: Встановлення Sidecar
description: Встановіть sidecar Istio в podʼи застосунків автоматично за допомогою вебхуку інжектора sidecar або вручну за допомогою istioctl CLI.
weight: 45
keywords: [kubernetes,sidecar,sidecar-injection]
aliases:
    - /uk/docs/setup/kubernetes/automatic-sidecar-inject.html
    - /uk/docs/setup/kubernetes/sidecar-injection/
    - /uk/docs/setup/kubernetes/additional-setup/sidecar-injection/
owner: istio/wg-environments-maintainers
test: no
---

## Виконання інʼєкції {#injection}

Для того, щоб скористатися всіма можливостями Istio, podʼи в mesh повинні мати sidecar проксі Istio.

У наступних розділах описані два способи впровадження sidecar проксі Istio в pod: увімкнення автоматичної інʼєкції sidecar проксі Istio у просторі імен podʼа або вручну за допомогою команди [`istioctl`](/docs/reference/commands/istioctl).

Коли автоматична інʼєкція увімкнена у просторі імен podʼа, конфігурація проксі додається під час створення podʼа з використанням контролера допуску.

Вручну конфігурація проксі додається безпосередньо до конфігурації, наприклад, до deployment.

Якщо ви не впевнені, який варіант обрати, рекомендується автоматична інʼєкція.

### Автоматична інʼєкція sidecar проксі {#automatic-sidecar-injection}

Sidecar проксі можна автоматично додавати до відповідних podʼів Kubernetes за допомогою [контролера допуску з модифікацією вебхука](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/), який надається Istio.

{{< tip >}}
Хоча контролери допуску стандартно увімкнені, деякі дистрибутиви Kubernetes можуть їх вимкнути. Якщо це так, дотримуйтесь інструкцій, щоб [увімкнути контролери допуску](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller).
{{< /tip >}}

Коли ви встановлюєте мітку `istio-injection=enabled` в простір імен і вебхук для інʼєкції увімкнено, будь-які нові podʼи, створені в цьому просторі імен, автоматично матимуть доданий sidecar.

Зверніть увагу, що на відміну від ручної інʼєкції, автоматична інʼєкція відбувається на рівні podʼа. Ви не побачите жодних змін у самому розгортанні. Замість цього, вам потрібно буде перевірити окремі podʼи (за допомогою `kubectl describe`), щоб побачити доданий проксі.

#### Розгортання застосунку {#deploying-an-app}

Розгорніть застосунок curl. Переконайтесь, що як deployment, так і pod мають один контейнер.

{{< text bash >}}
$ kubectl apply -f @samples/curl/curl.yaml@
$ kubectl get deployment -o wide
NAME    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
curl    1/1     1            1           12s   curl         curlimages/curl           app=curl
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                    READY   STATUS    RESTARTS   AGE
curl-8f795f47d-hdcgs    1/1     Running   0          42s
{{< /text >}}

Позначте простір імен `default` міткою `istio-injection=enabled`.

{{< text bash >}}
$ kubectl label namespace default istio-injection=enabled --overwrite
$ kubectl get namespace -L istio-injection
NAME                 STATUS   AGE     ISTIO-INJECTION
default              Active   5m9s    enabled
...
{{< /text >}}

Інʼєкція відбувається під час створення podʼа. Вбийте запущений pod і переконайтесь, що новий pod створено з впровадженим sidecar проксі. Початковий pod має `1/1 READY`, а контейнер з доданим sidecar проксі має `2/2 READY`.

{{< text bash >}}
$ kubectl delete pod -l app=curl
$ kubectl get pod -l app=curl
pod "curl-776b7bcdcd-7hpnk" deleted
NAME                     READY     STATUS        RESTARTS   AGE
curl-776b7bcdcd-7hpnk    1/1       Terminating   0          1m
curl-776b7bcdcd-bhn9m    2/2       Running       0          7s
{{< /text >}}

Перегляньте детальний стан podʼа з інʼєкцією. Ви повинні побачити доданий контейнер `istio-proxy` та відповідні томи.

{{< text bash >}}
$ kubectl describe pod -l app=curl
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  ...
  Normal  Created    11s   kubelet            Created container istio-init
  Normal  Started    11s   kubelet            Started container istio-init
  ...
  Normal  Created    10s   kubelet            Created container curl
  Normal  Started    10s   kubelet            Started container curl
  ...
  Normal  Created    9s    kubelet            Created container istio-proxy
  Normal  Started    8s    kubelet            Started container istio-proxy
{{< /text >}}

Вимкніть інʼєкцію для простору імен `default` і переконайтесь, що нові podʼи створюються без sidecar проксі.

{{< text bash >}}
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=curl
$ kubectl get pod
namespace/default labeled
pod "curl-776b7bcdcd-bhn9m" deleted
NAME                     READY     STATUS        RESTARTS   AGE
curl-776b7bcdcd-bhn9m    2/2       Terminating   0          2m
curl-776b7bcdcd-gmvnr    1/1       Running       0          2s
{{< /text >}}

#### Контроль політики інʼєкції {#controlling-the-injection-policy}

У наведених вище прикладах ви включали та відключали інʼєкцію на рівні простору імен. Інʼєкцію також можна контролювати на рівні кожного окремого podʼа, налаштовуючи мітку `sidecar.istio.io/inject`:

| Ресурс | Мітка | Значення "Включено" | Значення "Вимкнено" |
| -------- | ----- | ------------- | -------------- |
| Namespace | `istio-injection` | `enabled` | `disabled` |
| Pod | `sidecar.istio.io/inject` | `"true"` | `"false"` |

Якщо ви використовуєте [ревізії панелі управління](/docs/setup/upgrade/canary/), замість цього використовуються мітки, специфічні для ревізії, за допомогою відповідної мітки `istio.io/rev`. Наприклад, для ревізії з назвою `canary`:

| Ресурс | Мітка "Включено" | Мітка "Вимкнено" |
| -------- | ------------- | -------------- |
| Namespace | `istio.io/rev=canary` | `istio-injection=disabled` |
| Pod | `istio.io/rev=canary` | `sidecar.istio.io/inject="false"` |

Якщо мітки `istio-injection` та `istio.io/rev` присутні одночасно на одному просторі імен, пріоритет матиме мітка `istio-injection`.

Інжектор налаштований на виконання такої логіки:

1. Якщо будь-яка з міток (`istio-injection` або `sidecar.istio.io/inject`) вимкнена, інʼєкція в pod не відбувається.
2. Якщо будь-яка з міток (`istio-injection`, `sidecar.istio.io/inject` або `istio.io/rev`) включена, відбувається інʼєкція в pod.
3. Якщо жодна з міток не встановлена, відбувається інʼєкція в pod, якщо увімкнено `.values.sidecarInjectorWebhook.enableNamespacesByDefault`. Стандартно ця опція вимкнена, тому загалом це означає, що інʼєкція в pod не відбувається..

### Ручна інʼєкція sidecar {#manual-sidecar-injection}

Для ручної інʼєкції в deployment використовуйте команду [`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject):

{{< text bash >}}
$ istioctl kube-inject -f @samples/curl/curl.yaml@ | kubectl apply -f -
serviceaccount/curl created
service/curl created
deployment.apps/curl created
{{< /text >}}

Стандартно буде використовуватися конфігурація в кластері. Альтернативно інʼєкція може бути виконана з використанням локальних копій конфігурації.

{{< text bash >}}
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.values}' > inject-values.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
{{< /text >}}

Запустіть `kube-inject` для вхідного файлу та розгорніть.

{{< text bash >}}
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --valuesFile inject-values.yaml \
    --filename @samples/curl/curl.yaml@ \
    | kubectl apply -f -
serviceaccount/curl created
service/curl created
deployment.apps/curl created
{{< /text >}}

Перевірте, що sidecar було додано в pod curl зі значенням `2/2` у колонці READY.

{{< text bash >}}
$ kubectl get pod -l app=curl
NAME                     READY   STATUS    RESTARTS   AGE
curl-64c6f57bc8-f5n4x    2/2     Running   0          24s
{{< /text >}}

## Налаштування інʼєкції {#customizing-injection}

Загалом інʼєкція podʼів відбувається на основі шаблону інʼєкції sidecar, налаштованого в configmap `istio-sidecar-injector`. Налаштування окремих podʼів доступне для перевизначення цих опцій на індивідуальних podʼах. Це робиться шляхом додавання контейнера `istio-proxy` до вашого podʼу. Інʼєкція sidecar розглядатиме будь-яку конфігурацію, визначену тут, як перевизначення стандартного шаблону інʼєкції.

Слід бути обережним при налаштуванні цих параметрів, оскільки це дозволяє повністю налаштувати отриманий `Pod`, включаючи внесення змін, які можуть спричинити некоректну роботу контейнера sidecar.

Наприклад, наступна конфігурація налаштовує різні параметри, зокрема знижує запити на ЦП, додає монтування тому і додає хук `preStop`:

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:
  - name: hello
    image: alpine
  - name: istio-proxy
    image: auto
    resources:
      requests:
        cpu: "100m"
    volumeMounts:
    - mountPath: /etc/certs
      name: certs
    lifecycle:
      preStop:
        exec:
          command: ["curl", "10"]
  volumes:
  - name: certs
    secret:
      secretName: istio-certs
{{< /text >}}

Загалом можна налаштувати будь-яке поле в podʼі. Однак потрібно бути обережним з певними полями:

- Kubernetes вимагає, щоб поле `image` було встановлено до запуску інʼєкції. Хоча ви можете встановити конкретний образ для перевизначення стандартного, рекомендується встановити `image` на `auto`, що дозволить інжектору sidecar автоматично вибирати образ для використання.
- Деякі поля в `Pod` залежать від повʼязаних налаштувань. Наприклад, запит на ЦП має бути меншим за обмеження ЦП. Якщо обидва поля не налаштовані разом, pod може не запуститися.
- Поля `securityContext.RunAsUser` і `securityContext.RunAsGroup` можуть не бути прийняті в деяких випадках, наприклад, коли використовується режим `TPROXY`, оскільки він вимагає запуску sidecar від імені користувача `0`. Неправильне перевизначення цих полів може призвести до втрати трафіку, і повинно виконуватися з особливою обережністю.

{{< warning >}}
Інші контролери доступу можуть виконувати специфікацію Pod до інʼєкції Istio, що може змінити або відхилити конфігурацію. Наприклад, `LimitRange` може автоматично вставляти запити на ресурси до того, як Istio додасть свої налаштовані ресурси, що може призвести до неочікуваних результатів.
{{< /warning >}}

Крім того, деякі поля налаштовуються за допомогою [анотацій](/docs/reference/config/annotations/) на podʼі, хоча рекомендується використовувати наведений вище підхід до налаштування параметрів. Додатково потрібно бути обережним з деякими анотаціями:

- Якщо встановлено `sidecar.istio.io/proxyCPU`, обовʼязково встановіть `sidecar.istio.io/proxyCPULimit`. Інакше обмеження на `cpu` для sidecar буде встановлено як необмежене.
- Якщо встановлено `sidecar.istio.io/proxyMemory`, обовʼязково встановіть `sidecar.istio.io/proxyMemoryLimit`. Інакше обмеження на `memory` для sidecar буде встановлено як необмежене.

Наприклад, дивіться наведену нижче конфігурацію неповних анотацій ресурсів і відповідні налаштування введених ресурсів:

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/proxyCPU: "200m"
        sidecar.istio.io/proxyMemoryLimit: "5Gi"
{{< /text >}}

{{< text yaml >}}
spec:
  containers:
  - name: istio-proxy
    resources:
      limits:
        memory: 5Gi
      requests:
        cpu: 200m
        memory: 5Gi
      securityContext:
        allowPrivilegeEscalation: false
{{< /text >}}

### Власні шаблони (експериментально) {#custom-templates-experimental}

{{< warning >}}
Ця функція експериментальна та може змінюватися або видалена у будь-який момент.
{{< /warning >}}

Повністю власні шаблони також можна визначити під час встановлення. Наприклад, щоб визначити власний шаблон, який інжектує змінну середовища `GREETING` у контейнер `istio-proxy`:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  values:
    sidecarInjectorWebhook:
      templates:
        custom: |
          spec:
            containers:
            - name: istio-proxy
              env:
              - name: GREETING
                value: hello-world
{{< /text >}}

Podʼи стандартно використовуватимуть шаблон інʼєкції `sidecar`, який створюється автоматично. Це можна перевизначити за допомогою анотації `inject.istio.io/templates`. Наприклад, щоб застосувати стандартний шаблон і наше налаштування, можна встановити `inject.istio.io/templates=sidecar,custom`.

Крім шаблона `sidecar`, стандартно надається шаблон `gateway` для підтримки інʼєкції проксі у розгортання Gateway.
