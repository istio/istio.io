---
title: 修复 Citadel
description: 如果 Citadel 表现不正常该怎么办。
weight: 10
keywords: [安全,citadel,运维]
---

如果您怀疑 Citadel 无法正常工作，请验证 `istio-citadel` pod 的状态：

{{< text bash >}}
$ kubectl get pod -l istio=citadel -n istio-system
NAME                                     READY     STATUS   RESTARTS   AGE
istio-citadel-ff5696f6f-ht4gq            1/1       Running  0          25d
{{< /text >}}

如果 `istio-citadel` pod 不存在，请尝试重新部署 pod。

如果 `istio-citadel` pod 存在但其状态不是 `Running` ，请运行以下命令以获得更多
调试信息并检查是否有任何错误：

{{< text bash >}}
$ kubectl logs -l istio=citadel -n istio-system
$ kubectl describe pod -l istio=citadel -n istio-system
{{< /text >}}
