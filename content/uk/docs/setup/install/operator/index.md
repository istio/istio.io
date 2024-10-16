---
title: Встановлення Istio Operator
description: Інструкції для встановлення Istio в кластері Kubernetes за допомогою Istio operator.
weight: 99
keywords: [kubernetes, operator]
aliases:
    - /uk/docs/setup/install/standalone-operator
owner: istio/wg-environments-maintainers
test: yes
status: Beta
---

{{< warning >}}
Використання оператора для нових установок Istio не рекомендується на користь методів установки [Istioctl](/docs/setup/install/istioctl) та [Helm](/docs/setup/install/helm). Хоча оператор буде продовжувати підтримуватися, нові запити на функції не будуть пріоритетними.
{{< /warning >}}

Замість того, щоб вручну встановлювати, оновлювати та видаляти Istio, ви можете дозволити [оператору](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) Istio управляти установкою за вас. Це знімає з вас навантаження з управління різними версіями `istioctl`. Просто оновіть {{<gloss CRD>}}custom resource (CR){{</gloss>}} оператора, і контролер оператора застосує відповідні зміни конфігурації за вас.

Той самий [`IstioOperator` API](/docs/reference/config/istio.operator.v1alpha1/) використовується для встановлення Istio з оператором, як і при використанні [інструкцій установки istioctl](/docs/setup/install/istioctl). В обох випадках конфігурація перевіряється на відповідність схемі, і виконуються ті ж перевірки.

{{< warning >}}
Використання оператора має наслідки для безпеки. З командою `istioctl install` операція буде виконуватись у контексті безпеки адміністратора, тоді як з оператором, операцію виконуватиме podʼі в кластері у своєму контексті безпеки. Щоб уникнути вразливості, переконайтеся, що розгортання оператора достатньо захищене.
{{< /warning >}}

## Передумови {#prerequisites}

1. Виконайте потрібні [платформозалежні налаштування](/docs/setup/platform-setup/).

