---
title: Configure Egress Gateway for HTTPS traffic to wildcarded domains
description: Use an SNI proxy in addition to the Envoy instance in the istio-egressgateway for wildcarded domains
publishdate: 2018-07-01
attribution: Vadim Eisenberg
weight: 86
---

The [Configure Egress Gateway]() task, [Direct HTTPS traffic through an egress gateway]() section described how to
configure an Istio egress gateway for HTTPS traffic for specific hostnames, like _edition.cnn.com_. This blog post
explains how to enable an egress gateway for HTTPS traffic to a set of domains, for example to _*.wikipedia.org_,
without the need to specify each and every host.

## Background

Suppose we want to enable secure egress traffic control in Istio for the _wikipedia.org_ sites in all the languages.
Each version of _wikipedia.org_ in a particular language has its own hostnames, e.g. _en.wikipida.org_ and
_de.wikipia.org_ in the English and the German languages, respectively.


## Before you begin

## Cleanup
