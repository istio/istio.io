---
title: SPIRE
description: 如何配置 Istio 以集成 SPIRE 通过 Envoy 的 SDS API 获取加密身份。
weight: 31
keywords: [kubernetes,spiffe,spire]
aliases:
owner: istio/wg-networking-maintainers
test: yes
---

[SPIRE](https://spiffe.io/docs/latest/spire-about/spire-concepts/) 是 SPIFFE
规范的一个可用于生产环境的实现，它执行节点和工作负载的认证，以便在异构环境中安全地为运行的工作负载颁发加密身份。
通过与 [Envoy 的 SDS API](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret)
集成，可以将 SPIRE 配置为 Istio 工作负载的加密身份源。Istio 可以检测到实现了 Envoy SDS API 的 UNIX 域套接字的存在，
并允许 Envoy 直接从其中通信并获取身份。

与默认的 Istio 身份管理相比，与 SPIRE 的集成提供了灵活的认证选项。例如，SPIRE 的插件架构使您可以选择 Kubernetes
命名空间和服务账户认证之外的多样化工作负载认证选项。SPIRE 的节点认证将认证扩展到工作负载所运行的物理或虚拟硬件上。

要了解关于如何将 SPIRE 与 Istio 集成的快速演示，请参阅[通过 Envoy 的 SDS API 将 SPIRE 集成为 CA]({{< github_tree >}}/samples/security/spire)。

## 安装 SPIRE {#install-spire}

我们建议您遵循 SPIRE 的安装说明和最佳实践来安装 SPIRE，并在生产环境中部署 SPIRE。

对于本指南中的示例，[SPIRE Helm Chart](https://artifacthub.io/packages/helm/spiffe/spire)
将与上游默认值一起使用，以仅关注集成 SPIRE 和 Istio 所需的配置。

{{< text syntax=bash snip_id=install_spire_crds >}}
$ helm upgrade --install -n spire-server spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace
{{< /text >}}

{{< text syntax=bash snip_id=install_spire_istio_overrides >}}
$ helm upgrade --install -n spire-server spire spire --repo https://spiffe.github.io/helm-charts-hardened/ --wait --set global.spire.trustDomain="example.org"
{{< /text >}}

{{< tip >}}
请参阅 [SPIRE Helm Chart](https://artifacthub.io/packages/helm/spiffe/spire) 文档，
了解您可以为安装配置的其他值。

重要的是，SPIRE 和 Istio 配置了完全相同的信任域，以防止身份验证和授权错误，
并且启用并安装了 [SPIFFE CSI 驱动程序](https://github.com/spiffe/spiffe-csi)。
{{< /tip >}}

默认情况下，以上操作还将安装：

- [SPIFFE CSI 驱动程序](https://github.com/spiffe/spiffe-csi)，
  用于将与 Envoy 兼容的 SDS 套接字挂载到代理中。
  Istio 和 SPIRE 都强烈建议使用 SPIFFE CSI 驱动程序挂载 SDS 套接字，
  因为 `hostMounts` 具有更大的安全风险并会带来操作障碍。本指南假设使用 SPIFFE CSI 驱动程序。

- [SPIRE 控制器管理器](https://github.com/spiffe/spire-controller-manager)，
  它简化了为工作负载创建 SPIFFE 注册的过程。

## 注册工作负载 {#register-workloads}

根据设计，SPIRE 仅向已在 SPIRE 服务器上注册的工作负载授予身份；
这包括用户工作负载以及 Istio 组件。Istio Sidecar 和 Gateway 一旦配置为 SPIRE 集成，
就无法获取身份，因此无法达到 READY 状态，除非事先为它们创建了预先存在的匹配 SPIRE 注册。

有关使用多个选择器来加强证明标准以及可用选择器的更多信息，
请参阅[有关注册工作负载的 SPIRE 文档](https://spiffe.io/docs/latest/deploying/registering/)。

本节介绍在 SPIRE 服务器中注册 Istio 工作负载的可用选项，并提供一些工作负载注册示例。

{{< warning >}}
Istio 目前要求工作负载采用特定的 SPIFFE ID 格式。
所有注册都必须遵循 Istio SPIFFE ID 模式：`spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

### 选项 1：使用 SPIRE 控制器管理器自动注册 {#option-1-auto-registration-using-the-spire-controller-manager}

每个与 [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)
自定义资源中定义的选择器匹配的新 Pod 将自动注册新 Entry。

Istio Sidecar 和 Istio Gateway 都需要在 SPIRE 上注册，以便它们可以请求身份。

#### Istio Gateway `ClusterSPIFFEID` {#istio-gateway-clusterspiffeid}

下面将创建一个 `ClusterSPIFFEID`，如果 Istio Ingress Gateway Pod
被调度到 `istio-system` 命名空间，它将自动向 SPIRE 注册该 Pod，
并且该 Pod 有一个名为 `istio-ingressgateway-service-account` 的服务帐户。
这些选择器用作简单示例；有关更多详细信息，
请参阅 [SPIRE Con​​troller Manager 文档](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)。

{{< text syntax=bash snip_id=spire_csid_istio_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-ingressgateway-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  workloadSelectorTemplates:
    - "k8s:ns:istio-system"
    - "k8s:sa:istio-ingressgateway-service-account"
EOF
{{< /text >}}

#### Istio Sidecar `ClusterSPIFFEID` {#istio-sidecar-clusterspiffeid}

下面将创建一个 `ClusterSPIFFEID`，
它将自动注册任何带有 `spiffe.io/spire-managed-identity: true` 标签的 Pod，
这些 Pod 会使用 SPIRE 部署到 `default` 命名空间中。这些选择器用作简单示例；
有关更多详细信息，请参阅 [SPIRE 控制器管理器文档](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)。

{{< text syntax=bash snip_id=spire_csid_istio_sidecar >}}
$ kubectl apply -f - <<EOF
apiVersion: spire.spiffe.io/v1alpha1
kind: ClusterSPIFFEID
metadata:
  name: istio-sidecar-reg
spec:
  spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
  podSelector:
    matchLabels:
      spiffe.io/spire-managed-identity: "true"
  workloadSelectorTemplates:
    - "k8s:ns:default"
EOF
{{< /text >}}

### 选项 2：手动注册 {#option-2-manual-registration}

如果您希望手动创建 SPIRE 注册，
而不是使用[推荐选项](#option-1-auto-registration-using-the-spire-controller-manager)中提到的 SPIRE 控制器管理器，
请参阅[有关手动注册的 SPIRE 文档](https://spiffe.io/docs/latest/deploying/registering/)。

以下是基于[选项 1](#option-1-auto-registration-using-the-spire-controller-manager) 中的自动注册的等效手动注册。
以下步骤假设您[已经按照 SPIRE 文档手动注册了您的 SPIRE 代理和节点证明](https://spiffe.io/docs/latest/deploying/registering/#1-defining-the-spiffe-id-of-the-agent)，
并且您的 SPIRE 代理已使用 SPIFFE 身份 `spiffe://example.org/ns/spire/sa/spire-agent` 注册。

1. 获取 `spire-server` Pod：

    {{< text syntax=bash snip_id=set_spire_server_pod_name_var >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l statefulset.kubernetes.io/pod-name=spire-server-0 -n spire-server -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. 为 Istio Ingress Gateway Pod 注册一个 Entry：

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:sa:istio-ingressgateway-service-account \
        -selector k8s:ns:istio-system \
        -socketPath /run/spire/sockets/server.sock

    Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
    SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
    Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Revision         : 0
    TTL              : default
    Selector         : k8s:ns:istio-system
    Selector         : k8s:sa:istio-ingressgateway-service-account
    {{< /text >}}

1. 注册一个通过 Istio Sidecar 注入工作负载的 Entry：

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/curl \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-label:spiffe.io/spire-managed-identity:true \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

## 安装 Istio {#install-istio}

1. [下载 Istio 发行版](/zh/docs/setup/additional-setup/download-istio-release/)。

1. 使用自定义补丁为 Ingress Gateway 和 `istio-proxy` 创建 Istio 配置。
   Ingress Gateway 组件包含 `spiffe.io/spire-managed-identity: "true"` 标签。

    {{< text syntax=bash snip_id=define_istio_operator_for_auto_registration >}}
    $ cat <<EOF > ./istio.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: istio-system
    spec:
      profile: default
      meshConfig:
        trustDomain: example.org
      values:
        # 这用于自定义 Sidecar 模板。
        # 它添加了标签以指示 SPIRE 应该管理此 Pod 的身份，
        # 以及 CSI 驱动程序挂载。
        sidecarInjectorWebhook:
          templates:
            spire: |
              labels:
                spiffe.io/spire-managed-identity: "true"
              spec:
                containers:
                - name: istio-proxy
                  volumeMounts:
                  - name: workload-socket
                    mountPath: /run/secrets/workload-spiffe-uds
                    readOnly: true
                volumes:
                  - name: workload-socket
                    csi:
                      driver: "csi.spiffe.io"
                      readOnly: true
      components:
        ingressGateways:
          - name: istio-ingressgateway
            enabled: true
            label:
              istio: ingressgateway
            k8s:
              overlays:
                # 这用于定制 Ingress Gateway 模板。
                # 它添加了 CSI 驱动程序挂载，以及一个 init 容器来停止网关启动，
                # 直到 CSI 驱动程序挂载套接字。
                - apiVersion: apps/v1
                  kind: Deployment
                  name: istio-ingressgateway
                  patches:
                    - path: spec.template.spec.volumes.[name:workload-socket]
                      value:
                        name: workload-socket
                        csi:
                          driver: "csi.spiffe.io"
                          readOnly: true
                    - path: spec.template.spec.containers.[name:istio-proxy].volumeMounts.[name:workload-socket]
                      value:
                        name: workload-socket
                        mountPath: "/run/secrets/workload-spiffe-uds"
                        readOnly: true
    EOF
    {{< /text >}}

    {{< warning >}}
    如果您使用的是 Kubernetes 1.33 版本，并且尚未在 Istio 控制平面中禁用对原生 Sidecar 的支持，
    则必须在 Sidecar 注入模板中使用 `initContainers`。
    这是必需的，因为原生 Sidecar 支持会改变 Sidecar 的注入方式。
    **注意：**网关的 SPIRE 注入模板应继续像以前一样使用常规 `containers`。
    {{< /warning >}}

1. 应用配置：

    {{< text syntax=bash snip_id=apply_istio_operator_configuration >}}
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. 检查 Ingress Gateway Pod 状态：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

    Ingress Gateway Pod 已 `Ready`，因为 SPIRE 服务器上会自动为其创建相应的注册条目。
    Envoy 能够从 SPIRE 获取加密身份。

    此配置还向网关添加了一个 `initContainer`，它将等待 SPIRE 创建 UNIX 域套接字，
    然后再启动 `istio-proxy`。如果 SPIRE 代理尚未准备就绪，或者未正确配置相同的套接字路径，
    则 Ingress Gateway `initContainer` 将永远等待。

1. 部署示例工作负载：

    {{< text syntax=bash snip_id=apply_curl >}}
    $ istioctl kube-inject --filename @samples/security/spire/curl-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    除了需要 `spiffe.io/spire-managed-identity` 标签之外，工作负载还需要使用 SPIFFE CSI
    驱动器卷来访问 SPIRE 代理套接字。为了实现这一点，您可以利用[安装 Istio](#install-istio) 部分中的
    `spire` Pod 注解模板，或者将 CSI 卷添加到您的工作负载的部署规范中。这两种方法都在下面的示例片段中进行了突出显示：

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: curl
    spec:
      replicas: 1
      selector:
          matchLabels:
            app: curl
      template:
          metadata:
            labels:
              app: curl
            # 注入自定义 Sidecar 模板
            annotations:
                inject.istio.io/templates: "sidecar,spire"
          spec:
            terminationGracePeriodSeconds: 0
            serviceAccountName: curl
            containers:
            - name: curl
              image: curlimages/curl
              command: ["/bin/sleep", "3650d"]
              imagePullPolicy: IfNotPresent
              volumeMounts:
                - name: tmp
                  mountPath: /tmp
              securityContext:
                runAsUser: 1000
            volumes:
              - name: tmp
                emptyDir: {}
              # CSI 卷
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
    {{< /text >}}

Istio 配置与 Ingress Gateway 和将要注入工作负载容器的 Sidecar 共享 `spiffe-csi-driver`，
从而授予它们访问 SPIRE 代理的 UNIX 域套接字的权限。

请参阅[验证为工作负载创建的身份](#verifying-that-identities-were-created-for-workloads)
以检查已颁发的身份。

## 验证工作负载的身份是否已创建  {#verifying-that-identities-were-created-for-workloads}

请使用以下命令确认是否已为工作负载创建了身份：

{{< text syntax=bash snip_id=none >}}
$ kubectl exec -t "$SPIRE_SERVER_POD" -n spire-server -c spire-server -- ./bin/spire-server entry show
Found 2 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/curl
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:ee490447-e502-46bd-8532-5a746b0871d6
{{< /text >}}

检查 Ingress-gateway Pod 状态：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          60s
istiod-989f54d9c-sg7sn                  1/1     Running   0          45s
{{< /text >}}

在为入口网关 Pod 注册条目后，Envoy 将收到 SPIRE 颁发的身份并将其用于所有 TLS 和 mTLS 通信。

### 检查工作负载身份是否由 SPIRE 颁发 {#check-that-the-workload-identity-was-issued-by-spire}

1. 获取 Pod 信息：

    {{< text syntax=bash snip_id=set_curl_pod_var >}}
    $ CURL_POD=$(kubectl get pod -l app=curl -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. 使用 `istioctl proxy-config secret` 命令检索 curl 的 SVID 身份文档：

    {{< text syntax=bash snip_id=get_curl_svid >}}
    $ istioctl proxy-config secret "$CURL_POD" -o json | jq -r \
    '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
    {{< /text >}}

1. 检查证书并确认 SPIRE 是颁发者：

    {{< text syntax=bash snip_id=get_svid_subject >}}
    $ openssl x509 -in chain.pem -text | grep SPIRE
        Subject: C = US, O = SPIRE, CN = curl-5f4d47c948-njvpk
    {{< /text >}}

## SPIFFE 联邦 {#spiffe-federation}

SPIRE 服务器能够对来自不同信任域的 SPIFFE 身份进行认证，这被称为 SPIFFE 联邦。

可以配置 SPIRE 代理通过 Envoy SDS API 向 Envoy 推送联邦捆绑包，从而使 Envoy
能够使用[验证上下文](https://spiffe.io/docs/latest/microservices/envoy/#validation-context)来验证对等证书并信任来自另一个信任域的工作负载。
要使 Istio 能够通过 SPIRE 集成实现 SPIFFE 身份联合，请参阅
[SPIRE 代理 SDS 配置](https://github.com/spiffe/spire/blob/main/doc/spire_agent.md#sds-configuration)，
并为您的 SPIRE 代理配置文件设置以下 SDS 配置值。

| 配置                        | 描述                                                    | 资源名称        |
| -------------------------- | ------------------------------------------------------- | ------------- |
| `default_svid_name`        | 用于 Envoy SDS 的默认 `X509-SVID` 的 TLS 证书资源名称       | 默认           |
| `default_bundle_name`      | 用于 Envoy SDS 的默认 X.509 bundle 的验证上下文资源名称      | 空             |
| `default_all_bundles_name` | 用于 Envoy SDS 的所有 bundle（包括联邦的）的验证上下文资源名称  | ROOTCA        |

这将允许 Envoy 直接从 SPIRE 获取联邦 bundle。

### 创建联邦注册条目 {#create-federated-registration-entries}

- 如果使用 SPIRE Controller Manager，请通过将 [ClusterSPIFFEID CR](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)
  的 `federatesWith` 字段设置为您希望 Pod 与之联邦的信任域来为工作负载创建联邦条目：

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: spire.spiffe.io/v1alpha1
    kind: ClusterSPIFFEID
    metadata:
      name: federation
    spec:
      spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
      podSelector:
        matchLabels:
          spiffe.io/spire-managed-identity: "true"
      federatesWith: ["example.io", "example.ai"]
    {{< /text >}}

- 要进行手动注册，请参阅[为联邦创建注册条目](https://spiffe.io/docs/latest/architecture/federation/readme/#create-registration-entries-for-federation)。

## 清理 SPIRE {#cleanup-spire}

通过卸载 Helm Chart 来删除 SPIRE：

{{< text syntax=bash snip_id=uninstall_spire >}}
$ helm delete -n spire-server spire
{{< /text >}}

{{< text syntax=bash snip_id=uninstall_spire_crds >}}
$ helm delete -n spire-server spire-crds
{{< /text >}}
