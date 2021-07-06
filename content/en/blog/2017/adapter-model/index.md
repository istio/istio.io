---
title: Mixer Adapter Model
description: Provides an overview of Mixer's plug-in architecture.
publishdate: 2017-11-03
subtitle: Extending Istio to integrate with a world of infrastructure backends
attribution: Martin Taillefer
keywords: [adapters,mixer,policies,telemetry]
aliases:
    - /blog/mixer-adapter-model.html
target_release: 0.2
exclude_from_see_also: true
---

Istio 0.2 introduced a new Mixer adapter model which is intended to increase Mixer’s flexibility to address a varied set of infrastructure backends. This post intends to put the adapter model in context and explain how it works.

## Why adapters?

Infrastructure backends provide support functionality used to build services. They include such things as access control systems, telemetry capturing systems, quota enforcement systems, billing systems, and so forth. Services traditionally directly integrate with these backend systems, creating a hard coupling and baking-in specific semantics and usage options.

Mixer serves as an abstraction layer between Istio and an open-ended set of infrastructure backends. The Istio components and services that run within the mesh can interact with these backends, while not being coupled to the backends’ specific interfaces.

In addition to insulating application-level code from the details of infrastructure backends, Mixer provides an intermediation model that allows operators to inject and control policies between application code and backends. Operators can control which data is reported to which backend, which backend to consult for authorization, and much more.

Given that individual infrastructure backends each have different interfaces and operational models, Mixer needs custom
code to deal with each and we call these custom bundles of code [*adapters*](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide).

Adapters are Go packages that are directly linked into the Mixer binary. It’s fairly simple to create custom Mixer binaries linked with specialized sets of adapters, in case the default set of adapters is not sufficient for specific use cases.

## Philosophy

Mixer is essentially an attribute processing and routing machine. The proxy sends it [attributes](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes) as part of doing precondition checks and telemetry reports, which it turns into a series of calls into adapters. The operator supplies configuration which describes how to map incoming attributes to inputs for the adapters.

{{< image width="60%"
    link="/blog/2017/adapter-model/machine.svg"
    caption="Attribute Machine"
    >}}

Configuration is a complex task. In fact, evidence shows that the overwhelming majority of service outages are caused by configuration errors. To help combat this, Mixer’s configuration model enforces a number of constraints designed to avoid errors. For example, the configuration model uses strong typing to ensure that only meaningful attributes or attribute expressions are used in any given context.

## Handlers: configuring adapters

Each adapter that Mixer uses requires some configuration to operate. Typically, adapters need things like the URL to their backend, credentials, caching options, and so forth. Each adapter defines the exact configuration data it needs via a [protobuf](https://developers.google.com/protocol-buffers/) message.

You configure each adapter by creating [*handlers*](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/#handlers) for them. A handler is a
configuration resource which represents a fully configured adapter ready for use. There can be any number of handlers for a single adapter, making it possible to reuse an adapter in different scenarios.

## Templates: adapter input schema

Mixer is typically invoked twice for every incoming request to a mesh service, once for precondition checks and once for telemetry reporting. For every such call, Mixer invokes one or more adapters. Different adapters need different pieces of data as input in order to do their work. A logging adapter needs a log entry, a metric adapter needs a metric, an authorization adapter needs credentials, etc.
Mixer [*templates*](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/templates/) are used to describe the exact data that an adapter consumes at request time.

Each template is specified as a [protobuf](https://developers.google.com/protocol-buffers/) message. A single template describes a bundle of data that is delivered to one or more adapters at runtime. Any given adapter can be designed to support any number of templates, the specific templates the adapter supports is determined by the adapter developer.

[`metric`](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/templates/metric/) and [`logentry`](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/templates/logentry/) are two of the most essential templates used within Istio. They represent respectively the payload to report a single metric and a single log entry to appropriate backends.

## Instances: attribute mapping

You control which data is delivered to individual adapters by creating
[*instances*](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/#instances).
Instances control how Mixer uses the [attributes](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes) delivered
by the proxy into individual bundles of data that can be routed to different adapters.

Creating instances generally requires using [attribute expressions](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/expression-language/). The point of these expressions is to use any attribute or literal value in order to produce a result that can be assigned to an instance’s field.

Every instance field has a type, as defined in the template, every attribute has a
[type](https://github.com/istio/api/blob/{{< source_branch_name >}}/policy/v1beta1/value_type.proto), and every attribute expression has a type.
You can only assign type-compatible expressions to any given instance fields. For example, you can’t assign an integer expression
to a string field.  This kind of strong typing is designed to minimize the risk of creating bogus configurations.

## Rules: delivering data to adapters

The last piece to the puzzle is telling Mixer which instances to send to which handler and when. This is done by
creating [*rules*](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/#rules). Each rule identifies a specific handler and the set of
instances to send to that handler. Whenever Mixer processes an incoming call, it invokes the indicated handler and gives it the specific set of instances for processing.

Rules contain matching predicates. A predicate is an attribute expression which returns a true/false value. A rule only takes effect if its predicate expression returns true. Otherwise, it’s like the rule didn’t exist and the indicated handler isn’t invoked.

## Future

We are working to improve the end to end experience of using and developing adapters. For example, several new features are planned to make templates more expressive. Additionally, the expression language is being substantially enhanced to be more powerful and well-rounded.

Longer term, we are evaluating ways to support adapters which aren’t directly linked into the main Mixer binary. This would simplify deployment and composition.

## Conclusion

The refreshed Mixer adapter model is designed to provide a flexible framework to support an open-ended set of infrastructure backends.

Handlers provide configuration data for individual adapters, templates determine exactly what kind of data different adapters want to consume at runtime, instances let operators prepare this data, rules direct the data to one or more handlers.

You can learn more about Mixer's overall architecture [here](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/mixer-overview/), and learn the specifics of templates, handlers,
and rules [here](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry). You can find many examples of Mixer configuration resources in the Bookinfo sample
[here]({{< github_tree >}}/samples/bookinfo).