2. Перевірте [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

3. Встановіть [команду {{< istioctl >}}](/docs/ops/diagnostic-tools/istioctl/).

## Встановлення {#install}

### Розгортання Istio Operator {#deploy-the-istio-operator}

Команду `istioctl` можна використовувати для автоматичного розгортання Istio оператора:

{{< text syntax=bash snip_id=deploy_istio_operator >}}
$ istioctl operator init
{{< /text >}}

Ця команда запускає оператора, створюючи наступні ресурси в просторі імен `istio-operator`:

- Визначення custom resource для оператора
- Розгортання контролера оператора
- Сервіс для доступу до метрик оператора
- Необхідні правила RBAC для оператора Istio

Ви можете налаштувати, в якому просторі імен буде встановлений контролер оператора, які простори імен оператор буде відстежувати, джерела і версії образів Istio та інше. Наприклад, ви можете передати один або кілька просторів імен для відстеження, використовуючи прапорець `--watchedNamespaces`:

{{< text syntax=bash snip_id=deploy_istio_operator_watch_ns >}}
$ istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
{{< /text >}}

Дивіться [довідку команди `istioctl operator init`](/docs/reference/commands/istioctl/#istioctl-operator-init) для отримання деталей.

{{< tip >}}
Ви також можете розгорнути оператор за допомогою Helm:

1. Створіть простір імен `istio-operator`.

    {{< text syntax=bash snip_id=create_ns_istio_operator >}}
    $ kubectl create namespace istio-operator
    {{< /text >}}

2. Встановіть оператор за допомогою Helm.

    {{< text syntax=bash snip_id=deploy_istio_operator_helm >}}
    $ helm install istio-operator manifests/charts/istio-operator \
        --set watchedNamespaces="istio-namespace1\,istio-namespace2" \
        -n istio-operator
    {{< /text >}}

Зверніть увагу, що вам потрібно [завантажити реліз Istio](/docs/setup/additional-setup/download-istio-release/) для виконання цієї команди.
{{< /tip >}}

{{< warning >}}
До версії Istio 1.10.0 потрібно було створювати простір імен `istio-system` до установки оператора. Починаючи з Istio 1.10.0, команда `istioctl operator init` автоматично створить простір імен `istio-system`.

Якщо ви використовуєте щось інше, ніж `istioctl operator init`, то простір імен `istio-system` потрібно створити вручну.
{{< /warning >}}

### Встановлення Istio за допомогою оператора {#install-istio-with-the-operator}

Після встановлення оператора ви можете створити mesh, розгорнувши ресурс `IstioOperator`. Щоб встановити Istio з конфігураційним профілем `demo` за допомогою оператора, виконайте наступну команду:

{{< text syntax=bash snip_id=install_istio_demo_profile >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

Контролер виявить ресурс `IstioOperator` і встановить компоненти Istio відповідно до вказаної конфігурації (`demo`).

{{< warning >}}
Якщо ви використовували `--watchedNamespaces` під час ініціалізації Istio оператора, застосуйте ресурс `IstioOperator` в одному з відстежуваних просторів імен, а не в `istio-system`.
{{< /warning >}}

Стандартно панель управління Istio (istiod) буде встановлена в просторі імен `istio-system`. Щоб встановити її в іншому місці, вкажіть простір імен за допомогою поля `values.global.istioNamespace` наступним чином:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
...
spec:
  profile: demo
  values:
    global:
      istioNamespace: istio-namespace1
{{< /text >}}

{{< tip >}}
Контролер оператора Istio починає процес установки Istio протягом 90 секунд після створення ресурсу `IstioOperator`. Установка Istio завершується протягом 120 секунд.
{{< /tip >}}

Ви можете підтвердити, що сервіси панелі управління Istio були розгорнуті, за допомогою наступних команд:

{{< text syntax=bash snip_id=kubectl_get_svc >}}
$ kubectl get services -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)   AGE
istio-egressgateway    ClusterIP      10.96.65.145    <none>           ...       30s
istio-ingressgateway   LoadBalancer   10.96.189.244   192.168.11.156   ...       30s
istiod                 ClusterIP      10.96.189.20    <none>           ...       37s
{{< /text >}}

{{< text syntax=bash snip_id=kubectl_get_pods >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-696cccb5-m8ndk      1/1     Running   0          68s
istio-ingressgateway-86cb4b6795-9jlrk   1/1     Running   0          68s
istiod-b47586647-sf6sw                  1/1     Running   0          74s
{{< /text >}}

### Оновлення {#update}

Тепер, коли контролер працює, ви можете змінювати конфігурацію Istio, редагуючи або замінюючи ресурс `IstioOperator`. Контролер виявить зміни та відповідно оновить установку Istio.

Наприклад, ви можете переключити установку на конфігураційний профіль `default` за допомогою наступної команди:

{{< text syntax=bash snip_id=update_to_default_profile >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

Ви також можете увімкнути або вимкнути компоненти та змінити налаштування ресурсів. Наприклад, щоб увімкнути компонент `istio-egressgateway` і збільшити запити памʼяті для `istiod`, використовуйте наступну команду:

{{< text syntax=bash snip_id=update_to_default_profile_egress >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
  components:
    pilot:
      k8s:
        resources:
          requests:
            memory: 3072Mi
    egressGateways:
    - name: istio-egressgateway
      enabled: true
EOF
{{< /text >}}

Ви можете спостерігати за змінами, які контролер вносить у кластер у відповідь на оновлення CR `IstioOperator`, перевіряючи журнали контролера оператора:

{{< text syntax=bash snip_id=operator_logs >}}
$ kubectl logs -f -n istio-operator "$(kubectl get pods -n istio-operator -lname=istio-operator -o jsonpath='{.items[0].metadata.name}')"
{{< /text >}}

Зверніться до [API `IstioOperator`](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec) для отримання повного списку налаштувань конфігурації.

## Оновлення на місці {#in-place-upgrade}

Завантажте та розпакуйте `istioctl`, що відповідає версії Istio, до якої ви хочете оновитись. Перевстановіть оператор на цільову версію Istio:

{{< text syntax=bash snip_id=inplace_upgrade >}}
$ <extracted-dir>/bin/istioctl operator init
{{< /text >}}

Ви повинні побачити, що pod `istio-operator` перезапущено, і його версія змінилася на цільову версію:

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_operator >}}
$ kubectl get pods --namespace istio-operator \
  -o=jsonpath='{range .items[*]}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

Через хвилину-другу компоненти панелі управління Istio також повинні бути перезапущені на новій версії:

{{< text syntax=bash snip_id=inplace_upgrade_get_pods_istio_system >}}
$ kubectl get pods --namespace istio-system \
  -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{"\n"}{end}'
{{< /text >}}

## Канаркове оновлення {#canary-upgrade}

Процес поетапного оновлення подібний до [поетапного оновлення з `istioctl`](/docs/setup/upgrade/canary/).

Наприклад, щоб оновити Istio з версії {{< istio_previous_version >}}.0 до {{< istio_full_version >}}, спочатку встановіть {{< istio_previous_version >}}.0:

{{< text syntax=bash snip_id=download_istio_previous_version >}}
$ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_previous_version >}}.0 sh -
{{< /text >}}

Розгорніть оператор, використовуючи версію Istio {{< istio_previous_version >}}.0:

{{< text syntax=bash snip_id=deploy_operator_previous_version >}}
$ istio-{{< istio_previous_version >}}.0/bin/istioctl operator init
{{< /text >}}

Встановіть профіль демо панелі управління Istio:

{{< text syntax=bash snip_id=install_istio_previous_version >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_previous_version_revision >}}-0
spec:
  profile: default
EOF
{{< /text >}}

Перевірте, чи існує CR `IstioOperator` з іменем `example-istiocontrolplane` у вашому кластері:

{{< text syntax=bash snip_id=verify_operator_cr >}}
$ kubectl get iop --all-namespaces
NAMESPACE      NAME                              REVISION   STATUS    AGE
istio-system   example-istiocontrolplane{{< istio_previous_version_revision >}}-0              HEALTHY   11m
{{< /text >}}

Завантажте та розпакуйте `istioctl`, для версії Istio, до якої ви хочете оновитись. Потім виконайте наступну команду, щоб встановити нову цільову ревізію панелі управління Istio на основі CR `IstioOperator` у кластері (тут ми припускаємо, що цільова ревізія — {{< istio_full_version_revision >}}):

{{< text syntax=bash snip_id=canary_upgrade_init >}}
$ istio-{{< istio_full_version >}}/bin/istioctl operator init --revision {{< istio_full_version_revision >}}
{{< /text >}}

{{< tip >}}
Ви також можете використовувати Helm для розгортання іншого оператора з налаштуванням ревізії:

{{< text syntax=bash snip_id=none >}}
$ helm install istio-operator manifests/charts/istio-operator \
  --set watchedNamespaces=istio-system \
  -n istio-operator \
  --set revision={{< istio_full_version_revision >}}
{{< /text >}}

Зверніть увагу, що для виконання наведених вище команд потрібно [завантажити реліз Istio](/docs/setup/additional-setup/download-istio-release/).
{{< /tip >}}

Зробіть копію CR `example-istiocontrolplane` і збережіть її у файлі з іменем `example-istiocontrolplane-{{< istio_full_version_revision >}}.yaml`. Змініть імʼя на `example-istiocontrolplane-{{< istio_full_version_revision >}}` і додайте `revision: {{< istio_full_version_revision >}}` до CR. Ваш оновлений CR `IstioOperator` повинен виглядати приблизно так:

{{< text syntax=bash snip_id=cat_operator_yaml >}}
$ cat example-istiocontrolplane-{{< istio_full_version_revision >}}.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane-{{< istio_full_version_revision >}}
spec:
  revision: {{< istio_full_version_revision >}}
  profile: default
{{< /text >}}

Застосуйте оновлений CR `IstioOperator` до кластера. Після цього у вас буде два розгортання панелі управління та сервіси, що працюють паралельно:

{{< text syntax=bash snip_id=get_pods_istio_system >}}
$ kubectl get pod -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-{{< istio_full_version_revision >}}-597475f4f6-bgtcz   1/1     Running   0          64s
istiod-6ffcc65b96-bxzv5          1/1     Running   0          2m11s
{{< /text >}}

{{< text syntax=bash snip_id=get_svc_istio_system >}}
$ kubectl get services -n istio-system -l app=istiod
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                         AGE
istiod          ClusterIP   10.104.129.150   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,853/TCP   2m35s
istiod-{{< istio_full_version_revision >}}   ClusterIP   10.111.17.49     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP           88s
{{< /text >}}

Щоб завершити оновлення, позначте простори імен міткою `istio.io/rev={{< istio_full_version_revision >}}` і перезапустіть робочі навантаження, як описано в документації по [оновленню робочих навантажень](/docs/setup/upgrade/canary/#data-plane).

## Видалення {#uninstall}

Якщо ви використовували оператор для виконання поетапного оновлення панелі управління, ви можете видалити стару панель управління та зберегти нову, видаливши старий `IstioOperator` CR у кластері, що видалить стару версію Istio:

{{< text syntax=bash snip_id=delete_example_istiocontrolplane >}}
$ kubectl delete istiooperators.install.istio.io -n istio-system example-istiocontrolplane
{{< /text >}}

Зачекайте, поки Istio буде видалено — це може зайняти деякий час.

Потім ви можете видалити оператор Istio для старої версії, виконавши наступну команду:

{{< text syntax=bash snip_id=none >}}
$ istioctl operator remove --revision <revision>
{{< /text >}}

Якщо ви пропустите параметр `revision`, будуть видалені всі версії оператора Istio.

Зверніть увагу, що видалення оператора до того, як `IstioOperator` CR і відповідна версія Istio будуть повністю видалені, може призвести до залишкових ресурсів Istio.
Щоб очистити все, що не було видалено оператором:

{{< text syntax=bash snip_id=cleanup >}}
$ istioctl uninstall -y --purge
$ kubectl delete ns istio-system istio-operator
{{< /text >}}
