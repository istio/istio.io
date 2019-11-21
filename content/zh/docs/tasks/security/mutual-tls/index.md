---
title: 深入了解双向 TLS
description: 对 Istio 双向 TLS 认证功能进行体验和测试。
weight: 10
keywords: [security,mutual-tls]
---

通过本任务，你可以进一步了解双向 TLS 以及如何配置。本任务假设：

* 您已经完成[认证策略](/zh/docs/tasks/security/authn-policy/) 任务.
* 您熟悉如何通过认证策略开启双向 TLS。
* Istio 在 Kubernetes 上运行，并且开启全局双向 TLS。可以参考 [Istio 安装说明文档](/zh/docs/setup/)。
如果已经安装 Istio，可以根据[为所有服务启用双向 TLS 认证](/zh/docs/tasks/security/authn-policy/#globally-enabling-istio-mutual-tls) 任务中说明，通过增加或者修改认证策略和目的规则来开启双向 TLS。
* [httpbin]({{< github_tree >}}/samples/httpbin) 和 [sleep]({{< github_tree >}}/samples/sleep) 已经部署在了 `default` namespace，并且这两个应用带有 Envoy sidecar. 例如，可以通过以下命令[手动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection) 来完成服务的部署:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

## 检查 Citadel 是否运行正常{#verify-citadel-runs-properly}

[Citadel](/zh/docs/concepts/security/#PKI) 是Istio 的密钥管理服务，它必须正常运行才能使双向 TLS 正常工作。
使用以下命令验证 Citadel 在集群中是否正确运行：

{{< text bash >}}
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
{{< /text >}}

如果 "AVAILABLE" 列值为 1，则说明 Citadel 已经成功运行。

## 校验密钥和证书的安装情况{#verify-keys-and-certificates-installation}

Istio 会为所有的 sidecar 容器自动安装双向 TLS 认证所必要的密钥和证书。运行以下命令，确认 `/etc/certs` 目录下存在密钥和证书文件：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- ls /etc/certs
cert-chain.pem
key.pem
root-cert.pem
{{< /text >}}

{{< tip >}}
`cert-chain.pem` 是 Envoy 的证书，会在需要的时候提供给对端。而 `key.pem` 就是 Envoy 的私钥，和 `cert-chain.pem` 中的证书相匹配。`root-cert.pem` 是用于证书校验的根证书。这个例子中，我们集群中只部署了一个 Citadel，所以所有的 Envoy 共用同一个 `root-cert.pem`。
{{< /tip >}}

使用 `openssl` 工具来检查证书的有效性（当前时间应该介于 `Not Before` 和 `Not After` 之间）

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep Validity -A 2
Validity
        Not Before: May 17 23:02:11 2018 GMT
        Not After : Aug 15 23:02:11 2018 GMT
{{< /text >}}

也可以检查客户端证书的**身份**标示（SAN）：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
        X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/default/sa/default
{{< /text >}}

请参阅 [Istio 认证](/zh/docs/concepts/security/#istio-identity) 一节，可以了解更多**服务身份**方面的内容。

## 验证双向 TLS 配置{#verify-mutual-TLS-configuration}

您可以按照 [`istioctl 检查 TLS 认证`](/zh/docs/reference/commands/istioctl/#istioctl-authn-tls-check) 检查双向 TLS 设置是否有效。`istioctl` 命令需要知道客户端 pod 名称，因为目标规则依赖客户端的 namespace。
您也可以根据目标服务过滤只显示该服务的状态。

{{< tip >}}
这个工具只能检查目标规则与认证策略之间 TLS 设置的一致性，它并不能用于判断对应的负载中是否存在 sidecar。如果不存在 sidecar，认证策略和目标规则没有被执行，状态 `CONFLICT` 并不意味着流量被破坏。
{{< /tip >}}

下面的命令验证针对同一个`sleep` 应用 pod，`httpbin.default.svc.cluster.local` 服务的认证策略与目标规则相一致。

{{< text bash >}}
$ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ istioctl authn tls-check ${SLEEP_POD} httpbin.default.svc.cluster.local
{{< /text >}}

在以下示例输出中，您可以看到：

* 在 8080 端口上始终为 `httpbin.default.svc.cluster.local` 设置双向 TLS。
* Istio 使用网格范围的 `default` 身份验证策略。
* Istio 在 `istio-system` 命名空间中有 `default` 目的地规则。

{{< text plain >}}
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         mTLS       mTLS       /default            istio-system/default
{{< /text >}}

输出显示：

* `STATUS`：本例中的 `httpbin` 服务和调用 `httpbin` 的客户端之间的 TLS 设置是否一致。

* `SERVER`：服务器上使用的模式。

* `CLIENT`：所有客户端使用的模式。

* `AUTHN POLICY`：身份验证策略的名称和命名空间。如果策略是网格范围的策略，则命名空间为空，如本例所示：`default/`

* `DESTINATION RULE`：使用的目标规则的名称和名称空间。

为了说明存在冲突的场景，为具有错误 TLS 模式的 `httpbin` 添加特定的服务目标规则：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "bad-rule"
  namespace: "default"
spec:
  host: "httpbin.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
{{< /text >}}

运行与上面相同的 `istioctl` 命令，您现在看到状态为 `CONFLICT` ，因为客户端处于 `HTTP` 模式，而服务器处于 `mTLS` 。

{{< text bash >}}
$ istioctl authn tls-check ${SLEEP_POD} httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS       SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     CONFLICT     mTLS       HTTP       /default            default/bad-rule
{{< /text >}}

您还可以确认从 `sleep` 到 `httpbin` 的请求现在已失败：

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
503
{{< /text >}}

在继续之前，请使用以下命令删除错误的目标规则以使双向 TLS 再次起作用：

{{< text bash >}}
$ kubectl delete destinationrule --ignore-not-found=true bad-rule
{{< /text >}}

## 验证请求{#verify-requests}

此任务演示已启用双向 TLS 的服务器如何对以下请求响应：

* 使用明文请求中（即 HTTP 请求）
* 使用 TLS 但没有客户端证书
* 使用 TLS 和客户端证书

要执行此任务，您需要绕过客户端代理。最简单的方法是从 `istio-proxy` 容器发出请求。

1. 确认执行下面明文请求失败，因为调用 `httpbin` 服务需要 TLS 认证：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl http://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    {{< /text >}}

    {{< tip >}}
    请注意，退出代码为 56，代表无法接收网络数据。
    {{< /tip >}}

1. 确认没有客户端证书的 TLS 请求也会失败：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' -k
    000
    command terminated with exit code 35
    {{< /text >}}

    {{< tip >}}
    这次，退出代码为 35，这对应于 SSL/TLS 握手中某处发生的问题。
    {{< /tip >}}

1. 确认使用客户端证书的 TLS 请求成功：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
    200
    {{< /text >}}

{{< tip >}}
Istio 使用 [Kubernetes Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 作为服务标识，
提供比服务名称更强的安全性（有关更多详细信息，请参阅 [Istio 身份](/zh/docs/concepts/security/#istio-identity)）。因此，Istio 使用的证书没有注明服务名称，
但是 `curl` 需要利用这些信息验证服务器的身份。为了防止 `curl` 客户端报错，我们使用 `curl` 的 `-k` 参数。该参数可跳过客户端对服务器名称的验证，
例如，`httpbin.default.svc.cluster.local` 服务器提供的证书。
{{< /tip >}}

## 清理{#cleanup}

{{< text bash >}}
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
$ kubectl delete --ignore-not-found=true -f @samples/sleep/sleep.yaml@
{{< /text >}}
