---
title: 清理
description: 删除 Istio 和相关资源。
weight: 6
owner: istio/wg-networking-maintainers
test: yes
---

如果您不再需要 Istio 和相关资源，可以按照本节中的步骤删除它们。

## 删除 Ambient 和 waypoint 标签 {#remove-the-ambient-and-waypoint-labels}

指示 Istio 自动将 `default` 命名空间中的应用程序包含到 Ambient
网格的标签默认情况下不会被删除。如果不再需要，请使用以下命令将其删除：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
$ kubectl label namespace default istio.io/use-waypoint-
{{< /text >}}

## 删除 waypoint 代理 {#remove-waypoint-proxies}

要删除 waypoint 代理、已安装的策略并卸载 Istio，请运行以下命令：

{{< text bash >}}
$ istioctl waypoint delete --all
{{< /text >}}

## 卸载 Istio {#uninstall-istio}

要卸载 Istio：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## 删除示例应用程序 {#remove-the-sample-application}

要删除 Bookinfo 示例应用程序和 `curl` 部署，请运行以下命令：

{{< text bash >}}
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f samples/curl/curl.yaml
{{< /text >}}

## 删除 Kubernetes Gateway API CRD {#remove-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-remove-crds >}}
