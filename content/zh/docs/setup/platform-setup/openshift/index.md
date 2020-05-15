---
title: OpenShift
description: 对 OpenShift 集群进行配置以便安装运行 Istio。
weight: 24
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/openshift/
    - /zh/docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
---

{{< warning >}}
OpenShift 4.1 及以上版本使用的 `nftables` 与 Istio 的 `proxy-init` 容器不兼容。请使用 [CNI](/zh/docs/setup/additional-setup/cni/) 插件代替。
{{< /warning >}}

依照本指南对 OpenShift 集群进行配置以便安装运行 Istio。

默认情况下，OpenShift 不允许容器使用 User ID（UID）0 来运行。通过以下命令可以让 Istio 的服务账户（Service Accounts）以 UID 0 来运行容器
（如果你将 Istio 部署到其它命名空间，请注意替换 `istio-system` ）：

{{< text bash >}}
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts -n istio-system
{{< /text >}}

现在你可以按照 [CNI](/zh/docs/setup/additional-setup/cni/) 的操作来安装 Istio。

安装完成后，为 ingress 网关暴露一个 OpenShift 路由。

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=80
{{< /text >}}

## 自动 sidecar 注入{#automatic-sidecar-injection}

{{< tip >}}
如果你使用的是 OpenShift 4.1 或更高的版本，以下配置不是必须的，可以跳到下一章节。
{{< /tip >}}

要使[自动注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)能正常工作必须启用 Webhook 和证书签名请求（CSR）的支持。
请按以下说明在集群 master 节点修改 master 配置文件。

{{< tip >}}
默认情况下，master 配置文件的路径是 `/etc/origin/master/master-config.yaml`。
{{< /tip >}}

在 master 配置文件相同目录下创建文件 `master-config.patch`，内容如下：

{{< text yaml >}}
admissionConfig:
  pluginConfig:
    MutatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
    ValidatingAdmissionWebhook:
      configuration:
        apiVersion: apiserver.config.k8s.io/v1alpha1
        kubeConfigFile: /dev/null
        kind: WebhookAdmission
{{< /text >}}

然后在该目录下执行：

{{< text bash >}}
$ cp -p master-config.yaml master-config.yaml.prepatch
$ oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
$ master-restart api
$ master-restart controllers
{{< /text >}}

## Sidecar 应用的专用安全上下文约束（SCC）{#privileged-security-context-constraints-for-application-sidecars}

OpenShift 默认是不允许 Istio sidecar 注入到每个应用 Pod 中以 ID 为 1377 的用户运行的。要允许使用该 UID 运行，需要执行以下命令（注意替换 `<target-namespace>` 为适当的命名空间）：

{{< text bash >}}
$ oc adm policy add-scc-to-group privileged system:serviceaccounts -n <target-namespace>
$ oc adm policy add-scc-to-group anyuid system:serviceaccounts -n <target-namespace>
{{< /text >}}

当需要移除应用时，请按以下操作移除权限：

{{< text bash >}}
$ oc adm policy remove-scc-from-group privileged system:serviceaccounts -n <target-namespace>
$ oc adm policy remove-scc-from-group anyuid system:serviceaccounts -n <target-namespace>
{{< /text >}}
