---
title: Attributes
description: Explains the important notion of attributes, which is a central mechanism for how policies and control are applied to services within the mesh.

weight: 10

---
{% include home.html %}

The page describes Istio attributes, what they are and how they are used.

## Background

Istio uses *attributes* to control the runtime behavior of services running in the mesh.
Attributes are named and typed pieces of metadata describing ingress and egress traffic and the
environment this traffic occurs in. An Istio attribute carries a specific piece
of information such as the error code of an API request, the latency of an API request, or the
original IP address of a TCP connection. For example:

```xxx
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.service: example
```

## Attribute vocabulary

A given Istio deployment has a fixed vocabulary of attributes that it understands.
The specific vocabulary is determined by the set of attribute producers being used
in the deployment. The primary attribute producer in Istio is Envoy, although
specialized Mixer adapters can also generate attributes.

The common baseline set of attributes available in most Istio deployments is defined
[here]({{home}}/docs/reference/config/mixer/attribute-vocabulary.html).

## Attribute names

Istio attributes use Java-like fully qualified identifiers as attribute names. The
allowed characters are `[_.a-z0-9]`. The character `"."` is used as namespace
separator. For example, `request.size` and `source.ip`.

## Attribute types

Istio attributes are strongly typed. The supported attribute types are defined by
[ValueType](https://github.com/istio/api/blob/master/policy/v1beta1/value_type.proto).
