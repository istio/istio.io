---
title: Amazon Web Services
description: 对 AWS 中以 Kops 安装的集群进行配置以便安装运行 Istio。
weight: 3
keywords: [platform-setup,aws]
---

依照本指南对 AWS 中以 Kops 安装的集群进行配置以便安装运行 Istio。

如果使新安装的集群是 Kubernetes 1.9 版本，安装运行 Istio 所需的 `admissionregistration.k8s.io/v1beta1` 应该已经包含其中。

无论如何，还必须更新 Admission controllers 的列表。

1. 打开配置文件：

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. 在其中加入下列内容：

    {{< text yaml >}}
    kubeAPIServer:
        admissionControl:
        - NamespaceLifecycle
        - LimitRanger
        - ServiceAccount
        - PersistentVolumeLabel
        - DefaultStorageClass
        - DefaultTolerationSeconds
        - MutatingAdmissionWebhook
        - ValidatingAdmissionWebhook
        - ResourceQuota
        - NodeRestriction
        - Priority
    {{< /text >}}

1. 执行更新：

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. 进行滚动更新

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}

1. 使用 `kubectl` 在 `kube-api` Pod 上检查更新情况，应该会看到新的 Admission controller：

    {{< text bash >}}
    $ for i in `kubectl \
      get pods -nkube-system | grep api | awk '{print $1}'` ; \
      do  kubectl describe pods -nkube-system \
      $i | grep "/usr/local/bin/kube-apiserver"  ; done
    {{< /text >}}

1. 查看输出内容：

    {{< text plain >}}
    [...]
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,
    PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,
    MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,
    NodeRestriction,Priority
    [...]
    {{< /text >}}
