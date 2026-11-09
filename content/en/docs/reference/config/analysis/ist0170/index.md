---
title: MultiClusterInconsistentService
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a `Service` with the same name and namespace is different in two or more
clusters of a multicluster mesh.

Istio merges services with the same name and namespace from all clusters into one service. If the
definitions are different, the behavior is not defined. The analyzer compares these items:

- The service type.
- The ports.
- If the service is headless (`clusterIP: None`) or not.

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0170] (Service sample/helloworld) The service helloworld in namespace "sample" is inconsistent across clusters ["cluster1" "cluster2"], which can lead to undefined behaviors. The inconsistent behaviors are: service ports are inconsistent.
{{< /text >}}

## How to resolve

Make the `Service` definitions the same in all clusters.
