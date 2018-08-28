---
title: Istio 是惠普 FitStation 平台的改变者
description: 惠普如何在 Istio 上构建其下一代鞋类个性化平台。
subtitle: 惠普如何在 Istio 上构建其下一代鞋类个性化平台
publishdate: 2018-07-31
attribution: Steven Ceuppens, Chief Software Architect @ HP FitStation, Open Source Advocate / Contributor
weight: 84
---

惠普的 FitStation 团队坚信 Kubernetes，BPF 和服务网络的未来是云基础设施的下一个标准。
我们也很高兴看到 Istio 即将推出其官方的 Istio 1.0 版本 - 这要归功于 2017 年 5 月从 Google，IBM 和 Lyft 开始的联合合作。

在 FitStation 大规模和渐进式云平台的开发过程中，Istio，Cilium 和 Kubernetes 技术提供了大量机会，使我们的系统更加强大和可扩展。
 Istio 在创建可靠和动态的网络通信方面改变了游戏规则。

[由惠普提供支持的 FitStation](http://www.fitstation.com) 是一个技术平台，可捕获 3D 生物识别数据，设计个性化鞋类，
完美贴合个人足部尺寸和形状以及步态轮廓。它使用 3D 扫描，压力感应，3D 打印和可变密度注塑成型来制造独特的鞋类。
Brooks，Steitz Secura 或 Superfeet 等鞋类品牌正在连接 FitStation，以打造下一代高性能运动鞋，专业鞋和医用鞋。

FitStation 建立在对用户生物识别数据的最终安全性和隐私承诺的基础上。 Istio 是我们在云中实现数据传输的基石。
通过在基础架构级别管理这些方面，我们专注于解决业务问题，而不是花时间在安全服务通信的单独实现上。
使用 Istio 可以大大降低维护大量库和服务的复杂性，从而提供安全的通信服务。

作为使用 Istio 1.0 的额外好处，我们获得了网络可见性，指标和开箱即用的跟踪。这极大地改善了我们开发的决策和响应质量
和 devops 团队。该团队深入了解整个平台的网络通信，包括新应用程序和旧应用程序。 Cilium 的整合
与 Envoy 在 Istio 服务网状网通信方面取得了显着的性能优势，并结合了细粒度的内核驱动的 L7 网络安全层。这是由于 BPF 将功率提升给了 Istio。
我们相信未来将推动 Linux 的内核安全。

跟随 Istio 的成长一直非常令人兴奋。我们已经能够看到不同开发版本的性能和稳定性的明显改进。
版本 0.7 和 0.8 之间的改进使我们的团队对 1.0 版本感到满意，我们可以说 Istio 现在已经准备好用于实际生产。

我们期待着 Istio，Envoy，Cilium 的产品 和 CNCF 充满希望的路线图。