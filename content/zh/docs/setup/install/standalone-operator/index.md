---
title: 安装独立 Operator [实验]
description: 使用 Istio operator 在 Kubernetes 集群中安装 Istio 指南。
weight: 25
keywords: [kubernetes, operator]
aliases:
---

{{< boilerplate experimental-feature-warning >}}

该指南将会指引您使用独立的 Istio [operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/) 来安装 Istio。
唯一的依赖就是一个 Kubernetes 集群和 `kubectl` 命令行工具。

如果要安装生产环境的 Istio，我们还是建议您参考[使用 {{< istioctl >}} 安装](/zh/docs/setup/install/istioctl/)。

## 前提条件{#prerequisites}

1. 执行必要的[平台特定设置](/zh/docs/setup/platform-setup/)。

1. 检查 [Pods 和 Services 需求](/zh/docs/ops/deployment/requirements/)。

1. 部署 Istio operator：

    {{< text bash >}}
    $ kubectl apply -f https://preliminary.istio.io/operator.yaml
    {{< /text >}}

    这条命令会在 `istio-operator` 命名空间中创建以下资源并运行 Istio operator :

    - operator 自定义资源
    - operator 控制器 deployment
    - operator 指标信息 service
    - operator 必要的 RBAC 规则

## 安装{#install}

运行以下命令用 operator 安装 Istio `demo` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
{{< /text >}}

控制器会检测 `IstioControlPlane` 资源，然后按照指定的（`demo`）配置安装 Istio 组件。

您可以使用以下命令来确认 Istio 控制面板服务是否部署：

{{< text bash >}}
$ kubectl get svc -n istio-system
NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP                                                                                                                                     2m
istio-citadel            ClusterIP      172.21.177.222   <none>          8060/TCP,15014/TCP                                                                                                                           2m
istio-egressgateway      ClusterIP      172.21.113.24    <none>          80/TCP,443/TCP,15443/TCP                                                                                                                     2m
istio-galley             ClusterIP      172.21.132.247   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                                   2m
istio-ingressgateway     LoadBalancer   172.21.144.254   52.116.22.242   15020:31831/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30318/TCP,15030:32645/TCP,15031:31933/TCP,15032:31188/TCP,15443:30838/TCP   2m
istio-pilot              ClusterIP      172.21.105.205   <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                       2m
istio-policy             ClusterIP      172.21.14.236    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                                 2m
istio-sidecar-injector   ClusterIP      172.21.155.47    <none>          443/TCP,15014/TCP                                                                                                                            2m
istio-telemetry          ClusterIP      172.21.196.79    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                       2m
jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                                   2m
jaeger-collector         ClusterIP      172.21.135.51    <none>          14267/TCP,14268/TCP                                                                                                                          2m
jaeger-query             ClusterIP      172.21.26.187    <none>          16686/TCP                                                                                                                                    2m
kiali                    ClusterIP      172.21.155.201   <none>          20001/TCP                                                                                                                                    2m
prometheus               ClusterIP      172.21.63.159    <none>          9090/TCP                                                                                                                                     2m
tracing                  ClusterIP      172.21.2.245     <none>          80/TCP                                                                                                                                       2m
zipkin                   ClusterIP      172.21.182.245   <none>          9411/TCP                                                                                                                                     2m
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                                           READY   STATUS      RESTARTS   AGE
grafana-f8467cc6-rbjlg                                         1/1     Running     0          1m
istio-citadel-78df5b548f-g5cpw                                 1/1     Running     0          1m
istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
istio-pilot-f479bbf5c-qwr28                                    1/1     Running     0          1m
istio-policy-6fccc5c868-xhblv                                  1/1     Running     2          1m
istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
istio-telemetry-78b96c6cb6-ldm9q                               1/1     Running     2          1m
istio-tracing-69b5f778b7-s2zvw                                 1/1     Running     0          1m
kiali-99f7467dc-6rvwp                                          1/1     Running     0          1m
prometheus-67cdb66cbb-9w2hm                                    1/1     Running     0          1m
{{< /text >}}

## 更新{#update}

现在，控制器已经在运行了，您可以通过编辑或替换 `IstioControlPlane` 资源来改变 Istio 的配置。
控制器将会检测该变化，并对应的更新 Istio 的安装。

例如，您可以运行以下命令将安装切换为 `default` 配置：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
EOF
{{< /text >}}

您还可以启用或禁用指定的特性或组件。
例如，禁用遥测特性：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha2
kind: IstioControlPlane
metadata:
  namespace: istio-operator
  name: example-istiocontrolplane
spec:
  profile: default
  telemetry:
    enabled: false
EOF
{{< /text >}}

参考 [`IstioControlPlane` 接口](/zh/docs/reference/config/istio.operator.v1alpha12.pb/)获取完整的配置项。

## 卸载{#uninstall}

删除 Istio operator 和 Istio 部署：

{{< text bash >}}
$ kubectl -n istio-operator get IstioControlPlane example-istiocontrolplane -o=json | jq '.metadata.finalizers = null' | kubectl delete -f -
$ kubectl delete ns istio-operator --grace-period=0 --force
$ kubectl delete ns istio-system --grace-period=0 --force
{{< /text >}}
