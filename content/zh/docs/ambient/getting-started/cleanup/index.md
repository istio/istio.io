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

## 删除 waypoint 代理并卸载 Istio {#remove-waypoint-proxies-and-uninstall-istio}

要删除 waypoint 代理、已安装的策略并卸载 Istio，请运行以下命令：

{{< text bash >}}
$ istioctl x waypoint delete --all
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

## 删除示例应用程序 {#remove-the-sample-application}

要删除 Bookinfo 示例应用程序和 `sleep` 部署，请运行以下命令：

{{< text bash >}}
$ kubectl delete -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl delete -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-versions.yaml
$ kubectl delete -f {{< github_file >}}/samples/sleep/sleep.yaml
{{< /text >}}

## 删除 Kubernetes Gateway API CRD {#remove-the-kubernetes-gateway-api-crds}

如果您安装了 Gateway API CRD，请将其删除：

{{< text bash >}}
$ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
{{< /text >}}
