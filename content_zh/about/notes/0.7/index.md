---
title: Istio 0.7
weight: 94
page_icon: /img/notes.svg
---

本次发布，我们专注于提升我们的构建和测试基础设施并且提高了测试的质量。因此，这个月没有新的特性发布。

尽管如此，这次发布包含了大量的问题修复和性能提升。

请注意该发布包含新的v1alpha3流量管理功能的初步支持，这个功能尚处于频繁变动当中并且可能会在0.8版本存在不兼容的变更。
所以如果您希望尝试，敬请自便，但是请预期这些功能可能会在0.8或者之后的版本发生变动。

已知问题:

我们的 [Helm chart](/zh/docs/setup/kubernetes/helm-install/)
目前需要一些变通的方式才能正确工作，这里 [Issue 4701](https://github.com/istio/istio/issues/4701) 有相关细节。

