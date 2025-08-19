---
title: Istio 1.15 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.15.0.
publishdate: 2022-08-31
weight: 20
---

When you upgrade from Istio 1.14.x to Istio 1.15.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.14.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.14.x`.
Users upgrading from 1.13.x to Istio 1.15.0 should also reference the [1.15.0 change logs](/news/releases/1.15.x/announcing-1.15/change-notes/).

## Remote cluster management

Starting with Istio 1.15.0, a remote cluster is no longer automatically managed by the control plane
to which it is attached. Remote clusters will now only be managed by a control plane if its cluster ID
is specified with a `topology.istio.io/controlPlaneClusters` annotation on the system namespace of the
remote cluster. This annotation must be added to a remote cluster BEFORE upgrading the corresponding
control plane on an external or primary cluster.

Refer to the [external control plane](/docs/setup/install/external-controlplane/#register-the-new-cluster)
and [multicluster primary-remote](/docs/setup/install/multicluster/primary-remote/#attach-cluster2-as-a-remote-cluster-of-cluster1)
installation instructions for more details.
