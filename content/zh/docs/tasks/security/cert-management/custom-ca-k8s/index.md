---
title: 使用 Kubernetes CSR 自定义 CA 集成
description: 演示如何使用自定义证书颁发机构(与 Kubernetes CSR API 集成)来提供 Istio 工作负载证书。
weight: 100
keywords: [security,certificate]
aliases:
    - /zh/docs/tasks/security/custom-ca-k8s/
owner: istio/wg-security-maintainers
test: no
status: Experimental
---

{{< boilerplate experimental >}}

这个特性需要 Kubernetes 版本 >= 1.18。

此任务显示如何提供工作负载证书的自定义证书颁发机构[Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)。这个特性利用了[Chiron](/zh/blog/2019/dns-cert/)，一个轻量级组件与Istiod链接，使用 Kubernetes CSR API 签署证书。

这项任务分为两部分。第一部分演示了如何使用 Kubernetes CA 本身来签署工作负载证书。第二部分演示了如何使用与 Kubernetes CSR API 集成的自定义 CA 来为证书签名。

## 第一部分: 使用 Kubernetes CA{#using-Kubernetes-ca}

{{< warning >}}
注意，这个示例只用于基本计算。不建议在生产环境中使用 `kubernetes.io/legacy-unknown`。
{{< /warning >}}

### 使用 Kubernetes CA 部署 Istio {#deploying-Istio-with-Kubernetes-ca}

1. 使用 `istioctl` 在集群上部署 Istio，配置如下。

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
      apiVersion: install.istio.io/v1alpha1
      kind: IstioOperator
      spec:
        pilot:
          k8s:
            env:
            # Indicate to Istiod that we use a Custom Certificate Authority
            - name: EXTERNAL_CA
              value: ISTIOD_RA_KUBERNETES_API
            # Tells Istiod to use the Kubernetes legacy CA Signer
            - name: K8S_SIGNER
              value: kubernetes.io/legacy-unknown
      EOF
    $ istioctl install --set profile=demo -f ./istio.yaml
    {{< /text >}}

1. 在 bookinfo 命名空间中部署 `bookinfo` 示例应用程序。确保在 Istio 根目录下执行以下命令。

    {{< text bash >}}
    $ kubectl create ns bookinfo
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
    {{< /text >}}

### 验证安装的证书是否正确{#verify-that-the-certificates-installed-are-correct}

在部署工作负载时，它们会向 Istiod 发送 CSR 请求，Istiod 将它们转发到 Kubernetes CA 进行签名。如果一切顺利，签名的证书将被发送回安装它们的工作负载。要验证它们是否已由 Kubernetes CA 签名，您需要先提取已签名的证书。

1. 获取在命名空间中运行的所有 pod。

    {{< text bash >}}
    $ kubectl get pods -n bookinfo
    {{< /text >}}

    为下一步选择任何一个正在运行的 Pod。

1. 获取 Istio 代理用于 mTLS 的证书链和 CA 根证书。

    {{< text bash >}}
    $ istioctl pc secret <pod-name> -o json > proxy_secret
    {{< /text >}}

    proxy_secret json 文件在 `trustedCA` 字段中包含 mTLS 的 CA 根证书。请注意，此证书是 base64 编码的。

1. Kubernetes CA 使用的证书（特别是 `kubernetes.io/legacy-unknown`）被加载到与 bookinfo 命名空间中的每个服务帐号关联的密钥上。

    {{< text bash >}}
    $ kubectl get secrets -n bookinfo
    {{< /text >}}

    选择与任何服务帐号关联的 secrets 名称。它们的名称中有一个 "token"。

    {{< text bash >}}
    $ kubectl get secrets -n bookinfo <secret-name> -o json
    {{< /text >}}

    输出中的 `ca.crt` 字段包含 base64 编码的 Kubernetes CA 证书。

1. 将上一步获得的 `ca.cert` 与上一步中 `TrustedCA` 字段的内容进行比较。这两个应该是一样的。

1. （可选）按照[bookinfo 示例](/zh/docs/examples/bookinfo/)中的其余步骤确保服务之间的通信按预期进行。

### Cleanup Part 1

* 删除 `istio-system` 和 `bookinfo` 命名空间：

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns bookinfo
    {{< /text >}}

## 第二部分: 使用自定义 CA{#using-custom-CA}

假设自定义 CA 实现了一个控制器，该控制器具有读取和签署 Kubernetes CSR 请求的必要权限。
更多细节请参考[Kubernetes CSR 文档](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)。请注意，以下步骤取决于外部源并且可能会发生变化。

### 在 Kubernetes 集群中部署自定义 CA 控制器{#deploy-custom-CA-controller-in-the-Kubernetes-cluster}

