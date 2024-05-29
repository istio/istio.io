---
title: Deploy the application
description: Deploy the Bookinfo sample application.
weight: 2
owner: istio/wg-networking-maintainers
test: yes
---

You’ll install the sample [bookinfo application](/docs/examples/bookinfo/) that's comprised of multiple microservices and is used for demonstration purposes.

Here's the architecture of the Bookinfo application:

{{< image width="50%" link="./bookinfo.svg" caption="Bookinfo Application" >}}

As part of this guide, you'll deploy the Bookinfo application and expose the `productpage` service using an ingress gateway.

## 1. Deploy Bookinfo application

Let's start by deploying the application:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-versions.yaml
{{< /text >}}

To verify that the application is running, check the status of the pods:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-cf74bb974-nw94k       1/1     Running   0          9m20s
productpage-v1-87d54dd59-wl7qf   1/1     Running   0          9m19s
ratings-v1-7c4bbf97db-rwkw5      1/1     Running   0          9m20s
reviews-v1-5fd6d4f8f8-66j45      1/1     Running   0          9m19s
reviews-v2-6f9b55c5db-6ts96      1/1     Running   0          9m19s
reviews-v3-7d99fd7978-dm6mx      1/1     Running   0          9m19s
{{< /text >}}

To access the `productpage` service from outside the cluster, you need to configure an ingress gateway.

## 2. Deploy and configure the ingress gateway

You will use the Kubernetes Gateway API to deploy a gateway called `bookinfo-gateway`:

{{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
$ kubectl apply -f {{< github_file >}}/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
{{< /text >}}

By default, Istio creates a `LoadBalancer` service for a gateway. Change the service type to `ClusterIP` by annotating the gateway:

{{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
$ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
{{< /text >}}

To check the status of the gateway, run:

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         88s
{{< /text >}}

## 3. Test the application

Let's test the application using the `port-forward` command to access the `productpage` service through the gateway:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

Open your browser and navigate to `http://localhost:8080/productpage` to view the Bookinfo application.

{{< image width="80%" link="./bookinfo-browser.png" caption="Bookinfo Application" >}}

If you refresh the page, you should see the book reviews changing as the requests are distributed across different versions of the `reviews` service.

## 4. Next steps

In the next section you'll enable ambient mode and learn how to secure and visualize the communication between the applications.
