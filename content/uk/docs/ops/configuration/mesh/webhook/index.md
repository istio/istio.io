---
title: Огляд динамічних вебхуків допуску
description: Надає загальний огляд використання Istio вебхуків Kubernetes та повʼязаних з цим проблем.
weight: 10
aliases:
  - /uk/help/ops/setup/webhook
  - /uk/docs/ops/setup/webhook
owner: istio/wg-user-experience-maintainers
test: no
---

З механізмів [модифікуючих та валідаційних вебхуків Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/):

{{< tip >}}
Вебхуки допуску (Admission webhooks) — це зворотні виклики HTTP, які отримують запити на допуск та обробляють їх. Ви можете визначити два типи вебхуків допуску: валідаційний вебхук допуску та модифікуючий вебхук допуску. З валідаційним вебхуком допуску ви можете відхиляти запити для забезпечення виконання спеціальних політик допуску. З модифікуючим вебхуком допуску ви можете змінювати запити для забезпечення власних стандартних значень.
{{< /tip >}}

Istio використовує `ValidatingAdmissionWebhooks` для перевірки конфігурації Istio та `MutatingAdmissionWebhooks` для автоматичного впровадження sidecar проксі у контейнери користувачів.

Посібники з налаштування вебхуків передбачають загальну обізнаність з Kubernetes Dynamic Admission Webhooks. Проконсультуйтеся з API-довідниками Kubernetes для отримання детальної документації про [Mutating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io) та [Validating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#validatingwebhookconfiguration-v1-admissionregistration-k8s-io).

## Перевірка передумов для динамічних вебхуків допуску {#verify-dynamic-admission-webhook-prerequisites}

Дивіться [інструкції з налаштування платформи](/docs/setup/platform-setup/) для специфічних інструкцій постачальника з налаштування Kubernetes. Вебхуки не функціонуватимуть належним чином, якщо кластер налаштований неправильно. Ви можете виконати ці кроки після налаштування кластера, якщо динамічні вебхуки та залежні функції не працюють належним чином.

1. Перевірте, що ви використовуєте [підтримувану версію](/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}}) [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) та сервера Kubernetes:

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.29.0
    Server Version: v1.29.1
    {{< /text >}}

1. `admissionregistration.k8s.io/v1` має бути увімкнений

    {{< text bash >}}
    $ kubectl api-versions | grep admissionregistration.k8s.io/v1
    admissionregistration.k8s.io/v1
    {{< /text >}}

1. Перевірте, що втулки `MutatingAdmissionWebhook` і `ValidatingAdmissionWebhook` є у списку `kube-apiserver --enable-admission-plugins`. Доступ до цього параметра є [специфічним для постачальника](/docs/setup/platform-setup/).

1. Перевірте, чи має api-server Kubernetes мережеву зʼєднаність з podʼом вебхука. Наприклад, неправильні налаштування `http_proxy` можуть перешкоджати роботі api-server (див. повʼязані проблеми [тут](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)та [тут](https://github.com/kubernetes/kubeadm/issues/666) для отримання додаткової інформації).
