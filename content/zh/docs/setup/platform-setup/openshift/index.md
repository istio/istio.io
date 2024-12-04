---
title: OpenShift
description: 在 OpenShift 集群上快速搭建 Istio 服务。
weight: 55
skip_seealso: true
aliases:
  - /zh/docs/setup/kubernetes/prepare/platform-setup/openshift/
  - /zh/docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
owner: istio/wg-environments-maintainers
test: no
---

根据以下操作指南 为 Istio 准备一个 OpenShift 集群。

使用 OpenShift 配置文件进行安装 Istio：

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

安装 Istio 完成后，通过以下命令为 Ingress Gateway 暴露 OpenShift 路由：

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=http2
{{< /text >}}
