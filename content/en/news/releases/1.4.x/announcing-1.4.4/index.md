---
title: Announcing Istio 1.4.4
linktitle: 1.4.4
subtitle: Patch Release
description: Istio 1.4.4 patch release.
publishdate: 2020-02-10
release: 1.4.4
aliases:
    - /news/announcing-1.4.4
---

This release includes bug fixes to improve robustness and user experience. This release note describes what’s different between Istio 1.4.3 and Istio 1.4.4.

{{< relnote >}}

## Bug fixes
- **Fixed** Debian packaging of `iptables` scripts ([Issue 19615](https://github.com/istio/istio/issues/19615)).
- **Fixed** an issue where Pilot generated a wrong Envoy configuration when the same port was used more than once ([Issue 19935](https://github.com/istio/istio/issues/19935)).
- **Fixed** an issue where running multiple instances of Pilot could lead to a crash ([Issue 20047](https://github.com/istio/istio/issues/20047)).
- **Fixed** a potential flood of configuration pushes from Pilot to Envoy when scaling the deployment to zero ([Issue 17957](https://github.com/istio/istio/issues/17957)).
- **Fixed** an issue where Mixer could not fetch the correct information from the request/response when pod contains a dot in its name  ([Issue 20028](https://github.com/istio/istio/issues/20028)).
- **Fixed** an issue where a change in the pod IP address could not be picked up correctly by Pilot ([Issue 20676](https://github.com/istio/istio/issues/20676)).
- **Fixed** an issue where Pilot sometimes would not send a correct pod configuration to Envoy ([Issue 19025](https://github.com/istio/istio/issues/19025)).
- **Fixed** an issue where sidecar injector with SDS enabled was overwriting pod `securityContex` section, instead of just patching it ([Issue 20409](https://github.com/istio/istio/issues/20409)).


## Improvements

- **Improved** Better compatibility with Google CA. (Issues [20530](https://github.com/istio/istio/issues/20530), [20560](https://github.com/istio/istio/issues/20560)).
- **Improved** Added analyzer error message when Policies using JWT are not configured properly (Issues [20884](https://github.com/istio/istio/issues/20884), [20767](https://github.com/istio/istio/issues/20767)).
- **Improved** Added CNI repair functionality to the `istioctl` installer ([Issue 20715](https://github.com/istio/istio/issues/20715)).
