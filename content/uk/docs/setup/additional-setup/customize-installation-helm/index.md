---
title: Розширене налаштування Helm Chart
description: Описує, як налаштувати параметри конфігурації установки при встановленні з helm.
weight: 55
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

## Передумови {#prerequisites}

Перед початком перевірте наступні передумови:

1. [Завантажте реліз Istio](/docs/setup/additional-setup/download-istio-release/).
1. Виконайте будь-які необхідні [специфічні налаштування платформи](/docs/setup/platform-setup/).
1. Перевірте [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).
1. [Використання helm для установки Istio](/docs/setup/install/helm).
1. Версія Helm, яка підтримує пост-рендеринг (>= 3.1).
1. kubectl або kustomize.

## Розширені налаштування Helm Chart {#advanced-helm-chart-customization}

Helm chart для Istio намагається включити більшість атрибутів, необхідних користувачам для їх специфічних вимог. Однак він не містить кожного можливого значення Kubernetes, яке ви можете захотіти налаштувати. Хоча практично неможливо реалізувати такий механізм, в цьому документі ми покажемо метод, який дозволить вам здійснювати розширене налаштування Helm чарту без необхідності безпосередньо модифікувати Helm чарт Istio.

### Використання Helm з kustomize для пост-рендерингу Istio charts {#using-helm-with-kustomize-to-post-render-istio-charts}

Використовуючи можливість `post-renderer` Helm, ви можете легко налаштувати маніфести установки відповідно до ваших вимог. `Пост-рендеринг` надає гнучкість для маніпулювання, налаштування і/або перевірки створених маніфестів перед їх установкою за допомогою Helm. Це дозволяє користувачам з розширеними потребами в конфігурації використовувати такі інструменти, як Kustomize, для застосування змін конфігурації без потреби у додатковій підтримці від оригінальних розробників чартів.

### Додавання значення до наявного чарту {#adding-a-value-to-an-already-existing-chart}

У цьому прикладі ми додамо значення `sysctl` до розгортання `ingress-gateway` Istio. Ми збираємось:

1. Створити шаблон патча налаштування `sysctl` для розгортання.
1. Застосувати патч за допомогою пост-рендерингу Helm.
1. Перевірити, що патч `sysctl` був правильно застосований до podʼів.

## Створення Kustomization {#create-the-kustomization}

Спочатку створимо файл патча `sysctl`, додавши `securityContext` до podʼа `ingress-gateway` з додатковим атрибутом:

{{< text bash >}}
$ cat > sysctl-ingress-gw-customization.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    spec:
      securityContext:
          sysctls:
          - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
            value: "10"
EOF
{{< /text >}}

Нижче наведений сценарій оболонки допомагає зʼєднати Helm `post-renderer` та Kustomize, оскільки перший працює з `stdin/stdout`, а другий працює з файлами.

{{< text bash >}}
$ cat > kustomize.sh <<EOF
#!/bin/sh
cat > base.yaml
exec kubectl kustomize # також можна використовувати "kustomize build .", якщо у вас його встановлено.
EOF
$ chmod +x ./kustomize.sh
{{< /text >}}

Нарешті, створимо файл `kustomization.yaml`, який є вхідним для `kustomize`
зі списком ресурсів та супутніми деталями налаштування.

{{< text bash >}}
$ cat > kustomization.yaml <<EOF
resources:
- base.yaml
patchesStrategicMerge:
- sysctl-ingress-gw-customization.yaml
EOF
{{< /text >}}

## Застосування Kustomization {#apply-the-kustomization}

Тепер, коли файл Kustomization готовий, використаємо Helm, щоб переконатися, що він буде застосований належним чином.

### Додати репозиторій Helm для Istio {#add-the-helm-repository-for-istio}

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

### Рендеринг та перевірка за допомогою Helm Template {#render-and-verify-using-helm-template}

Ми можемо використовувати Helm `post-renderer`, щоб перевірити створені маніфести перед їх установкою за допомогою Helm.

{{< text bash >}}
$ helm template istio-ingress istio/gateway --namespace istio-ingress --post-renderer ./kustomize.sh | grep -B 2 -A 1 netfilter.nf_conntrack_tcp_timeout_close_wait
{{< /text >}}

У виводі перевірте новий атрибут `sysctl` для podʼа `ingress-gateway`:

{{< text yaml >}}
    securityContext:
      sysctls:
      - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
        value: "10"
{{< /text >}}

### Застосування патча за допомогою Helm `Post-Renderer` {#apply-the-patch-using-helm-post-renderer}

Використовуйте наступну команду для установки ingress-gateway Istio, застосовуючи наше налаштування за допомогою Helm `post-renderer`:

{{< text bash >}}
$ kubectl create ns istio-ingress
$ helm upgrade -i istio-ingress istio/gateway --namespace istio-ingress --wait --post-renderer ./kustomize.sh
{{< /text >}}

## Перевірка Kustomization {#verify-the-kustomization}

Перевірте розгортання ingress-gateway, ви побачите нове змінене значення `sysctl`:

{{< text bash >}}
$ kubectl -n istio-ingress get deployment istio-ingress -o yaml
{{< /text >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  …
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    metadata:
      …
    spec:
      securityContext:
        sysctls:
        - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
          value: "10"
{{< /text >}}

## Додаткова інформація {#additional-information}

Для отримання детальнішої інформації про концепції та техніки, описані в цьому документі, будь ласка, зверніться до:

1. [IstioOperator — Налаштування установки](/docs/setup/additional-setup/customize-installation)
1. [Розширені техніки Helm](https://helm.sh/docs/topics/advanced/)
1. [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
