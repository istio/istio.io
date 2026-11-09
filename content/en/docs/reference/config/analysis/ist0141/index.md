---
title: InsufficientPermissions
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when [`istioctl x precheck`](/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
finds that you do not have the permissions that are necessary to install Istio.

## An example

You will receive a message like this:

{{< text plain >}}
Error [IST0141] (Cluster) Missing required permission to create resource clusterroles (...)
{{< /text >}}

## How to resolve

Get the missing permissions from your cluster administrator, or install Istio with a user that has
cluster administrator permissions. You can examine a permission with `kubectl auth can-i`:

{{< text bash >}}
$ kubectl auth can-i create clusterroles
{{< /text >}}
