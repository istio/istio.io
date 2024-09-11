---
title: Проблеми з інʼєкцією Sidecar
description: Вирішення загальних проблем із використанням вебхуків Kubernetes для автоматичної інʼєкції sidecar у Istio.
force_inline_toc: true
weight: 40
aliases:
  - /uk/docs/ops/troubleshooting/injection
owner: istio/wg-user-experience-maintainers
test: n/a
---

## Результат інʼєкції sidecar не відповідає очікуванням {#the-result-of-sidecar-injection-was-not-what-i-expected}

Це включає випадки, коли виконано інʼєкцію sidecar тоді, коли це не очікувалося, і відсутність інʼєкції sidecar, коли це було потрібно.

1. Переконайтеся, що ваш pod не знаходиться в просторі імен `kube-system` або `kube-public`. Автоматична інʼєкція sidecar буде проігнорована для podʼів у цих просторах імен.

2. Переконайтеся, що ваш pod не має `hostNetwork: true` у своїй специфікації. Автоматична інʼєкція sidecar буде проігнорована для podʼів, які знаходяться в мережі хосту.

    Модель sidecar передбачає, що зміни iptables, необхідні для перехоплення трафіку Envoy, відбуваються всередині podʼа. Для podʼів в мережі хосту це припущення порушується, що може призвести до збоїв маршрутизації на рівні хосту.

3. Перевірте `namespaceSelector` вебхука, щоб визначити, чи вебхук має область застосування "opt-in" чи "opt-out" для цільового простору імен.

    `namespaceSelector` для opt-in виглядає так:

    {{< text bash yaml >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchLabels:
          istio-injection: enabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    Вебхук інʼєкції буде викликано для podʼів, створених у просторах імен з міткою `istio-injection=enabled`.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d       enabled
    istio-system   Active    3d
    kube-public    Active    18d
    kube-system    Active    18d
    {{< /text >}}

    `namespaceSelector` для opt-out виглядає так:

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep "namespaceSelector:" -A5
      namespaceSelector:
        matchExpressions:
        - key: istio-injection
          operator: NotIn
          values:
          - disabled
      rules:
      - apiGroups:
        - ""
    {{< /text >}}

    Вебхук інʼєкції буде викликано для podʼів, створених у просторах імен без мітки `istio-injection=disabled`.

    {{< text bash >}}
    $ kubectl get namespace -L istio-injection
    NAME           STATUS    AGE       ISTIO-INJECTION
    default        Active    18d
    istio-system   Active    3d        disabled
    kube-public    Active    18d       disabled
    kube-system    Active    18d       disabled
    {{< /text >}}

    Переконайтеся, що простір імен вашого застосунку правильно позначений і (пере)поставте мітки відповідно, наприклад:

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=disabled --overwrite
    {{< /text >}}

    (повторіть для всіх просторів імен, у яких вебхук інʼєкції має бути викликаний для нових podʼів)

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled --overwrite
    {{< /text >}}

4. Перевірте стандартну політику

    Перевірте стандартну політику інʼєкції у `configmap` `istio-sidecar-injector`.

    {{< text bash yaml >}}
    $ kubectl -n istio-system get configmap istio-sidecar-injector -o jsonpath='{.data.config}' | grep policy:
    policy: enabled
    {{< /text >}}

    Дозволені значення політики — `disabled` та `enabled`. Стандартна політика застосовується лише в разі відповідності `namespaceSelector` вебхука до цільового простору імен. Невідомі політики повністю вимикають інʼєкцію.

5. Перевірте переважну анотацію для podʼа

    Стандартну політику можна перевизначити за допомогою мітки `sidecar.istio.io/inject` у _метаданих шаблону podʼа_. Метадані розгортання ігноруються. Значення мітки `true` виконує примусову інʼєкцію sidecar, тоді як значення `false` не виконує примусової інʼєкції sidecar.

    Наступна мітка перевизначає будь-яку стандартну політику і виконує примусову інʼєкцію sidecar:

    {{< text bash yaml >}}
    $ kubectl get deployment sleep -o yaml | grep "sidecar.istio.io/inject:" -B4
    template:
      metadata:
        labels:
          app: sleep
          sidecar.istio.io/inject: "true"
    {{< /text >}}

## Поди не можуть бути створені взагалі {#pods-cannot-be-created-at-all}

Виконайте команду `kubectl describe -n namespace deployment name` для розгортання невдалого podʼа. Невдача виклику вебхука інʼєкції зазвичай буде зафіксована в журналі подій.

### Помилки, повʼязані з сертифікатами x509 {#x509-certificate-related-errors}

{{< text plain >}}
Warning  FailedCreate  3m (x17 over 8m)  replicaset-controller  Error creating: Internal error occurred: \
    failed calling admission webhook "sidecar-injector.istio.io": Post https://istiod.istio-system.svc:443/inject: \
    x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying \
    to verify candidate authority certificate "Kubernetes.cluster.local")
{{< /text >}}

Помилки `x509: certificate signed by unknown authority` зазвичай викликані порожнім `caBundle` у конфігурації вебхука.

Перевірте, щоб `caBundle` у `mutatingwebhookconfiguration` відповідало кореневому сертифікату, змонтованому в podʼі `istiod`.

{{< text bash >}}
$ kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
$ kubectl -n istio-system get configmap istio-ca-root-cert -o jsonpath='{.data.root-cert\.pem}' | base64 -w 0 | md5sum
4b95d2ba22ce8971c7c92084da31faf0  -
{{< /text >}}

CA сертифікат повинен збігатися. Якщо вони не збігаються, перезапустіть podʼи `istiod`.

{{< text bash >}}
$ kubectl -n istio-system patch deployment istiod \
    -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
deployment.extensions "istiod" patched
{{< /text >}}

### Помилки в статусі розгортання {#errors-in-deployment-status}

Коли автоматична інʼєкція sidecar увімкнена для podʼа, і інʼєкція за будь-якої причини не вдається, створення podʼа також зазнає невдачі. У таких випадках ви можете перевірити статус розгортання podʼа, щоб визначити помилку. Помилки також зʼявляться в подіях простору імен, повʼязаного з розгортанням.

Наприклад, якщо pod контролера `istiod` не працював, коли ви намагалися розгорнути ваш pod, події покажуть таку помилку:

{{< text bash >}}
$ kubectl get events -n sleep
...
23m Normal   SuccessfulCreate replicaset/sleep-9454cc476  Created pod: sleep-9454cc476-khp45
22m Warning  FailedCreate     replicaset/sleep-9454cc476  Error creating: Internal error occurred: failed calling webhook "namespace.sidecar-injector.istio.io": failed to call webhook: Post "https://istiod.istio-system.svc:443/inject?timeout=10s": dial tcp 10.96.44.51:443: connect: connection refused
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get pod -lapp=istiod
NAME                            READY     STATUS    RESTARTS   AGE
istiod-7d46d8d9db-jz2mh         1/1       Running     0         2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istiod
NAME           ENDPOINTS                                                  AGE
istiod   10.244.2.8:15012,10.244.2.8:15010,10.244.2.8:15017 + 1 more...   3h18m
{{< /text >}}

Якщо pod або точки доступу istiod не готові, перевірте журнали podʼа та статус для будь-яких ознак того, чому вебхук podʼа не запускається і не обслуговує трафік.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done


$ for pod in $(kubectl -n istio-system get pod -l app=istiod -o name); do \
kubectl -n istio-system describe ${pod}; \
done
$
{{< /text >}}

## Автоматична інʼєкція sidecar не працює, якщо у сервера API Kubernetes є налаштування проксі {#automatic-sidecar-injection-fails-if-the-kubernetes-api-server-has-proxy-settings}

Коли сервер API Kubernetes має налаштування проксі, такі як:

{{< text yaml >}}
env:
  - name: http_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: https_proxy
    value: http://proxy-wsa.esl.foo.com:80
  - name: no_proxy
    value: 127.0.0.1,localhost,dockerhub.foo.com,devhub-docker.foo.com,10.84.100.125,10.84.100.126,10.84.100.127
{{< /text >}}

З такими налаштуваннями інʼєкція sidecar зазнає невдачі. Єдиний повʼязаний запис можна знайти в журналі `kube-apiserver`:

{{< text plain >}}
W0227 21:51:03.156818       1 admission.go:257] Failed calling webhook, failing open sidecar-injector.istio.io: failed calling admission webhook "sidecar-injector.istio.io": Post https://istio-sidecar-injector.istio-system.svc:443/inject: Service Unavailable
{{< /text >}}

