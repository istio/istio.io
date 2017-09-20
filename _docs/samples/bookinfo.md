---
title: BookInfo
overview: This sample deploys a simple application composed of four separate microservices which will be used to demonstrate various features of the Istio service mesh.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

This sample deploys a simple application composed of four separate microservices which will be used
to demonstrate various features of the Istio service mesh.

## Before you begin
* If you use GKE, please ensure your cluster has at least 4 standard GKE nodes.

* Setup Istio by following the instructions in the
[Installation guide]({{home}}/docs/tasks/installing-istio.html).

## Overview

In this sample we will deploy a simple application that displays information about a
book, similar to a single catalog entry of an online book store. Displayed
on the page is a description of the book, book details (ISBN, number of
pages, and so on), and a few book reviews.

The BookInfo application is broken into four separate microservices:

* *productpage*. The productpage microservice calls the *details* and *reviews* microservices to populate the page.
* *details*. The details microservice contains book information.
* *reviews*. The reviews microservice contains book reviews. It also calls the *ratings* microservice.
* *ratings*. The ratings microservice contains book ranking information that accompanies a book review.

There are 3 versions of the reviews microservice:

* Version v1 doesn't call the ratings service.
* Version v2 calls the ratings service, and displays each rating as 1 to 5 black stars.
* Version v3 calls the ratings service, and displays each rating as 1 to 5 red stars.

The end-to-end architecture of the application is shown below.

<figure><img src="./img/bookinfo/noistio.svg" alt="BookInfo Application without Istio" title="BookInfo Application without Istio" />
<figcaption>BookInfo Application without Istio</figcaption></figure>

This application is polyglot, i.e., the microservices are written in different languages.

## Start the application

1. Change directory to the root of the Istio installation directory.

1. Bring up the application containers:

   ```bash
   kubectl apply -f <(istioctl kube-inject -f samples/apps/bookinfo/bookinfo.yaml)
   ```

   The above command launches four microservices and creates the gateway
   ingress resource as illustrated in the diagram below.
   The reviews microservice has 3 versions: v1, v2, and v3.

   > Note that in a realistic deployment, new versions of a microservice are deployed
   over time instead of deploying all versions simultaneously.

   Notice that the `istioctl kube-inject` command is used to modify the `bookinfo.yaml`
   file before creating the deployments. This injects Envoy into Kubernetes resources
   as documented [here]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject).
   Consequently, all of the microservices are now packaged with an Envoy sidecar
   that manages incoming and outgoing calls for the service. The updated diagram looks
   like this:

   <figure><img src="./img/bookinfo/withistio.svg" alt="BookInfo Application" title="BookInfo Application" />
   <figcaption>BookInfo Application</figcaption></figure>

1. Confirm all services and pods are correctly defined and running:

   ```bash
   kubectl get services
   ```

   which produces the following output:
   
   ```bash
   NAME                       CLUSTER-IP   EXTERNAL-IP   PORT(S)              AGE
   details                    10.0.0.31    <none>        9080/TCP             6m
   kubernetes                 10.0.0.1     <none>        443/TCP              7d
   productpage                10.0.0.120   <none>        9080/TCP             6m
   ratings                    10.0.0.15    <none>        9080/TCP             6m
   reviews                    10.0.0.170   <none>        9080/TCP             6m
   ```

   and

   ```bash
   kubectl get pods
   ```
   
   which produces
   
   ```bash
   NAME                                        READY     STATUS    RESTARTS   AGE
   details-v1-1520924117-48z17                 2/2       Running   0          6m
   productpage-v1-560495357-jk1lz              2/2       Running   0          6m
   ratings-v1-734492171-rnr5l                  2/2       Running   0          6m
   reviews-v1-874083890-f0qf0                  2/2       Running   0          6m
   reviews-v2-1343845940-b34q5                 2/2       Running   0          6m
   reviews-v3-1813607990-8ch52                 2/2       Running   0          6m
   ```

1. Determine the gateway ingress URL:

   ```bash
   kubectl get ingress -o wide
   ```
   
   ```bash
   NAME      HOSTS     ADDRESS                 PORTS     AGE
   gateway   *         130.211.10.121          80        1d
   ```

   If your Kubernetes cluster is running in an environment that supports external load balancers,
   and the Istio ingress service was able to obtain an External IP, the ingress resource ADDRESS will be equal to the
   ingress service external IP.

   ```bash
   export GATEWAY_URL=130.211.10.121:80
   ```
   
   > Sometimes when the service is unable to obtain an external IP, the ingress ADDRESS may display a list
   > of NodePort addresses. In this case, you can use any of the addresses, along with the NodePort, to access the ingress. 
   > If, however, the cluster has a firewall, you will also need to create a firewall rule to allow TCP traffic to the NodePort.
   > In GKE, for instance, you can create a firewall rule using the following command:
   > ```bash
   > gcloud compute firewall-rules create allow-book --allow tcp:$(kubectl get svc istio-ingress -o jsonpath='{.spec.ports[0].nodePort}')
   > ```

   If your deployment environment does not support external load balancers (e.g., minikube), the ADDRESS field will be empty.
   In this case you can use the service NodePort instead:
   
   ```bash
   export GATEWAY_URL=$(kubectl get po -n istio-system -l istio=ingress -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
   ```

1. Confirm that the BookInfo application is running with the following `curl` command:

   ```bash
   curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
   ```
   ```bash
   200
   ```
   
## Cleanup

When you're finished experimenting with the BookInfo sample, you can uninstall it as follows:

1. Delete the routing rules and terminate the application pods

   ```bash
   samples/apps/bookinfo/cleanup.sh
   ```

1. Confirm shutdown

   ```bash
   istioctl get routerules   #-- there should be no more routing rules
   kubectl get pods          #-- the BookInfo pods should be deleted
   ```

## What's next

Now that you have the BookInfo sample up and running, you can point your browser to `http://$GATEWAY_URL/productpage`
to see the running application and use Istio to control traffic routing, inject faults, rate limit services, etc..

To get started, check out the [request routing task]({{home}}/docs/tasks/request-routing.html).
