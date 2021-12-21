---
---
{{< warning >}}

默认 chart 配置使用安全的第三方令牌作为 Istio 代理使用的
服务帐户令牌投影，以向 Istio 控制平面
进行身份验证。在继续安装以下任何图表之前，您应该
按照[此处](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)描述的步骤，验证是否在您的
集群中启用了第三方令牌。
如果未启用第三方令牌，则应将该选项
 `--set global.jwtPolicy=first-party-jwt` 添加到 Helm 的安装命令中。
如果 `jwtPolicy` 未正确设置，则 `istiod` 由于缺少 `istio-token` 卷，
与、网关或具有注入 Envoy 代理的工作负载相关
联的 Pod 将不会被部署。
{{< /warning >}}