Переконайтеся, що CIDR podʼів і сервісів не оброблені відповідно до змінних `*_proxy`. Перевірте файли та журнали `kube-apiserver`, щоб перевірити конфігурацію та чи оброблялись якісь запити.

Одним зі способів вирішення є видалення налаштувань проксі з маніфесту `kube-apiserver`, іншим — включення `istio-sidecar-injector.istio-system.svc` або `.svc` у значення `no_proxy`. Переконайтеся, що `kube-apiserver` перезапущено після кожного способу розвʼязання.

Була сповіщено про [проблему](https://github.com/kubernetes/kubeadm/issues/666) у Kubernetes, повʼязану з цим, і згодом вона була закрита.
[https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)

## Обмеження при використанні Tcpdump у podʼах {#limitations-for-using-tcpdump-in-pods}

Tcpdump не працює у sidecar podʼі — контейнер не запускається з правами root. Проте будь-який інший контейнер у тому ж podʼі побачить усі пакети, оскільки мережевий простір імен спільний. `iptables` також побачить конфігурацію на рівні podʼа.

Комунікація між Envoy та застосунком відбувається на 127.0.0.1 і не є зашифрованою.

## Кластер не масштабується автоматично {#cluster-is-not-scaled-down-automatically}

Через те, що контейнер sidecar монтує локальний том для зберігання, автомастабувач вузлів не може видалити вузли з podʼами, до яких було виконано інʼєкції. Це є [відомою проблемою](https://github.com/kubernetes/autoscaler/issues/3947). Вирішенням є додавання анотації podʼа `"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"` до podʼів з інʼєкіями.

## Pod або контейнери запускаються з мережевими проблемами, якщо istio-proxy не готовий {#pod-or-containers-start-with-network-issues-if-istio-proxy-is-not-ready}

Багато застосунків виконують команди або перевірки під час запуску, які потребують зʼєднання з мережею. Це може призвести до зависання або перезавантаження контейнерів застосунку, якщо контейнер sidecar `istio-proxy` не готовий.

Щоб уникнути цього, встановіть `holdApplicationUntilProxyStarts` на `true`. Це призведе до інʼєкції sidecar на початку списку контейнерів podʼа та налаштує його так, щоб блокувати запуск усіх інших контейнерів до тих пір, поки проксі не буде готовий.

Це можна додати як глобальну опцію конфігурації:

{{< text yaml >}}
values.global.proxy.holdApplicationUntilProxyStarts: true
{{< /text >}}

або як анотацію podʼа:

{{< text yaml >}}
proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
{{< /text >}}
