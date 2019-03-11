---
title: Docker For Desktop
description: Instructions to setup Docker For Desktop for use with Istio.
weight: 12
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/docker-for-desktop/
keywords: [platform-setup,kubernetes,docker-for-desktop]
---

If you want to run Istio under Docker for desktop's built-in Kubernetes, you may need to increase Docker's memory limit
under the *Advanced* pane of Docker's preferences.  Pilot by default requests `2048Mi` of memory, which is Docker's
default limit.

{{< image width="60%" link="./dockerprefs.png"  caption="Docker Preferences"  >}}

Alternatively, you may reduce Pilot's memory reservation by passing the helm argument
`--set pilot.resources.requests.memory="512Mi"`.  Otherwise Pilot may refuse to start due to insufficient resources.
See [Installation Options](/docs/reference/config/installation-options) for more information.
