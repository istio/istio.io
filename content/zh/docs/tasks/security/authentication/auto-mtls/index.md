---
title: 自动双向 TLS
description: 通过一个简化的工作流和最小化配置实现双向 TLS。
weight: 10
keywords: [security,mtls,ux]
---

本任务通过一个简化的工作流，展示如何使用双向 TLS。

借助 Istio 的自动双向 TLS 特性，您只需配置认证策略即可使用双向 TLS，而无需关注目标规则。

Istio 跟踪迁移到 sidecar 的服务端工作负载，并将客户端 sidecar 配置为自动向这些工作负载发送双向 TLS 流量，
同时将明文流量发送到没有 sidecar 的工作负载。这使您可以通过最少的配置，逐步在网格中使用双向 TLS。

## 开始之前{#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies) 和关于
[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication) 章节的内容。

* 安装 Istio 时，配置 `global.mtls.enabled` 选项为 false，`global.mtls.auto` 选项为 true。
以安装 `demo` 配置文件为例：

{{< text bash >}}
$ istioctl manifest apply --set profile=demo \
  --set values.global.mtls.auto=true \
  --set values.global.mtls.enabled=false
{{< /text >}}

## 操作指南{#instructions}

### 安装{#setup}

本例中，我们部署 `httpbin` 服务到 `full`、`partial` 和 `legacy` 三个命名空间中，分别
代表 Istio 迁移的不同阶段。

命名空间 `full` 包含已完成 Istio 迁移的所有服务器工作负载。
每一个部署都有 Sidecar 注入。

{{< text bash >}}
$ kubectl create ns full
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n full
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n full
{{< /text >}}

命名空间 `partial` 包含部分迁移到 Istio 的服务器工作负载。
只有完成迁移的服务器工作负载（由于已注入 Sidecar）能够使用双向 TLS 流量。

{{< text bash >}}
$ kubectl create ns partial
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n partial
$ cat <<EOF | kubectl apply -n partial -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin-nosidecar
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
  template:
    metadata:
      labels:
        app: httpbin
        version: nosidecar
    spec:
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
{{< /text >}}

命名空间 `legacy` 中的工作负载，都没有注入 Sidecar。

{{< text bash >}}
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

接着，我们部署两个 `sleep` 工作负载，一个有 Sidecar，另一个没有。

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n full
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

您可以确认在所有命名空间部署完成。

{{< text bash >}}
$ kubectl get pods -n full
$ kubectl get pods -n partial
$ kubectl get pods -n legacy
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-dcd949489-5cndk   2/2     Running   0          39s
sleep-58d6644d44-gb55j    2/2     Running   0          38s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-6f6fc94fb6-8d62h   1/1     Running   0          10s
httpbin-dcd949489-5fsbs    2/2     Running   0          12s
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-54f5bb4957-lzxlg   1/1     Running   0          6s
sleep-74564b477b-vb6h4     1/1     Running   0          4s
{{< /text >}}

您还需验证系统中是否存在默认的网格验证策略，可以参考下面操作：

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
$ kubectl get meshpolicies -o yaml | grep ' mode'
NAMESPACE      NAME                          AGE
istio-system   grafana-ports-mtls-disabled   2h
        mode: PERMISSIVE
{{< /text >}}

最后但并非最不重要的一点是，确认没有应用于示例服务的目标规则。
您可以通过检查已有目标规则的 `host:` 字段，并确保它们没有匹配我们的示例服务。例如：

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    host: istio-policy.istio-system.svc.cluster.local
    host: istio-telemetry.istio-system.svc.cluster.local
{{< /text >}}

您可通过使用 `curl` 从命名空间 `full`、`partial` 或 `legacy` 中的任一 `sleep` Pod 发送 HTTP 请求到 `httpbin.full`、`httpbin.partial` 或 `httpbin.legacy` 以验证安装。
所有的请求都应成功返回 HTTP 200 状态码。

例如，这是一个检查 `sleep.full` 到 `httpbin.full` 可达性的命令：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -n full -- curl http://httpbin.full:8000/headers  -s  -w "response %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$'
URI=spiffe://cluster.local/ns/full/sa/sleep
response 200
{{< /text >}}

SPIFFE URI 显示来自 X509 证书的客户端标识，它表明流量是在双向 TLS 中发送的。
如果流量为明文，将不会显示客户端证书。

### 从 PERMISSIVE 模式开始{#start-from-permissive-mode}

这里，我们从开启网格服务双向 TLS 的 `PERMISSIVE` 模式开始。

1. 所有的 `httpbin.full` 工作负载以及在 `httpbin.partial` 中使用了 Sidecar 的工作负载都能够使用双向 TLS 和明文流量。

1. 命名空间 `httpbin.partial` 中没有 Sidecar 的服务和 `httpbin.legacy` 中的服务都只能使用明文流量。

