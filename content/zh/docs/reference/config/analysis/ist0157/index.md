---
title: InvalidTelemetryProvider
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当设置了具有空提供程序的 Telemetry 资源时，会出现此消息，
如果 MeshConfig 中的 `defaultProviders` 为空，则该消息将被忽略。
