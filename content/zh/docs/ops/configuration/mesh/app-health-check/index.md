---
title: Istio 服务的健康检查
description: 为您展示如何对 Istio 服务做健康检查。
weight: 50
aliases:
  - /zh/docs/tasks/traffic-management/app-health-check/
  - /zh/docs/ops/security/health-checks-and-mtls/
  - /zh/help/ops/setup/app-health-check
  - /zh/help/ops/app-health-check
  - /zh/docs/ops/app-health-check
  - /zh/docs/ops/setup/app-health-check
keywords: [security,health-check]
owner: istio/wg-user-experience-maintainers
test: yes
---

[Kubernetes 存活和就绪探针](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
描述了几种配置存活和就绪探针的方法：

1. [命令](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
1. [HTTP 请求](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-http-request)
1. [TCP 探针](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-tcp-liveness-probe)
1. [gRPC 探针](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-grpc-liveness-probe)

命令方式无需更改即可工作，但 HTTP 请求、TCP 探针和 gRPC 探针需要 Istio 更改 Pod 的配置。

对 `liveness-http` 服务的健康检查请求由 kubelet 发送。当启用双向 TLS 时，
这会成为一个问题，因为 kubelet 没有 Istio 颁发的证书。
因此，健康检查请求将失败。

TCP 探针检查需要特殊处理，因为 Istio 将所有传入的流量重定向到 Sidecar，
所以所有 TCP 端口都显示为开放。kubelet 仅检查某个进程是否正在监听指定的端口，
因此只要 Sidecar 正在运行，该探针就总会成功。

Istio 通过重写应用程序 `PodSpec` 就绪/存活探针来解决这两个问题，
以便将探针请求发送到 [Sidecar 代理](/zh/docs/reference/commands/pilot-agent/)。

## 存活探针重写示例 {#liveness-probe-rewrite-example}

为了演示存活探针和就绪探针如何在应用程序 `PodSpec` 级别进行重写，
可以使用 [liveness-http-same-port 样例]({{< github_file >}}/samples/health-check/liveness-http-same-port.yaml)。

首先为此样例应用创建一个命名空间并打好标签：

{{< text bash >}}
$ kubectl create namespace istio-io-health-rewrite
$ kubectl label namespace istio-io-health-rewrite istio-injection=enabled
{{< /text >}}

然后部署样例应用程序：

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

部署完成后，您可以检查 Pod 的应用容器，以查看已更改的路径：

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o json | jq '.spec.containers[0].livenessProbe.httpGet'
{
  "path": "/app-health/liveness-http/livez",
  "port": 15020,
  "scheme": "HTTP"
}
{{< /text >}}

原来的 `livenessProbe` 路径现在被映射到 Sidecar 容器环境变量 `ISTIO_KUBE_APP_PROBERS` 中的新路径：

{{< text bash json >}}
$ kubectl get pod "$LIVENESS_POD" -n istio-io-health-rewrite -o=jsonpath="{.spec.containers[1].env[?(@.name=='ISTIO_KUBE_APP_PROBERS')]}"
{
  "name":"ISTIO_KUBE_APP_PROBERS",
  "value":"{\"/app-health/liveness-http/livez\":{\"httpGet\":{\"path\":\"/foo\",\"port\":8001,\"scheme\":\"HTTP\"},\"timeoutSeconds\":1}}"
}
{{< /text >}}

对于 HTTP 和 gRPC 请求，Sidecar 代理将请求重定向到应用程序并剥离响应体，仅返回响应代码。
对于 TCP 探针，Sidecar 代理会在避免流量重定向的同时进行端口检查。

在所有内置的 Istio [配置文件](/zh/docs/setup/additional-setup/config-profiles/)中，
有问题的探针的重写是默认启用的，但可以如下所述禁用。

## 使用命令方式的存活和就绪探针 {#liveness-and-readiness-probes-using-the-command-approach}

Istio 提供了一个[存活示例]({{< github_file >}}/samples/health-check/liveness-command.yaml)来实现这种方式。
为了演示该探针在启用双向 TLS 的情况下如何工作，本例先创建一个命名空间：

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

要配置 `STRICT` 双向 TLS，请运行：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-io-health"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

接下来，运行以下命令来部署示例服务：

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

要确认存活探针是否正常工作，请检查示例 Pod 的状态以验证它是否正在运行。

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## 使用 HTTP、TCP 和 gRPC 方式的存活和就绪探针 {#liveness-and-readiness-probes-using-the-http-request-approach}

如上所述，Istio 默认使用探针重写来实现 HTTP、TCP 和 gRPC 探针。
您可以为特定 Pod 或全局禁用此特性。

### 为 Pod 禁用探针重写 {#disable-the-http-probe-rewrite-for-a-pod}

您可以使用 `sidecar.istio.io/rewriteAppHTTPProbers: "false"`
来[为 Pod 添加注解](/zh/docs/reference/config/annotations/)
以禁用探针重写选项。确保将注解添加到
[Pod 资源](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/pod-overview/)，
因为在其他任何地方该注解会被忽略（例如，在封闭的 Deployment 资源上）。

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

这种方式允许您在单个 Deployment 上逐步禁用健康检查探针重写，
而无需重新安装 Istio。

### 全局禁用探针重写 {#disable-the-probe-rewrite-globally}

[安装 Istio](/zh/docs/setup/install/istioctl/) 时使用
`--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=false`
全局禁用探针重写。**或者**更新 Istio Sidecar 注入器的配置映射：

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe": true/"rewriteAppHTTPProbe": false/' | kubectl apply -f -
{{< /text >}}

## 清理 {#cleanup}

移除这些示例所用的命名空间：

{{< text bash >}}
$ kubectl delete ns istio-io-health istio-io-health-rewrite
{{< /text >}}
