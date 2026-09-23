---
title: Kops
description: Інструкції для налаштування Kops для використання з Istio.
weight: 33
skip_seealso: true
keywords: [platform-setup,kubernetes,kops]
owner: istio/wg-environments-maintainers
test: no
---

{{< tip >}}
Спеціальної конфігурації для запуску Istio на кластерах Kubernetes версії 1.22 або новішої не потрібно. Для попередніх версій Kubernetes вам необхідно продовжити виконання цих кроків.
{{< /tip >}}

Якщо ви хочете запустити [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration) (SDS) для вашої сервісної мережі на кластерах, керованих Kops, вам потрібно додати [додаткові конфігурації](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) для увімкнення проєкції томів токенів службового облікового запису в api-server.

1. Відкрийте файл конфігурації:

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. Додайте наступне у файл конфігурації:

    {{< text yaml >}}
    kubeAPIServer:
        apiAudiences:
        - api
        - istio-ca
        serviceAccountIssuer: kubernetes.default.svc
    {{< /text >}}

1. Виконайте оновлення:

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. Запустіть поетапне оновлення:

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}
