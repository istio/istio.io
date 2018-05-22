---
title: Why does Istio need Mixer?
order: 0
type: markdown
---
{% include home.html %}

Mixer provides a rich intermediation layer between the Istio components as well as Istio-based services,
and the infrastructure backends used to perform access control checks and telemetry capture. This
layer enables operators to have rich insights and control over service behavior without requiring
changes to service binaries.

Mixer is designed as a stand-alone component, distinct from Envoy. This has numerous benefits:

- *Scalability*.
The work that Mixer and Envoy do is very different in nature, leading to different scalability
requirements. Keeping the components separate enables independent component-appropriate scaling.

- *Resource Usage*.
Istio depends on being able to deploy many instances of its proxy, making it important to minimize the
cost of each individual instance. Moving Mixer's complex logic into a distinct component makes it
possible for Envoy to remain svelte and agile.

- *Reliability*.
Mixer and its open-ended extensibility model represents the most complex parts of the
data path processing pipeline. By hosting this functionality in Mixer rather than Envoy,
it creates distinct failure domains which enables Envoy to continue operating even if Mixer
fails, preventing outages.

- *Isolation*.
Mixer provides a level of insulation between Istio and the infrastructure backends. Each Envoy instance can be configured to have a
very narrow scope of interaction, limiting the impact of potential attacks.

- *Extensibility*.
It was imperative to design a simple extensibility model to allow Istio to interoperate
with as widest breath of backends as possible. Due to its design and language choice, Mixer is inherently
easier to extend than Envoy is. The separation of concerns also makes it possible to use
Istio policy and telemetry processing with different proxies, just as a mix of Envoy and NGINX.

Envoy implements sophisticated caching, batching, and prefetching, to largely mitigate the
latency impact of needing to interact with Mixer on the request path.
