---
title: Enable Ambient Mode
description: Enable Ambient mode and add the application to the mesh.
weight: 3
---

## Adding your application to the ambient mesh {#addtoambient}

1. You can enable all pods in a given namespace to be part of an ambient mesh by simply labeling the namespace:

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    namespace/default labeled
    {{< /text >}}

    Congratulations! You have successfully added all pods in the default namespace
    to the mesh. Note that you did not have to restart or redeploy anything!

1. Now, send some test traffic:

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

You’ll immediately gain mTLS communication and L4 telemetry among the applications in the ambient mesh.
If you follow the instructions to install [Prometheus](/docs/ops/integrations/prometheus/#installation)
and [Kiali](/docs/ops/integrations/kiali/#installation), you’ll be able to visualize your application
in Kiali’s dashboard:

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali dashboard" >}}
