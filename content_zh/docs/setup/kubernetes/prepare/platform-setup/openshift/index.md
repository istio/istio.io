---
title: OpenShift
description: 对 OpenShift 集群进行配置以便安装运行 Istio。
weight: 24
skip_seealso: true
keywords: [platform-setup,openshift]
---

依照本指南对 OpenShift 集群进行配置以便安装运行 Istio。

缺省情况下，OpenShift 不允许容器使用 User ID（UID） 0 来运行。
下面的命令让 Istio 的 Service account 可以使用 UID 0 来运行容器：

{{< text bash >}}
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system
{{< /text >}}

上面列出的 Service account 会分配给 Istio。如果要启动其它的 Istio 服务，例如 _Grafana_ ，就需要使用类似命令来为其设置 Service account。

运行应用的 Service account 需要在安全上下文中具备一定特权，这也是 Sidecar 注入过程的一部分：

{{< text bash >}}
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
{{< /text >}}

## 自动注入

要使用[自动注入](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection)，必须启用 Webhook 和证书签名请求支持。
修改群集主节点上的主配置文件，如下所示。

{{< tip >}}
默认情况下，主配置文件可以在 `/etc/origin/master/master-config.yaml` 中找到。
{{< /tip >}}

在与主配置文件相同的目录中，使用以下内容创建名为 master-config.patch 的文件：

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

在同一目录中，执行：

{{< text bash >}}
$ cp -p master-config.yaml master-config.yaml.prepatch
$ oc ex config patch master-config.yaml.prepatch -p "$(cat master-config.patch)" > master-config.yaml
$ master-restart api
$ master-restart controllers
{{< /text >}}
