---
title: Перевірка справності сервісів Istio
description: Показує, як здійснювати перевірку справності для сервісів Istio.
weight: 50
aliases:
  - /uk/docs/tasks/traffic-management/app-health-check/
  - /uk/docs/ops/security/health-checks-and-mtls/
  - /uk/help/ops/setup/app-health-check
  - /uk/help/ops/app-health-check
  - /uk/docs/ops/app-health-check
  - /uk/docs/ops/setup/app-health-check
keywords: [security,health-check]
owner: istio/wg-user-experience-maintainers
test: yes

---

[Протоколи перевірки справності Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) описують кілька способів налаштування перевірок справності та готовності:

1. [Команда](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
2. [HTTP запит](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request)
3. [TCP перевірка](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe)
4. [gRPC перевірка](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe)

Метод з командою працює без змін, але HTTP запити, TCP перевірки та gRPC перевірки потребують внесення змін до конфігурації podʼа.

Запити перевірки справності до сервісу `liveness-http` надсилаються Kubelet. Це стає проблемою, коли увімкнено взаємний TLS, оскільки Kubelet не має сертифіката, виданого Istio. Тому запити перевірки справності зазнають невдачі.

Перевірки TCP потребують спеціальної обробки, оскільки Istio перенаправляє весь вхідний трафік у sidecar, і всі TCP порти виглядають відкритими. Kubelet просто перевіряє, чи є процес, який слухає на вказаному порту, тому перевірка завжди буде успішною, поки sidecar працює.

Istio розвʼязує обидві ці проблеми, переписуючи перевірку готовності/справності застосунку `PodSpec`, щоб запит перевірки надсилався до [агента sidecar](/docs/reference/commands/pilot-agent/).

## Приклад переписування перевірки справності {#liveness-probe-rewrite-example}

Щоб продемонструвати, як переписується перевірка готовності/справності на рівні `PodSpec` застосунку, скористаємося [зразком liveness-http-same-port]({{< github_file >}}/samples/health-check/liveness-http-same-port.yaml).

Спочатку створіть і позначте простір імен для прикладу:

{{< text bash >}}
$ kubectl create namespace istio-io-health-rewrite
$ kubectl label namespace istio-io-health-rewrite istio-injection=enabled
{{< /text >}}

І розгорніть демонстраційний застосунок:

{{< text bash yaml >}}
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
  namespace: istio-io-health-rewrite
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

Після розгортання ви можете перевірити контейнер застосунку podʼа, щоб побачити змінений шлях:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o json | jq '.spec.containers[0].livenessProbe.httpGet'
{
  "path": "/app-health/liveness-http/livez",
  "port": 15020,
  "scheme": "HTTP"
}
{{< /text >}}

Оригінальний шлях `livenessProbe` тепер зіставлено на новий шлях у змінній середовища контейнера sidecar `ISTIO_KUBE_APP_PROBERS`:

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o=jsonpath="{.spec.containers[1].env[?(@.name=='ISTIO_KUBE_APP_PROBERS')]}"
{
  "name":"ISTIO_KUBE_APP_PROBERS",
  "value":"{\"/app-health/liveness-http/livez\":{\"httpGet\":{\"path\":\"/foo\",\"port\":8001,\"scheme\":\"HTTP\"},\"timeoutSeconds\":1}}"
}
{{< /text >}}

Для HTTP та gRPC запитів агент sidecar перенаправляє запит до застосунку і видаляє тіло відповіді, повертаючи тільки код відповіді. Для перевірок TCP агент sidecar потім виконає перевірку порту, уникаючи перенаправлення трафіку.

Переписування проблемних перевірок стандартно увімкнено у всіх стандартних профілях конфігурації Istio [конфігураційних профілях](/docs/setup/additional-setup/config-profiles/), але його можна вимкнути, як описано нижче.

## Перевірки справності та готовності за допомогою команди {#liveness-and-readiness-probes-using-the-command-approach}

Istio надає [демонстраційний застосунок для перевірки справності]({{< github_file >}}/samples/health-check/liveness-command.yaml), який реалізує цей підхід. Щоб продемонструвати його роботу з увімкненим взаємним TLS,
спочатку створіть простір імен для прикладу:

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

Щоб налаштувати строгий взаємний TLS, виконайте:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Далі перейдіть до кореневої теки установки Istio і виконайте наступну команду для розгортання демонстраційного сервісу:

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Щоб підтвердити, що перевірки справності працюють, перевірте статус демонстраційного podʼа, щоб упевнитися, що він працює.

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Перевірки справності та готовності за допомогою HTTP, TCP і gRPC {#liveness-and-readiness-probes-using-the-http-request-approach}

Як зазначалося раніше, Istio стандартно використовує переписування перевірок для реалізації HTTP, TCP і gRPC перевірок. Ви можете вимкнути цю
функцію або для конкретних podʼів, або глобально.

### Вимкнення переписування перевірок для podʼа {#disable-the-http-probe-rewrite-for-a-pod}

Ви можете додати [анотацію](/docs/reference/config/annotations/) `sidecar.istio.io/rewriteAppHTTPProbers: "false"` до podʼа, щоб вимкнути опцію переписування перевірок. Переконайтеся, що ви додали анотацію до [ресурсу pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/), оскільки вона буде ігноруватися в будь-якому іншому місці (наприклад, на ресурсі deployment, який містить pod).

{{< tabset category-name="disable-probe-rewrite" >}}

{{< tab name="HTTP Probe" category-value="http-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-http
spec:
  selector:
    matchLabels:
      app: liveness-http
      version: v1
  template:
    metadata:
      labels:
        app: liveness-http
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: liveness-http
        image: docker.io/istio/health:example
        ports:
        - containerPort: 8001
        livenessProbe:
          httpGet:
            path: /foo
            port: 8001
          initialDelaySeconds: 5
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="gRPC Probe" category-value="grpc-probe" >}}

{{< text yaml >}}
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: liveness-grpc
spec:
  selector:
    matchLabels:
      app: liveness-grpc
      version: v1
  template:
    metadata:
      labels:
        app: liveness-grpc
        version: v1
      annotations:
        sidecar.istio.io/rewriteAppHTTPProbers: "false"
    spec:
      containers:
      - name: etcd
        image: registry.k8s.io/etcd:3.5.1-0
        command: ["--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
        ports:
        - containerPort: 2379
        livenessProbe:
          grpc:
            port: 2379
          initialDelaySeconds: 10
          periodSeconds: 5
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Цей підхід дозволяє вам поступово вимикати переписування перевірок справності на окремих deployments, без перевстановлення Istio.

### Вимкнення переписування перевірок глобально {#disable-the-http-probe-rewrite-globally}

[Встановіть Istio](/docs/setup/install/istioctl/) з параметром `--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=false`, щоб вимкнути переписування перевірок глобально. **Альтернативно**, оновіть config map для інжектора sidecar Istio:

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
{{< /text >}}

## Очищення {#cleanup}

Видаліть простори імен, використані для прикладів:

{{< text bash >}}
$ kubectl delete ns istio-io-health istio-io-health-rewrite
{{< /text >}}
