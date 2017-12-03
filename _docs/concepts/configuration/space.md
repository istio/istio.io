---
title: Functional space
overview: Functional view of the Istio configuration space. 

order: 15

layout: docs
type: markdown
---

Current Istio config is component oriented. Each component exposes a separate
config spec to the Istio end user. These are what we refer to as Mixer config,
or Pilot config, etc. Another way to look at the config space is to catagorize
them with functions. This graph lays out the catagorization of Istio config and
their relationships. Please find specific config terminology defined in
[Glossary]({{home}}/glossary).

<figure><img src="./img/space.svg" alt="The overall config functions." title="Istio Config Functional Space" />
<figcaption>Istio Config Functional Space</figcaption></figure>
