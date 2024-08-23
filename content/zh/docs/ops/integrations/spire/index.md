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

We recommend you follow SPIRE's installation instructions and best practices for installing SPIRE, and for deploying SPIRE in production environments.

For the examples in this guide, the [SPIRE Helm charts](https://artifacthub.io/packages/helm/spiffe/spire) will be used with upstream defaults, to focus on just the configuration necessary to integrate SPIRE and Istio.

{{< text syntax=bash snip_id=install_spire_crds >}}
$ helm upgrade --install -n spire-server spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace
{{< /text >}}

{{< text syntax=bash snip_id=install_spire_istio_overrides >}}
$ helm upgrade --install -n spire-server spire spire --repo https://spiffe.github.io/helm-charts-hardened/ --wait --set global.spire.trustDomain="example.org"
{{< /text >}}

{{< tip >}}
See the [SPIRE Helm chart](https://artifacthub.io/packages/helm/spiffe/spire) documentation for other values you can configure for your installation.

It is important that SPIRE and Istio are configured with the exact same trust domain, to prevent authentication and authorization errors, and that the [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi) is enabled and installed.
{{< /tip >}}

By default, the above will also install:

- The [SPIFFE CSI driver](https://github.com/spiffe/spiffe-csi), which is used to mount an Envoy-compatible SDS socket into proxies. Using the SPIFFE CSI driver to mount SDS sockets is strongly recommended by both Istio and SPIRE, as `hostMounts` are a larger security risk and introduce operational hurdles. This guide assumes the use of the SPIFFE CSI driver.

- The [SPIRE Controller Manager](https://github.com/spiffe/spire-controller-manager), which eases the creation of SPIFFE registrations for workloads.

## Register workloads

By design, SPIRE only grants identities to workloads that have been registered with the SPIRE server; this includes user workloads, as well as Istio components. Istio sidecars and gateways, once configured for SPIRE integration, cannot get identities, and therefore cannot reach READY status, unless there is a preexisting, matching SPIRE registration created for them ahead of time.

See the [SPIRE docs on registering workloads](https://spiffe.io/docs/latest/deploying/registering/) for more information on using multiple selectors to strengthen attestation criteria, and the selectors available.

This section describes the options available for registering Istio workloads in a SPIRE Server and provides some example workload registrations.

{{< warning >}}
Istio currently requires a specific SPIFFE ID format for workloads. All registrations must follow the Istio SPIFFE ID pattern: `spiffe://<trust.domain>/ns/<namespace>/sa/<service-account>`
{{< /warning >}}

### Option 1: Auto-registration using the SPIRE Controller Manager


New entries will be automatically registered for each new pod that matches the selector defined in a [ClusterSPIFFEID](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) custom resource.

Both Istio sidecars and Istio gateways need to be registered with SPIRE, so that they can request identities.

#### Istio Gateway `ClusterSPIFFEID`

The following will create a `ClusterSPIFFEID`, which will auto-register any Istio Ingress gateway pod with SPIRE if it is scheduled into the `istio-system` namespace, and has a service account named `istio-ingressgateway-service-account`. These selectors are used as a simple example; consult the [SPIRE Controller Manager documentation](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) for more details.


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

#### Istio Sidecar `ClusterSPIFFEID`

The following will create a `ClusterSPIFFEID` which will auto-register any pod with the `spiffe.io/spire-managed-identity: true` label that is deployed into the `default` namespace with SPIRE. These selectors are used as a simple example; consult the [SPIRE Controller Manager documentation](https://github.com/spiffe/spire-controller-manager/blob/main/docs/clusterspiffeid-crd.md) for more details.

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

### Option 2: Manual Registration

If you wish to manually create your SPIRE registrations, rather than use the SPIRE Controller Manager mentioned in [the recommended option](#option-1-auto-registration-using-the-spire-controller-manager), refer to the [SPIRE documentation on manual registration](https://spiffe.io/docs/latest/deploying/registering/).


Below are the equivalent manual registrations based off the automatic registrations in [Option 1](#option-1-auto-registration-using-the-spire-controller-manager). The following steps assume you have [already followed the SPIRE documentation to manually register your SPIRE agent and node attestation](https://spiffe.io/docs/latest/deploying/registering/#1-defining-the-spiffe-id-of-the-agent) and that your SPIRE agent was registered with the SPIFFE identity `spiffe://example.org/ns/spire/sa/spire-agent`.

1. Get the `spire-server` pod:

    {{< text syntax=bash snip_id=set_spire_server_pod_name_var >}}
    $ SPIRE_SERVER_POD=$(kubectl get pod -l statefulset.kubernetes.io/pod-name=spire-server-0 -n spire-server -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}

1. Register an entry for the Istio Ingress gateway pod:

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

1. Register an entry for workloads injected with an Istio sidecar:

    {{< text bash >}}
    $ kubectl exec -n spire "$SPIRE_SERVER_POD" -- \
    /opt/spire/bin/spire-server entry create \
        -spiffeID spiffe://example.org/ns/default/sa/sleep \
        -parentID spiffe://example.org/ns/spire/sa/spire-agent \
        -selector k8s:ns:default \
        -selector k8s:pod-label:spiffe.io/spire-managed-identity:true \
        -socketPath /run/spire/sockets/server.sock
    {{< /text >}}

## Install Istio

1. [下载 Istio 发行版](/zh/docs/setup/additional-setup/download-istio-release/)。

1. Create the Istio configuration with custom patches for the Ingress Gateway and `istio-proxy`. The Ingress Gateway component includes the `spiffe.io/spire-managed-identity: "true"` label.

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
        # This is used to customize the sidecar template.
        # It adds both the label to indicate that SPIRE should manage the
        # identity of this pod, as well as the CSI driver mounts.
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
                # This is used to customize the ingress gateway template.
                # It adds the CSI driver mounts, as well as an init container
                # to stall gateway startup until the CSI driver mounts the socket.
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
                          image: busybox:1.36
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

1. 检查 Ingress Gateway Pod 状态：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-ingressgateway-5b45864fd4-lgrxs   1/1     Running   0          17s
    istiod-989f54d9c-sg7sn                  1/1     Running   0          23s
    {{< /text >}}

    The Ingress Gateway pod is `Ready` since the corresponding registration entry is automatically created for it on the SPIRE Server. Envoy is able to fetch cryptographic identities from SPIRE.

    This configuration also adds an `initContainer` to the gateway that will wait for SPIRE to create the UNIX Domain Socket before starting the `istio-proxy`. If the SPIRE agent is not ready, or has not been properly configured with the same socket path, the Ingress Gateway `initContainer` will wait forever.


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

The Istio configuration shares the `spiffe-csi-driver` with the Ingress Gateway and the sidecars that are going to be injected on workload pods, granting them access to the SPIRE Agent's UNIX Domain Socket.


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

在为入口网关 Pod 注册条目后，Envoy 将收到 SPIRE 颁发的身份并将其用于所有 TLS 和 mTLS 通信。

### 检查工作负载身份是否由 SPIRE 颁发 {#check-that-the-workload-identity-was-issued-by-spire}

1. Get pod information:

    {{< text syntax=bash snip_id=set_sleep_pod_var >}}
    $ SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath="{.items[0].metadata.name}")
    {{< /text >}}


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

Remove SPIRE by uninstalling its Helm charts:

{{< text syntax=bash snip_id=uninstall_spire >}}
$ helm delete -n spire-server spire
{{< /text >}}

{{< text syntax=bash snip_id=uninstall_spire_crds >}}
$ helm delete -n spire-server spire-crds
{{< /text >}}
