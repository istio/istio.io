---
title: 服务健康检查
description: 如何对Istio服务进行运行状况检查。
weight: 65
keywords: [security,health-check]
---

此任务说明如何使用[Kubernetes活性和准备探针]（https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/）进行Istio服务的健康检查。

Kubernetes中有三种实时和准备探测选项：

1. Command
1. HTTP 请求
1. TCP 请求

此任务分别为启用和禁用Istio相互TLS的前两个选项提供示例。

## 开始之前

* Understand [Kubernetes liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/), Istio
[authentication policy](/docs/concepts/security/#authentication-policies) and [mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication) concepts.

* Have a Kubernetes cluster with Istio installed, without global mutual TLS enabled (meaning use `istio.yaml` as described in [installation steps](/docs/setup/kubernetes/install/kubernetes/#installation-steps), or set `global.mtls.enabled` to false using [Helm](/docs/setup/kubernetes/install/helm/)).

## Liveness and readiness probes with command option

In this section, you configure health checking when mutual TLS is disabled, then when mutual TLS is enabled.

### Mutual TLS disabled

Run this command to deploy [liveness]({{< github_file >}}/samples/health-check/liveness-command.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

Wait for a minute and check the pod status:

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           1m
{{< /text >}}

The number '0' in the 'RESTARTS' column means liveness probes worked fine. Readiness probes work in the same way and you can modify `liveness-command.yaml` accordingly to try it yourself.

### Mutual TLS enabled

To enable mutual TLS for services in the default namespace, you must configure an authentication policy and a destination rule.
Follow these steps to complete the configuration:

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

运行此命令以重新部署服务：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

重复检查状态命令以验证活动探测是否有效：

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-6857c8775f-zdv9r        2/2       Running   0           4m
{{< /text >}}

### 清理

删除上述步骤中添加的相互TLS策略和相应的目标规则：

1. 要删除相互TLS策略，请运行：

    {{< text bash >}}
    $ kubectl delete policies default
    {{< /text >}}

1. 要删除相应的目标规则，请运行：

    {{< text bash >}}
    $ kubectl delete destinationrules default
    {{< /text >}}

## 具有HTTP请求选项的活动和准备情况探测

本节说明如何使用HTTP请求选项配置运行状况检查。

### Mutual TLS is disabled

Run this command to deploy [liveness-http]({{< github_file >}}/samples/health-check/liveness-http.yaml) in the default namespace:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

Wait for a minute and check the pod status to make sure the liveness probes work with '0' in the 'RESTARTS' column.

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

### Mutual TLS is enabled

When mutual TLS is enabled, we have two options to support HTTP probes: probe rewrites and separate ports.

#### 探针重写

This approach rewrites the application `PodSpec` liveness probe, such that the probe request will be sent to
[Pilot agent](/docs/reference/commands/pilot-agent/). Pilot agent then redirects the
request to application, and strips the response body only returning the response code.

To use this approach, you need to install Istio with Helm option `sidecarInjectorWebhook.rewriteAppHTTPProbe=true`.
Note this is a global flag. **Turning it on means all Istio app deployment will be affected.**
请注意风险。

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set global.mtls.enabled=true --set sidecarInjectorWebhook.rewriteAppHTTPProbe=true \
    -f install/kubernetes/helm/istio/values.yaml > $HOME/istio.yaml
$ kubectl apply -f $HOME/istio.yaml
{{< /text >}}

重新部署活跃健康检查应用程序。

上面的Helm配置使得侧车注入自动重写Kubernetes pod YAML，
这样健康检查可以在相互TLS下工作。无需自行更新您的应用程序或Pod YAML。

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-command.yaml@)
{{< /text >}}

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-975595bb6-5b2z7c   2/2       Running   0           1m
{{< /text >}}

This features is not currently turned on by default. We'd like to [hear your feedback](https://github.com/istio/istio/issues/10357)
on whether we should change this to default behavior for Istio installation.

#### 独立的港口

同样，通过添加命名空间范围的身份验证策略和目标规则，为默认命名空间中的服务启用相互TLS：

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

运行以下命令以重新部署服务：

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/health-check/liveness-http.yaml@)
{{< /text >}}

等待一分钟并检查pod状态以确保活动探测器在“RESTARTS”列中使用“0”。

{{< text bash >}}
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
liveness-http-67d5db65f5-765bb   2/2       Running   0          1m
{{< /text >}}

请注意，[liveness-http]（{{<github_file>}} / samples / health-check / liveness-http.yaml）中的图像公开了两个端口：8001和8002（[源代码]（{{<github_file>}} } /samples/health-check/server.go））。在此部署中，端口8001用于常规流量，而端口8002用于活跃度探测。因为Istio代理仅拦截在`containerPort`字段中显式声明的端口，所以无论是否启用了Istio相互TLS，到8002端口的流量都会绕过Istio代理。但是，如果将端口8001用于常规流量和活动探测，则启用相互TLS时运行状况检查将失败，因为HTTP请求是从Kubelet发送的，而Kubelet不会将客户端证书发送到`liveness-http`服务。
