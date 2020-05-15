---
title: Istio 1.1 发布公告
linktitle: 1.1
subtitle: 重大更新
description: Istio 1.1 发布公告。
publishdate: 2019-03-19
release: 1.1.0
skip_list: true
aliases:
    - /zh/blog/2019/announcing-1.1
    - /zh/news/2019/announcing-1.1
    - /zh/news/announcing-1.1.0
    - /zh/news/announcing-1.1
---

我们很高兴的宣布 Istio 1.1 正式发布！

{{< relnote >}}

自 7 月份发布 1.0 版本以来，我们已经做了很多工作来帮助人们投入生产。理所当然，我们不得不做一些[补丁发布](/zh/news)（到目前为止有 6 个！），但是我们也一直在努力为产品添加新功能。

1.1 的主题是企业就绪。我们很高兴看到越来越多的公司在生产中使用 Istio，但是一些大型公司在尝试使用 Istio 的过程中，遇到了一些瓶颈。

我们关注的主要领域之一是[性能和可伸缩性](/zh/docs/ops/deployment/performance-and-scalability/)。随着人们进入生产环境，大型集群以更高的容量运行更多的服务，他们遇到了一些扩展和性能问题。[sidecar](/zh/docs/concepts/traffic-management/#sidecars) 占用了太多资源，并增加了太多延迟。控制平面（尤其是 [Pilot](/zh/docs/ops/deployment/architecture/#pilot)）过于浪费资源。

我们已经做了很多工作，以提高数据平面和控制平面的使用效率。您可以在本次更新的[性能和可扩展性概念](/zh/docs/ops/deployment/performance-and-scalability/)中找到我们对 1.1 性能测试的详细信息和测试结果。

我们还完成了有关命名空间隔离的工作。这使您可以使用 Kubernetes 命名空间来强制控制边界，并确保您的团队和另一个团队之间不会相互干扰。

我们还改进了[多集群的功能及可用性](/zh/docs/ops/deployment/deployment-models/)。我们听取了社区的意见，并改进了流量控制和策略的默认设置。我们引入了一个名为 [Galley](/zh/docs/ops/deployment/architecture/#galley) 的新组件。Galley 验证了 YAML 配置，从而减少了配置错误的机会。Galley 还将在[多集群设置](/zh/docs/setup/install/multicluster/)中发挥作用，从每个 Kubernetes 集群收集服务发现信息。我们还支持其他多集群拓扑，包括不同的[控制平面模型](/zh/docs/ops/deployment/deployment-models/#control-plane-models)拓扑，而无需使用扁平网络。

有关更多、更完整的信息请参见[变更说明](./change-notes)。

项目中还有更多正在进行的内容。我们知道 Istio 有很多活动部件，可以承担很多责任。为了解决这个问题，我们最近成立了一个[可用性工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)（欢迎随时加入）。[社区会议](https://github.com/istio/community#community-meeting)（星期四，上午 11 点）和[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)中也发生了很多事情。如果您尚未加入 [discuss.istio.io](https://discuss.istio.io) 上的对话，请直接使用 GitHub 凭据登录并加入我们！

我们感谢在过去几个月中为了 Istio 的发展而努力工作的每个人。他们修补了 1.0 版本，并为 1.1 版本增加了许多新功能，最近又对 1.1 版本进行了大量的测试。特别感谢在早期版本，与我们一起完成安装和升级方面的工作，并帮助我们在发布之前发现问题的那些公司和用户。

现在：时机已到！就是 1.1，查看[更新文档](/zh/docs/)、[安装它](/zh/docs/setup/)，然后...happy meshing!
