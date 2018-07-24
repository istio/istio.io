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

* 了解 [Kubernetes liveness 和 readiness 探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)，Istio [认证策略](/docs/concepts/security/#authentication-policies)和[双向 TLS 认证](/docs/concepts/security/#mutual-tls-authentication)的概念。

* 具有一个安装了 Istio 的 Kubernetes 集群，但没有启用全局双向 TLS（例如按照 [安装步骤](/docs/setup/kubernetes/quick-start/#installation-steps) 中的描述使用 istio-demo.yaml，或者在使用 [Helm](/docs/setup/kubernetes/helm-install/) 时将 `global.mtls.enabled` 设置为 false）。

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

运行此命令以在默认 namespace 中启用 service 的双向 TLS。

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
{{< /text >}}

运行此命令重新部署该 service：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

并重复上一小节中的相同步骤以验证 liveness 探针是否工作正常。

## 使用 http 请求选项的 liveness 和 readiness 探针

本节介绍了如何使用 HTTP 请求选项配置健康检查。

### 禁用双向 TLS 策略

运行此命令删除双向 TLS 策略。

{{< text bash >}}
$ cat <<EOF | istioctl delete -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
  - mtls:
EOF
{{< /text >}}

运行此命令以在默认 namespace 中部署 [liveness]({{< github_file >}}/samples/health-check/liveness-http.yaml)：

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

运行此命令以在默认 namespace 中启用 service 的双向 TLS。

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "example-1"
  namespace: "default"
spec:
  peers:
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