1. 对于此示例，我们使用[开源证书颁发机构实现](https://github.com/cert-manager/signer-ca)。此代码构建了一个控制器，该控制器读取 Kubernetes 集群上的 CSR 资源并使用本地密钥创建证书。按照页面上的说明进行操作:
   1. 构建 Certificate-Controller docker 镜像
   1. 将镜像上传到 Docker Registry
   1. 生成 Kubernetes manifest 以进行部署

1. 将在上一步中生成的 Kubernetes 清单部署到 signer-ca-system 命名空间中的本地集群上。

    {{< text bash >}}
    $ kubectl apply -f local-ca.yaml
    {{< /text >}}

   确认所有的服务都在运行。

    {{< text bash >}}
    $ kubectl get services -n signer-ca-system
      NAME                                           TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
      signer-ca-controller-manager-metrics-service   ClusterIP   10.8.9.25    none        8443/TCP   72s
    {{< /text >}}

1. 获取 CA 的公钥。这是在 signer-ca-system 命名空间中的 “signer-ca-*” secrets 中编码的。

    {{< text bash >}}
    $ kubectl get secrets signer-ca-5hff5h74hm -o json
    {{< /text >}}

    `tls.crt` 字段包含 base64 编码的公钥文件。记录下来以备将来使用。

### 将 CA 根证书加载到 istiod 可以访问的 secret{#load-the-CA-root-certificate-into-a-secret-that-istiod-can-access}

1. 将 secret 加载到 istiod 命名空间中。

    {{< text bash >}}
    $ cat <<EOF > ./external-ca-secret.yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: external-ca-cert
        namespace: istio-system
      data:
      root-cert.pem: <tls.cert from the step above>
      EOF
    $ kubectl apply -f external-ca-secret.yaml
    {{< /text >}}

    Istio 需要此步骤来验证工作负载证书是否已由正确的证书颁发机构签名，并将根证书添加到信任包以使 mTLS 正常工作。

### 部署 Istio{#deploying-Istio}

1. 使用 `istioctl` 在集群上部署 Istio，配置如下。

    {{< text bash >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      components:
        base:
          k8s:
            overlays:
              # Amend ClusterRole to add permission for istiod to approve certificate signing by custom signer
              - kind: ClusterRole
                name: istiod-istio-system
                patches:
                  - path: rules[-1]
                    value: |
                      apiGroups:
                      - certificates.k8s.io
                      resourceNames:
                      # Name of k8s external Signer in this example
                      - example.com/foo
                      resources:
                      - signers
                      verbs:
                      - approve
        pilot:
          k8s:
            env:
              # Indicate to Istiod that we use an external signer
              - name: EXTERNAL_CA
                value: ISTIOD_RA_KUBERNETES_API
              # Indicate to Istiod the external k8s Signer Name
              - name: K8S_SIGNER
                value: example.com/foo
            overlays:
            - kind: Deployment
              name: istiod
              patches:
                - path: spec.template.spec.containers[0].volumeMounts[-1]
                  value: |
                    # Mount external CA certificate into Istiod
                    name: external-ca-cert
                    mountPath: /etc/external-ca-cert
                    readOnly: true
                - path: spec.template.spec.volumes[-1]
                  value: |
                    name: external-ca-cert
                    secret:
                      secretName: external-ca-cert
                      optional: true
    EOF
    $ istioctl install --set profile=demo -f ./istio.yaml
    {{< /text >}}

1. 在 bookinfo 命名空间中部署 `bookinfo` 示例应用程序。

    {{< text bash >}}
    $ kubectl create ns bookinfo
    $ kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml) -n bookinfo
    {{< /text >}}

### 验证安装的自定义 CA 证书是否正确{#verify-that-custom-CA-certificates-installed-are-correct}

在部署工作负载时，它们会向 Istiod 发送 CSR 请求，Istiod 将它们转发到 Kubernetes CA 进行签名。如果一切顺利，签名的证书将被发送回安装它们的工作负载。要验证它们确实已由 Kubernetes CA 签名，您需要首先提取已签名的证书。

1. 获取在命名空间中运行的所有 pod。

    {{< text bash >}}
    $ kubectl get pods -n bookinfo
    {{< /text >}}

   为下一步选择任何正在运行的 Pod。

1. 获取 Istio 代理用于 mTLS 的证书链和 CA 根证书。

    {{< text bash >}}
    $ istioctl pc secret <pod-name> -o json > proxy_secret
    {{< /text >}}

   `proxy_secret` json 文件在 `trustedCA` 字段中包含 mTLS 的 CA 根证书。请注意，此证书是 base64 编码的。

1. 将上述步骤中获得的 CA 根证书与 external-ca-cert 中的 ”root-cert.pem“ 值进行比较。这两个应该是一样的。

1. （可选）按照[bookinfo 示例](/zh/docs/examples/bookinfo/)中的其余步骤确保服务之间的通信按预期进行。

### 清理第 2 部分{#cleanup-Part-2}

* 删除 `istio-system` 和 `bookinfo` 命名空间:

    {{< text bash >}}
    $ kubectl delete ns istio-system
    $ kubectl delete ns bookinfo
    {{< /text >}}

## 使用此功能的原因{#reasons-to-use-this-feature}

* 增加了安全性 -  `plugin-ca-cert` 或默认的 `self-signed` 选项不同，启用此功能意味着 CA 私钥不需要存在于 Kubernetes 集群中。

* 自定义 CA 集成 - 通过在 Kubernetes CSR 请求中指定签名者名称，此功能允许 Istio 使用 Kubernetes CSR API 接口与自定义证书颁发机构集成。这确实需要自定义 CA 来实现一个 Kubernetes 控制器来观察 `CertificateSigningRequest` 和 `Certificate` 资源并对其采取行动。
