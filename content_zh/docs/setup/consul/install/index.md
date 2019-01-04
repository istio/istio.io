---
title: 安装
description: 基于 Consul 和 Nomad 安装 Istio 控制平面。
weight: 30
keywords: [consul]
---

> 在 Nomad 上安装还没有被测试过

在非 Kubernetes 环境中使用 Istio 包含几个关键任务：

1. 通过 Istio API server 设置 Istio 控制平面
1. 为每个实例的服务添加 Istio sidecar
1. 确保请求是通过 sidecars 进行路由的

## 创建控制平面

Istio 控制平面有四个主要的服务：Pilot、Mixer、Citadel 和 API server 。

### API Server

Istio 的 API server （基于 Kubernetes 的 API server）提供了配置管理和角色访问控制等关键功能。Istio API server 需要 [etcd cluster](https://kubernetes.io/docs/getting-started-guides/scratch/#etcd) 做持久化存储。 请参阅 [API server 的配置](https://kubernetes.io/docs/getting-started-guides/scratch/#apiserver-controller-manager-and-scheduler)。

#### 本地安装

出于验证概念的目的，可以通过下面的 Docker-compose 文件来安装一个简单的 API server 容器：

{{< text yaml >}}
version: '2'
services:
  etcd:
    image: quay.io/coreos/etcd:latest
    networks:
      istiomesh:
        aliases:
          - etcd
    ports:
      - "4001:4001"
      - "2380:2380"
      - "2379:2379"
    environment:
      - SERVICE_IGNORE=1
    command: [
              "/usr/local/bin/etcd",
              "-advertise-client-urls=http://0.0.0.0:2379",
              "-listen-client-urls=http://0.0.0.0:2379"
             ]

  istio-apiserver:
    image: gcr.io/google_containers/kube-apiserver-amd64:v1.7.3
    networks:
      istiomesh:
        ipv4_address: 172.28.0.13
        aliases:
          - apiserver
    ports:
      - "8080:8080"
    privileged: true
    environment:
      - SERVICE_IGNORE=1
    command: [
               "kube-apiserver", "--etcd-servers", "http://etcd:2379",
               "--service-cluster-ip-range", "10.99.0.0/16",
               "--insecure-port", "8080",
               "-v", "2",
               "--insecure-bind-address", "0.0.0.0"
             ]
{{< /text >}}

### 其他 Istio 组件

Istio Pilot 、Mixer 和 Citadel 的 Debian 包可以通过 Istio 的发行版获得。同时，这些组件可以运行在 Docker 容器( docker.io/istio/pilot, docker.io/istio/mixer, docker.io/istio/citadel ) 中。请注意，这些组件都是无状态的并且可以水平伸缩。每个组件都依赖 Istio API server，而 Istio API server 依赖 etcd 集群做持久存储。为了实现高可用，每个控制平面服务可以作为 [job](https://www.nomadproject.io/docs/job-specification/index.html) 在 Nomad 中运行，其中 [service stanza](https://www.nomadproject.io/docs/job-specification/service.html) 可以用来描述控制平面服务的期望属性。

## 将 sidecars 添加到服务实例中

每个实例在应用中都需要 Istio sidecar。根据你的安装环境 （Docker 容器 、虚拟机或者裸机），Istio sidecar 需要被安装到这些组件中。例如，如果你的基础架构使用了虚拟机，则需要在成为服务网格节点的每个虚拟机上运行 Istio sidecar 进程。

一种将 sidecars 打包到基于 Nomad 部署的方式，是将 Istio sidecar 进程作为一个[任务组](https://www.nomadproject.io/docs/job-specification/group.html)中的任务。任务组是一个或多个保证驻留在相同主机上的相关任务集合。但是，与 Kubernetes Pods 不同的是，在同一个组里的任务不会共享网络命名空间。因此，当通过 Istio sidecar 使用 `iptables` 规则透明地重新路由所有网络流量时，必须确保每台机器上只有一个任务组在运行。当 Istio 支持非透明代理（应用明确与 sidecar 通信）时，这个限制将不再适用。

## 通过 Istio sidecars 做流量路由

为了能够通过 Istio sidecars 透明地路由应用的网络流量，部分 sidecar 的安装需要设置适当的 IP Table 规则。这种转发规则的 IP Table 脚本可以在[这里]({{< github_file >}}/tools/deb/istio-iptables.sh)找到。

> 该脚本必须在启动应用和 sidecar 之前执行。
