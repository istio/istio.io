---
title: Component Introspection
description: Describes how to use ControlZ to get insight into individual running components.
weight: 60
keywords: [ops]
aliases:
  - /help/ops/controlz
  - /docs/ops/troubleshooting/controlz
owner: istio/wg-user-experience-maintainers
test: no
---

Istio components are built with a flexible introspection framework which makes it easy to inspect and manipulate the internal state
of a running component. Components open a port which can be used from a web browser to get an interactive view into the state of the
component, or via REST for access and control from external tools.

Istiod implement the ControlZ functionality. When it starts, a message is logged indicating the
IP address and port to connect to in order to interact with ControlZ.

{{< text plain >}}
2020-08-04T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

Here's sample of the ControlZ interface:

{{< image width="90%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

To access the ControlZ page of istiod, you can port-forward its ControlZ endpoint
locally and connect through your local browser:

{{< text bash >}}
$ istioctl dashboard controlz istiod-954c974bb-qgb4h -n istio-system
{{< /text >}}

This will redirect the component's ControlZ page to `http://localhost:9876` for remote access.
