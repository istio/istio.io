---
title: Istiod Introspection
description: Describes how to use ControlZ to get insight into a running istiod component.
weight: 60
keywords: [ops]
aliases:
  - /help/ops/controlz
  - /docs/ops/troubleshooting/controlz
owner: istio/wg-user-experience-maintainers
test: no
---

Istiod is built with a flexible introspection framework, called ControlZ, which makes it easy to inspect and manipulate the internal state
of an istiod instance. Istiod opens a port which can be used from a web browser to get an interactive view into its state,
or via REST for access and control from external tools.

When Istiod starts, a message is logged indicating the IP address and port to connect to in order to interact with ControlZ.

{{< text plain >}}
2020-08-04T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

Here's sample of the ControlZ interface:

{{< image width="90%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

To access the ControlZ page of istiod, you can port-forward its ControlZ endpoint
locally and connect through your local browser:

{{< text bash >}}
$ istioctl dashboard controlz deployment/istiod.istio-system
{{< /text >}}

This will redirect the component's ControlZ page to `http://localhost:9876` for remote access.
