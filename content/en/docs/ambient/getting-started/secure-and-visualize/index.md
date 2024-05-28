---
title: Secure and visualize the application
description: Enable Ambient mode and secure the communication between applications.
weight: 3
---

Adding applications to the ambient mesh is as simple as labeling the namespace where the application resides. By adding the applications to the ambient mesh, you automatically secure the communication between them and Istio starts gathering L4 telemetry. And no, you don't need to restart or redeploy the applications!

## 1. Add applications to the ambient mesh

You can enable all pods in a given namespace to be part of an ambient mesh by simply labeling the namespace:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

🎉Congratulations! You have successfully added all pods in the default namespace to the ambient mesh. If you open the Bookinfo application in your browser, you should see the product page, just like before.

The difference this time is that the communication between the Bookinfo application pods is encrypted and it's **automatically using mTLS**. Additionally, Istio is gathering **L4 telemetry** for all traffic between the pods!

**You did all this without even restarting or redeploy any of the applications!**

You can run the following command to verify that all pods are running and they haven't been restarted:

{{< text bash >}}
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-cf74bb974-nw94k       1/1     Running   0          16m20s
productpage-v1-87d54dd59-wl7qf   1/1     Running   0          16m19s
ratings-v1-7c4bbf97db-rwkw5      1/1     Running   0          16m20s
reviews-v1-5fd6d4f8f8-66j45      1/1     Running   0          16m19s
reviews-v2-6f9b55c5db-6ts96      1/1     Running   0          16m19s
reviews-v3-7d99fd7978-dm6mx      1/1     Running   0          16m19s
{{< /text >}}

Note the `RESTARTS` column. If the value is `0`, it means that the pods haven't been restarted.

## 2. Visualize the application and metrics

Let's deploy Prometheus and Kiali to see the L4 telemetry and visualize the application in Kiali's dashboard:

{{< text bash>}}
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
{{< /text >}}

You can access the Kiali dashboard by running the following command:

{{< text bash >}}
$ istioctl dashboard kiali
{{< /text >}}

Click on the Traffic Graph and you should see the Bookinfo application:

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali dashboard" >}}

{{< tip >}}
If you don't see any traffic in Kiali, try refreshing the Bookinfo application in your browser. This will generate some traffic and you should see it in Kiali.
{{</ tip >}}
If you click on one of the services on the the dashboard, you can see the inbound and outbound traffic metrics gathered by Istio:

{{< image link="./kiali-tcp-traffic.png" caption="L4 traffic" >}}

In addition to mTLS and telemetry, Istio has created a strong identity for each service (a SPIFFE ID). This identity can be used for creating authorization policies.

## 3. Next steps

Now that we have the strong identities assigned to the services, let's [enforce authorization policies](/docs/ambient/getting-started/enforce-auth-policies/) to secure the application access.
