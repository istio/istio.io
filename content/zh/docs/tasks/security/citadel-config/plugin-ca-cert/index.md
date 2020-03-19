---
title: 插入外部 CA 密钥和证书
description: 运维人员如何使用现有根证书配置 Citadel 进行证书以及密钥的签发。
weight: 10
keywords: [security,certificates]
aliases:
    - /zh/docs/tasks/security/plugin-ca-cert/
---

本任务展示运维人员如何使用现有根证书配置 Citadel 进行证书以及密钥的签发。

缺省情况下 Citadel 生成自签署的根证书和密钥，用于给工作负载签署证书。Citadel 还可以使用运维人员指定的根证书、证书和密钥进行工作负载的证书颁发。该任务所演示了向 Citadel 插入外部证书和密钥的方法。

## 开始之前{#before-you-begin}

* 按照[快速启动](/zh/docs/setup/install/istioctl/)中的说明安装 Istio：

## 插入现有密钥和证书{#plugging-in-the-existing-certificate-and-key}

假设我们想让 Citadel 使用现有的 `ca-cert.pem` 证书和 `ca-key.pem`，其中 `ca-cert.pem` 是由 `root-cert.pem` 根证书签发的，我们也准备使用 `root-cert.pem` 作为 Istio 工作负载的根证书。

下面的例子中，Citadel 的签署（CA）证书（`root-cert.pem`）不同于根证书（`root-cert.pem`），因此工作负载无法使用根证书进行证书校验。工作负载需要一个 `cert-chain.pem` 文件作为信任链，其中需要包含所有从根证书到工作负载证书之间的中间 CA。在我们的例子中，他包含了 Citadel 的签署证书，所以 `cert-chain.pem` 和 `ca-cert.pem` 是一致的。注意如果你的 `ca-cert.pem` 和 `ca-cert.pem` 是一致的，那么 `cert-chain.pem` 就是个空文件了。

这些文件都会在 `samples/certs/` 目录中准备就绪提供使用。

    {{< tip >}}
    The default Citadel installation sets [command line options](/zh/docs/reference/commands/istio_ca/index.html) to configure the location of certificates and keys based on the predefined secret and file names used in the command below (i.e., secret named `cacert`, root certificate in a file named `root-cert.pem`, Citadel key in `ca-key.pem`, etc.)
    You must use these specific secret and file names, or reconfigure Citadel when you deploy it.
    {{< /tip >}}

下面的步骤在 Citadel 中插入了证书和密钥：

1. 创建一个名为 `cacert` 的 secret，其中包含所有输入文件 `ca-cert.pem`、`ca-key.pem`、`root-cert.pem` 以及 `cert-chain.pem`：

    {{< text bash >}}
    $ kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem \
        --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem \
        --from-file=samples/certs/cert-chain.pem
    {{< /text >}}

1. `global.mtls.enabled` 设置为 `true`，`security.selfSigned` 设置为 `false`，重新部署 Citadel。

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.mtls.enabled=true --set values.security.selfSigned=false
    {{< /text >}}

1. 为了确定工作负载获取了正确的证书，删除 Citadel 生成的 Secret（命名为 `istio.\*`）。在本例中就是 `istio.default`。Citadel 会签发新的证书给工作负载。

    {{< text bash >}}
    $ kubectl delete secret istio.default
    {{< /text >}}

## 检查新证书{#verifying-the-new-certificates}

本节中，我们要校验新的工作负载证书以及根证书是否正确传播。需要在本机安装 `openssl`。

1. 根据[部署文档](/zh/docs/examples/bookinfo/)安装 Bookinfo 应用。

1. 获取已加载的证书。
    下面我们使用 ratings pod 作为例子，检查这个 Pod 上加载的证书。

    用变量 `RATINGSPOD` 保存 Pod 名称：

    {{< text bash >}}
    $ RATINGSPOD=`kubectl get pods -l app=ratings -o jsonpath='{.items[0].metadata.name}'`
    {{< /text >}}

    运行下列命令，获取 `proxy` 容器中加载的证书：

    {{< text bash >}}
    $ kubectl exec -it $RATINGSPOD -c istio-proxy -- /bin/cat /etc/certs/root-cert.pem > /tmp/pod-root-cert.pem
    {{< /text >}}

    `/tmp/pod-root-cert.pem` 文件中包含传播到 Pod 中的根证书。

    {{< text bash >}}
    $ kubectl exec -it $RATINGSPOD -c istio-proxy -- /bin/cat /etc/certs/cert-chain.pem > /tmp/pod-cert-chain.pem
    {{< /text >}}

    而 `/tmp/pod-cert-chain.pem` 这个文件则包含了工作负载证书以及传播到 Pod 中的 CA 证书

1. 检查根证书和运维人员指定的证书是否一致：

    {{< text bash >}}
    $ openssl x509 -in @samples/certs/root-cert.pem@ -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in /tmp/pod-root-cert.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    {{< /text >}}

    输出为空代表符合预期。

1. 检查 CA 证书和运维人员指定的是否一致

    {{< text bash >}}
    $ sed '0,/^-----END CERTIFICATE-----/d' /tmp/pod-cert-chain.pem > /tmp/pod-cert-chain-ca.pem
    $ openssl x509 -in @samples/certs/ca-cert.pem@ -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in /tmp/pod-cert-chain-ca.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    {{< /text >}}

    输出为空代表符合预期。

1. 检查从根证书到工作负载证书的证书链：

    {{< text bash >}}
    $ head -n 21 /tmp/pod-cert-chain.pem > /tmp/pod-cert-chain-workload.pem
    $ openssl verify -CAfile <(cat @samples/certs/ca-cert.pem@ @samples/certs/root-cert.pem@) /tmp/pod-cert-chain-workload.pem
    /tmp/pod-cert-chain-workload.pem: OK
    {{< /text >}}

## 清理{#cleanup}

* 移除 secret `cacerts`：

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    $ istioctl manifest apply --set values.global.mtls.enabled=true
    {{< /text >}}

* 移除 Istio 组件：按照[卸载说明](/zh/docs/setup/getting-started/#uninstall)进行删除。
