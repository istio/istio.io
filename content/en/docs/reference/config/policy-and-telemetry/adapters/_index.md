---
title: Mixer Adapters (Deprecated)
description: Mixer adapters allow Istio to interface to a variety of infrastructure backends for such things as metrics and logs.
weight: 40
aliases:
    - /docs/reference/config/mixer/adapters/index.html
    - /docs/reference/config/adapters/
test: n/a
---

{{< warning >}}
Mixer is deprecated. The functionality provided by Mixer is being moved into the Envoy proxies.
Use of Mixer with Istio will only be supported through the 1.7 release of Istio.
{{</ warning>}}

{{< idea >}}
To implement a new adapter for Mixer, please refer to the
[Adapter Developer's Guide](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide).
{{< /idea >}}

## Templates

The table below shows the set of [templates](/docs/reference/config/policy-and-telemetry/templates) that are implemented by each supported adapter.

{{< adapter_table >}}
