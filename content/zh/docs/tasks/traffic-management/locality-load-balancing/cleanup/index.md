---
title: 清理
description: 地域负载均衡的清理步骤。
weight: 30
icon: tasks
keywords: [locality,load balancing]
test: yes
owner: istio/wg-networking-maintainers
---

现在您已经完成了地域负载均衡的任务，让我们执行清理操作。

## 删除生成的文件 {#remove-generated-files}

{{< text bash >}}
$ rm -f sample.yaml helloworld-region*.zone*.yaml
{{< /text >}}

## 删除 `sample` 命名空间 {#remove-the-sample-namespace}

{{< text bash >}}
$ for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" delete ns sample --ignore-not-found=true; \
  done
{{< /text >}}

**恭喜！** 您成功地完成了地域负载均衡任务!
