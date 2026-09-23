---
title: Проблеми з валідацією конфігурації
description: Описує, як вирішити проблеми з валідацією конфігурації.
force_inline_toc: true
weight: 50
aliases:
    - /uk/help/ops/setup/validation
    - /uk/help/ops/troubleshooting/validation
    - /uk/docs/ops/troubleshooting/validation
owner: istio/wg-user-experience-maintainers
test: no

---

## Здається, що конфігурація є правильною, але вона відхиляєтсья {#seemingly-valid-configuration-is-rejected}

Використовуйте [istioctl validate -f](/docs/reference/commands/istioctl/#istioctl-validate) та [istioctl analyze](/docs/reference/commands/istioctl/#istioctl-analyze) для отримання додаткової інформації про те, чому конфігурація відхиляється. Використовуйте _istioctl_ CLI з версією, яка відповідає версії панелі управління.

Найчастіше зустрічаються проблеми з конфігурацією повʼязані з відступами YAML та помилками нотації масиву (`-`).

Перевірте вашу конфігурацію вручну, порівнюючи з [довідником API Istio](/docs/reference/config), якщо це необхідно.

## Недійсна конфігурація приймається {#invalid-configuration-is-accepted}

Перевірте, чи існує `validatingwebhookconfiguration` з імʼям `istio-validator-`, далі `<revision>-`, якщо це не стандартна ревізія, і закінчуючи іменем простору імен Istio (наприклад, `istio-validator-myrev-istio-system`) і чи вона правильна.

`apiVersion`, `apiGroup` і `resource` недійсної конфігурації повинні бути перераховані в розділі `webhooks` конфігурації `validatingwebhookconfiguration`.

{{< text bash yaml >}}
$ kubectl get validatingwebhookconfiguration istio-validator-istio-system -o yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  labels:
    app: istiod
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio: istiod
    istio.io/rev: default
    operator.istio.io/component: Pilot
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: unknown
    release: istio
  name: istio-validator-istio-system
  resourceVersion: "615569"
  uid: 112fed62-93e7-41c9-8cb1-b2665f392dd7
webhooks:
- admissionReviewVersions:
  - v1beta1
  - v1
  clientConfig:
    # caBundle має бути не порожнім. Це періодично (перезатверджується)
    # кожну секунду вебхуком, що використовує сертифікат ca
    # з змонтованого секрету службового облікового запису.
    caBundle: LS0t...
    # service відповідає Kubernetes сервісу, що реалізує вебхук
    service:
      name: istiod
      namespace: istio-system
      path: /validate
      port: 443
  failurePolicy: Fail
  matchPolicy: Equivalent
  name: rev.validation.istio.io
  namespaceSelector: {}
  objectSelector:
    matchExpressions:
    - key: istio.io/rev
      operator: In
      values:
      - default
  rules:
  - apiGroups:
    - security.istio.io
    - networking.istio.io
    - telemetry.istio.io
    - extensions.istio.io
    apiVersions:
    - '*'
    operations:
    - CREATE
    - UPDATE
    resources:
    - '*'
    scope: '*'
  sideEffects: None
  timeoutSeconds: 10
{{< /text >}}

Якщо вебхук `istio-validator-` не існує, перевірте, чи опція `global.configValidation` встановлена в `true`.

Конфігурація валідації має політику `fail-close`. Якщо конфігурація існує і правильно обмежена, вебхук буде викликаний. Відсутність `caBundle`, поганий сертифікат або проблема з мережею викличе повідомлення про помилку під час створення/оновлення ресурсу. Якщо ви не бачите жодного повідомлення про помилку і вебхук не був викликаний, а конфігурація вебхука є правильною, ваш кластер неправильно налаштований.

## Помилки при створенні конфігурації з сертифікатами x509 {#creating-configuration-fails-with-x509-certificate-errors}

Помилки, повʼязані з `x509: certificate signed by unknown authority`, зазвичай викликані порожнім `caBundle` у конфігурації вебхука. Перевірте, щоб він не був порожнім (див. [перевірка конфігурації вебхука](#invalid-configuration-is-accepted)). Istio свідомо узгоджує конфігурацію вебхука, використовуючи `istio-validation` `configmap` та кореневий сертифікат.

1. Перевірте, чи працюють podʼи `istiod`:

    {{< text bash >}}
    $  kubectl -n istio-system get pod -lapp=istiod
    NAME                            READY     STATUS    RESTARTS   AGE
    istiod-5dbbbdb746-d676g   1/1       Running   0          2d
    {{< /text >}}

2. Перевірте журнали podʼа на наявність помилок. Невдача в накладанні патчів `caBundle` повинна вивести помилку.

    {{< text bash >}}
    $ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
        kubectl -n istio-system logs ${pod} \
    done
    {{< /text >}}

3. Якщо накладання патчів не вдалося, перевірте конфігурацію RBAC для Istiod:

    {{< text bash yaml >}}
    $ kubectl get clusterrole istiod-istio-system -o yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
      name: istiod-istio-system
    rules:
    - apiGroups:
      - admissionregistration.k8s.io
      resources:
      - validatingwebhookconfigurations
      verbs:
      - '*'
    {{< /text >}}

    Istio потрібен доступ до `validatingwebhookconfigurations` для створення та оновлення `validatingwebhookconfiguration`.

## Помилки при створенні конфігурації з `no such hosts` або `no endpoints available` {#creating-configuration-fails-with-no-such-hosts-or-no-endpoints-available-errors}

Валідація має політику `fail-close`. Якщо pod `istiod` не готовий, конфігурацію не можна створити або оновити. У таких випадках ви побачите помилку про `no endpoints available`.

Перевірте, чи працюють podʼи `istiod` і чи готові точки доступу.

{{< text bash >}}
$  kubectl -n istio-system get pod -lapp=istiod
NAME                            READY     STATUS    RESTARTS   AGE
istiod-5dbbbdb746-d676g   1/1       Running   0          2d
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system get endpoints istiod
NAME           ENDPOINTS                          AGE
istiod         10.48.6.108:15014,10.48.6.108:443   3d
{{< /text >}}

Якщо podʼи або точки доступу не готові, перевірте журнали podʼів та статус для будь-яких ознак того, чому pod вебхука не запускається і не обслуговує трафік.

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o jsonpath='{.items[*].metadata.name}'); do \
    kubectl -n istio-system logs ${pod} \
done
{{< /text >}}

{{< text bash >}}
$ for pod in $(kubectl -n istio-system get pod -lapp=istiod -o name); do \
    kubectl -n istio-system describe ${pod} \
done
{{< /text >}}