自动双向 TLS 将客户端和 `sleep.full` 配置为可将双向 TLS 流量发送到具有 Sidecar 的工作负载，明文流量发送到没有 Sidecar 的工作负载。

您可以通过以下方式验证可达性：

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### 使用 Sidecar 迁移{#working-with-Sidecar-Migration}

无论工作负载是否带有 Sidecar，对 `httpbin.partial` 的请求都可以到达。
Istio 自动将 `sleep.full` 客户端配置为使用双向 TLS 连接带有 Sidecar 的工作负载。

{{< text bash >}}
$ for i in `seq 1 10`; do kubectl exec $(kubectl get pod -l app=sleep -n full -o jsonpath={.items..metadata.name}) -c sleep -nfull  -- curl http://httpbin.partial:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

response code: 200

response code: 200
{{< /text >}}

如果不使用自动双向 TLS，您必须跟踪 Sidecar 迁移完成情况，然后显式的配置目标规则，使客户端发送双向 TLS 流量到 `httpbin.full`。

### 锁定双向 TLS 为 STRICT 模式{#lock-down-mutual-TLS-to-STRICT}

您可配置认证策略为 `STRICT`，以锁定 `httpbin.full` 服务仅接收双向 TLS 流量。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
  peers:
  - mtls: {}
EOF
{{< /text >}}

All `httpbin.full` workloads and the workload with sidecar for `httpbin.partial` can only serve
mutual TLS traffic.

所有 `httpbin.full` 工作负载和带有 Sidecar 的 `httpbin.partial` 都只可使用双向 TLS 流量。

现在来自 `sleep.legacy` 的请求将开始失败，因为其不支持发送双向 TLS 流量。
但是客户端 `sleep.full` 的请求将仍可成功返回 200 状态码，因为它已配置为自动双向 TLS，并且发送双向 TLS 请求。

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 000
command terminated with exit code 56

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### 禁用双向 TLS 以启用明文传输{#disable-mutual-TLS-to-plain-text}

如果出于某种原因，您希望服务显式地处于明文模式，则可以将身份验证策略配置为明文。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "httpbin"
spec:
  targets:
  - name: httpbin
EOF
{{< /text >}}

在这种情况下，由于服务处于纯文本模式。Istio 自动配置客户端 Sidecar 发送明文流量以避免错误。

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
response code: 200

sleep.full to httpbin.partial
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200
{{< /text >}}

现在，所有流量都可以明文传输。

### 重写目标规则{#destination-rule-overrides}

为了向后兼容，您仍然可以像以前一样使用目标规则来覆盖 TLS 配置。当目标规则具有显式 TLS 配置时，它将覆盖 Sidecar 客户端的 TLS 配置。

例如，您可以显式的为 `httpbin.full` 配置目标规则，以显式启用或禁用双向 TLS。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n full -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "httpbin-full-mtls"
spec:
  host: httpbin.full.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
EOF
{{< /text >}}

由于在前面的步骤中，我们已经禁用了 `httpbin.full` 的身份验证策略，以禁用双向TLS，现在应该看到来自 `sleep.full` 的流量开始失败。

{{< text bash >}}
$ for from in "full" "legacy"; do for to in "full" "partial" "legacy"; do echo "sleep.${from} to httpbin.${to}";kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/headers  -s  -w "response code: %{http_code}\n" | egrep -o 'URI\=spiffe.*sa/[a-z]*|response.*$';  echo -n "\n"; done; done
sleep.full to httpbin.full
response code: 503

sleep.full to httpbin.partial
URI=spiffe://cluster.local/ns/full/sa/sleep
response code: 200

sleep.full to httpbin.legacy
response code: 200

sleep.legacy to httpbin.full
response code: 200

sleep.legacy to httpbin.partial
response code: 200

sleep.legacy to httpbin.legacy
response code: 200

{{< /text >}}

### 清理{#cleanup}

{{< text bash >}}
$ kubectl delete ns full partial legacy
{{< /text >}}

## 摘要{#summary}

自动双向 TLS 配置 Sidecar 客户端默认情况下在 Sidecar 之间发送 TLS 流量。您只需要配置身份验证策略。

如前所述，自动双向 TLS 是网格 Helm 安装选项。您必须重新安装 Istio 才能启用或禁用该功能。
当此功能被禁用，如果您已经依靠它来自动加密流量，则流量可以**回退到纯明文**模式，
这可能会影响您的**安全状态或中断流量**（如果该服务已配置为 `STRICT` 模式以仅接收双向 TLS 流量）。

当前，自动双向 TLS 还处于 Alpha 阶段，请注意其风险以及 TLS 加密的额外 CPU 成本。

我们正在考虑将此功能设置为默认启用。当您使用自动双向 TLS 时，请考虑通过 GitHub 发送您的反馈或遇到的问题。
