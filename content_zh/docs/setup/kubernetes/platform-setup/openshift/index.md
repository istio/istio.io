---
title: OpenShift
description: 对 OpenShift 集群进行配置以便安装运行 Istio。
weight: 18
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
