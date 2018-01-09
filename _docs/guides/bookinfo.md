---
1;95;0ctitle: Bookinfo Sample Application
overview: This guide deploys a sample application composed of four separate microservices which will be used to demonstrate various features of the Istio service mesh.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

This guide deploys a sample application composed of four separate microservices which will be used
to demonstrate various features of the Istio service mesh.

## Overview

In this guide we will deploy a simple application that displays information about a
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

{% include figure.html width='80%' ratio='68.52%'
    img='./img/bookinfo/noistio.svg'
    alt='BookInfo Application without Istio'
    title='BookInfo Application without Istio'
    caption='BookInfo Application without Istio'
    %}

This application is polyglot, i.e., the microservices are written in different languages.
It’s worth noting that these services have no dependencies on Istio, but make an interesting
sevice mesh example, particularly because of the multitude of services, languages and versions
for the reviews service.

## Before you begin

If you haven't already done so, setup Istio by following the instructions
corresponding to your platform [installation guide]({{home}}/docs/setup/).

## Deploying the application

To run the sample with Istio requires no changes to the
application itself. Instead, we simply need to configure and run the services in an
Istio-enabled environment, with Envoy sidecars injected along side each service.
The needed commands and configuration vary depending on the runtime environment
although in all cases the resulting deployment will look like this:

{% include figure.html width='80%' ratio='59.08%'
    img='./img/bookinfo/withistio.svg'
    alt='BookInfo Application'
    title='BookInfo Application'
    caption='BookInfo Application'
    %}

All of the microservices will be packaged with an Envoy sidecar that intercepts incoming
and outgoing calls for the services, providing the hooks needed to externally control,
via the Istio control plane, routing, telemetry collection, and policy enforcement
for the application as a whole.

To start the application, follow the instructions below corresponding to your Istio runtime environment.

### Running on Kubernetes

> Note: If you use GKE, please ensure your cluster has at least 4 standard GKE nodes. If you use Minikube, please ensure you have at least 4GB RAM.

1. Change directory to the root of the Istio installation directory.

1. Bring up the application containers:

   If you are using [manual sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#manual-sidecar-injection),
   use the following command instead:

   ```bash
   kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/kube/bookinfo.yaml)
   ```

   If you are using a cluster with
   [automatic sidecar injection]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection)
   enabled, simply deploy the services using `kubectl`:

   ```bash
   kubectl apply -f samples/bookinfo/kube/bookinfo.yaml
   ```

   The `istioctl kube-inject` command is used to manually modify the `bookinfo.yaml`
   file before creating the deployments as documented [here]({{home}}/docs/reference/commands/istioctl.html#istioctl-kube-inject).

   Either of the above commands launches all four microservices and creates the gateway
   ingress resource as illustrated in the above diagram.
   All 3 versions of the reviews service, v1, v2, and v3, are started.

   > Note that in a realistic deployment, new versions of a microservice are deployed
   over time instead of deploying all versions simultaneously.

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

#### Determining the ingress IP and Port

1. If your Kubernetes cluster is running in an environment that supports external load balancers, the IP address of ingress can be  obtained by the following command:

   ```bash
   kubectl get ingress -o wide
   ```

   whose output should be similar to

   ```bash
   NAME      HOSTS     ADDRESS                 PORTS     AGE
   gateway   *         130.211.10.121          80        1d
   ```

   The address of the ingress service would then be
   
   ```bash
   export GATEWAY_URL=130.211.10.121:80
   ```

1. _GKE:_ Sometimes when the service is unable to obtain an external IP, `kubectl get ingress -o wide` may display a list of worker node addresses. In this case, you can use any of the addresses, along with the NodePort, to access the ingress. If the cluster has a firewall, you will also need to create a firewall rule to allow TCP traffic to the NodePort.

   ```bash
   export GATEWAY_URL=<workerNodeAddress>:$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
   gcloud compute firewall-rules create allow-book --allow tcp:$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
   ```

1. _IBM Cloud Container Service Free Tier:_ External load balancer is not available for kubernetes clusters in the free tier. You can use the public IP of the worker node, along with the NodePort, to access the ingress. The public IP of the worker node can be obtained from the output of the following command:

   ```bash
   bx cs workers <cluster-name or id>
   export GATEWAY_URL=<public IP of the worker node>:$(kubectl get svc istio-ingress -n istio-system -o jsonpath='{.spec.ports[0].nodePort}')
   ```

1. _IBM Cloud Private:_ External load balancers are not supported in IBM Cloud Private. You can use the host IP of the ingress service, along with the NodePort, to access the ingress.

   ```bash
   export GATEWAY_URL=$(kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
   ```

1. _Minikube:_ External load balancers are not supported in Minikube. You can use the host IP of the ingress service, along with the NodePort, to access the ingress.
   
   ```bash
   export GATEWAY_URL=$(kubectl get po -l istio=ingress -n istio-system -o 'jsonpath={.items[0].status.hostIP}'):$(kubectl get svc istio-ingress -n istio-system -o 'jsonpath={.spec.ports[0].nodePort}')
   ```

### Running on Docker with Consul or Eureka

1. Change directory to the root of the Istio installation directory.

1. Bring up the application containers.

    * To test with Consul, run the following commands:
      ```bash
      docker-compose -f samples/bookinfo/consul/bookinfo.yaml up -d
      docker-compose -f samples/bookinfo/consul/bookinfo.sidecars.yaml up -d
      ```
    * To test with Eureka, run the following commands:
      ```bash
      docker-compose -f samples/bookinfo/eureka/bookinfo.yaml up -d
      docker-compose -f samples/bookinfo/eureka/bookinfo.sidecars.yaml up -d
      ```
1. Confirm that all docker containers are running:

   ```bash
   docker ps -a
   ```

   > If the Istio Pilot container terminates, re-run the command from the previous step.

1. Set the GATEWAY_URL:

   ```bash
   export GATEWAY_URL=localhost:9081
   ```

## What's next

To confirm that the BookInfo application is running, run the following `curl` command:

```bash
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
```
```
200
```

You can also point your browser to `http://$GATEWAY_URL/productpage`
to view the Bookinfo web page. If you refresh the page several times, you should
see different versions of reviews shown in productpage, presented in a round robin style (red
stars, black stars, no stars), since we haven't yet used Istio to control the
version routing.

You can now use this sample to experiment with Istio's features for
traffic routing, fault injection, rate limitting, etc..
To proceed, refer to one or more of the [Istio Guides]({{home}}/docs/guides),
depending on your interest. [Intelligent Routing]({{home}}/docs/guides/intelligent-routing.html)
is a good place to start for beginners.

## Cleanup

When you're finished experimenting with the BookInfo sample, you can
uninstall and clean it up using the following instructions.

### Uninstall from Kubernetes environment

1. Delete the routing rules and terminate the application pods

   ```bash
   samples/bookinfo/kube/cleanup.sh
   ```

1. Confirm shutdown

   ```bash
   istioctl get routerules   #-- there should be no more routing rules
   kubectl get pods          #-- the BookInfo pods should be deleted
   ```

### Uninstall from Docker environment

1. Delete the routing rules and application containers

    1. In a Consul setup, run the following command:

   ```bash
   samples/bookinfo/consul/cleanup.sh
   ```
   
   1. In a Eureka setup, run the following command:
   
   ```bash
   samples/bookinfo/eureka/cleanup.sh
   ```

2. Confirm cleanup

   ```bash
   istioctl get routerules   #-- there should be no more routing rules
   docker ps -a              #-- the BookInfo containers should be deleted
   ```
