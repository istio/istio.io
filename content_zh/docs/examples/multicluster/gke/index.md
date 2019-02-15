---
title: Google Kubernetes Engine
description: 基于 GKE 的 Istio 多集群安装。
weight: 65
keywords: [kubernetes,multicluster]
---

本文示例演示了如何使用 Istio 多集群功能，借助[基于 VPN 的多集群设置](/zh/docs/setup/kubernetes/multicluster-install/vpn/)将两个 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) 集群连接起来。

## 开始之前

在安装 Istio 的先决条件之外，本示例还需要如下安装步骤：

* 这个例子需要一个有效的 Google Platform 项目

* 此示例需要启用结算的有效 Google Cloud Platform 项目。

    * 如果你还没有建立 GCP 用户，那么还可以申请 300 美元的[免费试用](https://cloud.google.com/free/)额度。

    * [创建一个 Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) 来运行你的 GKE 集群。

* 安装并初始化 [Google Cloud SDK](https://cloud.google.com/sdk/install)

## 创建 GKE 集群

1. 为 `gcloud` 创建缺省项目以进行后续操作。

    {{< text bash >}}
    $ gcloud config set project myProject
    $ proj=$(gcloud config list --format='value(core.project)')
    {{< /text >}}

1. 创建两个 GKE 集群以便尝试多集群功能。

    **注意**：为了使用跨集群的直接 Pod 间通信，需要启用 `--enable-ip-alias`，`zone` 的值要从 [GCP zones](https://cloud.google.com/compute/docs/regions-zones/) 中进行选择。

    {{< text bash >}}
    $ zone="us-east1-b"
    $ cluster="cluster-1"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --cluster-version "1.9.6-gke.1" --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
      "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
      "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
      "https://www.googleapis.com/auth/trace.append" \
      --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    $ cluster="cluster-2"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --cluster-version "1.9.6-gke.1" --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
      "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
      "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
      "https://www.googleapis.com/auth/trace.append" \
      --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    {{< /text >}}

1. 反复执行下面的命令，等待集群进入 `RUNNING` 状态：

    {{< text bash >}}
    $ gcloud container clusters list
    {{< /text >}}

1. 获取集群凭据（[命令详情](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)）：

    {{< text bash >}}
    $ gcloud container clusters get-credentials cluster-1 --zone $zone
    $ gcloud container clusters get-credentials cluster-2 --zone $zone
    {{< /text >}}

1. 使用 `kubectl` 访问各个集群：

    1. 检查 `cluster-1`：

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
        $ kubectl get pods --all-namespaces
        {{< /text >}}

    1. 检查 `cluster-2`：

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
        $ kubectl get pods --all-namespaces
        {{< /text >}}

1. 为当前 GPC 用户的 Kubernetes 凭据创建一个 `cluster-admin` 角色绑定。

    **注意**：使用你的 Google Cloud 账号绑定的邮箱替换下面的 `mygcp@gmail.com`：

    {{< text bash >}}
    $ KUBE_USER="mygcp@gmail.com"
    $ kubectl create clusterrolebinding gke-cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user="${KUBE_USER}"
    {{< /text >}}

## 创建 Google Cloud 防火墙规则

为了允许每个集群中的 Pod 能够直接通信，创建如下规则：

{{< text bash >}}
$ function join_by { local IFS="$1"; shift; echo "$*"; }
$ ALL_CLUSTER_CIDRS=$(gcloud container clusters list --format='value(clusterIpv4Cidr)' | sort | uniq)
$ ALL_CLUSTER_CIDRS=$(join_by , $(echo "${ALL_CLUSTER_CIDRS}"))
$ ALL_CLUSTER_NETTAGS=$(gcloud compute instances list --format='value(tags.items.[0])' | sort | uniq)
$ ALL_CLUSTER_NETTAGS=$(join_by , $(echo "${ALL_CLUSTER_NETTAGS}"))
$ gcloud compute firewall-rules create istio-multicluster-test-pods \
  --allow=tcp,udp,icmp,esp,ah,sctp \
  --direction=INGRESS \
  --priority=900 \
  --source-ranges="${ALL_CLUSTER_CIDRS}" \
  --target-tags="${ALL_CLUSTER_NETTAGS}" --quiet
{{< /text >}}

## 安装 Istio 控制平面

接下来生成一个 Istio 安装文件、安装、并在 `default` 命名空间中启用 Sidecar 的自动注入：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio_master.yaml
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio_master.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

执行下面的命令，等待 Pod 启动：

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## 生成远程集群的安装文件

1. 获取控制平面 Pod 的 IP 地址：

    {{< text bash >}}
    $ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
    $ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
    $ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
    {{< /text >}}

1. 生成远程集群的安装文件：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-remote --namespace istio-system \
      --name istio-remote \
      --set global.remotePilotAddress=${PILOT_POD_IP} \
      --set global.remotePolicyAddress=${POLICY_POD_IP} \
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

## 安装远程集群

下面的步骤会安装一个最精简的 Istio 组件集合，并为远端集群 `default` 命名空间启用 Sidecar 的自动注入：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio-remote.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

## 为 Istio pilot 创建远程集群的 kubeconfig 文件

`istio-remote` Helm chart 会给 Istio pilot discovery 创建一个最小化权限的 Service account。

1. 在给 Service account `istio-multi` 创建 `kubeconfig` 文件之前，首先要准备环境变量：

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o "jsonpath={.clusters[].name}")
    $ CLUSTER_NAME="${CLUSTER_NAME##*_}"
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o "jsonpath={.clusters[].cluster.server}")
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-multi
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o "jsonpath={.data['token']}" | base64 --decode)
    {{< /text >}}

    **注意**：在很多系统中都可以使用 `openssl enc -d -base64 -A` 来替代 `base64 --decode`。

