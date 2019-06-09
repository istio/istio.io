---
title: Istio Vault CA 集成
description: 整合 Vault CA 到 Istio 中为双向 TLS 提供 支持。
weight: 10
keywords: [security,certificate]
---

本任务展示了如何将 [Vault CA](https://www.vaultproject.io/) 集成到 Istio 之中，并为网格中的工作负载签发证书。任务里会使用 Vault CA 签发的证书为 Istio 双向 TLS 提供支持。

## 开始之前{#before-you-begin}

* 创建一个新的 Kubernetes 集群以运行本教程中的示例。

## 证书请求流程

在高级视角中，Istio 代理（例如 Envoy）通过 SDS 从 Node Agent 请求证书。Node Agent 会向 Vault CA 发送一个 CSR（证书签名请求），其中包含了 Envoy 代理所在的 Kubernetes Service account 的 Token。

## 安装 Istio 并启用双向 和 SDS

1. 使用 [Helm](/docs/setup/kubernetes/install/helm/#prerequisites) 安装 Istio 并启用双向 TLS、SDS 以及 Node Agent，Node Agent 发送向测试 Vault CA 发送 CSR：
    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ cat install/kubernetes/namespace.yaml > istio-auth.yaml
    $ cat install/kubernetes/helm/istio-init/files/crd-* >> istio-auth.yaml
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --set global.mtls.enabled=true \
        --values install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml \
        install/kubernetes/helm/istio >> istio-auth.yaml
    $ kubectl create -f istio-auth.yaml
    {{< /text >}}

文件 [`values-istio-example-sds-vault.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-example-sds-vault.yaml) 中包含 Istio 中启用 SDS（密钥发现服务）的配置。将 Vault CA 相关配置设置为环境变量：

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

1. 这里用于测试的 Vault 服务器 IP 地址是  `34.83.129.211`。用这个地址为 Vault 服务器创建一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: vault-service-entry
    spec:
      hosts:
      - vault-server
      addresses:
      - 34.83.129.211/32
      ports:
      - number: 8200
        name: https
        protocol: HTTPS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

## 部署测试工作负载 {#deploy-workloads-for-testing}

本节中部署的测试工作负载是 `httpbin` 和 `sleep`。当测试工作负载的 Sidecar 通过 SDS 请求证书时，Node Agent 将向 Vault 发送证书签名请求。

1. 生成 `sleep` 和 `httpbin` 的 Deployment：

    {{< text bash >}}
    $ istioctl kube-inject -f @samples/httpbin/httpbin-vault.yaml@ > httpbin-injected.yaml
    $ istioctl kube-inject -f @samples/sleep/sleep-vault.yaml@ > sleep-injected.yaml
    {{< /text >}}

1. 为 Vault CA 创建 SA：`vault-citadel-sa`：

    {{< text bash >}}
    $ kubectl create serviceaccount vault-citadel-sa
    {{< /text >}}

1. Vault CA 需要 Kubernetes Service account 的认证和鉴权，因此必须对 `vault-citadel-sa` Service account 进行编辑，令其使用 Vault CA 中配置的样例 JWT。要了解更多关于使用 Vault CA 为 Kubernetes 提供认证和鉴权的内容，可以浏览 [Vault Kubernetes `auth` method reference documentation](https://www.vaultproject.io/docs/auth/kubernetes.html)。[Integration Kubernetes with Vault - auth](https://evalle.xyz/posts/integration-kubernetes-with-vault-auth/) 中包含了配置 Vault 来为 Kubernetes Service account 提供认证和鉴权过程的详细例子。

    {{< text bash >}}
    $ export SA_SECRET_NAME=$(kubectl get serviceaccount vault-citadel-sa -o=jsonpath='{.secrets[0].name}')
    $ kubectl patch secret ${SA_SECRET_NAME} -p='{"data":{"token": "ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmtaV1poZFd4MElpd2lhM1ZpWlhKdVpYUmxjeTVwYnk5elpYSjJhV05sWVdOamIzVnVkQzl6WldOeVpYUXVibUZ0WlNJNkluWmhkV3gwTFdOcGRHRmtaV3d0YzJFdGRHOXJaVzR0TnpSMGQzTWlMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lkbUYxYkhRdFkybDBZV1JsYkMxellTSXNJbXQxWW1WeWJtVjBaWE11YVc4dmMyVnlkbWxqWldGalkyOTFiblF2YzJWeWRtbGpaUzFoWTJOdmRXNTBMblZwWkNJNklqSmhZekF6WW1FeUxUWTVNVFV0TVRGbE9TMDVOamt3TFRReU1ERXdZVGhoTURFeE5DSXNJbk4xWWlJNkluTjVjM1JsYlRwelpYSjJhV05sWVdOamIzVnVkRHBrWldaaGRXeDBPblpoZFd4MExXTnBkR0ZrWld3dGMyRWlmUS5wWjhTaXlOZU8wcDFwOEhCOW9YdlhPQUkxWENKWktrMndWSFhCc1RTektXeGxWRDlIckhiQWNTYk8yZGxoRnBlQ2drbnQ2ZVp5d3ZoU2haSmgyRjYtaUhQX1lvVVZvQ3FRbXpqUG9CM2MzSm9ZRnBKby05alROMV9tTlJ0WlVjTnZZbC10RGxUbUJsYUtFdm9DNVAyV0dWVUYzQW9Mc0VTNjZ1NEZHOVdsbG1MVjkyTEcxV05xeF9sdGtUMXRhaFN5OVdpSFFneXpQcXd0d0U3MlQxakFHZGdWSW9KeTFsZlNhTGFtX2JvOXJxa1JsZ1NnLWF1OUJBalppREd0bTl0ZjNsd3JjZ2ZieGNjZGxHNGpBc1RGYTJhTnMzZFc0TkxrN21GbldDSmEtaVdqLVRnRnhmOVRXLTlYUEswZzNvWUlRMElkMENJVzJTaUZ4S0dQQWpCLWc="}}'
    {{< /text >}}

1. 部署 `httpbin` 和 `sleep`：

    {{< text bash >}}
    $ kubectl apply -f httpbin-injected.yaml
    $ kubectl apply -f sleep-injected.yaml
    {{< /text >}}

## 集成 Vault CA 到 Istio 双向 TLS

本节中会演示集成了 Vault CA 的双向 TLS。前面的步骤中，为 Istio 服务网格启用了双向 TLS，并部署了 `httpbin` 和 `sleep` 工作负载。这些工作负载会从测试 Vault CA 中接收证书。如果从 `sleep` 工作负载中使用 `curl` 向 `httpbin` 发出请求，请求从双向 TLS 保护的通道中进行传输，这一隧道就是使用 Vault CA 签发的证书创建的。

1. 从 `sleep` 发送一个 `curl` 请求到 `httpbin`。

    通过 Vault CA 签发的证书，建立起双向 TLS 保护的通道，这一请求通过该通道，会收到一个 `200` 响应码。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    200
    {{< /text >}}

1. 要检查并非所有请求都会成功，可以从 `sleep` 的 Sidecar 中向 `httpbin` 发送请求。这一请求会失败，原因是从 Sidecar 到 `httpbin` 的通信没有使用双向 TLS。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -- curl -s -o /dev/null -w "%{http_code}" httpbin:8000/headers
    000command terminated with exit code 56
    {{< /text >}}

**恭喜你！**成功的将 Vault CA 集成到了 Istio 之中，用 Vault CA 签发的证书为工作负载之间的双向 TLS 通信提供支持。

## 清理{#cleanup}

完成本教程后，您可以删除在本教程开头创建的测试集群。

