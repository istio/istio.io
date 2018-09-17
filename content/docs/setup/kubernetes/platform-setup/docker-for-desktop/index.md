---
title: Docker For Desktop
description: Instructions to setup Docker For Desktop for use with Istio.
weight: 15
skip_seealso: true
keywords: [platform-setup,kubernetes,docker-for-desktop]
---

If you want to run istio under docker for desktop's built-in Kubernetes, you may need to increase docker's memory limit
under the *Advanced* pane of docker's preferences.  Pilot by default requests `2048Mi` of memory, which is docker's
default limit.

{{< image width="60%" ratio="92.24%"
    link="./dockerprefs.png"
    caption="Docker Preferences"
    >}}

Alternatively, you may reduce Pilot's memory reservation by passing the helm argument
`--set pilot.resources.requests.memory="512Mi"`.  Otherwise Pilot may refuse to start due to insufficient resources.
See [Installation Options](https://istio.io/docs/reference/config/installation-options) for more information.