1. 在工作目录中为 Service account 创建一个 `kubeconfig` 文件：

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

至此，远程集群的 `kubeconfig` 就已经创建好并保存到了 `${WORK_DIR}` 目录之中了，文件名称和原始的 `kubeconfig` 文件中的集群名称一致。

## 配置 Istio 控制平面，以发现远程集群

为每个远程集群创建 secret 并用标签进行标记：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

## 部署跨集群的 Bookinfo 示例

1. 在第一个集群上安装 Bookinfo，然后删除 `reviews-v3` 的 `Deployment`，以便在远程集群进行部署：

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    $ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1. 为远端集群创建 `reviews-v3.yaml` 文件，准备部署：

    {{< text yaml plain "reviews-v3.yaml" >}}
    ---
    ##################################################################################################
    # Ratings service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: ratings
      labels:
        app: ratings
    spec:
      ports:
      - port: 9080
        name: http
    ---
    ##################################################################################################
    # Reviews service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: reviews
      labels:
        app: reviews
    spec:
      ports:
      - port: 9080
        name: http
      selector:
        app: reviews
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: reviews-v3
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: reviews
            version: v3
        spec:
          containers:
          - name: reviews
            image: istio/examples-bookinfo-reviews-v3:1.5.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    EOF
    {{< /text >}}

    **注意**：`ratings` 服务定义也被加入远程集群，其原因是 `reviews-v3` 是 `ratings` 的客户端，创建了服务对象，就创建了 DNS 条目。`reivews-v3` 中的 Sidecar 会在 DNS 解析到服务地址之后来确定正确的 `ratings` 服务端点。如果使用的是多集群 DNS 方案，例如在 Kubernetes 联邦集群之中，这一步骤就不必执行了。

1. 在远端部署 `reviews-v3`：

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
    $ kubectl apply -f $HOME/reviews-v3.yaml
    {{< /text >}}

1. 获取 `istio-ingressgateway` 服务的外部 IP，以便发起对 `bookinfo` 页面的访问，来验证 Istio 是否已经在 reviews 服务的负载均衡中包含了远端集群的 `reviews-v3` 实例：

    {{< text bash >}}
    $ kubectl get svc istio-ingressgateway -n istio-system
    {{< /text >}}

    重复访问 `http://<GATEWAY_IP>/productpage`，每个版本的 `reviews` 服务应该会以同样几率做出响应，其中包含了远端集群的 `reviews-v3`（红色）。可能需要多次访问才能看到预期效果。

## 卸载

除了按照[基于 VPN 的多集群卸载](/zh/docs/setup/kubernetes/multicluster-install/vpn/)操作之外，还应该执行以下步骤：

1. 删除 Google Cloud 防火墙规则：

    {{< text bash >}}
    $ gcloud compute firewall-rules delete istio-multicluster-test-pods --quiet
    {{< /text >}}

1. 从不再用于 Istio 的每个集群中删除 `cluster-admin` 角色绑定：

    {{< text bash >}}
    $ kubectl delete clusterrolebinding gke-cluster-admin-binding
    {{< /text >}}

1. 删除不再使用的任何 GKE 集群。以下是远程集群 `cluster-2` 的示例 delete 命令：

    {{< text bash >}}
    $ gcloud container clusters delete cluster-2 --zone $zone
    {{< /text >}}
