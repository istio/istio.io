---
title: Component Introspection
description: Describes how to use ControlZ to get insight into individual running components.
weight: 98
keywords: [ops]
aliases:
    - /help/ops/controlz
---

Istio components are built with a flexible introspection framework which makes it easy to inspect and manipulate the internal state
of a running component. Components open a port which can be used from a web browser to get an interactive view into the state of the
component, or via REST for access and control from external tools.

Mixer, Pilot, and Galley all implement the ControlZ functionality. When these components start, a message is logged indicating the
IP address and port to connect to in order to interact with ControlZ.

{{< text plain >}}
2018-07-26T23:28:48.889370Z     info    ControlZ available at 100.76.122.230:9876
{{< /text >}}

Here's sample of the ControlZ interface:

{{< image width="80%" link="./ctrlz.png" caption="ControlZ User Interface" >}}

The `--ctrlz_port` and `--ctrlz_address` command-line options can be given when starting a component to control the
specific address and port where ControlZ should be exposed.

To access the ControlZ page of deployed components (i.e. Mixer, Galley, Pilot), you can port-forward their ControlZ endpoints
locally and connect through your local browser:

{{< text bash >}}
$ kubectl port-forward -n istio-system <podname> 9876:9876
{{< /text >}}

This will redirect the component's ControlZ page to `http://localhost:9876` for remote access.

