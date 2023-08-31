---
title: OpenShift
description: Instructions to set up an OpenShift cluster for Istio.
weight: 55
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/openshift/
    - /docs/setup/kubernetes/platform-setup/openshift/
keywords: [platform-setup,openshift]
owner: istio/wg-environments-maintainers
test: no
---

Follow these instructions to prepare an OpenShift cluster for Istio.

Install Istio using the OpenShift profile:

{{< text bash >}}
$ istioctl install --set profile=openshift
{{< /text >}}

After installation is complete, expose an OpenShift route for the ingress gateway.

{{< text bash >}}
$ oc -n istio-system expose svc/istio-ingressgateway --port=http2
{{< /text >}}
