---
title: Istio Vault CA 集成
description: 有关如何整合 Vault CA 到 Istio 中颁发证书的教程。
weight: 10
keywords: [security,certificate]
---

本教程将向您介绍如何在 Istio 中整合 Vault CA 颁发证书的示例。

## 开始之前{#before-you-begin}

* 创建一个新的 Kubernetes 集群以运行本教程中的示例。

## 安装启用 SDS 的 Istio

1.  使用 [Helm](/docs/setup/kubernetes/install/helm/#prerequisites) 安装 Istio 启用 SDS 和向节点代理发送证书签名请求来测试 Vault CA ：

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ helm dep update --skip-refresh install/kubernetes/helm/istio
    $ cat install/kubernetes/namespace.yaml > istio-auth.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth.yaml
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --set global.proxy.excludeIPRanges="35.233.249.249/32" \
        --values install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml \
        install/kubernetes/helm/istio >> istio-auth.yaml
    $ kubectl create -f istio-auth.yaml
    {{< /text >}}

本教程中使用的测试 Vault 服务器的 IP 地址为 `35.233.249.249`。配置 `global.proxy.excludeIPRanges ="35.233.249.249/32"` 将测试 Vault 服务器的 IP 地址列入白名单，以便 Envoy 不会拦截从 Node Agent 到 Vault 的流量。

这个 yaml 文件 [`values-istio-example-sds-vault.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml)
包含 Istio 中启用 SDS（密钥发现服务）的配置。
Vault CA 相关配置设置为环境变量：

{{< text yaml >}}
env:
- name: CA_ADDR
  value: "https://35.233.249.249:8200"
- name: CA_PROVIDER
  value: "VaultCA"
- name: "VAULT_ADDR"
  value: "https://35.233.249.249:8200"
- name: "VAULT_AUTH_PATH"
  value: "auth/kubernetes/login"
- name: "VAULT_ROLE"
  value: "istio-cert"
- name: "VAULT_SIGN_CSR_PATH"
  value: "istio_ca/sign/istio-pki-role"
{{< /text >}}

## 部署测试工作负载{#deploy-a-testing-workload}

本节部署测试工作负载 `httpbin`。当测试工作负载的 sidecar 通过 SDS 请求证书时，Node Agent 将向 Vault 发送证书签名请求。

1.  生成示例 `httpbin` 后端的部署：

    {{< text bash >}}
    $ istioctl kube-inject -f @samples/httpbin/httpbin.yaml@ > httpbin-injected.yaml
    {{< /text >}}

1.  部署示例后端：

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    {{< /text >}}

1.  列出节点代理的 pod：

    {{< text bash >}}
    $ kubectl get pod -n istio-system -l app=nodeagent -o jsonpath={.items..metadata.name}
    {{< /text >}}

1.  查看每个节点代理的日志。驻留在与测试工作负载相同的节点上的节点代理将包含与 Vault 相关的日志。

    {{< text bash >}}
    $ kubectl logs -n istio-system THE-POD-NAME-FROM-PREVIOUS-COMMAND
    {{< /text >}}

1.  因为在此示例中，Vault 未配置为从 `httpbin` 工作负载接受 Kubernetes JWT 服务帐户，您应该看到 Vault 使用以下日志拒绝签名请求：

    {{< text plain >}}
    2019-01-16T19:42:19.274291Z     info    SDS gRPC server start, listen "/var/run/sds/uds_path"
    2019-01-16T19:42:22.015814Z     error   failed to login Vault: Error making API request.
    URL: PUT https://35.233.249.249:8200/v1/auth/kubernetes/login
    Code: 500. Errors:
    * service account name not authorized
    2019-01-16T19:42:22.016112Z     error   Failed to sign cert for "default": failed to login Vault at https://35.233.249.249:8200: Error making API request.
    {{< /text >}}

1.  生成上述日志后，您已完成本文中的教程，该教程将整合外部 Vault CA 并将证书签名请求路由到 Vault。

## 清理{#cleanup}

完成本教程后，您可以删除在本教程开头创建的测试集群。

