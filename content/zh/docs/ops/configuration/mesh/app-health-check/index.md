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
---

众所周知，Kubernetes 有两种健康检查机制：[Liveness 和 Readiness 探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)，并且有三种方式供选择：

1. 命令方式
1. TCP 请求方式
1. HTTP 请求方式

本节将阐述如何在启用了双向 TLS 的 Istio 中使用这三种方式。

注意，无论是否启用了双向 TLS 认证，命令和 TCP 请求方式都可以与 Istio 一起使用。HTTP 请求方式则要求启用了 TLS 的 Istio 使用不同的配置。

## 在学习本节之前{#before-you-begin}

* 理解 Kubernetes 的 [Liveness 和 Readiness 探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)，Istio 的[认证策略](/zh/docs/concepts/security/#authentication-policies)和[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)概念。

* 有一个安装了 Istio 的 Kubernetes 集群，并且未开启全局双向 TLS 认证。

## Liveness 和 Readiness 探针之命令方式{#liveness-and-readiness-probes-with-command-option}

首先，您需要配置健康检查并开启双向 TLS 认证。

要为服务开启双向 TLS 认证，必须配置验证策略和目标规则。
按照以下步骤来完成配置：

运行下面的命令创建命名空间：

{{< text bash >}}
$ kubectl create ns istio-io-health
{{< /text >}}

1. 配置验证策略，并运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "istio-io-health"
    spec:
      peers:
      - mtls: {}
    EOF
    {{< /text >}}

1. 配置目标规则，并运行：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "networking.istio.io/v1alpha3"
    kind: "DestinationRule"
    metadata:
      name: "default"
      namespace: "istio-io-health"
    spec:
      host: "*.default.svc.cluster.local"
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

运行以下命令来部署服务：

{{< text bash >}}
$ kubectl -n istio-io-health apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

重复使用检查状态的命令来验证 Liveness 探针是否正常工作：

{{< text bash >}}
$ kubectl -n istio-io-health get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

## Liveness 和 Readiness 探针之 HTTP 请求方式{#liveness-and-readiness-probes-with-http-request-option}

本部分介绍，当双向 TLS 认证开启的时候，如何使用 HTTP 请求方式来做健康检查。

Kubernetes 的 HTTP 健康检查是由 Kubelet 来发送的， 但是 Istio 并未颁发证书给 `liveness-http` 服务。 因此，当启用双向 TLS 认证之后，所有的健康检查请求将会失败。

有两种方式来解决此问题：探针重写和端口分离。

### 探针重写{#probe-rewrite}

这种方式重写了应用程序的 `PodSpec` Readiness 和 Liveness 探针， 以便将探针请求发送给
[Pilot agent](/zh/docs/reference/commands/pilot-agent/). Pilot agent 将请求重定向到应用程序，剥离 response body ，只返回 response code 。

有两种方式来让 Istio 重写 Liveness 探针。

#### 通过安装参数，全局启用{#enable-globally-via-install-option}

[安装 Istio](/zh/docs/setup/install/istioctl/) 的时候使用 `--set values.sidecarInjectorWebhook.rewriteAppHTTPProbe=true`.

**或者**，更新 Istio sidecar 注入的 map ：

{{< text bash >}}
$ kubectl get cm istio-sidecar-injector -n istio-system -o yaml | sed -e 's/"rewriteAppHTTPProbe":false/"rewriteAppHTTPProbe":true/' | kubectl apply -f -
{{< /text >}}

上面的安装参数和注入的 map ，都指引着 Sidecar 注入过程中自动重写 Kubernetes pod 的 spec，以便让健康检查能够在双向 TLS 认证下正常工作。无需更新应用程序或者 pod 的 spec ：

{{< warning >}}
上面更改的配置 （通过安装参数或注入的 map ）会影响到所有 Istio 应用程序部署。
{{< /warning >}}

#### 对 pod 使用 annotation{#use-annotations-on-pod}

<!-- Add samples YAML or kubectl patch? -->

与安装 Istio 使用的参数方式相似，您也可以使用`sidecar.istio.io/rewriteAppHTTPProbers: "true"`来 [为 pod 添加 annotation](/zh/docs/reference/config/annotations/) 。确保 annotation 成功添加到了 [pod 资源](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) 因为在其他地方（比如封闭的部署资源上）， annotation 会被忽略。

{{< text yaml >}}
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
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
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
{{< /text >}}

这种方式可以使得在每个部署的应用上逐个启用健康检查并重写探针，而无需重新安装 Istio 。

#### 重新部署需要 Liveness 健康检查的应用程序{#re-deploy-the-liveness-health-check-app}

以下的说明假定您通过安装选项全局启用了该功能，Annotation 同样奏效。

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http-same-port.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http-same-port.yaml@)
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

默认情况下未启用此功能。 我们希望[收到您的反馈](https://github.com/istio/istio/issues/10357)，
是否应将其更改为 Istio 安装过程中的默认行为。

### 端口分离{#separate-port}

另一种方式是使用单独的端口来进行运行状态检查和常规流量检查。

运行下面的命令，重新部署服务：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

稍等片刻，检查 pod 状态，确认 Liveness 探针在 'RESTARTS' 列的工作状态是 '0' 。

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
{{< /text >}}

请注意，[liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) 的镜像公开了两个端口：8001 和 8002 ([源码]({{< github_file >}}/samples/health-check/server.go))。在这个部署方式里面，端口 8001 用于常规流量，而端口 8002 给 Liveness 探针使用。

### 清除{#cleanup}

请按照如下操作删除上述步骤中添加的双向 TLS 策略和相应的目标规则：

{{< text bash >}}
$ kubectl delete policies default
$ kubectl delete destinationrules default
$ kubectl delete ns istio-io-health
{{< /text >}}
