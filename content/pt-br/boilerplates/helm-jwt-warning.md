---
---
{{< warning >}}
The default chart configuration uses the secure third party tokens for the service
account token projections used by Istio proxies to authenticate with the Istio
control plane. Before proceeding to install any of the charts below, you should
verify if third party tokens are enabled in your cluster by following the steps
describe [here](/docs/ops/best-practices/security/#configure-third-party-service-account-tokens).
If third party tokens are not enabled, you should add the option
`--set global.jwtPolicy=first-party-jwt` to the Helm install commands.
If the `jwtPolicy` is not set correctly, pods associated with `istiod`,
gateways or workloads with injected Envoy proxies will not get deployed due
to the missing `istio-token` volume.
{{< /warning >}}
