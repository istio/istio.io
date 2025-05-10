---
title: "Випущено Sail Operator 1.0.0: керуйте Istio за допомогою оператора"
description: Зануртеся в основи Sail Operator і перегляньте приклад, щоб побачити, як легко використовувати його для управління Istio.
publishdate: 2025-04-03
attribution: "Francisco Herrera - Red Hat"
keywords: [istio,operator,sail,incluster,istiooperator]
---

[Sail Operator](https://github.com/istio-ecosystem/sail-operator) — це проєкт спільноти, започаткований Red Hat для створення сучасного [оператора](https://www.redhat.com/en/topics/containers/what-is-a-kubernetes-operator) для Istio. [Вперше анонсований у серпні 2024 року](/blog/2024/introducing-sail-operator/), ми раді повідомити, що Sail Operator тепер є GA з чіткою місією: спростити та впорядкувати управління Istio у вашому кластері.

## Спрощене розгортання та керування {#simplified-deployment--management}

Sail Operator розроблений, щоб зменшити складність встановлення та запуску Istio. Він автоматизує ручні завдання, забезпечуючи послідовну, надійну і нескладну роботу від початкового встановлення до постійного обслуговування та оновлення версій Istio у вашому кластері. API-інтерфейси Sail Operator побудовані на основі API-інтерфейсів Helm chart Istio, що означає, що всі конфігурації Istio доступні через значення CRD Sail Operator.

Ми рекомендуємо користувачам ознайомитися з нашою [документацією](https://github.com/istio-ecosystem/sail-operator/tree/main/docs), щоб дізнатися більше про цей новий спосіб керування середовищем Istio.

Основними ресурсами, що входять до складу Sail Operator, є

* `Istio`: керує панеллю управлінняIstio.
* `IstioRevision`: представляє ревізію панелі управління.
* `IstioRevisionTag`: представляє стабільний теґ ревізії, який функціонує як псевдонім для ревізії панелі управління Istio.
* `IstioCNI`: керує агентом вузла CNI Istio.
* `ZTunnel`: керує режимом оточення ztunnel DaemonSet (функція Alpha).

{{< idea >}}
Якщо ви мігруєте з [since-removed Istio in-cluster operator](/blog/2024/in-cluster-operator-deprecation-announcement/), ви можете ознайомитися з цим розділом нашої [документації](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#migrating-from-istio-in-cluster-operator), де ми пояснюємо еквівалентність ресурсів, або ви також можете спробувати наш [конвертер ресурсів](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#converter-script), щоб легко перетворити ваш ресурс `IstioOperator` на ресурс `Istio`.
{{< /idea >}}

## Основні функції та підтримка {#main-features-and-support}

- Кожним компонентом панелі управління Istio керує Sail Operator незалежно за допомогою спеціальних власних ресурсів Kubernetes (CR). Sail Operator надає окремі CRD для таких компонентів, як `Istio`, `IstioCNI` та `ZTunnel`, що дозволяє вам налаштовувати, керувати та оновлювати їх окремо. Крім того, існують CRD для `IstioRevision` та `IstioRevisionTag` для керування ревізіями панелі управління Istio.
- Підтримка декількох версій Istio. Наразі підтримується версія 1.0.0: 1.24.3, 1.24.2, 1.24.1, 1.23.5, 1.23.4, 1.23.3, 1.23.0.
- Підтримуються дві стратегії оновлення: `InPlace` і `RevisionBased`. Для отримання додаткової інформації про підтримувані типи оновлень зверніться до нашої документації.
- Підтримка багатокластерної [моделі розгортання](/docs/setup/install/multicluster/) Istio: multi-primary, primary-remote, зовнішня панель управління. Більше інформації та прикладів у нашій [документації](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#multi-cluster).
- Підтримка режиму Ambient у версії Alpha: зверніться до нашої спеціальної [документації](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/common/istio-ambient-mode.md).
- Надбудови управляються окремо від Sail Operator. Вони можуть бути легко інтегровані з Sail Operator, зверніться до цього розділу [документації](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#addons) за прикладами та додатковою інформацією.

## Чому зараз? {#why-now}

Оскільки хмарні архітектури продовжують розвиватися, ми вважаємо, що надійний і зручний оператор для Istio є більш важливим, ніж будь-коли. Sail Operator пропонує розробникам та операційним командам послідовне, безпечне та ефективне рішення, яке є звичним для тих, хто звик працювати з операторами. Його випуск GA сигналізує про зрілість рішення, готового підтримувати навіть найвимогливіші виробничі середовища.

## Спробуйте {#try-it-out}

Хочете спробувати Sail Operator?
Цей приклад покаже вам, як безпечно оновити панель управління Istio, використовуючи стратегію оновлення на основі ревізій. Це означає, що у вас будуть одночасно працювати дві панелі управління Istio, що дозволить вам легко мігрувати робочі навантаження, мінімізуючи ризик перебоїв у роботі.

Необхідні умови:

- Працюючий кластер
- Helm
- Kubectl
- Istioctl

### Встановіть Sail Operator за допомогою Helm {#install-the-sail-operator-using-helm}

{{< text bash >}}
$ helm repo add sail-operator https://istio-ecosystem.github.io/sail-operator
$ helm repo update
$ kubectl create namespace sail-operator
$ helm install sail-operator sail-operator/sail-operator --version 1.0.0 -n sail-operator
{{< /text >}}

Тепер оператор встановлений у вашому кластері:

{{< text plain >}}
NAME: sail-operator
LAST DEPLOYED: Tue Mar 18 12:00:46 2025
NAMESPACE: sail-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
{{< /text >}}

Перевірте, чи працює pod оператора:

{{< text bash >}}
$ kubectl get pods -n sail-operator
NAME                             READY   STATUS    RESTARTS   AGE
sail-operator-56bf994f49-j67ft   1/1     Running   0          87s
{{< /text >}}

### Створіть ресурси `Istio` та `IstioRevisionTag` {#create-istio-and-istiorevisiontag-resources}

Створіть ресурси `Istio` з версією `v1.24.2` та `IstioRevisionTag`:

{{< text bash >}}
$ kubectl create ns istio-system
$ cat <<EOF | kubectl apply -f-
apiVersion: sailoperator.io/v1
kind: Istio
metadata:
  name: default
spec:
  namespace: istio-system
  updateStrategy:
    type: RevisionBased
    inactiveRevisionDeletionGracePeriodSeconds: 30
  version: v1.24.2
---
apiVersion: sailoperator.io/v1
kind: IstioRevisionTag
metadata:
  name: default
spec:
  targetRef:
    kind: Istio
    name: default
EOF
{{< /text >}}

Зверніть увагу, що теґ `IstioRevisionTag` має цільове посилання на ресурс `Istio` з іменем `default`.

Перевірте стан створених ресурсів:

- podʼи `istiod` запущено

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-2-bd8458c4-jl8zm   1/1     Running   0          3m45s
    {{< /text >}}

- ресурс `Istio` створено

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-2   Healthy   v1.24.2   4m27s
    {{< /text >}}

- ресурс `IstioRevisionTag` створено

    {{< text bash >}}
    $ kubectl get istiorevisiontag
    NAME      STATUS                    IN USE   REVISION          AGE
    default   NotReferencedByAnything   False    default-v1-24-2   4m43s
    {{< /text >}}

Зверніть увагу, що статус `IstioRevisionTag` має значення `NotReferencedByAnything`. Це повʼязано з тим, що наразі немає ресурсів, які використовують ревізію `default-v1-24-2`.

### Розгорніть демонстраційний застосунок {#deploy-sample-application}

Створіть простір імен та позначте його, щоб увімкнути інʼєкцію Istio:

{{< text bash >}}
$ kubectl create namespace sample
$ kubectl label namespace sample istio-injection=enabled
{{< /text >}}

Після позначення міткою простору імен ви побачите, що статус ресурсу `IstioRevisionTag` зміниться на 'In Use: True', оскільки тепер існує ресурс, який використовує ревізію `default-v1-24-2`:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-2   6m24s
{{< /text >}}

Розгорніть демонстраційний застосунок:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/sleep/sleep.yaml -n sample
{{< /text >}}

Переконайтеся, що проксі-версія демонстраційного застосунку збігається з версією панелі управління:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     SYNCED (78s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

### Оновлення панелі управління Istio до версії 1.24.3 {#upgrade-the-istio-control-plane-to-version-1243}

Оновіть ресурс `Istio` до нової версії:

{{< text bash >}}
$ kubectl patch istio default -n istio-system --type='merge' -p '{"spec":{"version":"v1.24.3"}}'
{{< /text >}}

Перевірте ресурс `Istio`. Ви побачите, що там є дві версії і обидві 'ready':

{{< text bash >}}
$ kubectl get istio
NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
default   2           2       2        default-v1-24-3   Healthy   v1.24.3   10m
{{< /text >}}

Тег `IstioRevisiontag` тепер посилається на нову ревізію:

{{< text bash >}}
$ kubectl get istiorevisiontag
NAME      STATUS    IN USE   REVISION          AGE
default   Healthy   True     default-v1-24-3   11m
{{< /text >}}

Існує дві `IstioRevisions`, по одній для кожної версії Istio:

{{< text bash >}}
$ kubectl get istiorevision
NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
default-v1-24-2          True    Healthy   True     v1.24.2   11m
default-v1-24-3          True    Healthy   True     v1.24.3   92s
{{< /text >}}

Sail Operator автоматично визначає, чи використовується дана панель управління Istio, і записує цю інформацію в стан «In Use», який ви бачите вище. Наразі всі `IstioRevisions` та наш `IstioRevisionTag` вважаються «In Use»:

* Стара ревізія `default-v1-24-2` вважається такою, що використовується, оскільки на неї є посилання у sidecar демонстраційного застосунку.
* Нова ревізія `default-v1-24-3` вважається такою, що використовується, оскільки на неї посилається теґ.
* Теґ вважається таким, що використовується, оскільки на нього посилається простір імен демонстраційного застосунку.

Переконайтеся, що запущено два pod'и панелі управління, по одному для кожної ревізії:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                      READY   STATUS    RESTARTS   AGE
istiod-default-v1-24-2-bd8458c4-jl8zm     1/1     Running   0          16m
istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          6m32s
{{< /text >}}

Переконайтеся, що версія проксі-sidecar не змінилася:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS                LDS                EDS                RDS                ECDS        ISTIOD                                    VERSION
sleep-5fcd8fd6c8-q4c9x.sample     Kubernetes     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     SYNCED (6m40s)     IGNORED     istiod-default-v1-24-2-bd8458c4-jl8zm     1.24.2
{{< /text >}}

Перезапустіть pod sample:

{{< text bash >}}
$ kubectl rollout restart deployment -n sample
{{< /text >}}

Переконайтеся, що версія проксі-sidecar оновлена:

{{< text bash >}}
$ istioctl proxy-status
NAME                              CLUSTER        CDS              LDS              EDS              RDS              ECDS        ISTIOD                                      VERSION
sleep-6f87fcf556-k9nh9.sample     Kubernetes     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     SYNCED (29s)     IGNORED     istiod-default-v1-24-3-68df97dfbb-v7ndm     1.24.3
{{< /text >}}

Коли `IstioRevision` більше не використовується і не є активною ревізією ресурсу `Istio` (наприклад, коли це не та версія, що вказана у полі `spec.version`), Sail Operator видалить її після пільгового періоду, який стандартно становить 30 секунд. Підтвердьте видалення старої панелі управління та `IstioRevision`:

- Pod старої панелі управління видалено

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY   STATUS    RESTARTS   AGE
    istiod-default-v1-24-3-68df97dfbb-v7ndm   1/1     Running   0          10m
    {{< /text >}}

- Старий ресурс `IstioRevision` видалено

    {{< text bash >}}
    $ kubectl get istiorevision
    NAME              TYPE   READY   STATUS    IN USE   VERSION   AGE
    default-v1-24-3          True    Healthy   True     v1.24.3   13m
    {{< /text >}}

- Ресурс `Istio`тепер має тільки одну ревізію

    {{< text bash >}}
    $ kubectl get istio
    NAME      REVISIONS   READY   IN USE   ACTIVE REVISION   STATUS    VERSION   AGE
    default   1           1       1        default-v1-24-3   Healthy   v1.24.3   24m
    {{< /text >}}

**Вітаємо!** Ви успішно оновили панель управління Istio за допомогою стратегії оновлення на основі ревізій.

{{< idea >}}
Щоб перевірити останню версію Sail Operator, відвідайте нашу [сторінку випусків](https://github.com/istio-ecosystem/sail-operator/releases).  Оскільки цей приклад може змінюватися з часом, будь ласка, зверніться до нашої [документації](https://github.com/istio-ecosystem/sail-operator/tree/main/docs#example-using-the-revisionbased-strategy-and-an-istiorevisiontag), щоб переконатися, що ви читаєте найновішу версію.
{{< /idea >}}

## Висновок {#висновок}

Sail Operator автоматизує ручні завдання, забезпечуючи послідовну, надійну і нескладну роботу від початкового встановлення до поточного обслуговування та оновлення Istio у вашому кластері. Sail Operator є проєктом [istio-екосистеми](https://github.com/istio-ecosystem), і ми заохочуємо вас випробувати його і надати відгуки, щоб допомогти нам поліпшити його, ви можете ознайомитися з нашим [посібником з участі](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md) для отримання додаткової інформації про те, як зробити свій внесок у проєкт.
