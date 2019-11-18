---
title: Google Kubernetes 引擎
description: 在两套 GKE 集群之上搭建一个多集群的服务网格
weight: 65
keywords: [kubernetes,multicluster]
aliases:
  - /zh/docs/tasks/multicluster/gke/
---

这个例子展示了怎样通过一个 [single-network deployment](/docs/setup/deployment-models/#single-network) 在2个 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) 集群之上配置一个多集群的服务网格。 

## 开始之前

除了安装 `Istio` 的外，此示例还需要以下设置

* 这个例子需要一个有效的 `Google Cloud Platform` 项目并启用了计费功能, 如果你没有现成的 `GCP` 用户，你可以申请一个价值 $300  的 [免费试用](https://cloud.google.com/free/) 账户
    * [创建 Google Cloud  项目](https://cloud.google.com/resource-manager/docs/creating-managing-projects) 去托管你的 `GKE` 集群。

* 安装和初始化这个 [Google Cloud SDK](https://cloud.google.com/sdk/install)

## 创建 GKE 集群

1. 设置 `gcloud` 的默认项目以在其中执行操作:

    {{< text bash >}}
    $ gcloud config set project myProject
    $ proj=$(gcloud config list --format='value(core.project)')
    {{< /text >}}

1. 创建2个 `GKE` 集群。注意：`--enable-ip-alias` 是必须开启的，以允许集群间直接 `Pod` 到 `Pod` 的通信。区域必须是 [GCP zones](https://cloud.google.com/compute/docs/regions-zones/) 中的一个。

    {{< text bash >}}
    $ zone="us-east1-b"
    $ cluster="cluster-1"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
    "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
    "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
    "https://www.googleapis.com/auth/trace.append" \
    --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    $ cluster="cluster-2"
    $ gcloud container clusters create $cluster --zone $zone --username "admin" \
      --machine-type "n1-standard-2" --image-type "COS" --disk-size "100" \
      --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only",\
    "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring",\
    "https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly",\
    "https://www.googleapis.com/auth/trace.append" \
    --num-nodes "4" --network "default" --enable-cloud-logging --enable-cloud-monitoring --enable-ip-alias --async
    {{< /text >}}

1. 通过以下命令轮询集群的状态来等待集群转换为RUNNING状态

    {{< text bash >}}
    $ gcloud container clusters list
    {{< /text >}}

1. 获取集群的证书 ([命令](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials))

    {{< text bash >}}
    $ gcloud container clusters get-credentials cluster-1 --zone $zone
    $ gcloud container clusters get-credentials cluster-2 --zone $zone
    {{< /text >}}

1. 验证 `kubectl` 可以访问每个集群；并且能够创建 `cluster-admin` 集群角色，并将此角色和你的 `GCP` 用户关联绑定到 `Kubernetes` 证书上。

    1.  对于 cluster-1:

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

    1.  对于 cluster-2:

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

## 创建一个 Google Cloud 防火墙规则

要允许每个群集上的 `Pod` 直接通信，请创建以下规则:

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

下面的代码生成 `Istio` 安装清单，安装在 `default` 名称空间中并开启 `sidecar` 自动注入。

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio_master.yaml
$ kubectl create ns istio-system
$ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
$ kubectl apply -f $HOME/istio_master.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

通过以下命令轮询其状态，以等待 `Pod` 出现:

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## 生成远程集群清单

1.  获取控制平面 `Pod` 的 `IP`:

    {{< text bash >}}
    $ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
    $ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
    $ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
    {{< /text >}}

1.  生成远程集群清单:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio \
      --namespace istio-system --name istio-remote \
      --values @install/kubernetes/helm/istio/values-istio-remote.yaml@ \
      --set global.remotePilotAddress=${PILOT_POD_IP} \
      --set global.remotePolicyAddress=${POLICY_POD_IP} \
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

## 安装远程集群清单

以下内容将安装最少的 `Istio` 组件，并在远程集群中的 `default` 名称空间上启用 `sidecar` 注入。

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio-remote.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

## 为 Istio Pilot 创建远程集群的 kubeconfig

`istio-remote` Helm chart 创建了一个具有最少访问权限的服务帐户，供 `Istio Pilot` 发现使用。

1. 为构建 `kubeconfig` 文件准备环境遍历以及 `istio-multi` 的服务账号。

    {{< text bash >}}
    $ export WORK_DIR=$(pwd)
    $ CLUSTER_NAME=$(kubectl config view --minify=true -o jsonpath='{.clusters[].name}')
    $ CLUSTER_NAME="${CLUSTER_NAME##*_}"
    $ export KUBECFG_FILE=${WORK_DIR}/${CLUSTER_NAME}
    $ SERVER=$(kubectl config view --minify=true -o jsonpath='{.clusters[].cluster.server}')
    $ NAMESPACE=istio-system
    $ SERVICE_ACCOUNT=istio-multi
    $ SECRET_NAME=$(kubectl get sa ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
    $ CA_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['ca\.crt']}")
    $ TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath="{.data['token']}" | base64 --decode)
    {{< /text >}}

    {{< tip >}}
    An alternative to `base64 --decode` is `openssl enc -d -base64 -A` on many systems.
    {{< /tip >}}

1. 在工作目录中为 `istio-multi` 服务帐户创建 `kubeconfig` 文件。

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

至此，远程集群的 `kubeconfig` 文 件已在 `${WORK_DIR}` 目录中创建。集群的文件名与原始 `kubeconfig` 集群名称相同。

## 配置 Istio 控制平面以发现远程集群

创建一个密钥并且为每个远程集群都打上标签:

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

## 跨集群部署 Bookinfo 示例

1. 在第一个群集上安装 `Bookinfo`。 删除 `reviews-v3 Deployment` 以远程部署:

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1. 在远程集群上安装 `reviews-v3 Deployment`。

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l service=ratings
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l service=reviews
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l account=reviews
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l app=reviews,version=v3
    {{< /text >}}

    提示： 这 `ratings` 服务定义添加到远程集群，因为 `reviews-v3` 是 `ratings` 的客户端，并且创建服务对象会创建 `DNS` 记录。`DNS` 解析道服务地址之后, `reviews-v3 Pod` 中的 `Istio sidecar` 将确定适当的 `ratings endpoint` 。如果另外设置了多群集 `DNS` 解决方案，则没有必要。例如在联合 `Kubernetes` 环境中。

1. 获取 `istio-ingressgateway` 服务的外部 `IP` 来访问 `bookinfo` 页面，以验证`Istio` 是否在评论版本的负载平衡中包括了远程的 `reviews-v3` 实例。

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl get svc istio-ingressgateway -n istio-system
    {{< /text >}}

    重复访问 `http：// <GATEWAY_IP> / productpage`，并且每个评论版本均应均衡负载，包括远程群集中的 `reviews-v3`（红色星号）。可能需要几次访问（数十次）才能证明评论版本之间的负载均衡相等。

## 删除安装

除了基于 [VPN的多集群卸载](/docs/setup/install/multicluster/shared-vpn/) 部分中所述的 `Istio` 卸载之外，还应执行以下操作。
 
1.  删除 `Google Cloud` 防火墙规则：

    {{< text bash >}}
    $ gcloud compute firewall-rules delete istio-multicluster-test-pods --quiet
    {{< /text >}}

1.  从不再用于 `Istio` 的每个集群中删除 `cluster-admin` 集群角色绑定。

    {{< text bash >}}
    $ kubectl delete clusterrolebinding gke-cluster-admin-binding
    {{< /text >}}

1.  删除不再使用的所有 `GKE` 群集。以下是远程群集 `cluster-2` 的示例删除命令:

    {{< text bash >}}
    $ gcloud container clusters delete cluster-2 --zone $zone
    {{< /text >}}
