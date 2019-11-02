---
title: Adapters
description: Mixer adapters allow Istio to interface to a variety of infrastructure backends for such things as metrics and logs.
weight: 40
aliases:
    - /docs/reference/config/mixer/adapters/index.html
    - /docs/reference/config/adapters/
---

{{< idea >}}
To implement a new adapter for Mixer, please refer to the
[Adapter Developer's Guide](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide).
{{< /idea >}}

## Templates

The table below shows the set of [templates](/docs/reference/config/policy-and-telemetry/templates) that are implemented by each supported adapter.

{{< adapter_table >}}
