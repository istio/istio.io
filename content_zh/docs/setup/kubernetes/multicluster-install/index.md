---
title: Istio 多集群设置
description: 安装支持多集群的 Istio。
weight: 65
keywords: [kubernetes,multicluster]
---

介绍 Istio 多集群的安装过程。

## 先决条件

* 两个或更多的 **1.7.3 以上版本** 的 Kubernetes 集群。
* 在 **一个** Kubernetes 上部署 [Istio 控制平面](/zh/docs/setup/kubernetes/quick-start/) 的能力。
* RFC 1918、VPN 或者其他更高级的网络技术，需完成下列要求：
    * 各集群的 Pod CIDR 范围和 Service CIDR 范围必须是唯一的，不允许相互重叠。
    * 每个集群中的所有的 Pod CIDR 需要能够互相路由。
    * 所有的 Kubernetes 控制平面 API Server 互相可路由。
* Helm **2.7.2 或者更新的版本**。Tiller 可选。
* 目前只有[手工注入 Sidecar 方式](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)经过了多集群验证。

## 注意事项和已知问题

{{< warning_icon >}}
0.8 版本在多集群模式下的的所有的注意事项和已知问题都在 [Issue](https://github.com/istio/istio/issues/4822) 中进行跟踪。

## 概要

在 Kubernetes 控制平面上运行远程配置，连接到 **同一个** Istio 控制平面。（主控）Istio 在连接了一个或多个 Kubernetes 集群之后，Envoy 就能和这个 Istio 控制平面进行通信，并生成一个跨越多个 Kubernetes 集群的网格网络。

## 在远程集群上创建 Service account，并生成 `kubeconfig` 文件

Istio 控制平面需要访问网格中的所有集群，来完成服务发现的目的。下面描述了如何在远程集群中创建一个 Service account，并赋予它必要的 RBAC 权限；后面还会使用这个 Service account 的凭据为远程集群生成一个 `kubeconfig` 文件，这样就可以访问远程集群了。

下面的过程应该在每一个要加入到服务网格中的集群上执行。这个过程需要对应集群的管理员用户来完成。

1. 创建一个名为 `istio-reader` 的 `ClusterRole`，用于 Istio 控制平面（对集群）的访问：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-reader
    rules:
       - apiGroups: ['']
         resources: ['nodes', 'pods', 'services', 'endpoints']
         verbs: ['get', 'watch', 'list']
    EOF
    {{< /text >}}

1. 为 Istio 控制平面创建一个 `ServiceAccount`，取名为 `istio-multi`：

    {{< text bash >}}
    $ export SERVICE_ACCOUNT=istio-multi
    $ export NAMESPACE=istio-system
    $ kubectl create ns ${NAMESPACE}
    $ kubectl create sa ${SERVICE_ACCOUNT} -n ${NAMESPACE}
    {{< /text >}}

1. 把前面创建的 `ServiceAccount` 和 `ClusterRole` 绑定起来：

    {{< text bash >}}
    $ kubectl create clusterrolebinding istio-multi --clusterrole=istio-reader --serviceaccount=${NAMESPACE}:${SERVICE_ACCOUNT}
    {{< /text >}}

1. 在创建 `kubeconfig` 文件之前，首先给 `istio-multi` 创建环境变量：

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    __注意__：在很多系统中可以使用 `openssl enc -d -base64 -A` 来替代 `base64 --decode`。

1. 在工作目录中为 `istio-multi` 用户创建 `kubeconfig` 文件。

    {{< text bash >}}
    $ cat <<EOF > ${KUBECFG_FILE}
    apiVersion: v1
    clusters:
       - cluster:
           certificate-authority-data: ${CA_DATA}
           server: ${SERVER}
         name: ${CLUSTER_NAME}
    contexts:
       - context:
           cluster: ${CLUSTER_NAME}
           user: ${CLUSTER_NAME}
         name: ${CLUSTER_NAME}
    current-context: ${CLUSTER_NAME}
    kind: Config
    preferences: {}
    users:
       - name: ${CLUSTER_NAME}
         user:
           token: ${TOKEN}
    EOF
    {{< /text >}}

完成这些步骤之后，就在当前目录中创建了远程集群的 `kubeconfig` 文件。集群的文件名和原始的 `kubeconfig` 集群名称一致。

## 为每个集群设置凭据

> 在预备运行 Istio 控制平面的集群上完成这部分工作。
> Istio 可以安装在 `istio-system` 之外的 namespace 中。

新建一个 namespace 用于保存 secret：

{{< text bash >}}
$ kubectl create ns istio-system
{{< /text >}}

> 可以在部署 Istio 控制平面之前或者之后创建这些 secret。创建 Secret 的过程中要使用 Istio 属性进行标记。
> 运行 Istio 控制平面的集群不需要保存和标记自己的 Secret。这是因为本地的 Node 始终会知道本集群的凭据，但却无法知晓远程节点的凭据。

为每个远程集群创建一个 Secret，并使用标签进行标记：

{{< text bash >}}
$ cd $WORK_DIR
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${CLUSTER_NAME} -n istio-system
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n istio-system
{{< /text >}}

{{< warning_icon >}}
这个 Secret 的命名和文件名一致。Kubernetes 的 Secret 键需符合 `DNS-1123 subdomain` [格式](https://tools.ietf.org/html/rfc1123#page-13) 的要求，例如文件名中不能包含下划线。如果不符合这一要求，就需要修改文件和 Secret 的名称。

## 在本地部署 Istio 的控制平面

在 **一个** Kubernetes 集群上[安装 Istio 控制平面](/zh/docs/setup/kubernetes/quick-start/#安装步骤)

## 在每个远程集群上安装 Istio 远程组件

Istio-remote 组件必须在每个远程集群上分别部署。有两种安装方式：使用 Helm 结合 Tiller，或者用 Helm 配合 `kubectl`。

### 从 Istio 控制平面设置 Istio 远程组件所需的 Pod IP 环境变量

> 在进行本节操作之前，请等待 Istio 控制平面完成初始化。
> 这个操作必须在 Istio 控制平面所在集群上运行，以便于完成对 Pilot、Policy 以及 Pod IP 端点的抓取工作。
> 如果在每个远程集群上都使用了 Helm + Tiller 的组合，在使用 Helm 把远程机群和 Istio 控制平面连接起来之前，首先要把环境变量拷贝到各个 Node 上。

{{< text bash >}}
$ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
$ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
$ export STATSD_POD_IP=$(kubectl -n istio-system get pod -l istio=statsd-prom-bridge -o jsonpath='{.items[0].status.podIP}')
$ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
$ export ZIPKIN_POD_IP=$(kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].status.podIP}')
{{< /text >}}

### 使用 Helm + `kubectl` 把远程集群连接到本地

1. 在远程集群上用 Helm template 命令来指定 Istio 控制平面的服务端点：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system --name istio-remote --set global.pilotEndpoint=${PILOT_POD_IP} --set global.policyEndpoint=${POLICY_POD_IP} --set global.statsdEndpoint=${STATSD_POD_IP} --set global.telemetryEndpoint=${TELEMETRY_POD_IP} --set global.zipkinEndpoint=${ZIPKIN_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

1. 为远程 Istio 创建一个 namespace。

    {{< text bash >}}
    $ kubectl create ns istio-system
    {{< /text >}}

1. 完成远程集群到 Istio 控制平面的连接：

    {{< text bash >}}
    $ kubectl create -f $HOME/istio-remote.yaml
    {{< /text >}}

### 使用 Helm + Tiller 进行远程集群的连接

1. 如果还没有给 Helm 设置 Service account，请执行：

    {{< text bash >}}
    $ kubectl create -f @install/kubernetes/helm/helm-service-account.yaml@
    {{< /text >}}

1. Helm 初始化：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 Helm Chart：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-remote --name istio-remote --set global.pilotEndpoint=${PILOT_POD_IP} --set global.policyEndpoint=${POLICY_POD_IP} --set global.statsdEndpoint=${STATSD_POD_IP} --namespace istio-system
    {{< /text >}}

### Helm 配置参数

> `pilotEndpoint`、`policyEndpoint` 以及 `statsdEndpoint` 必须是 Kubernetes 可以解析的。让这些变量可解析的最简单的办法就是指定这些服务中的 Pod IP。当然如果 Pod IP 发生变化，这种办法就会出现问题。

`istio-remote` Helm Chart 需要这三个变量来完成配置，如下表所示：

| Helm 变量 | 可接受取值 | 缺省值 | 作用 |
| --- | --- | --- | --- |
| `global.pilotEndpoint` | 一个有效的 IP 地址 | `istio-pilot.istio-system` | 指定 Istio 控制平面中的 Pilot 的 Pod IP 地址 |
| `global.policyEndpoint` | 一个有效的 IP 地址 | `istio-policy.istio-system` | 指定 Istio 控制平面中的 策略组件的 Pod IP 地址 |
| `global.statsdEndpoint` | 一个有效的 IP 地址 | `istio-statsd-prom-bridge.istio-system` | 指定 Istio 控制平面中的 `stats` 的 Pod IP 地址 |

## 删除

> 删除方法必须和之前的安装方法一致（`Helm and kubectl` 或者 `Helm and Tiller`）

### 使用 `kubectl` 删除 istio-remote

{{< text bash >}}
$ kubectl delete -f $HOME/istio-remote.yaml
{{< /text >}}

### 使用 Helm + Tiller 删除 istio-remote

{{< text bash >}}
$ helm delete --purge istio-remote
{{< /text >}}
