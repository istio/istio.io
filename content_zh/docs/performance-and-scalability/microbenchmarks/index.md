---
title: 微基准测试
description: 通过代码级微基准测试测试性能。
weight: 20
---

我们使用 Go 的原生工具在性能敏感区域编写有针对性的微基准测试。我们使用此方法的主要目标是提供易于使用的微基准测试，开发人员可以使用这些基准测试来对它们的更改快速执行更改前后的性能对比。

查看 Mixer 的 [示例微基准测试](https://github.com/istio/istio/blob/{{<branch_name>}}/mixer/test/perf/singlecheck_test.go)，以衡量属性处理代码的性能。

开发人员还可以利用 golden-file 方法来捕获源代码树中基准测试结果的状态，以达到保持跟踪和引用的目的。 GitHub 有一个 [基线文件](https://github.com/istio/istio/blob/{{<branch_name>}}/mixer/test/perf/bench.baseline)。

由于这种测试类型的性质，机器间的延迟数据存在很大差异。建议以这种方式捕获的微基准数据仅与同一台机器上先前运行的数据进行比较。

可以使用 [perfcheck.sh](https://github.com/istio/istio/blob/{{<branch_name>}}/bin/perfcheck.sh) 脚本快速运行子文件夹中的基准测试并将其结果与相同目录下的基线文件进行对比。