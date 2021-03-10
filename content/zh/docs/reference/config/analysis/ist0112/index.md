---
title: VirtualServiceDestinationPortSelectorRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当一个 virtual service 连接到一个有多个端口的 service，但是并未指定使用哪一个端口时会出现此信息。这种情况会导致行为未被定义。

要解决这个问题，需在 virtual service [Destination](/zh/docs/reference/config/networking/virtual-service/#Destination)中添加一个`port`用于指定使用的端口。