---
title: 通过 HTTPS 进行双向 TLS
description: 展示如何在 HTTPS 服务上启用双向 TLS。
weight: 80
keywords: [security,mutual-tls,https]
---

这个任务展示了 Istio 双向 TLS 是如何与 HTTPS 服务一起工作的。它包括:

* 在没有 Istio sidecar 的情况下部署 HTTPS 服务

* 关闭 Istio 双向 TLS 认证情况下部署 HTTPS 服务

* 部署一个启动双向 TLS 的 HTTPS 服务。对于每个部署，请连接到此服务并验证其是否有效。

当 Istio sidecar 使用 HTTPS 服务部署时，代理将自动从 L7 降至 L4（无论是否启用了双向 TLS），这就意味着它不会终止原来的 HTTPS 通信。这就是为什么 Istio 可以在 HTTPS 服务上工作。

## 开始之前

按照下面的[快速开始](/zh/docs/setup/kubernetes/install/kubernetes/)设置 Istio。注意，在[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)第5步中，身份验证应该被**禁用**。

### 生成证书和 configmap

您需要安装 openssl 来运行以下命令：

{{< text bash >}}
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
$ kubectl create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
secret "nginxsecret" created
{{< /text >}}

创建用于 HTTPS 服务的 configmap

{{< text bash >}}
$ kubectl create configmap nginxconfigmap --from-file=samples/https/default.conf
configmap "nginxconfigmap" created
{{< /text >}}

## 在没有 Istio sidecar 的情况下部署 HTTPS 服务

本节将创建一个基于 nginx 的 HTTPS 服务。

{{< text bash >}}
$ kubectl apply -f @samples/https/nginx-app.yaml@
service "my-nginx" created
replicationcontroller "my-nginx" created
{{< /text >}}

然后，创建另一个 pod 来调用这个服务。

{{< text bash >}}
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
{{< /text >}}

获取 pods

{{< text bash >}}
$ kubectl get pod
NAME                              READY     STATUS    RESTARTS   AGE
my-nginx-jwwck                    1/1       Running   0          1h
sleep-847544bbfc-d27jg            2/2       Running   0          18h
{{< /text >}}

SSH 进入包含 sleep pod 的 `istio-proxy` 容器。

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

你可以把上面的三个命令合并成一个：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

### 使用 Istio sidecar 和禁用双向 TLS 创建 HTTPS 服务

在"开始之前”部分中，Istio 控制平面被部署在双向 TLS 禁用的情况下。所以您只需要使用 sidecar 重新部署 NGINX HTTPS 服务。

删除这个 HTTPS 服务

{{< text bash >}}
$ kubectl delete -f @samples/https/nginx-app.yaml@
{{< /text >}}

用一个 sidecar 来部署它

{{< text bash >}}
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

确保这个 pod 已经启动并运行

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

如果从 `istio-proxy` 容器运行，它也应该正常运行

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
...
<h1>Welcome to nginx!</h1>
...
{{< /text >}}

{{< tip >}}
这个例子是从 [Kubernetes 的例子](https://github.com/kubernetes/examples/blob/master/staging/https-nginx/README.md)中引用的。
{{< /tip >}}

### 用 Istio sidecar 创建一个 HTTPS 服务，并使用双向 TLS

您需要使用启用了双向 TLS 的 Istio 控制平面。如果您已经安装了 Istio 控制平面，并安装了双向 TLS，请删除它：

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}

等待一切都完成了，也就是说在控制平面名称空间（`istio-system`）中没有 pod。

{{< text bash >}}
$ kubectl get pod -n istio-system
No resources found.
{{< /text >}}

根据[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)安装自定义资源定义。

然后，安装并启用双向 TLS 部署 Istio 控制平面:

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --values install/kubernetes/helm/istio/values-istio-demo.yaml --set global.controlPlaneSecurityEnabled=true --set global.mtls.enabled=true | kubectl apply -f -
{{< /text >}}

确保一切正常运转：

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
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/sleep/sleep.yaml@)
$ kubectl delete -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
$ kubectl apply -f <(bin/istioctl kube-inject -f @samples/https/nginx-app.yaml@)
{{< /text >}}

确保 pod 已启动并正在运行

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

因为工作流"sleep --> sleep-proxy --> nginx-proxy --> nginx”，整个过程是7层流量，在 sleep-proxy 和 nginx-proxy 之间有一个 L4 双向 TLS 加密。在这种情况下，一切都很好。

但是，如果您从 `istio-proxy` 容器运行这个命令，它将无法工作。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
curl: (35) gnutls_handshake() failed: Handshake failed
command terminated with exit code 35
{{< /text >}}

原因是对于工作流"sleep-proxy --> nginx-proxy --> nginx”，nginx-proxy 可以从 sleep-proxy 中获得双向的 TLS 流量。在上面的命令中，sleep-proxy 不提供客户端证书，因此它不会起作用。此外，即使是 sleep-proxy 可以在上面的命令中提供客户端证书，它也不会工作，因为流量会从 nginx-proxy 降级到 nginx。

## 清除

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/https/nginx-app.yaml@
$ kubectl delete configmap nginxconfigmap
$ kubectl delete secret nginxsecret
{{< /text >}}
