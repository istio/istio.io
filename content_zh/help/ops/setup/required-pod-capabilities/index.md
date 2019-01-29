---
title: Pod 的必要功能
description: 如何检查 Pod 中被许可的功能。
weight: 40
---

如果集群中[启用](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#enabling-pod-security-policies)了 [Pod 安全策略](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)，在没使用 Istio CNI 插件的情况下，就必须允许 Pod 使用 `NET_ADMIN` 功能，Envoy 代理需要使用这一功能完成初始化过程。要检查允许 Pod 使用的功能，可以检查一下这些 Pod 的 [Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
的安全策略，看其中的授权列表中是否包含 `NET_ADMIN`。

如果没有给 Pod 特意指定 Service Account，这个 Pod 会以所在命名空间的 `default` Service Account 的身份运行。

要检查一个 Pod 所属 Service Account 被许可使用的功能列表，可以使用如下命令：

{{< text bash >}}
$ for psp in $(kubectl get psp); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:<your namespace>:<your service account>) = yes ]; then kubectl get psp $psp -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

例如我们想要看看 `default` 命名空间中 `default` Service Account 的许可功能列表：

{{< text bash >}}
$ for psp in $(kubectl get psp); do if [ $(kubectl auth can-i use psp/$psp --as=system:serviceaccount:default:default) = yes ]; then kubectl get psp $psp -o=custom-columns=NAME:.metadata.name,CAPS:.spec.allowedCapabilities; fi; done
{{< /text >}}

如果在许可策略的许可功能列表中看到了 `NET_ADMIN` 或者 `*`，就表明使用该 Service Account 身份运行的 Pod 具备运行 Istio 初始化容器的权限；否则必须进行[赋权](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#authorizing-policies)。