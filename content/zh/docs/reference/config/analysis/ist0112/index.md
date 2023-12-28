---
title: VirtualServiceDestinationPortSelectorRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Virtual Service 连接到暴露了多个端口的 Service 但并未指定使用哪一个端口时会出现此消息。
这种情况会造成未定义的行为。

要解决此问题，需在 Virtual Service [Destination](/zh/docs/reference/config/networking/virtual-service/#Destination)
中添加一个 `port` 用于指定要使用的端口。
