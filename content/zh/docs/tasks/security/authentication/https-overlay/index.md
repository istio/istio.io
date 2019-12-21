---
title: 通过 HTTPS 进行 TLS
description: 展示如何在 HTTPS 服务上启用双向 TLS。
weight: 30
keywords: [security,mutual-tls,https]
aliases:
    - /zh/docs/tasks/security/https-overlay/
---

这个任务展示了双向 TLS 是如何与 HTTPS 服务一起工作的。它包括：

* 在没有 Istio sidecar 的情况下部署 HTTPS 服务

* 关闭 Istio 双向 TLS 情况下部署 HTTPS 服务

* 部署一个启用双向 TLS 的 HTTPS 服务。对于每个部署，连接到此服务并验证其是否有效。

当 Istio sidecar 与 HTTPS 服务一起部署时，代理将自动从 L7 降至 L4（无论是否启用了双向 TLS），这就意味着它不会终止原来的 HTTPS 通信。这就是为什么 Istio 可以对 HTTPS 服务产生作用。

## 开始之前{#before-you-begin}

按照[快速开始](/zh/docs/setup/getting-started/)中的说明设置 Istio。
请注意，当使用 `demo` 配置文件安装 Istio 时，应该**禁用**默认的双向 TLS 认证。

该演示还假定在一个禁用了自动 sidecar 注入的命名空间中运行，并且使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 手动注入 Istio sidecars。

### 生成证书和 configmap{#generate-certificates-and-configmap}

下面的例子考虑实现一个可以使用 HTTPS 加密流量的 NGINX 服务 pod。
在开始之前，先生成该服务后面会用到的 TLS 证书和密钥。

您需要安装 openssl 来运行如下命令：

{{< text bash >}}
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
$ kubectl create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
secret "nginxsecret" created
{{< /text >}}

创建一个该 HTTPS 服务所要用的 configmap

{{< text bash >}}
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
configmap "nginxconfigmap" created
{{< /text >}}

## 部署一个没有 Istio sidecar 的 HTTPS 服务{#deploy-an-HTTPS-service-without-the-Istio-sidecar}

本节创建一个基于 NGINX 的 HTTPS 服务。

{{< text bash >}}
$ kubectl apply -f @samples/https/nginx-app.yaml@
service "my-nginx" created
replicationcontroller "my-nginx" created
{{< /text >}}

然后，创建另一个 pod 来调用该服务。

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
{{< /text >}}

获取 pods

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    1/1       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

通过 ssh 进入 sleep pod 的 `istio-proxy` 容器。

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy /bin/bash
{{< /text >}}

调用 my-nginx

{{< text bash >}}
$ curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

其实，您可以将上述三个命令合并为一个：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

### 创建一个有 Istio sidecar 但禁用双向 TLS 的 HTTPS 服务{#create-an-HTTPS-service-with-the-Istio-sidecar-and-mutual-TLS-disabled}

在“开始之前”小节中，部署了一个禁用了双向 TLS 的 Istio 控制平面。
因此您只需带着 sidecar 重新部署 NGINX HTTPS 服务。

删除 HTTPS 服务。

{{< text bash >}}
$ kubectl delete -f @samples/https/nginx-app.yaml@
{{< /text >}}

与 sidecar 一起部署

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

确保该 pod 已经启动且正在运行

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-6svcc                    2/2       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

运行

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

如果您从 `istio-proxy` 容器运行，它应该也会正常运行：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

{{< tip >}}
该例子来自 [Kubernetes 示例](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md)。
{{< /tip >}}

### 创建一个有 Istio sidecar 并启用双向 TLS 的 HTTPS 服务{#create-an-HTTPS-service-with-Istio-sidecar-with-mutual-TLS-enabled}

您需要部署 Istio 控制平面并启用双向 TLS。
如果您已经安装了一个禁用双向 TLS 的 Istio 控制平面，请删除它。
例如，如果您按照入门中的指引：

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}

并且等所有内容都被删除，也就是说，在控制平面命名空间（`istio-system`）中已经没有 pod 了：

{{< text bash >}}
$ kubectl get pod -n istio-system
No resources found.
{{< /text >}}

安装 Istio 并启用**严格双向 TLS 模式**：

{{< text bash >}}
$ istioctl manifest apply --set profile=demo,values.global.controlPlaneSecurityEnabled=true,values.global.mtls.enabled=true
{{< /text >}}

确保所有内容都启动且正在运行：

{{< text bash >}}
$ kubectl get po -n istio-system
NAME                                       READY     STATUS      RESTARTS   AGE
grafana-6f6dff9986-r6xnq                   1/1       Running     0          23h
istio-citadel-599f7cbd46-85mtq             1/1       Running     0          1h
istio-cleanup-old-ca-mcq94                 0/1       Completed   0          23h
istio-egressgateway-78dd788b6d-jfcq5       1/1       Running     0          23h
istio-ingressgateway-7dd84b68d6-dxf28      1/1       Running     0          23h
istio-mixer-post-install-g8n9d             0/1       Completed   0          23h
istio-pilot-d5bbc5c59-6lws4                2/2       Running     0          23h
istio-policy-64595c6fff-svs6v              2/2       Running     0          23h
istio-sidecar-injector-645c89bc64-h2dnx    1/1       Running     0          23h
istio-statsd-prom-bridge-949999c4c-mv8qt   1/1       Running     0          23h
istio-telemetry-cfb674b6c-rgdhb            2/2       Running     0          23h
istio-tracing-754cdfd695-wqwr4             1/1       Running     0          23h
prometheus-86cb6dd77c-ntw88                1/1       Running     0          23h
{{< /text >}}

然后重新部署 HTTPS 服务和 sleep 服务

{{< text bash >}}
$ kubectl delete -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl delete -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
$ kubectl apply -f <(istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

确保该 pod 已经启动且正在运行

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-9dvet                    2/2       Running   0          1h
sleep-77f457bfdd-hdknx            2/2       Running   0          18h
{{< /text >}}

运行

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

原因在于，对于工作流 "sleep -> `sleep-proxy` -> `nginx-proxy` -> nginx"，整个流程是 L7 流，而在 `sleep-proxy` 和 `nginx-proxy` 之间存在一个 L4 的双向 TLS 加密。
在这种情况下，一切都运行正常。

但是，如果您在 `istio-proxy` 容器中运行整个命令，它将不起作用：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
curl: (35) gnutls_handshake() failed: Handshake failed
command terminated with exit code 35
{{< /text >}}

这个是因为对于工作流 "sleep-proxy -> nginx-proxy -> nginx"，nginx-proxy 期望的是来自 sleep-proxy 的双向 TLS 流量。
在上面的命令中，sleep-proxy 并未提供客户端证书。因此，它无法正常运行。
而且，就算 sleep-proxy 提供了客户端证书，它也无法正常运行，因为从 nginx-proxy 到 nginx 时，流量会降为 http。

## 清理{#cleanup}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/https/nginx-app.yaml@
$ kubectl delete configmap nginxconfigmap
$ kubectl delete secret nginxsecret
{{< /text >}}
