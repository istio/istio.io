---
title: 测试双向 TLS
description: 对 Istio 的自动双向 TLS 认证功能进行体验和测试。
weight: 10
keywords: [安全,双向 TLS]
---

通过本任务，将学习如何：

* 验证 Istio 双向 TLS 认证配置
* 手动对认证功能进行测试

## 开始之前

本任务假设已有一个 Kubernetes 集群：

* 安装启用全局双向 TLS 认证功能的 Istio：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

    _**或者**_

    使用 [Helm](/zh/docs/setup/kubernetes/helm-install/) 进行安装，设置 `global.mtls.enabled` 为 `true`.

> 从 Istio 0.7 开始，可以使用[认证策略](/zh/docs/concepts/security/#认证策略)来给命名空间中全部/部分服务配置双向 TLS 功能。（在所有命名空间中重复此操作，就相当于全局配置了）。这部分内容可参考[认证策略任务](/zh/docs/tasks/security/authn-policy/)

* 接下来进行演示应用的部署，首先是注入 Envoy sidecar 的 [httpbin](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/httpbin) 以及 [sleep](https://github.com/istio/istio/tree/master/samples/sleep)。为简单起见，我们将演示应用安装到 `default` 命名空间。如果想要部署到其他命名空间，可以在下一节的示例命令中加入 `-n yournamespace`。

    如果使用的是[手工 Sidecar 注入](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)，可使用如下命令：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    如果集群设置了[自动注入 Sidecar](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)，就只需要简单的使用 `kubectl` 就可以完成部署了。

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

## 检查 Istio 双向 TLS 认证的配置

### 检查 Citadel

检查集群内是否运行了 Citadel：

{{< text bash >}}
$ kubectl get deploy -l istio=citadel -n istio-system
NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel   1         1         1            1           1m
{{< /text >}}

如果 "AVAILABLE" 列值为 1，则说明 Citadel 已经成功运行。

### 检查服务配置

* 检查安装模式。如果缺省启用了双向 TLS（也就是在安装 Istio 的时候使用了 `istio-demo-auth.yaml`），会在 Configmap 中看到未被注释的 `authPolicy: MUTUAL_TLS` 一行：

    {{< text bash >}}
    $ kubectl get configmap istio -o yaml -n istio-system | grep authPolicy | head -1
    {{< /text >}}

* 检查认证策略。双向 TLS 的策略还能够以服务为单位进行启用（或停用）。如果存在仅对部分服务生效的策略，那么这部分服务原有的来自 Configmap 的策略就会被覆盖。不幸的是，目前没有快速的方法能够方便的获取某个服务的对应策略，只能在命名空间内获取所有策略。

    {{< text bash >}}
    $ kubectl get policies.authentication.istio.io -n default -o yaml
    {{< /text >}}

* 检查目标规则。从 Istio 0.8 开始，会使用目标规则的[流量策略](/docs/reference/config/istio.networking.v1alpha3/#TrafficPolicy)来对客户端进行配置，决定是否使用双向 TLS。为了向后兼容，**缺省**流量策略来自 Configmap 中的标志（也就是说，如果设置了 `authPolicy: MUTUAL_TLS`，那么**缺省**流量策略也会是 `MUTUAL_TLS` ）。如果使用针对部分服务的认证策略覆盖了原有配置，那么就要通过目标规则来实现了。跟认证策略类似，验证这一设置的方法也是需要通过获取全部规则的方式来进行：

    {{< text bash >}}
    $ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml
    {{< /text >}}

    > 注意目标规则的范围不仅限于单一命名空间，所以需要验证所有命名空间的规则。

### 校验密钥和证书的安装情况

为了完成双向 TLS 认证功能，Istio 会自动在所有 Sidecar 容器中安装必要的密钥和证书。

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- ls /etc/certs
cert-chain.pem
key.pem
root-cert.pem
{{< /text >}}

> `cert-chain.pem` 是 Envoy 的证书，会在需要的时候提供给对端。而 `key.pem` 就是 Envoy 的私钥，和 `cert-chain.pem` 中的证书相匹配。`root-cert.pem` 是用于证书校验的根证书。这个例子中，我们集群中只部署了一个 Citadel，所以所有的 Envoy 共用同一个 `root-cert.pem`。

是用 `openssl` 工具来检查证书的有效性（当前时间应该处于 `Not Before` 和 `Not After` 之间）

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep Validity -A 2
Validity
        Not Before: May 17 23:02:11 2018 GMT
        Not After : Aug 15 23:02:11 2018 GMT
{{< /text >}}

还可以查看一下客户端证书的 SAN（Subject Alternative Name）

{{< text bash >}}
$ kubectl exec $(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name}) -c istio-proxy -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
        X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/default/sa/default
{{< /text >}}

请参阅 [Istio 认证](/zh/docs/concepts/security/#认证) 一节，可以了解更多**服务认证**方面的内容。

## 测试认证配置

假设双向 TLS 认证正确启用，在两个注入了 Envoy sidecar 的服务之间的通信应该不会受到影响。然而如果从没有注入 Sidecar 的 Pod 发起连接，或者直接从 Sidecar 发起没有指定客户端证书的连接，就无法访问服务了。下面的例子就演示了这种情况：

1. 从 `sleep` 容器访问 `httpbin` 服务应该可以成功（返回 `200`）

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    200
    {{< /text >}}

1. 如果从 `sleep` 的 `proxy` 容器中访问 `httpbin` 服务，就会导致失败

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 77
    {{< /text >}}

1. 接下来，如果请求中提供了客户端证书，那么这次请求就会成功

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://httpbin:8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
    200
    {{< /text >}}

    > Istio 使用 [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 作为服务的认证基础，Service account 提供了比服务名称更强的安全性（参考 [Identity](/zh/docs/concepts/security/#认证) 获取更多信息）。Istio 中使用的证书不包含服务名，而 `curl` 需要用这个信息来检查服务认证。因此就需要给 `curl` 命令加上 `-k` 参数，在对服务器所出示的证书校验的时候，停止对服务器名称（例如 httpbin.ns.svc.cluster.local ）的验证。

1. 来自没有 Sidecar 的 Pod。可以重新部署另外一个 `sleep` 应用

    {{< text bash >}}
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
    {{< /text >}}

1. 等待 Pod 状态变为 `Running`，在其中发起类似的 `curl` 命令。由于这个 Pod 没有 Sidecar 协助完成 TLS 通信，因此这一请求会失败。

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n legacy) -c sleep -n legacy -- curl httpbin.default:8000/headers -o /dev/null -s -w '%{http_code}\n'
    000
    command terminated with exit code 56
    {{< /text >}}

## 清理

{{< text bash >}}
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
$ kubectl delete --ignore-not-found=true -f @samples/sleep/sleep.yaml@
$ kubectl delete --ignore-not-found=true ns legacy
{{< /text >}}
