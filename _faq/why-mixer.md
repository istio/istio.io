---
title: Why does Istio need Mixer?
order: 135
type: markdown
---
{% include home.html %}

Mixer provides a rich intermediation layer between the Istio components as well as Istio-based services,
and the infrastructure backends used to perform access control checks and telemetry capture. This
layer enables operators to have rich insights and control over service behavior without requiring
changes to service binaries.

Mixer is designed as a stand-alone component, distinct from Envoy, in order to be able
to manage scaling and reliability concerns independently . The proxy is focused on
high-performance routing, while Mixer takes responsibility for policy management and telemetry collection.
Mixer is invoked by Envoy, and in the future will also be invoked directly by Istio-based services.

Envoy implements sophisticated caching, batching, and prefetching, to largely mitigate the
latency impact of needing to interact with Mixer on the request path.
