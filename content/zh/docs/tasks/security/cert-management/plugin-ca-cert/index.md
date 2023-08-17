---
title: 插入 CA 证书
description: 系统管理员如何通过根证书、签名证书和密钥来配置 Istio 的 CA。
weight: 80
keywords: [security,certificates]
aliases:
    - /zh/docs/tasks/security/plugin-ca-cert/
owner: istio/wg-security-maintainers
test: yes
---

本任务介绍了系统管理员如何通过根证书、签名证书和密钥来配置 Istio 证书授权（CA）。

默认情况下，Istio CA 会生成一个自签名的根证书和密钥，并使用它们来签署工作负载证书。
为了保护根 CA 密钥，您应该使用在安全机器上离线运行的根 CA，并使用根 CA 向运行在每个集群上的
Istio CA 签发中间证书。Istio CA 可以使用管理员指定的证书和密钥来签署工作负载证书，
并将管理员指定的根证书作为信任根分配给工作负载。

下图展示了在包含两个集群的网格中推荐的 CA 层次结构。

{{< image width="50%"
    link="ca-hierarchy.svg"
    caption="CA Hierarchy"
    >}}

本任务介绍如何生成和插入 Istio CA 的证书和密钥。这些步骤可以重复进行，
为每个集群中运行的 Istio CA 提供证书和密钥。

## 在集群中插入证书和密钥{#plug-in-certificates-and-key-into-the-cluster}

{{< warning >}}
以下内容仅用于演示。对于生产型集群的设置，强烈建议使用生产型 CA，如
[Hashicorp Vault](https://www.hashicorp.com/products/vault)。
在具有强大安全保护功能的离线机器上管理根 CA 是一个很好的做法。
{{< /warning >}}

{{< warning >}}
[Go 1.18 默认禁用](https://github.com/golang/go/issues/41682)对 SHA-1 签名的支持。
如果您正在 macOS 上生成证书，请确保您使用的是 OpenSSL。详情请参阅
[GitHub issue 38049](https://github.com/istio/istio/issues/38049)。
{{< /warning >}}

1. 在 Istio 安装包的顶层目录下，创建一个目录来存放证书和密钥：

    {{< text bash >}}
    $ mkdir -p certs
    $ pushd certs
    {{< /text >}}

1. 生成根证书和密钥：

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk root-ca
    {{< /text >}}

    将会生成以下文件：

    * `root-cert.pem`：生成的根证书
    * `root-key.pem`：生成的根密钥
    * `root-ca.conf`：生成根证书的 `openssl` 配置
    * `root-cert.csr`：为根证书生成的 CSR

1. 对于每个集群，为 Istio CA 生成一个中间证书和密钥。
    以下是集群 `cluster1` 的例子：

    {{< text bash >}}
    $ make -f ../tools/certs/Makefile.selfsigned.mk cluster1-cacerts
    {{< /text >}}

    运行以上命令，将会在名为 `cluster1` 的目录下生成以下文件：

    * `ca-cert.pem`：生成的中间证书
    * `ca-key.pem`：生成的中间密钥
    * `cert-chain.pem`：istiod 使用的生成的证书链
    * `root-cert.pem`：根证书

    您可以使用一个您选择的字符串来替换 `cluster1`。例如，使用 `cluster2-cacerts` 参数，
    您可以在一个名为 `cluster2` 的目录中创建证书和密钥。

    如果您正在离线机器上进行此操作，请将生成的目录复制到可以访问集群的机器上。

1. 在每个集群中，创建一个私密 `cacerts`，包括所有输入文件 `ca-cert.pem`，
   `ca-key.pem`，`root-cert.pem` 和 `cert-chain.pem`。例如，在 `cluster1` 集群上：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create secret generic cacerts -n istio-system \
          --from-file=cluster1/ca-cert.pem \
          --from-file=cluster1/ca-key.pem \
          --from-file=cluster1/root-cert.pem \
          --from-file=cluster1/cert-chain.pem
    {{< /text >}}

1. 返回 Istio 安装的顶层目录：

    {{< text bash >}}
    $ popd
    {{< /text >}}

## 部署 Istio{#deploy-Istio}

1. 使用 `demo` 配置文件部署 Istio。

    Istio 的 CA 将会从私密安装文件中读取证书和密钥。

    {{< text bash >}}
    $ istioctl install --set profile=demo
    {{< /text >}}

## 部署示例服务{#deploying-example-services}

1. 部署 `httpbin` 和 `sleep` 示例服务。

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
    {{< /text >}}

1. 为 `foo` 命名空间中的工作负载部署一个策略，使其只接受相互的 TLS 流量。

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: "default"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

## 验证证书{#verifying-the-certificates}

本节中，验证工作负载证书是否已通过插入到 CA 中的证书签署。验证的前提要求机器上安装有 `openssl`。

1. 在检索 `httpbin` 的证书链之前，请等待 20 秒使mTLS策略生效。由于本例中使用的 CA 证书是自签的，
   所以可以预料 openssl 命令返回 `verify error:num=19:self signed certificate in certificate chain`。

    {{< text bash >}}
    $ sleep 20; kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
    {{< /text >}}

1. 解析证书链上的证书。

    {{< text bash >}}
    $ sed -n '/-----BEGIN CERTIFICATE-----/{:start /-----END CERTIFICATE-----/!{N;b start};/.*/p}' httpbin-proxy-cert.txt > certs.pem
    $ awk 'BEGIN {counter=0;} /BEGIN CERT/{counter++} { print > "proxy-cert-" counter ".pem"}' < certs.pem
    {{< /text >}}

1. 确认根证书与管理员指定的证书是否相同：

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/root-cert.pem -text -noout > /tmp/root-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt
    $ diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
    Files /tmp/root-cert.crt.txt and /tmp/pod-root-cert.crt.txt are identical
    {{< /text >}}

1. 验证 CA 证书与管理员指定的证书是否相同：

    {{< text bash >}}
    $ openssl x509 -in certs/cluster1/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt
    $ openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
    $ diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
    Files /tmp/ca-cert.crt.txt and /tmp/pod-cert-chain-ca.crt.txt are identical
    {{< /text >}}

1. 验证从根证书到工作负载证书的证书链：

    {{< text bash >}}
    $ openssl verify -CAfile <(cat certs/cluster1/ca-cert.pem certs/cluster1/root-cert.pem) ./proxy-cert-1.pem
    ./proxy-cert-1.pem: OK
    {{< /text >}}

## 清理{#cleanup}

*  从本地磁盘中删除证书、密钥和中间文件：

    {{< text bash >}}
    $ rm -rf certs
    {{< /text >}}

*  删除 Secret `cacerts`：

    {{< text bash >}}
    $ kubectl delete secret cacerts -n istio-system
    {{< /text >}}

*  从 `foo` 命名空间中删除身份验证策略：

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    {{< /text >}}

*  删除示例应用 `sleep` 和 `httpbin`：

    {{< text bash >}}
    $ kubectl delete -f samples/sleep/sleep.yaml -n foo
    $ kubectl delete -f samples/httpbin/httpbin.yaml -n foo
    {{< /text >}}

*  从集群中卸载 Istio：

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

*  从集群中删除命名空间 `foo` 和 `istio-system`：

    {{< text bash >}}
    $ kubectl delete ns foo istio-system
    {{< /text >}}
