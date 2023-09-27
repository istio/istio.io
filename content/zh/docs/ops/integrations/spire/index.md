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

{{< warning >}}
请注意，此集成需要 `istioctl` 和数据平面均为 1.14 及更高版本。
{{< /warning >}}

此集成与 Istio 升级兼容。

## 安装 SPIRE {#install-spire}

### 选项 1：快速开始 {#option-1-quick-start}

Istio 提供了一个基本的示例安装，可以快速启动 SPIRE：

{{< text syntax=bash snip_id=install_spire_with_controller_manager >}}
$ kubectl apply -f @samples/security/spire/spire-quickstart.yaml@
{{< /text >}}

这将在您的集群中部署 SPIRE，以及下述两个附加组件：

- [SPIFFE CSI 驱动](https://github.com/spiffe/spiffe-csi)，用于与节点中的其他 Pod 共享 SPIRE 代理的 UNIX 域套接字。
- [SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager)，它负责注册工作负载并在
  Kubernetes 中建立联合关系。请参阅[安装 Istio](#install-istio) 以配置 Istio 并集成 SPIFFE CSI 驱动。

### 选项 2：配置自定义 SPIRE 安装 {#option-2-configure-a-custom-spire-installation}

请参阅 [SPIRE 的 Kubernetes 快速入门指南](https://spiffe.io/docs/latest/try/getting-started-k8s/)
以开始将 SPIRE 部署到您的 Kubernetes 环境中。请参阅 [SPIRE CA 集成先决条件](#spire-ca-integration-prerequisites)
以获取有关如何配置 SPIRE 以与 Istio 部署集成的更多信息。

#### SPIRE CA 集成先决条件 {#spire-ca-integration-prerequisites}

要将您的 SPIRE 部署与 Istio 集成，需要配置 SPIRE：

1. 访问 [SPIRE 代理参考](https://spiffe.io/docs/latest/deploying/spire_agent/#agent-configuration-file)并将
   SPIRE 代理套接字路径配置为与 Envoy SDS 定义的套接字路径匹配。

    {{< text plain >}}
    socket_path = "/run/secrets/workload-spiffe-uds/socket"
    {{< /text >}}

1. 通过部署 [SPIFFE CSI 驱动](https://github.com/spiffe/spiffe-csi)与节点内的 Pod 共享 SPIRE 代理套接字，
   通过设置驱动程序的 `-workload-api-socket-dir` 参数来指定套接字目录的挂载位置。

请参阅[安装 Istio](#install-istio) 以配置 Istio 以集成 SPIFFE CSI 驱动。

{{< tip >}}
如果在 Istio 代理启动之前 SPIRE 尚未创建套接字，则 Istio 将成为 Envoy SDS 监听器。
此时的时间由自定义 IstioOperator 控制。
{{< /tip >}}

## 安装 Istio {#install-istio}

### 选项  1：使用 SPIRE Controller Manager 配置工作负载注册 {#option-1-configuration-for-workload-registration-with-the-spire-controller-manager}

通过部署 [SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager)
和 SPIRE 服务器，可以自动为与 [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)
自定义资源中定义的选择器匹配的每个新 Pod 进行注册。

必须在安装 Istio 之前应用 ClusterSPIFFEID。此外，必须配置 Ingress-gateway Pod 以匹配 ClusterSPIFFEID
中定义的选择器。如果在安装期间未自动创建 Ingress Gateway 工作负载的注册条目，则工作负载将无法达到 `Ready` 状态。

1. 创建 ClusterSPIFFEID 示例：

    {{< text syntax=bash snip_id=create_clusterspiffeid >}}
    $ kubectl apply -f - <<EOF
    apiVersion: spire.spiffe.io/v1alpha1
    kind: ClusterSPIFFEID
    metadata:
      name: example
    spec:
      spiffeIDTemplate: "spiffe://{{ .TrustDomain }}/ns/{{ .PodMeta.Namespace }}/sa/{{ .PodSpec.ServiceAccountName }}"
      podSelector:
        matchLabels:
          spiffe.io/spire-managed-identity: "true"
    EOF
    {{< /text >}}

    示例 ClusterSPIFFEID 允许自动注册所有具有 `spiffe.io/spire-managed-identity: "true"` 标签的工作负载。
    对于具有此标签的 Pod，将提取 `spiffeIDTemplate` 中指定的值以形成 SPIFFE ID。

1. [下载 Istio](/zh/docs/setup/getting-started/#download)。

1. 创建具有自定义补丁的 Ingress Gateway 和 istio-proxy 的 Istio 配置。Ingress Gateway 组件包括
   `spiffe.io/spire-managed-identity: "true"` 标签。

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
        global:
        # 这是用于自定义 sidecar 的模板
        sidecarInjectorWebhook:
          templates:
            spire: |
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
              spiffe.io/spire-managed-identity: "true"
            k8s:
              overlays:
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
                    - path: spec.template.spec.initContainers
                      value:
                        - name: wait-for-spire-socket
                          image: busybox:1.28
                          volumeMounts:
                            - name: workload-socket
                              mountPath: /run/secrets/workload-spiffe-uds
                              readOnly: true
                          env:
                            - name: CHECK_FILE
                              value: /run/secrets/workload-spiffe-uds/socket
                          command:
                            - sh
                            - "-c"
                            - |-
                              echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                              while [[ ! -e ${CHECK_FILE} ]] ; do
                                echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                                sleep 15
                              done
                              ls -l ${CHECK_FILE}
    EOF
    {{< /text >}}

1. 应用配置：

    {{< text syntax=bash snip_id=apply_istio_operator_configuration >}}
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. 检查 Ingress-gateway Pod 状态：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

    由于与之对应的注册条目已在 SPIRE 服务器上自动创建，Ingress-gateway Pod 状态为 `Ready`。Envoy 能够从 SPIRE 获取加密身份。

请注意，在[快速入门](#option-1-quick-start)部分中使用了 `SPIRE Controller Manager`。

### 选项 2：手动工作负载注册 {#option-2-configuration-for-manual-workload-registration-with-spire}

1. [下载 Istio](/zh/docs/setup/getting-started/#download)。

1. 在[部署 SPIRE](#install-spire) 到您的环境并确保所有 Deployment 都处于 `Ready` 状态后，
   使用 Ingress-gateway 和 istio-proxy 的自定义补丁来配置 Istio。

    创建 Istio 配置：

    {{< text syntax=bash snip_id=define_istio_operator_for_manual_registration >}}
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
        global:
        # 这是用于自定义 sidecar 的模板
        sidecarInjectorWebhook:
          templates:
            spire: |
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
                    - path: spec.template.spec.initContainers
                      value:
                        - name: wait-for-spire-socket
                          image: busybox:1.28
                          volumeMounts:
                            - name: workload-socket
                              mountPath: /run/secrets/workload-spiffe-uds
                              readOnly: true
                          env:
                            - name: CHECK_FILE
                              value: /run/secrets/workload-spiffe-uds/socket
                          command:
                            - sh
                            - "-c"
                            - |-
                              echo "$(date -Iseconds)" Waiting for: ${CHECK_FILE}
                              while [[ ! -e ${CHECK_FILE} ]] ; do
                                echo "$(date -Iseconds)" File does not exist: ${CHECK_FILE}
                                sleep 15
                              done
                              ls -l ${CHECK_FILE}
    EOF
    {{< /text >}}

1. 应用配置：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install --skip-confirmation -f ./istio.yaml
    {{< /text >}}

1. 检查 Ingress-gateway Pod 状态：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   0/1     Running   0          20s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          25s
    {{< /text >}}

    只有在 SPIRE 服务器上为 Ingress-gateway Pod 和数据平面容器创建了相应的注册条目后，它们才会达到 `Ready` 状态。
    接着，Envoy 将能够从 SPIRE 中获取加密身份信息。
    请参阅[注册工作负载](#register-workloads)以为您的网格中的服务注册条目。

Istio 配置与入口网关以及将要注入到工作负载 Pod 上的 Sidecar 共享 `spiffe-csi-driver`，
从而使它们能够访问 SPIRE 代理的 UNIX 域套接字。

此配置还向网关添加了一个 initContainer，它将等待 SPIRE 创建 UNIX 域套接字，然后再启动 istio-proxy。
如果 SPIRE 代理尚未准备好，或者尚未使用相同的套接字路径正确配置，Ingress 网关的 initContainer 将永远处于等待状态。

## 注册工作负载 {#register-workloads}

本节描述了在SPIRE服务器中注册工作负载的可用选项。

### 选项1：使用 SPIRE 控制器管理器进行注册 {#option-1-registration-using-the-spire-controller-manager}

将为与 [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md)
自定义资源中定义的选择器匹配的每个新 Pod 自动注册新条目。
请参阅[使用 SPIRE 控制器管理器进行工作负载注册的配置](#option-1-configuration-for-workload-registration-with-the-spire-controller-manager)以获取
ClusterSPIFFEID 示例配置。

1. 部署示例工作负载：

    {{< text syntax=bash snip_id=apply_sleep >}}
    $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    除了需要 `spiffe.io/spire-managed-identity` 标签之外，工作负载还需要使用 SPIFFE CSI
    驱动器卷来访问 SPIRE 代理套接字。为了实现这一点，您可以利用[安装 Istio](#install-istio) 部分中的
    `spire` Pod 注解模板，或者将 CSI 卷添加到您的工作负载的部署规范中。这两种方法都在下面的示例片段中进行了突出显示：

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      selector:
          matchLabels:
            app: sleep
      template:
          metadata:
            labels:
              app: sleep
              spiffe.io/spire-managed-identity: "true"
            # 注入自定义 Sidecar 模板
            annotations:
                inject.istio.io/templates: "sidecar,spire"
          spec:
            terminationGracePeriodSeconds: 0
            serviceAccountName: sleep
            containers:
            - name: sleep
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
              # CSI volume
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
    {{< /text >}}

请参阅[验证为工作负载创建的身份](#verifying-that-identities-were-created-for-workloads)
以检查已颁发的身份。

请注意，在[快速入门](#option-1-quick-start)部分中使用了`SPIRE控制器管理器`。

### 选项 2：手动注册 {#option-2-manual-registration}

为提高工作负载的认证安全性和稳健性，SPIRE 能够根据不同参数的一组选择器值来进行验证。
如果您是参照[快速入门](#option-1-quick-start)中的步骤来安装 `SPIRE`，则可以跳过这些步骤，
因为 SPIRE 使用自动注册的机制。

1. 使用一组选择器为 Ingress Gateway 生成条目，例如 Pod 名称和 Pod UID：

    {{< text bash >}}
    $ INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
    $ INGRESS_POD_UID=$(kubectl get pods -n istio-system "$INGRESS_POD" -o jsonpath='{.metadata.uid}')
    {{< /text >}}

1. 获取 spire-server Pod：

    {{< text syntax=bash snip_id=set_spire_server_pod_name_var >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l app=spire-server -n spire -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. 为节点上运行的 SPIRE 代理注册一个条目：

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s_psat:cluster:demo-cluster \
        -selector k8s_psat:agent_ns:spire \
        -selector k8s_psat:agent_sa:spire-agent \
        -node -socketPath /run/spire/sockets/server.sock

    Entry ID         : d38c88d0-7d7a-4957-933c-361a0a3b039c
    SPIFFE ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Parent ID        : spiffe://example.org/spire/server
    Revision         : 0
    TTL              : default
    Selector         : k8s_psat:agent_ns:spire
    Selector         : k8s_psat:agent_sa:spire-agent
    Selector         : k8s_psat:cluster:demo-cluster
    {{< /text >}}

1. 为 Ingress-gateway Pod 注册一个条目：

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:sa:istio-ingressgateway-service-account \
        -selector k8s:ns:istio-system \
        -selector k8s:pod-uid:"$INGRESS_POD_UID" \
        -dns "$INGRESS_POD" \
        -dns istio-ingressgateway.istio-system.svc \
        -socketPath /run/spire/sockets/server.sock

    Entry ID         : 6f2fe370-5261-4361-ac36-10aae8d91ff7
    SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
    Parent ID        : spiffe://example.org/ns/spire/sa/spire-agent
    Revision         : 0
    TTL              : default
    Selector         : k8s:ns:istio-system
    Selector         : k8s:pod-uid:63c2bbf5-a8b1-4b1f-ad64-f62ad2a69807
    Selector         : k8s:sa:istio-ingressgateway-service-account
    DNS name         : istio-ingressgateway.istio-system.svc
    DNS name         : istio-ingressgateway-5b45864fd4-lgrxs
    {{< /text >}}

1. 部署示例工作负载：

    {{< text bash >}}
    $ istioctl kube-inject --filename @samples/security/spire/sleep-spire.yaml@ | kubectl apply -f -
    {{< /text >}}

    请注意，工作负载需要使用 SPIFFE CSI 驱动器卷来访问 SPIRE 代理套接字。为了实现这一点，
    您可以使用[安装 Istio](#install-istio) 部分中的 `spire` Pod 注解模板，或者将 CSI
    卷添加到您的工作负载的部署规范中。这两种方法都在下面的示例片段中进行了突出显示：

    {{< text syntax=yaml snip_id=none >}}
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sleep
    spec:
      replicas: 1
      selector:
          matchLabels:
            app: sleep
      template:
          metadata:
            labels:
              app: sleep
            # 注入自定义 Sidecar 模板
            annotations:
                inject.istio.io/templates: "sidecar,spire"
          spec:
            terminationGracePeriodSeconds: 0
            serviceAccountName: sleep
            containers:
            - name: sleep
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
              # CSI volume
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
    {{< /text >}}

1. 获取 Pod 信息：

    {{< text syntax=bash snip_id=set_sleep_pod_vars >}}
    $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
    $ SLEEP_POD_UID=$(kubectl get pods "$SLEEP_POD" -o jsonpath='{.metadata.uid}')
    {{< /text >}}

1. 注册工作负载：

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/sleep \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-uid:"$SLEEP_POD_UID" \
        -dns "$SLEEP_POD" \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

{{< warning >}}
工作负载的 SPIFFE ID 必须遵循 Istio SPIFFE ID 规范：`spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

请参阅 [SPIRE 注册工作负载的帮助文档](https://spiffe.io/docs/latest/deploying/registering/)，了解如何为工作负载创建新条目，
并使用多个选择器进行认证以加强认证标准。

## 验证工作负载的身份是否已创建  {#verifying-that-identities-were-created-for-workloads}

请使用以下命令确认是否已为工作负载创建了身份：

{{< text bash >}}
$ kubectl exec -t "$SPIRE_SERVER_POD" -n spire -c spire-server -- ./bin/spire-server entry show
Found 2 entries
Entry ID         : c8dfccdc-9762-4762-80d3-5434e5388ae7
SPIFFE ID        : spiffe://example.org/ns/istio-system/sa/istio-ingressgateway-service-account
Parent ID        : spiffe://example.org/spire/agent/k8s_psat/demo-cluster/bea19580-ae04-4679-a22e-472e18ca4687
Revision         : 0
X509-SVID TTL    : default
JWT-SVID TTL     : default
Selector         : k8s:pod-uid:88b71387-4641-4d9c-9a89-989c88f7509d

Entry ID         : af7b53dc-4cc9-40d3-aaeb-08abbddd8e54
SPIFFE ID        : spiffe://example.org/ns/default/sa/sleep
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

在为入口网关 pod 注册条目后，Envoy 将收到 SPIRE 颁发的身份并将其用于所有 TLS 和 mTLS 通信。

### 检查工作负载身份是否由 SPIRE 颁发 {#check-that-the-workload-identity-was-issued-by-spire}

1. 使用 `istioctl proxy-config secret` 命令检索 sleep 的 SVID 身份文档：

    {{< text syntax=bash snip_id=get_sleep_svid >}}
    $ istioctl proxy-config secret "$SLEEP_POD" -o json | jq -r \
    '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
    {{< /text >}}

1. 检查证书并确认 SPIRE 是颁发者：

    {{< text syntax=bash snip_id=get_svid_subject >}}
    $ openssl x509 -in chain.pem -text | grep SPIRE
        Subject: C = US, O = SPIRE, CN = sleep-5f4d47c948-njvpk
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

如果您是通过 Istio 提供的快速入门 SPIRE 部署安装的 SPIRE，请使用以下命令来删除这些 Kubernetes 资源：

{{< text bash >}}
$ kubectl delete CustomResourceDefinition clusterspiffeids.spire.spiffe.io
$ kubectl delete CustomResourceDefinition clusterfederatedtrustdomains.spire.spiffe.io
$ kubectl delete -n spire configmap spire-bundle
$ kubectl delete -n spire serviceaccount spire-agent
$ kubectl delete -n spire configmap spire-agent
$ kubectl delete -n spire daemonset spire-agent
$ kubectl delete csidriver csi.spiffe.io
$ kubectl delete ValidatingWebhookConfiguration spire-controller-manager-webhook
$ kubectl delete -n spire configmap spire-controller-manager-config
$ kubectl delete -n spire configmap spire-server
$ kubectl delete -n spire service spire-controller-manager-webhook-service
$ kubectl delete -n spire service spire-server-bundle-endpoint
$ kubectl delete -n spire service spire-server
$ kubectl delete -n spire serviceaccount spire-server
$ kubectl delete -n spire deployment spire-server
$ kubectl delete clusterrole spire-server-cluster-role spire-agent-cluster-role manager-role
$ kubectl delete clusterrolebinding spire-server-cluster-role-binding spire-agent-cluster-role-binding manager-role-binding
$ kubectl delete -n spire role spire-server-role leader-election-role
$ kubectl delete -n spire rolebinding spire-server-role-binding leader-election-role-binding
$ kubectl delete namespace spire
$ rm istio.yaml chain.pem
{{< /text >}}
