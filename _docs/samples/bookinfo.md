---
category: Samples
title: BookInfo
overview: This sample deploys a simple application composed of four separate microservices which will be used to demonstrate various features of the Istio service mesh.
          
order: 10

bodyclass: docs
layout: docs
type: markdown
---

This sample deploys a simple application composed of four separate microservices which will be used
to demonstrate various features of the Istio service mesh.
          
## Before you begin

Setup Istio by following the instructions in the
[Installation guide](/docs/tasks/installing-istio.html).

## Overview

In this sample we will deploy a simple application that displays information about a
book, similar to a single catalog entry of an online book store. Displayed
on the page is a description of the book, book details (ISBN, number of
pages, and so on), and a few book reviews.

The bookinfo application is broken into four separate microservices:

* *productpage*. The productpage microservice calls the *details* and *reviews* microservices to populate the page.
* *details*. The details microservice contains book information.
* *reviews*. The reviews microservice contains book reviews. It also calls the *ratings* microservice.
* *ratings*. The ratings microservice contains book ranking information that accompanies a book review.

There are 3 versions of the reviews microservice:

* Version v1 doesn't call the ratings service.
* Version v2 calls the ratings service, and displays each rating as 1 to 5 black stars.
* Version v3 calls the ratings service, and displays each rating as 1 to 5 red stars.

The end-to-end architecture of the application is shown below.

![Bookinfo app_noistio]({{site.bareurl}}/docs/samples/img/bookinfo/noistio.svg)

This application is polyglot, i.e., the microservices are written in different languages.

## Start the application

1. Change your current working directory to the bookinfo application directory:

   ```bash
   cd demos/apps/bookinfo
   ```

1. Bring up the application containers:

   ```bash
   kubectl apply -f <(istioctl kube-inject -f bookinfo.yaml)
   ```
   
   The above command launches four microservices and creates the gateway
   ingress resource as illustrated in the diagram above.
   The reviews microservice has 3 versions: v1, v2, and v3.
     
   > Note that in a realistic deployment, new versions of a microservice are deployed
   over time instead of deploying all versions simultaneously.

   Notice that the `istioctl kube-inject` command is used to modify the `bookinfo.yaml`
   file before creating the deployments. This injects Envoy into kubernetes resources
   as documented [here]({{site.bareurl}}/docs/reference/istioctl.html#kube-inject).
   Consequently, all of the microservices are now packaged with an Envoy sidecar
   that manages incoming and outgoing calls for the service. The updated diagram looks
   like this:

   ![Bookinfo app]({{site.bareurl}}/docs/samples/img/bookinfo/withistio.svg)

1. Confirm all services and pods are correctly defined and running:

   ```bash
   $ kubectl get services
   NAME                       CLUSTER-IP   EXTERNAL-IP   PORT(S)              AGE
   details                    10.0.0.31    <none>        9080/TCP             6m
   istio-ingress              10.0.0.122   <pending>     80:31565/TCP         8m
   istio-manager              10.0.0.189   <none>        8080/TCP             8m
   istio-mixer                10.0.0.132   <none>        9091/TCP,42422/TCP   8m
   kubernetes                 10.0.0.1     <none>        443/TCP              14d
   productpage                10.0.0.120   <none>        9080/TCP             6m
   ratings                    10.0.0.15    <none>        9080/TCP             6m
   reviews                    10.0.0.170   <none>        9080/TCP             6m
   ```
   
   and

   ```bash
   $ kubectl get pods
   NAME                                        READY     STATUS    RESTARTS   AGE
   details-v1-1520924117-48z17                 2/2       Running   0          6m
   istio-ingress-3181829929-xrrk5              1/1       Running   0          8m
   istio-manager-175173354-d6jm7               2/2       Running   0          8m
   istio-mixer-3883863574-jt09j                2/2       Running   0          8m
   productpage-v1-560495357-jk1lz              2/2       Running   0          6m
   ratings-v1-734492171-rnr5l                  2/2       Running   0          6m
   reviews-v1-874083890-f0qf0                  2/2       Running   0          6m
   reviews-v2-1343845940-b34q5                 2/2       Running   0          6m
   reviews-v3-1813607990-8ch52                 2/2       Running   0          6m
   ```

1. Determine the gateway ingress URL:

   If your cluster is running in an environment that supports external loadbalancers,
   use the ingress' external address:

   ```bash
   $ kubectl get ingress
   NAME      HOSTS     ADDRESS                 PORTS     AGE
   gateway   *         130.211.10.121          80        1d
   $ export GATEWAY_URL=130.211.10.121:80
   ```

   If loadbalancers are not supported, use the service NodePort instead:
   ```bash
   $ export GATEWAY_URL=$(kubectl get po -l infra=istio-ingress-controller -o jsonpath={.items[0].status.hostIP}):$(kubectl get svc istio-ingress-controller -o jsonpath={.spec.ports[0].nodePort})
   ```

1. Confirm that the bookinfo application is running with the following `curl` command:
   
   ```bash
   $ curl -o /dev/null -s -w "%{http_code}\n" http://$GATEWAY_URL/productpage
   200
   ```

## What's next

Now that you have the bookinfo sample up and running, you can use Istio to control traffic routing,
inject faults, rate limit services, etc..

* To get started, check out the [request routing task](/docs/tasks/request-routing.html)

* When you're finished experimenting with the bookinfo sample, you can uninstall it as follows:

1. Delete the routing rules and terminate the application pods

   ```bash
   ./cleanup.sh
   ```

1. Confirm shutdown

   ```bash
   istioctl get route-rules   #-- there should be no more routing rules
   kubectl get pods           #-- the bookinfo pods should be deleted
   ```
