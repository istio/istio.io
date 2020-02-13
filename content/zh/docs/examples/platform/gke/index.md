---
title: Google Kubernetes Engine
description: 在两个 GKE 集群上设置多集群网格。
weight: 65
keywords: [kubernetes,multicluster]
aliases:
  - /zh/docs/tasks/multicluster/gke/
  - /zh/docs/examples/multicluster/gke/
---

此示例展示在两个 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/) 集群上使用[单网络 deployment](/zh/docs/ops/deployment/deployment-models/#single-network) 配置多集群网格。

## 开始之前{#before-you-begin}

除了为安装 Istio 准备环境，该示例还需要以下设置：

* 该示例需要一个有效并开启计费功能的 Google Cloud Platform project。如果您
  还不是 GCP 用户，您或许可以注册并获得 $300 美元的[免费使用](https://cloud.google.com/free/) 信用额度。

    * [创建一个 Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) 来
      托管您的 GKE 集群。

* 安装并初始化 [Google Cloud SDK](https://cloud.google.com/sdk/install)

## 创建 GKE 集群

1.  为 `gcloud` 设置默认的项目，并执行以下操作：

    {{< text bash >}}
    $ gcloud config set project myProject
    $ proj=$(gcloud config list --format='value(core.project)')
    {{< /text >}}

1.  创建 2 GKE 集群来使用多集群的特性。 _注意：_ `--enable-ip-alias` 需要允许集群中 pod 之间的直接通信。该 `zone` 值必须是
    [GCP zones](https://cloud.google.com/compute/docs/regions-zones/) 其中之一。

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

1.  通过以下命令轮询集群的状态，以等待集群转换为 `RUNNING` 状态：

    {{< text bash >}}
    $ gcloud container clusters list
    {{< /text >}}

1.  获取集群证书的 ([详细命令](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials))：

    {{< text bash >}}
    $ gcloud container clusters get-credentials cluster-1 --zone $zone
    $ gcloud container clusters get-credentials cluster-2 --zone $zone
    {{< /text >}}

1.  验证 `kubectl` 是否能访问每一个集群，并创建一个 `cluster-admin` 集群角色，使其与 GCP 用户关联的 Kubernetes 证书绑定。

    1.  对于 cluster-1：

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

    1.  对于 cluster-2：

        {{< text bash >}}
        $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
        $ kubectl get pods --all-namespaces
        $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
        {{< /text >}}

## 创建 Google Cloud 防火墙规则{#create-a-google-cloud-firewall-rule}

为了允许 pod 在每个集群中直接通信，创建以下规则：

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

## 安装 Istio 控制平面{#install-the-Istio-control-plane}

以下命令生成 Istio 安装清单，使其安装，并在 `default` 命名空间开启 sidecar 自动注入：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio_master.yaml
$ kubectl create ns istio-system
$ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
$ kubectl apply -f $HOME/istio_master.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

通过以下命令轮询其状态，以等待 pod 创建完成：

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## 生成远程集群清单{#generate-remote-cluster-manifest}

1.  获取控制平面 pod 的 IP：

    {{< text bash >}}
    $ export PILOT_POD_IP=$(kubectl -n istio-system get pod -l istio=pilot -o jsonpath='{.items[0].status.podIP}')
    $ export POLICY_POD_IP=$(kubectl -n istio-system get pod -l istio=mixer -o jsonpath='{.items[0].status.podIP}')
    $ export TELEMETRY_POD_IP=$(kubectl -n istio-system get pod -l istio-mixer-type=telemetry -o jsonpath='{.items[0].status.podIP}')
    {{< /text >}}

1.  生成远程集群清单；

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio \
      --namespace istio-system --name istio-remote \
      --values @install/kubernetes/helm/istio/values-istio-remote.yaml@ \
      --set global.remotePilotAddress=${PILOT_POD_IP} \
      --set global.remotePolicyAddress=${POLICY_POD_IP} \
      --set global.remoteTelemetryAddress=${TELEMETRY_POD_IP} > $HOME/istio-remote.yaml
    {{< /text >}}

## 安装远程集群清单中的配置{#install-remote-cluster-manifest}

以下命令将安装 Istio 最低配置所需的组件， 并在远程集群上的 `default` 命名空间开启 sidecar 自动注入：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/istio-remote.yaml
$ kubectl label namespace default istio-injection=enabled
{{< /text >}}

## 为 Istio Pilot 创建远程集群的 kubeconfig{#create-remote-cluster's-kubeconfig-for-Istio-pilot}

The `istio-remote` Helm 图表创建了一个具有最少访问权限的服务帐户，供 Istio Pilot 发现使用。

1.  准备环境变量为服务账户 `istio-multi` 创建 `kubeconfig` 文件：

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
    在许多系统中，`openssl enc -d -base64 -A` 是 `base64 --decode` 是的一种替代方式。
    {{< /tip >}}

1.  在工作目录中为服务账户 `istio-multi` 创建一个 `kubeconfig` 文件：

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

至此，远程集群的 `kubeconfig` 文件已被创建在 `${WORK_DIR}` 目录中。
集群的文件名与原始的 `kubeconfig` 集群名字相同。

## 配置 Istio 控制平面来发现远程集群{#configure-Istio-control-plane-to-discover-the-remote-cluster}

创建 secret 并为每一个远程集群标记：

{{< text bash >}}
$ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
$ kubectl create secret generic ${CLUSTER_NAME} --from-file ${KUBECFG_FILE} -n ${NAMESPACE}
$ kubectl label secret ${CLUSTER_NAME} istio/multiCluster=true -n ${NAMESPACE}
{{< /text >}}

## 跨集群部署 Bookinfo 示例{#deploy-the-Bookinfo-example-across-clusters}

1.  在第一个集群上安装 Bookinfo。移除 `reviews-v3` deployment 来部署在远程上：

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1.  在远程集群上安装 `reviews-v3` deployment。

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-2"
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l service=ratings
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l service=reviews
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l account=reviews
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@ -l app=reviews,version=v3
    {{< /text >}}

    _注意：_ 该 `ratings` 服务定义被添加到远程集群，因为 `reviews-v3` 是
    `ratings` 的一个客户端，并创建服务对象以创建 DNS 条目。
    在 DNS 查询被解析为服务地址后，在 `reviews-v3` pod 中的 Istio sidecar 将确定正确的 `ratings` endpoint。
    如果额外设置了多集群的 DNS 解决方案，例如联邦 Kubernetes 环境，则上面的步骤是没必要的。

1.  获取 `istio-ingressgateway` 服务的外部 IP 访问 `bookinfo` 页面以验证 Istio 是否
    在 review 版本的负载均衡中包括远程的 `reviews-v3` 实例：

    {{< text bash >}}
    $ kubectl config use-context "gke_${proj}_${zone}_cluster-1"
    $ kubectl get svc istio-ingressgateway -n istio-system
    {{< /text >}}

    重复访问 `http://<GATEWAY_IP>/productpage` 并且每个 review 的版本均应负载均衡，
    包含远程集群（红色星星）中的 `reviews-v3`。或许需要几次（数十次）操作才能演示 `reviews` 版本之间的负载均衡。

## 卸载 {#uninstalling}

除了卸载 Istio 之外，还应执行
[基于 VPN 的多集群卸载部分](/zh/docs/setup/install/multicluster/shared-vpn/) 中的操作：

1.  删除 Google Cloud 防火墙规则：

    {{< text bash >}}
    $ gcloud compute firewall-rules delete istio-multicluster-test-pods --quiet
    {{< /text >}}

1.  从不再用于 Istio 的每个集群中删除 `cluster-admin` 集群角色绑定：

    {{< text bash >}}
    $ kubectl delete clusterrolebinding gke-cluster-admin-binding
    {{< /text >}}

1.  删除不再使用的所有 GKE 集群。以下是删除 `cluster-2` 远程集群的命令示例：

    {{< text bash >}}
    $ gcloud container clusters delete cluster-2 --zone $zone
    {{< /text >}}
