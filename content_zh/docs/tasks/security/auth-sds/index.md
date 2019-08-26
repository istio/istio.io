---
title: 通过 SDS 提供身份服务
description: 展示启用 SDS 来为 Istio 提供身份服务的过程。
weight: 70
keywords: [security,auth-sds]
---

该任务展示了启用 [SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#config-secret-discovery-service) 来为 Istio 提供身份服务的过程。

Istio 1.1 之前，Istio 为工作负载提供的密钥和证书是由 Citadel 生成并使用加载 Secret 卷的方式分发给 Sidecar 的，这种方式有几大缺陷：

* 证书轮换造成的性能损失：
    证书发生轮换时，Envoy 会进行热重启以加载新的证书和密钥，会造成性能下降。

* 潜在的安全漏洞：
    工作负载的私钥使用 Kubernetes Secret 的方式进行分发，存在一定[风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)。

在 Istio 1.1 之中，上述问题可以使用 SDS 来解决。下面描述了它的工作流程：

1. 工作负载的 Sidecar 从 Citadel 代理中请求密钥和证书：Citadel 代理是一个 SDS 服务器，这一代理以 `DaemonSet` 的形式在每个节点上运行，在这一请求中，Envoy 把 Kubernetes service account 的 JWT 传递给 Citadel 代理。

1. Citadel 代理生成密钥对，并向 Citadel 发送 CSR 请求：
    Citadel 校验 JWT，并给 Citadel 代理签发证书。

1. Citadel 代理把密钥和证书返回给工作负载的 Sidecar。

这种方法有如下好处：

* 私钥不会离开节点：私钥仅存在于 Citadel 代理和 Envoy Sidecar 的内存中。

* 不再需要加载 Secret 卷：去掉对 Kubernetes Secret 的依赖。

* Sidecar 能够利用 SDS API 动态的刷新密钥和证书：证书轮换过程不再需要重启 Envoy。

## 开始之前 {#before-you-begin}

* 使用 [Helm](/zh/docs/setup/kubernetes/install/helm/) 安装 Istio，并启用 SDS 和全局的双向 TLS：

    {{< text bash >}}
    $ cat install/kubernetes/namespace.yaml > istio-auth-sds.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth-sds.yaml
    $ helm dep update --skip-refresh install/kubernetes/helm/istio
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --values @install/kubernetes/helm/istio/values-istio-sds-auth.yaml@ >> istio-auth-sds.yaml
    $ kubectl create -f istio-auth-sds.yaml
    {{< /text >}}

## 通过 SDS 提供的密钥和证书支持服务间的双向 TLS {#sds-mutual}

参考[认证策略任务](/zh/docs/tasks/security/authn-policy/)中的内容，部署测试服务。

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
{{< /text >}}

验证双向 TLS 请求是否成功：

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

## 验证：没有通过加载 Secret 卷的方式生成的文件 {#no-secret-volume}

要验证是否有通过加载 Secret 卷的方式生成的文件，可以访问工作负载的 Sidecar 容器：

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

这里会看到，在 `/etc/certs` 文件夹中没有加载 Secret 卷生成的文件。

## 清理 {#cleanup}

清理测试服务以及 Istio 控制面：

{{< text bash >}}
$ kubectl delete ns foo
$ kubectl delete ns bar
$ kubectl delete -f istio-auth-sds.yaml
{{< /text >}}

## 注意事项 {#caveats}

目前 SDS 的身份服务有几点需要注意的地方：

* 要启用控制面加密，还需要加载 Secret 卷。控制面的 SDS 支持还在开发之中。

* 从 Secret 卷到 SDS 的平滑迁移过程，也还在开发之中。
