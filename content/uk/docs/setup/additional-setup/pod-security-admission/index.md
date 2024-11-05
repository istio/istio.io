---
title: Встановлення Istio з Pod Security Admission
description: Встановлення та використання Istio з контролером допуску Pod Security Admission.
weight: 65
aliases:
    - /uk/docs/setup/kubernetes/install/pod-security-admission
    - /uk/docs/setup/kubernetes/additional-setup/pod-security-admission
keywords: [psa]
owner: istio/wg-networking-maintainers
test: yes
---

Слідуйте цьому посібнику для встановлення, налаштування та використання Istio mesh з контролером допуску Pod Security Admission ([PSA](https://kubernetes.io/docs/concepts/security/pod-security-admission/)), який забезпечує дотримання `baseline` [політики](https://kubernetes.io/docs/concepts/security/pod-security-standards/) у просторах імен всередині mesh.

Стандартно Istio вставляє init контейнер, `istio-init`, у podʼи, розгорнуті в mesh. `istio-init` вимагає, щоб користувач або службовий обліковий запис, що розгортає podʼи в mesh, мав достатні права Kubernetes RBAC для розгортання [контейнерів з можливостями `NET_ADMIN` та `NET_RAW`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container).

Однак, політика `baseline` не включає `NET_ADMIN` або `NET_RAW` до своїх [дозволених можливостей](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline). Щоб уникнути примусового застосування політики `privileged` у всіх просторах імен в mesh, необхідно використовувати Istio mesh з [втулком Istio Container Network Interface](/docs/setup/additional-setup/cni/). DaemonSet `istio-cni-node` у просторі імен `istio-system` вимагає томів `hostPath` для доступу до локальних тек CNI. Оскільки це не дозволено у політиці `baseline`, простір імен, де буде розгорнутий DaemonSet CNI, повинен забезпечувати дотримання політики `privileged` [policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged). Стандартно цей простір імен — `istio-system`.

{{< warning >}}
Простори імен у mesh також можуть використовувати політику `restricted` [policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline). Вам потрібно налаштувати `seccompProfile` для ваших застосунків відповідно до специфікацій політики.
{{< /warning >}}

## Встановлення Istio з PSA {#install-istio-with-psa}

1. Створіть простір імен `istio-system` і призначте йому мітку для забезпечення дотримання політики `privileged`.

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl label --overwrite ns istio-system \
        pod-security.kubernetes.io/enforce=privileged \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/istio-system labeled
    {{< /text >}}

1. [Встановіть Istio з CNI](/docs/setup/additional-setup/cni/#install-cni) в кластер Kubernetes версії 1.25 або пізнішої.

    {{< text bash >}}
    $ istioctl install --set components.cni.enabled=true -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Ingress gateways installed
    ✔ CNI installed
    ✔ Installation complete
    {{< /text >}}

## Розгортання демонстраційного застосунку {#deploy-the-sample-application}

1. Додайте мітку простору імен для забезпечення дотримання політики `baseline` для простору імен default, де буде запущено демонстраційний застосунок:

    {{< text bash >}}
    $ kubectl label --overwrite ns default \
        pod-security.kubernetes.io/enforce=baseline \
        pod-security.kubernetes.io/enforce-version=latest
    namespace/default labeled
    {{< /text >}}

2. Розгорніть демонстраційний застосунок, використовуючи конфігураційні ресурси з увімкненим PSA:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-psa.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

3. Перевірте, чи застосунок працює всередині кластера і відображає HTML-сторінки, перевіряючи заголовок сторінки у відповіді:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## Видалення {#uninstall}

1. Видаліть демонстраційний застосунок

    {{< text bash >}}
    $ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-psa.yaml
    {{< /text >}}

2. Видаліть мітки з простору імен default

    {{< text bash >}}
    $ kubectl label namespace default pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version-
    {{< /text >}}

3. Видаліть Istio

    {{< text bash >}}
    $ istioctl uninstall -y --purge
    {{< /text >}}

4. Видаліть простір імен `istio-system`

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
