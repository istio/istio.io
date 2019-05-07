---
title: Istio Service 健康检查
description: 展示如何对 Istio service 进行健康检查。
weight: 65
keywords: [security,health-check]
---

此任务展示了如何使用 [Kubernetes liveness 和 readiness 探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) 在 Istio Service 上进行健康检查。

在 Kubernetes 中存在三种 liveness 和 readiness 探针：

1. 命令
1. http 请求
1. tcp 请求

此任务分别提供在启用和禁用 Istio 双向 TLS 认证时，前两个选项的示例。

## 开始之前

* 了解 [Kubernetes liveness 和 readiness 探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)，Istio [认证策略](/zh/docs/concepts/security/#认证策略)和[双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)的概念。

* 具有一个安装了 Istio 的 Kubernetes 集群，但没有启用全局双向 TLS（例如按照 [安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤) 中的描述使用 `istio-demo.yaml`，或者在使用 [Helm](/zh/docs/setup/kubernetes/install/helm/) 时将 `global.mtls.enabled` 设置为 false）。

## 使用命令选项的 liveness 和 readiness 探针

在本节中，我们将展示如何在禁用双向 TLS 时配置健康检查，然后再展示在启用双向 TLS 时它的工作情况。

### 禁用双向 TLS

运行此命令以在默认 namespace 中部署 [liveness]({{< github_file >}}/samples/health-check/liveness-command.yaml)：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

等待一分钟，然后检查 pod 状态

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           1m
{{< /text >}}

'RESTARTS' 列中的数字 '0' 表示 liveness 探针工作正常。Readiness 探针的工作方式相同，您可以相应地修改 liveness-command.yaml 以自行尝试。

### 启用双向 TLS

要在默认命名空间中为服务启用双向 TLS，您必须配置身份验证策略和目标规则。
请按照以下步骤完成配置：

1. 要配置身份验证策略，请运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. 要配置目标规则，请运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

运行此命令重新部署该 service：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

并重复上一小节中的相同步骤以验证 liveness 探针是否工作正常。

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

### 清理

删除上述步骤中添加的相互TLS策略和相应的目标规则：

1. 要删除双向 TLS 策略，请运行：

    {{< text bash >}}
    $ kubectl delete policies default
    {{< /text >}}

1. 要删除相应的目标规则，请运行：

    {{< text bash >}}
    $ kubectl delete destinationrules default
    {{< /text >}}

## 使用 http 请求选项的 liveness 和 readiness 探针

本节介绍了如何使用 HTTP 请求选项配置健康检查。

### 禁用双向 TLS 策略

运行此命令以在默认 namespace 中部署 [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml)：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

等待一分钟，然后检查 pod 状态，查看 'RESTARTS' 列为 '0' 以确保 liveness 工作正常。

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

### 启用双向 TLS 策略

启用双向 TLS 后，我们有两个选项来支持 HTTP 探针：重写探针和单独的端口。

#### Probe rewrite

这种方法重写了应用程序 `PodSpec` liveness 探针, 这样探测请求将被发送给 [Pilot 代理](/docs/reference/commands/pilot-agent/). 然后，Pilot 代理将请求重定向到应用程序，并丢掉响应主体，仅返回响应代码。

要使用这种方法, 你安装 Istio 需要 Helm 的 `sidecarInjectorWebhook.rewriteAppHTTPProbe=true` 选项。
请注意，这是一个全局标志。 **打开它意味着所有 Istio 应用程序部署都将受到影响**。
请注意风险。

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set global.mtls.enabled=true --set sidecarInjectorWebhook.rewriteAppHTTPProbe=true \
    -f install/kubernetes/helm/istio/values.yaml > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

重新部署 liveness 健康检查应用程序。

上面的 Helm 配置使得 sidecar 注入自动重写 Kubernetes pod YAML,
这样健康检查可以在双向 TLS 下工作。无需自行更新您的应用程序或 Pod YAML。

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

默认情况下，此功能目前尚未启用。 我们想[听听您的反馈意见](https://github.com/istio/istio/issues/10357)，我们是否应将其更改为 Istio 安装的默认行为。

#### Separate port

同样，通过添加命名空间范围的身份验证策略和目标规则，为默认命名空间中的服务启用双向 TLS：

1. 要配置身份验证策略，请运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. 要配置目标规则，请运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
      namespace: "default"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

运行这些命令重新部署该 service：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

等待一分钟，然后检查 pod 状态，查看 'RESTARTS' 列为 '0' 以确保 liveness 工作正常。

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
{{< /text >}}

请注意， [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) 中的镜像公开了两个端口：8001 和 8002 ([源代码]({{< github_file >}}/samples/health-check/server.go))。在这个 deployment 中，端口 8001 提供常规通信，而端口 8002 用于 liveness 探针。由于 Istio 代理仅会拦截在 `containerPort` 字段中显式声明的端口，因此，无论 Istio 的双向 TLS 是否启用，到 8002 端口的流量都将绕过 Istio 代理。但是，如果我们将端口 8001 同时用于常规流量和 liveness 探针，在启用双向 TLS 时，由于 http 请求是从 Kubelet 发送的，所以不会将客户端证书发送到 `liveness-http` service，因此健康检查将会失效。
