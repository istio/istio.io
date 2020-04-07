---
title: 插入外部 CA 证书
description: 演示系统管理员如何使用现有的根证书、签名证书和密钥配置 Istio 的 CA。
weight: 80
keywords: [security,certificates]
aliases:
    - /zh/docs/tasks/security/plugin-ca-cert/
---

本任务演示系统管理员如何使用现有的根证书、签名证书和密钥配置 Istio 的 CA。

缺省情况下 Istio 的 CA 会生成自签署的根证书和密钥，用于给工作负载签署证书。Istio 的 CA 还可以使用运维人员指定的根证书、证书和密钥进行工作负载的证书颁发。该任务演示了向 Istio CA 插入外部证书和密钥的方法。

## 插入现有密钥和证书{#plugging-in-the-existing-certificate-and-key}

假设我们想让 Istio 的 CA 使用现有的 `ca-cert.pem` 证书和 `ca-key.pem`，其中 `ca-cert.pem` 是由 `root-cert.pem` 根证书签发的，我们也准备使用 `root-cert.pem` 作为 Istio 工作负载的根证书。

下面的例子中，Istio CA 的签署（CA）证书（`root-cert.pem`）不同于根证书（`root-cert.pem`），因此工作负载无法使用根证书进行证书校验。工作负载需要一个 `cert-chain.pem` 文件作为信任链，其中需要包含所有从根证书到工作负载证书之间的中间 CA。在我们的例子中，它包含了 Istio CA 的签署证书，所以 `cert-chain.pem` 和 `ca-cert.pem` 是一致的。注意，如果你的 `ca-cert.pem` 和 `ca-cert.pem` 是一致的，那么 `cert-chain.pem` 就是个空文件了。

这些文件都会在 `samples/certs/` 目录中准备就绪提供使用。

{{< tip >}}
缺省的 Istio CA 安装根据下面[命令](/zh/docs/reference/commands/istio_ca/index.html)中使用的预定义密钥和文件名来配置证书和密钥的位置（例如，secret 秘钥名为 `cacert`，根证书在一个名为 `root-cert.pem` 的文件中，Istio CA 的 key 在 `ca-key.pem` 中，等等）。
你必须使用这些特定的 secret 秘钥名和文件名，或者在部署 Istio 时重新配置 Istio 的 CA。
{{< /tip >}}

下面的步骤将外部证书和密钥存入 Kubernetes secret 对象，这些 secret 会被 Istio 的 CA 读取：

1. 创建一个名为 `cacert` 的 secret，其中包含所有输入文件 `ca-cert.pem`、`ca-key.pem`、`root-cert.pem` 以及 `cert-chain.pem`：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem \
        --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem \
        --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. 使用 `demo` 的部署配置，将 `global.mtls.enabled` 设置为 `true`，部署 Istio。

   Istio 的 CA 会从挂载的 secret 文件中读取证书和秘钥信息。

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo --set values.global.mtls.enabled=true
    {{< /text >}}

## 检查新证书{#verifying-the-new-certificates}

在本节中，我们将验证工作负载证书是否由插入 CA 的证书签名。这需要在本机安装 `openssl`。

1. 部署 `httpbin` 和 `sleep` 简单服务。

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1. 获取 `httpbin` 的证书链。

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

    打开上面命令生成的 `httpbin-proxy-cert.txt` 文件，将其中的三个证书分别保存到 `proxy-cert-0.pem`、`proxy-cert-1.pem` 和 `proxy-cert-2.pem`。每个证书以 `-----BEGIN CERTIFICATE-----` 开始，以 `-----END CERTIFICATE-----` 结束。

1. 检查根证书和运维人员指定的证书是否一致：

    {{< text bash >}}
    $ openssl x509 -in @samples/certs/root-cert.pem@ -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    {{< /text >}}

    输出为空代表符合预期。

1. 检查 CA 证书和运维人员指定的是否一致

    {{< text bash >}}
    $ openssl x509 -in @samples/certs/ca-cert.pem@ -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-1.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    {{< /text >}}

    输出为空代表符合预期。

1. 检查从根证书到工作负载证书的证书链：

    {{< text bash >}}
    $ openssl verify -CAfile <(cat @samples/certs/ca-cert.pem@ @samples/certs/root-cert.pem@) ./proxy-cert-0.pem
    ./proxy-cert-0.pem: OK
    {{< /text >}}

## 清理{#cleanup}

* 移除 secret `cacerts` 并使用 Istio CA 自签署证书重新部署 Istio：

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    $ istioctl manifest apply
    {{< /text >}}

* 移除 Istio 组件：按照[卸载说明](/zh/docs/setup/getting-started/#uninstall)进行删除。
