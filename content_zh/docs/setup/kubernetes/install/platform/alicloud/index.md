---
title: 使用阿里云 Kubernetes 容器服务快速启动
description: 如何使用阿里云 Kubernetes 容器服务快速安装 Istio。
weight: 60
keywords: [kubernetes,alibabacloud,aliyun]
---

在[阿里云 Kubernetes 容器服务](https://www.alibabacloud.com/product/kubernetes)中使用‘应用程序目录’中的项目，按照说明安装和运行 Istio 。

本向导安装 Istio 的当前版本并发布一个名为 [Bookinfo](/zh/docs/examples/bookinfo/) 的样例应用。

## 前置条件

- 你需要有一个可用的阿里云 Kubernetes 集群。否则，需要使用“容器服务控制台”快速简单的创建一个 Kubernetes 集群。

- 确保 `kubectl` 对你的 Kubernetes 集群工作正常

- 你可以创建一个命名空间用来部署 Istio 组建。例如如下创建的命名空间 `istio-system`：

{{< text bash >}}
$ kubectl create namespace istio-system
{{< /text >}}

- 您为 Tiller 安装了一个服务帐户。如果没有安装，运行如下命令：

{{< text bash >}}
$ kubectl create -f @install/kubernetes/helm/helm-service-account.yaml@
{{< /text >}}

- 使用服务安装 Tiller 。如果没有，请运行运行一下命令：

{{< text bash >}}
$ helm init --service-account tiller
{{< /text >}}

## 通过应用程序目录部署 Istio

- 登陆 **阿里云容器服务** 控制台。
- 在左侧的导航栏中点击 **应用程序目录** 。
- 在右侧的导航栏总选择 **ack-istio** 。

{{< image link="/docs/setup/kubernetes/install/platform/alicloud/app-catalog-istio-1.0.0.png" caption="Istio" >}}

### 使用参数自定义安装

下表解释了使用 Helm chart 自带的默认配置选项：

| 参数                            | 描述                                                  | 默认                                    |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------------ |
| `global.hub` | 为 Istio 指定镜像 hub | `registry.cn-hangzhou.aliyuncs.com/aliacs-app-catalog` |
| `global.tag`                     | 为 Istio 为大多数镜像指定 TAG |    0.8       |
| `global.proxy.image`             | 指定代理镜像的名称         | `proxyv2`        |
| `global.imagePullPolicy`       | 指定镜像的获取策略          | `IfNotPresent`        |
| `global.controlPlaneSecurityEnabled` | 指定是否用了控制平面 `mTLS` | `false` |
| `global.mtls.enabled`        | 指定是否在服务之间默认启用 `mTLS`| `false`  |
| `global.mtls.mtlsExcludedServices`  | 从 `mTLS` 中排除 `FQDNs`表 | -`kubernetes.default.svc.cluster.local` |
| `global.rbacEnabled` | 指定是否创建 Istio RBAC 规则 | `true` |
| `global.refreshInterval` | 指定网格发现刷新间隔 | `10s` |
| `global.arch.amd64` | 指定 `amd64` 架构的调度策略 | `2` |
| `global.arch.s390x` | 指定 `s390x` 架构的调度策略 | `2` |
| `global.arch.ppc64le` | 指定 `ppc64le` 架构的调度策略 | `2` |

参数选项卡公开每个服务选项。

{{< tip >}}
在继续运行之前，请等待 Istio 完全部署。部署可能需要几分钟。
{{< /tip >}}

## 卸载

1. 访问 [阿里云容器服务控制台的发布](https://www.alibabacloud.com/product/kubernetes).

1. 选择您希望卸载 Istio 的版本。

1. 单击 **删除** 按钮删除所有已部署的 Istio 组建。
