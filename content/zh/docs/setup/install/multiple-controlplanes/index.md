---
title: 在单集群中安装多个 Istio 控制面
description: 使用修订和 discoverySelectors 在单集群中安装多个 Istio 控制面。
weight: 55
keywords: [multiple,control,istiod,local]
owner: istio/wg-environments-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

本指南向您演示在单集群中安装多个 Istio 控制面的过程以及将工作负载的作用域指定到特定控制面的方式。
这个部署模型采用单个 Kubernetes 控制面以及多个 Istio 控制面和多个网格。
网格之间的分离通过 Kubernetes 命名空间和 RBAC 实现。

{{< image width="90%"
    link="single-cluster-multiple-istiods.svg"
    caption="Multiple meshes in a single cluster"
    >}}

使用 `discoverySelectors`，您可以将集群中 Kubernetes 资源的作用域指定到某个 Istio 控制面管理的特定命名空间。
这包括用于配置网格的 Istio 自定义资源（例如 Gateway、VirtualService、DestinationRule 等）。
此外，`discoverySelectors` 可用于配置哪个命名空间应包括用于特定 Istio 控制面的 `istio-ca-root-cert` ConfigMap。
这些功能共同允许网格操作员为给定的控制面指定命名空间，从而基于一个或多个命名空间的边界为多个网格启用软多租户。
本指南使用 `discoverySelectors` 以及 Istio 的修订功能来演示如何在单集群上部署两个网格，每个网格使用适当作用域的集群资源子集。

## 开始之前{#before-you-begin}

本指南要求您有一个 Kubernetes 集群，其上安装了任一[支持的 Kubernetes 版本：](/zh/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}。

本集群将包含两个不同的系统命名空间中安装的两个控制面。
网格应用负载将运行在多个应用特定的命名空间中，每个命名空间基于修订和发现选择器配置与一个或另一个控制面关联。

## 集群配置{#cluster-configuration}

### 部署多个控制面{#deploying-multiple-control-planes}

在单集群上部署多个 Istio 控制面可通过为每个控制面使用不同的系统命名空间来达成。
Istio 修订和 `discoverySelectors` 然后用于确定每个控制面托管的资源和工作负载的作用域。

{{< warning >}}
Istio 默认仅使用 `discoverySelectors` 确定工作负载端点的作用域。
若要启用包括配置资源在内的完整资源作用域，`ENABLE_ENHANCED_RESOURCE_SCOPING` 特性标记必须被设置为 true。
{{< /warning >}}

1. 创建第一个系统命名空间 `usergroup-1` 并在其中部署 istiod：

    {{< text bash >}}
    $ kubectl create ns usergroup-1
    $ kubectl label ns usergroup-1 usergroup=usergroup-1
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-1
    spec:
      profile: minimal
      revision: usergroup-1
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-1
      values:
        global:
          istioNamespace: usergroup-1
        pilot:
          env:
            ENABLE_ENHANCED_RESOURCE_SCOPING: true
    EOF
    {{< /text >}}

1. 创建第二个系统命名空间 `usergroup-2` 并在其中部署 istiod：

    {{< text bash >}}
    $ kubectl create ns usergroup-2
    $ kubectl label ns usergroup-2 usergroup=usergroup-2
    $ istioctl install -y -f - <<EOF
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    metadata:
      namespace: usergroup-2
    spec:
      profile: minimal
      revision: usergroup-2
      meshConfig:
        discoverySelectors:
          - matchLabels:
              usergroup: usergroup-2
      values:
        global:
          istioNamespace: usergroup-2
        pilot:
          env:
            ENABLE_ENHANCED_RESOURCE_SCOPING: true
    EOF
    {{< /text >}}

1. 在 `usergroup-1` 命名空间中为工作负载部署策略，以便只能接收双向 TLS 流量：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-1-peerauth"
      namespace: "usergroup-1"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

1. 在 `usergroup-2` 命名空间中为工作负载部署策略，以便只能接收双向 TLS 流量：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: PeerAuthentication
    metadata:
      name: "usergroup-2-peerauth"
      namespace: "usergroup-2"
    spec:
      mtls:
        mode: STRICT
    EOF
    {{< /text >}}

### 确认创建多个控制面{#verify-multiple-control-plane-creation}

1. 查看每个控制面的系统命名空间上的标签：

    {{< text bash >}}
    $ kubectl get ns usergroup-1 usergroup2 --show-labels
    NAME              STATUS   AGE     LABELS
    usergroup-1       Active   13m     kubernetes.io/metadata.name=usergroup-1,usergroup=usergroup-1
    usergroup-2       Active   12m     kubernetes.io/metadata.name=usergroup-2,usergroup=usergroup-2
    {{< /text >}}

1. 确认控制面被部署且正在运行：

    {{< text bash >}}
    $ kubectl get pods -n usergroup-1
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-1   istiod-usergroup-1-5ccc849b5f-wnqd6      1/1     Running   0                12m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n usergroup-2
    NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
    usergroup-2   istiod-usergroup-2-658d6458f7-slpd9      1/1     Running   0                12m
    {{< /text >}}

    您会注意到在指定的命名空间中为每个用户组创建了一个 Istiod Deployment。

