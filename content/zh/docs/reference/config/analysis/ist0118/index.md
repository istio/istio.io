---
title: PortNameIsNotUnderNamingConvention
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当端口不遵循 [Istio 服务端口命名约定](/zh/docs/ops/configuration/traffic-management/protocol-selection/)或端口未命名时，会出现此消息。

## 示例{#example}

您将收到这条消息：

{{< text plain >}}
Info [IST0118] (Service httpbin.default) Port name foo-http (port: 80, targetPort: 80) doesn't follow the naming convention of Istio port.
{{< /text >}}

当您的集群有以下 service 时：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
spec:
  ports:
  - name: foo-http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
{{< /text >}}

在这个示例中，端口 `foo-http` 并未遵循这个语法：`name: <protocol>[-<suffix>]`。

## 如何修复{#how-to-resolve}

- 如果您知道 service 端口的协议，将端口重命名为 `<protocol>[-<suffix>]` 格式就行；
- 如果您不知道 service 端口的协议，您需要[从 Prometheus 查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
    - 查询 `istio_requests_total{reporter="destination",destination_service_name="SERVICE_NAME",response_code="200"}[TIME_RANGE]`。如果您使用 Mixer v2 版本，
      也可以查询 `istio_requests_total{reporter="destination",destination_service_name="SERVICE_NAME",response_code="200",destination_port="TARGET_PORT"}[TIME_RANGE]`。
    - 如果有输出，您可以从记录中找到 `request_protocol`。例如，如果 `request_protocol` 是 `http`，则将端口重命名为 `http-foo`；
    - 如果没有输出，您可以将端口保持原样。
