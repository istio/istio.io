---
title: Повідомлення про помилки
description: Що робити, якщо ви знайшли помилку.
weight: 34
aliases:
    - /uk/bugs.html
    - /uk/bugs/index.html
    - /uk/help/bugs/
    - /uk/about/bugs
    - /uk/latest/about/bugs
owner: istio/wg-docs-maintainers
test: n/a
---

О ні! Ви знайшли помилку? Ми б хотіли про це дізнатися.

## Помилки продукту {#product-bugs}

Перевірте нашу [базу даних проблем](https://github.com/istio/istio/issues/), щоб дізнатися, чи вже відомо про вашу проблему, і дізнатися, коли ми, сподіваємось, зможемо її виправити. Якщо ви не знайшли свою проблему в базі даних, будь ласка, створіть [новий тікет](https://github.com/istio/istio/issues/new/choose) і повідомте нам, що відбувається.

Якщо ви думаєте, що помилка насправді є вразливістю безпеки, будь ласка, відвідайте [Повідомлення про вразливості безпеки](/docs/releases/security-vulnerabilities/), щоб дізнатися, що робити.

### Архіви стану кластеру Kubernetes {#kubernetes-cluster-state-archives}

Якщо ви працюєте на Kubernetes, розгляньте можливість включення архіву стану кластеру у ваш звіт про помилку. Для зручності ви можете запустити команду `istioctl bug-report`, щоб створити архів, що містить усі відповідні дані з вашого кластера Kubernetes:

    {{< text bash >}}
    $ istioctl bug-report
    {{< /text >}}

Потім прикріпіть створений файл `bug-report.tgz` до вашого тікета.

Якщо ваша мережа охоплює кілька кластерів, запустіть `istioctl bug-report` для кожного кластера, вказуючи прапорці `--context` або `--kubeconfig`.

{{< tip >}}
Команда `istioctl bug-report` доступна лише в `istioctl` версії `1.8.0` і новіших версіях, але її можна також використовувати для збору інформації з більш старої версії Istio, встановленої у вашому кластері.
{{< /tip >}}

{{< tip >}}
Якщо ви запускаєте `bug-report` на великому кластері, він може не завершитися успішно. Будь ласка, використовуйте опцію `--include ns1,ns2`, щоб зібрати команди проксі та журнали тільки для відповідних просторів імен. Для додаткових опцій `bug-report` відвідайте [довідник команди istioctl bug-report](/docs/reference/commands/istioctl/#istioctl-bug-report).
{{< /tip >}}

Якщо ви не можете використовувати команду `bug-report`, будь ласка, прикріпіть власний архів, що містить:

* Вивід команди istioctl analyze:

    {{< text bash >}}
    $ istioctl analyze --all-namespaces
    {{< /text >}}

* Podʼи, сервіси, deployments та точки доступу у всіх просторах імен:

    {{< text bash >}}
    $ kubectl get pods,services,deployments,endpoints --all-namespaces -o yaml > k8s_resources.yaml
    {{< /text >}}

* Імена секретів у `istio-system`:

    {{< text bash >}}
    $ kubectl --namespace istio-system get secrets
    {{< /text >}}

* ConfigMaps у просторі імен `istio-system`:

    {{< text bash >}}
    $ kubectl --namespace istio-system get cm -o yaml
    {{< /text >}}

* Поточні та попередні журнали всіх компонентів Istio та sidecar. Ось кілька прикладів того, як їх отримати, будь ласка, адаптуйте для вашого середовища:

    * Журнали Istiod:

        {{< text bash >}}
        $ kubectl logs -n istio-system -l app=istiod
        {{< /text >}}

    * Журнали Ingress Gateway:

        {{< text bash >}}
        $ kubectl logs -l istio=ingressgateway -n istio-system
        {{< /text >}}

    * Журнали Egress Gateway:

        {{< text bash >}}
        $ kubectl logs -l istio=egressgateway -n istio-system
        {{< /text >}}

    * Журнали Sidecar:

        {{< text bash >}}
        $ for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}') ; do kubectl logs -l service.istio.io/canonical-revision -c istio-proxy -n $ns ; done
        {{< /text >}}

* Усі артефакти конфігурації Istio:

    {{< text bash >}}
    $ kubectl get istio-io --all-namespaces -o yaml
    {{< /text >}}

## Помилки документації {#documentation-bugs}

Перевірте нашу [базу даних проблем документації](https://github.com/istio/istio.io/issues/), щоб дізнатися, чи вже відомо про вашу проблему, і дізнатися, коли ми, сподіваємось, зможемо її виправити. Якщо ви не знайшли свою проблему в базі даних, будь ласка, [повідомте про проблему там](https://github.com/istio/istio.io/issues/new). Якщо ви хочете подати запропоноване редагування сторінки, ви знайдете посилання "Edit this Page on GitHub" внизу праворуч кожної сторінки.