1. 执行以下命令列出已安装的 Webhook：

    {{< text bash >}}
    $ kubectl get validatingwebhookconfiguration
    NAME                                      WEBHOOKS   AGE
    istio-validator-usergroup-1-usergroup-1   1          18m
    istio-validator-usergroup-2-usergroup-2   1          18m
    istiod-default-validator                  1          18m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfiguration
    NAME                                             WEBHOOKS   AGE
    istio-revision-tag-default-usergroup-1           4          18m
    istio-sidecar-injector-usergroup-1-usergroup-1   2          19m
    istio-sidecar-injector-usergroup-2-usergroup-2   2          18m
    {{< /text >}}

    请注意，输出包括 `istiod-default-validator` 和 `istio-revision-tag-default-usergroup-1`，它们是用于处理来自与任何修订无关的资源请求的默认 Webhook 配置。
    在一个完整作用域的环境中，每个控制面都通过适当的命名空间标签与其资源相关联，不需要这些默认的 Webhook 配置。
    它们不应该被调用。

### 每个用户组部署应用负载{#deploy-app-workloads-per-usergroup}

1. 创建三个应用命名空间：

    {{< text bash >}}
    $ kubectl create ns app-ns-1
    $ kubectl create ns app-ns-2
    $ kubectl create ns app-ns-3
    {{< /text >}}

1. 为每个命名空间打标签，将其与各自的控制面相关联：

    {{< text bash >}}
    $ kubectl label ns app-ns-1 usergroup=usergroup-1 istio.io/rev=usergroup-1
    $ kubectl label ns app-ns-2 usergroup=usergroup-2 istio.io/rev=usergroup-2
    $ kubectl label ns app-ns-3 usergroup=usergroup-2 istio.io/rev=usergroup-2
    {{< /text >}}

1. 为每个命名空间部署一个 `sleep` 和 `httpbin` 应用：

    {{< text bash >}}
    $ kubectl -n app-ns-1 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-1 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-2 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-2 apply -f samples/httpbin/httpbin.yaml
    $ kubectl -n app-ns-3 apply -f samples/sleep/sleep.yaml
    $ kubectl -n app-ns-3 apply -f samples/httpbin/httpbin.yaml
    {{< /text >}}

1. 等待几秒钟，让 `httpbin` 和 `sleep` Pod 在注入 Sidecar 的情况下运行：

    {{< text bash >}}
    $ kubectl get pods -n app-ns-1
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-zc2v4   2/2     Running   0          115m
    sleep-78ff5975c6-fml7c    2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-2
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-sd9ln   2/2     Running   0          115m
    sleep-78ff5975c6-sz728    2/2     Running   0          115m
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get pods -n app-ns-3
    NAME                      READY   STATUS    RESTARTS   AGE
    httpbin-9dbd644c7-8ll27   2/2     Running   0          115m
    sleep-78ff5975c6-sg4tq    2/2     Running   0          115m
    {{< /text >}}

### 确认应用到控制面的映射{#verify-app-to-control-plane-mapping}

现在应用已部署，您可以使用 `istioctl ps` 命令确认应用负载由其各自的控制面管理，
即 `app-ns-1` 由 `usergroup-1` 管理，`app-ns-2` 和 `app-ns-3` 由 `usergroup-2` 管理：

{{< text bash >}}
$ istioctl ps -i usergroup-1
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-hccpf.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-9zb77.app-ns-1      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

{{< text bash >}}
$ istioctl ps -i usergroup-2
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-vvcqj.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
httpbin-9dbd644c7-xzgfm.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-fthmt.app-ns-2      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-nxtth.app-ns-3      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
{{< /text >}}

### 确认应用连接仅在各个用户组内{#verify-app-conn-is-only-within-respective-usergroup}

1. 将 `usergroup-1` 中 `app-ns-1` 中的 `sleep` Pod 的请求发送到 `usergroup-2` 中 `app-ns-2` 中的 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl -n app-ns-1 exec "$(kubectl -n app-ns-1 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-2.svc.cluster.local:8000
    HTTP/1.1 503 Service Unavailable
    content-length: 95
    content-type: text/plain
    date: Sat, 24 Dec 2022 06:54:54 GMT
    server: envoy
    {{< /text >}}

1. 将 `usergroup-2` 中 `app-ns-2` 中的 `sleep` Pod 的请求发送到 `usergroup-2` 中 `app-ns-3` 中的 `httpbin` 服务：通信应发挥作用：

    {{< text bash >}}
    $ kubectl -n app-ns-2 exec "$(kubectl -n app-ns-2 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-3.svc.cluster.local:8000
    HTTP/1.1 200 OK
    server: envoy
    date: Thu, 22 Dec 2022 15:01:36 GMT
    content-type: text/html; charset=utf-8
    content-length: 9593
    access-control-allow-origin: *
    access-control-allow-credentials: true
    x-envoy-upstream-service-time: 3
    {{< /text >}}

## 清理{#cleanup}

1. 清理第一个用户组：

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-1
    $ kubectl delete ns app-ns-1 usergroup-1
    {{< /text >}}

1. 清理第二个用户组：

    {{< text bash >}}
    $ istioctl uninstall --revision usergroup-2
    $ kubectl delete ns app-ns-2 app-ns-3 usergroup-2
    {{< /text >}}

{{< warning >}}
集群管理员必须确保网格管理员无权调用全局 `istioctl uninstall --purge` 命令，因为这将卸载集群中的所有控制面。
{{< /warning >}}
