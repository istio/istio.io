---
title: Istio 1.1.1
publishdate: 2019-03-22
icon: notes
---

Istio 1.1.1 is the first in a weekly series of patch releases for Istio 1.1.  It contains a small number of bug fixes and minor enhancements.

{{< relnote_links >}}

## Bug Fixes and Minor Enhancements

- Configure prometheus to monitor citadel ([Issue 12175](https://github.com/istio/istio/pull/12175))
- Improve output of istioctl's verify install command ([Issue 12174](https://github.com/istio/istio/pull/12174))
- Reduce log level for missing service account for spiffe uri ([Issue 12108](https://github.com/istio/istio/issues/12108))
- Fix broken path on the opt-in SDS feature's Unix domain socket ([Issue 12688](https://github.com/istio/istio/pull/12688))
- Fix Envoy tracing: If parent span is propagated with empty string, it causes the next child span to not be created ([Envoy Issue 6263](https://github.com/envoyproxy/envoy/pull/6263))
- Add namespace scoping to the Gateway 'port' names.  This fixes two issues:
   - IngressGateway only respects first port 443 Gateway definition ([Issue 11509](https://github.com/istio/istio/issues/11509)) 
   - Istio ingressgateway routing broken with two different gateways with same port name (SDS) ([Issue 12500](https://github.com/istio/istio/issues/12500)) 
- Five bug fixes for locality weighted load balancing:
   - Fix bug causing empty endpoints per locality ([Issue 12610](https://github.com/istio/istio/issues/12610))
   - Apply locality weighted lb config correctly ([Issue 12587](https://github.com/istio/istio/issues/12587))
   - Locality label istio-locality in k8s should not contain `/`, use `.` ([Issue 12582](https://github.com/istio/istio/issues/12582))
   - Fix crash in locality load balancing ([Issue 12649](https://github.com/istio/istio/pull/12649))
   - Fix bug in locality LB normalization ([Issue 12579](https://github.com/istio/istio/pull/12579))
- Propagate Envoy Metrics Service Config ([Issue 12569](https://github.com/istio/istio/issues/12569))
- Only use gateways for servers being processed / do not apply VirtualService rule to wrong Gateway ([Issue 10313](https://github.com/istio/istio/issues/10313))

