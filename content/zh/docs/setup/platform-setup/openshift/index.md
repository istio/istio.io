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

默认情况下，OpenShift 不允许容器使用 User ID（UID）1337 来运行。通过以下命令可以让 Istio
的服务账户（Service Account）以 UID 1337 来运行容器（如果您将 Istio 部署到其它 Namespace，
请注意替换 `istio-system`）：

{{< text bash >}}
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system
{{< /text >}}

使用 OpenShift 配置文件进行安装 Istio：

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

安装 Istio 完成后，通过以下命令为 Ingress Gateway 暴露 OpenShift 路由：

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=http2
{{< /text >}}

## Sidecar 应用的安全上下文约束（SCC）{#security-context-constraints-for-application-sidecars}

OpenShift 默认是不允许 Istio Sidecar 注入到每个应用 Pod 中以用户 ID 为 1377 来运行的。
要允许使用该 UID 运行，需要执行以下命令（注意替换 `<target-namespace>` 为适当的 Namespace）：

{{< text bash >}}
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts:<target-namespace>
{{< /text >}}

当需要移除应用时，请按以下操作移除权限：

{{< text bash >}}
$ oc adm policy remove-scc-from-group anyuid system:serviceaccounts:<target-namespace>
{{< /text >}}
