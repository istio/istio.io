---
title: Consuming External MongoDB Services
description: Describes a simple scenario based on Istio's Bookinfo example.
publishdate: 2018-11-16
last_update: 2019-04-18
subtitle: Istio Egress Control Options for MongoDB traffic
attribution: Vadim Eisenberg
keywords: [traffic-management,egress,tcp,mongo]
---

In the [Consuming External TCP Services](/blog/2018/egress-tcp/) blog post, I described how external services
can be consumed by in-mesh Istio applications via TCP. In this post, I demonstrate consuming external MongoDB services.
You use the [Istio Bookinfo sample application](/docs/examples/bookinfo/), the version in which the book
ratings data is persisted in a MongoDB database. You deploy this database outside the cluster and configure the
_ratings_ microservice to use it. You will learn multiple options of controlling traffic to external MongoDB services and their
pros and cons.

## Bookinfo with external ratings database

First, you set up a MongoDB database instance to hold book ratings data outside of your Kubernetes cluster. Then you
modify the [Bookinfo sample application](/docs/examples/bookinfo/) to use your database.

### Setting up the ratings database

For this task you set up an instance of [MongoDB](https://www.mongodb.com). You can use any MongoDB instance; I used
[Compose for MongoDB](https://www.ibm.com/cloud/compose/mongodb).

1. Set an environment variable for the password of your `admin` user. To prevent the password from being preserved in
   the Bash history, remove the command from the history immediately after running the command, using
   [history -d](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins).

    {{< text bash >}}
    $ export MONGO_ADMIN_PASSWORD=<your MongoDB admin password>
    {{< /text >}}

1.  Set an environment variable for the password of the new user you will create, namely `bookinfo`.
    Remove the command from the history using
    [history -d](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins).

    {{< text bash >}}
    $ export BOOKINFO_PASSWORD=<password>
    {{< /text >}}

1.  Set environment variables for your MongoDB service, `MONGODB_HOST` and `MONGODB_PORT`.

1.  Create the `bookinfo` user:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.createUser(
       {
         user: "bookinfo",
         pwd: "$BOOKINFO_PASSWORD",
         roles: [ "read"]
       }
    );
    EOF
    {{< /text >}}

1.  Create a _collection_ to hold ratings. The following command sets both ratings to be equal `1` to provide a visual
    clue when your database is used by the Bookinfo _ratings_ service (the default Bookinfo _ratings_ are `4` and `5`).

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.createCollection("ratings");
    db.ratings.insert(
      [{rating: 1},
       {rating: 1}]
    );
    EOF
    {{< /text >}}

1.  Check that `bookinfo` user can get ratings:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u bookinfo -p $BOOKINFO_PASSWORD --authenticationDatabase test
    use test
    db.ratings.find({});
    EOF
    {{< /text >}}

    The output should be similar to:

    {{< text plain >}}
    MongoDB server version: 3.4.10
    switched to db test
    { "_id" : ObjectId("5b7c29efd7596e65b6ed2572"), "rating" : 1 }
    { "_id" : ObjectId("5b7c29efd7596e65b6ed2573"), "rating" : 1 }
    bye
    {{< /text >}}

### Initial setting of Bookinfo application

To demonstrate the scenario of using an external database, you start with a Kubernetes cluster with [Istio installed](/docs/setup/install/kubernetes/#installation-steps). Then you deploy the
[Istio Bookinfo sample application](/docs/examples/bookinfo/), [apply the default destination rules](/docs/examples/bookinfo/#apply-default-destination-rules), and
[change Istio to the blocking-egress-by-default policy](/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy).

This application uses the `ratings` microservice to fetch book ratings, a number between 1 and 5. The ratings are
displayed as stars for each review. There are several versions of the `ratings` microservice. You will deploy the
version that uses [MongoDB](https://www.mongodb.com) as the ratings database in the next subsection.

The example commands in this blog post work with Istio 1.0.

As a reminder, here is the end-to-end architecture of the application from the
[Bookinfo sample application](/docs/examples/bookinfo/).

{{< image width="80%" link="/docs/examples/bookinfo/withistio.svg" caption="The original Bookinfo application" >}}

### Use the external database in Bookinfo application

1.  Deploy the spec of the _ratings_ microservice that uses a MongoDB database (_ratings v2_), while setting
    `MONGO_DB_URL` environment variable of the spec:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@ --dry-run -o yaml | kubectl set env --local -f - "MONGO_DB_URL=mongodb://bookinfo:$BOOKINFO_PASSWORD@$MONGODB_HOST:$MONGODB_PORT/test?authSource=test&ssl=true" -o yaml | kubectl apply -f -
    deployment "ratings-v2" created
    {{< /text >}}

1.  Route all the traffic destined to the _reviews_ service to its _v3_ version. You do this to ensure that the
_reviews_ service always calls the _ratings_ service. In addition, route all the traffic destined to the _ratings_
service to _ratings v2_ that uses your database.

    Specify the routing for both services above by adding two
    [virtual services](/docs/reference/config/networking/v1alpha3/virtual-service/). These virtual services are
    specified in `samples/bookinfo/networking/virtual-service-ratings-mongodb.yaml` of an Istio release archive.
    ***Important:*** make sure you
    [applied the default destination rules](/docs/examples/bookinfo/#apply-default-destination-rules) before running the
     following command.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

The updated architecture appears below. Note that the blue arrows inside the mesh mark the traffic configured according
to the virtual services we added. According to the virtual services, the traffic is sent to _reviews v3_ and
 _ratings v2_.

{{< image width="80%" link="./bookinfo-ratings-v2-mongodb-external.svg" caption="The Bookinfo application with ratings v2 and an external MongoDB database" >}}

Note that the MongoDB database is outside the Istio service mesh, or more precisely outside the Kubernetes cluster. The
boundary of the service mesh is marked by a dashed line.

### Access the webpage

Access the webpage of the application, after
[determining the ingress IP and port](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

Since you did not configure the egress traffic control yet, the access to the MongoDB service is blocked by Istio.
This is why instead of the rating stars, the message _"Ratings service is currently unavailable"_ is currently
 displayed below each review:

{{< image width="80%" link="./errorFetchingBookRating.png" caption="The Ratings service error messages" >}}

In the following sections you will configure egress access to the external MongoDB service, using different options for
egress control in Istio.

## Egress control for TCP

Since [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/) runs on top of TCP, you
can control the egress traffic to your MongoDB as traffic to any other [external TCP service](/blog/2018/egress-tcp/). To
control TCP traffic, a block of IPs in the [CIDR](https://tools.ietf.org/html/rfc2317) notation that includes the IP
address of your MongoDB host must be specified. The caveat here is that sometimes the IP of the MongoDB host is not
stable or known in advance.

In the cases when the IP of the MongoDB host is not stable, the egress traffic can either be
[controlled as TLS traffic](#egress-control-for-tls), or the traffic can be routed
[directly](/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services), bypassing the Istio sidecar
proxies.

Get the IP address of your MongoDB database instance. As an option, you can use the
    [host](https://linux.die.net/man/1/host) command:

{{< text bash >}}
$ export MONGODB_IP=$(host $MONGODB_HOST | grep " has address " | cut -d" " -f4)
{{< /text >}}

### Control TCP egress traffic without a gateway

In case you do not need to direct the traffic through an
[egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#use-case), for example if you do not have a
requirement that all the traffic that exists your mesh must exit through the gateway, follow the
instructions in this section. Alternatively, if you do want to direct your traffic through an egress gateway, proceed to
[Direct TCP egress traffic through an egress gateway](#direct-tcp-egress-traffic-through-an-egress-gateway).

1.  Define a TCP mesh-external service entry:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - my-mongo.tcp.svc
      addresses:
      - $MONGODB_IP/32
      ports:
      - number: $MONGODB_PORT
        name: tcp
        protocol: TCP
      location: MESH_EXTERNAL
      resolution: STATIC
      endpoints:
      - address: $MONGODB_IP
    EOF
    {{< /text >}}

    Note that the protocol `TCP` is specified instead of `MONGO` due to the fact that the traffic can be encrypted in
    case [the MongoDB protocol runs on top of TLS](https://docs.mongodb.com/manual/tutorial/configure-ssl/).
    If the traffic is encrypted, the encrypted MongoDB protocol cannot be parsed by the Istio proxy.

    If you know that the plain MongoDB protocol is used, without encryption, you can specify the protocol as `MONGO` and
    let the Istio proxy produce
    [MongoDB related statistics](https://www.envoyproxy.io/docs/envoy/latest/configuration/network_filters/mongo_proxy_filter#statistics).
    Also note that when the protocol `TCP` is specified, the configuration is not specific for MongoDB, but is the same
    for any other database with the protocol on top of TCP.

    Note that the host of your MongoDB is not used in TCP routing, so you can use any host, for example `my-mongo.tcp.svc`. Notice the `STATIC` resolution and the endpoint with the IP of your MongoDB service. Once you define such an endpoint, you can access MongoDB services that do not have a domain name.

1.  Refresh the web page of the application. Now the application should display the ratings without error:

    {{< image width="80%" link="./externalDBRatings.png" caption="Book Ratings Displayed Correctly" >}}

    Note that you see a one-star rating for both displayed reviews, as expected. You set the ratings to be one star to
    provide yourself with a visual clue that your external database is indeed being used.

1.  If you want to direct the traffic through an egress gateway, proceed to the next section. Otherwise, perform
    [cleanup](#cleanup-of-tcp-egress-traffic-control).

### Direct TCP Egress traffic through an egress gateway

In this section you handle the case when you need to direct the traffic through an
[egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#use-case). The sidecar proxy routes TCP
connections from the MongoDB client to the egress gateway, by matching the IP of the MongoDB host (a CIDR block of
  length 32). The egress gateway forwards the traffic to the MongoDB host, by its hostname.

1.  [Deploy Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

1.  If you did not perform the steps in [the previous section](#control-tcp-egress-traffic-without-a-gateway), perform them now.

1.  Proceed to the following section.

#### Configure TCP traffic from sidecars to the egress gateway

1.  Define the `EGRESS_GATEWAY_MONGODB_PORT` environment variable to hold some port for directing traffic through
    the egress gateway, e.g. `7777`. You must select a port that is not used for any other service in the mesh.

    {{< text bash >}}
    $ export EGRESS_GATEWAY_MONGODB_PORT=7777
    {{< /text >}}

1.  Add the selected port to the `istio-egressgateway` service. You should use the same values you used for installing
    Istio, in particular you have to specify all the ports of the `istio-egressgateway` service that you previously
    configured.

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio/ --name istio-egressgateway --namespace istio-system -x charts/gateways/templates/service.yaml --set gateways.istio-ingressgateway.enabled=false --set gateways.istio-egressgateway.enabled=true --set gateways.istio-egressgateway.ports[0].port=80 --set gateways.istio-egressgateway.ports[0].name=http --set gateways.istio-egressgateway.ports[1].port=443 --set gateways.istio-egressgateway.ports[1].name=https --set gateways.istio-egressgateway.ports[2].port=$EGRESS_GATEWAY_MONGODB_PORT --set gateways.istio-egressgateway.ports[2].name=mongo | kubectl apply -f -
    {{< /text >}}

1.  Check that the `istio-egressgateway` service indeed has the selected port:

    {{< text bash >}}
    $ kubectl get svc istio-egressgateway -n istio-system
    NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
    istio-egressgateway   ClusterIP   172.21.202.204   <none>        80/TCP,443/TCP,7777/TCP   34d
    {{< /text >}}

1.  Create an egress `Gateway` for your MongoDB service, and destination rules and a virtual service to direct the
    traffic through the egress gateway and from the egress gateway to the external service.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: $EGRESS_GATEWAY_MONGODB_PORT
          name: tcp
          protocol: TCP
        hosts:
        - my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mongo
    spec:
      host: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - my-mongo.tcp.svc
      gateways:
      - mesh
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - mesh
          destinationSubnets:
          - $MONGODB_IP/32
          port: $MONGODB_PORT
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: $EGRESS_GATEWAY_MONGODB_PORT
      - match:
        - gateways:
          - istio-egressgateway
          port: $EGRESS_GATEWAY_MONGODB_PORT
        route:
        - destination:
            host: my-mongo.tcp.svc
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1.  [Verify that egress traffic is directed through the egress gateway](#verify-that-egress-traffic-is-directed-through-the-egress-gateway).

#### Mutual TLS between the sidecar proxies and the egress gateway

You may want to enable [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) between the sidecar proxies of
your MongoDB clients and the egress gateway to let the egress gateway monitor the identity of the source pods and to
enable Mixer policy enforcement based on that identity. By enabling mutual TLS you also encrypt the traffic.

1.  Delete the configuration from the previous section:

    {{< text bash >}}
    $ kubectl delete gateway istio-egressgateway --ignore-not-found=true
    $ kubectl delete virtualservice direct-mongo-through-egress-gateway --ignore-not-found=true
    $ kubectl delete destinationrule egressgateway-for-mongo mongo --ignore-not-found=true
    {{< /text >}}

1.  Create an egress `Gateway` for your MongoDB service, and destination rules and a virtual service
    to direct the traffic through the egress gateway and from the egress gateway to the external service.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - my-mongo.tcp.svc
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mongo
    spec:
      host: my-mongo.tcp.svc
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - my-mongo.tcp.svc
      gateways:
      - mesh
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - mesh
          destinationSubnets:
          - $MONGODB_IP/32
          port: $MONGODB_PORT
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: my-mongo.tcp.svc
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1.  Proceed to the next section.

#### Verify that egress traffic is directed through the egress gateway

1.  Refresh the web page of the application again and verify that the ratings are still displayed correctly.

1.  [Enable Envoy’s access logging](/docs/tasks/telemetry/logs/access-log/#enable-envoy-s-access-logging)

1.  Check the log of the egress gateway's Envoy and see a line that corresponds to your
    requests to the MongoDB service. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -n istio-system
    [2019-04-14T06:12:07.636Z] "- - -" 0 - "-" 1591 4393 94 - "-" "-" "-" "-" "<Your MongoDB IP>:<your MongoDB port>" outbound|<your MongoDB port>||my-mongo.tcp.svc 172.30.146.119:59924 172.30.146.119:443 172.30.230.1:59206 -
    {{< /text >}}

### Cleanup of TCP egress traffic control

{{< text bash >}}
$ kubectl delete serviceentry mongo
$ kubectl delete gateway istio-egressgateway --ignore-not-found=true
$ kubectl delete virtualservice direct-mongo-through-egress-gateway --ignore-not-found=true
$ kubectl delete destinationrule egressgateway-for-mongo mongo --ignore-not-found=true
{{< /text >}}

## Egress control for TLS

In the real life, most of the communication to the external services must be encrypted and
[the MongoDB protocol runs on top of TLS](https://docs.mongodb.com/manual/tutorial/configure-ssl/).
Also, the TLS clients usually send
[Server Name Indication](https://en.wikipedia.org/wiki/Server_Name_Indication), SNI, as part of their handshake. If your
MongoDB server runs TLS and your MongoDB client sends SNI as part of the handshake, you can control your MongoDB egress
traffic as any other TLS-with-SNI traffic. With TLS and SNI, you do not need to specify the IP addresses of your MongoDB
servers. You specify their host names instead, which is more convenient since you do not have to rely on the stability of
the IP addresses. You can also specify wildcards as a prefix of the host names, for example allowing access to any
server from the `*.com` domain.

To check if your MongoDB server supports TLS, run:

{{< text bash >}}
$ openssl s_client -connect $MONGODB_HOST:$MONGODB_PORT -servername $MONGODB_HOST
{{< /text >}}

If the command above prints a certificate returned by the server, the server supports TLS. If not, you have to control
your MongoDB egress traffic on the TCP level, as described in the previous sections.

### Control TLS egress traffic without a gateway

In case you [do not need an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#use-case), follow the
instructions in this section. If you want to direct your traffic through an egress gateway, proceed to
[Direct TCP Egress traffic through an egress gateway](#direct-tcp-egress-traffic-through-an-egress-gateway).

1.  Create a `ServiceEntry` for the MongoDB service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - $MONGODB_HOST
      ports:
      - number: $MONGODB_PORT
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Refresh the web page of the application. The application should display the ratings without error.

#### Cleanup of the egress configuration for TLS

{{< text bash >}}
$ kubectl delete serviceentry mongo
{{< /text >}}

### Direct TLS Egress traffic through an egress gateway

In this section you handle the case when you need to direct the traffic through an
[egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#use-case). The sidecar proxy routes TLS
connections from the MongoDB client to the egress gateway, by matching the SNI of the MongoDB host.
The egress gateway forwards the traffic to the MongoDB host. Note that the sidecar proxy rewrites the destination port
to be 443. The egress gateway accepts the MongoDB traffic on the port 443, matches the MongoDB host by SNI, and rewrites
 the port again to be the port of the MongoDB server.

1.  [Deploy Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

1.  Create a `ServiceEntry` for the MongoDB service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - $MONGODB_HOST
      ports:
      - number: $MONGODB_PORT
        name: tls
        protocol: TLS
      - number: 443
        name: tls-port-for-egress-gateway
        protocol: TLS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Refresh the web page of the application and verify that the ratings are displayed correctly.

1.  Create an egress `Gateway` for your MongoDB service, and destination rules and virtual services
    to direct the traffic through the egress gateway and from the egress gateway to the external service.

    If you want to enable [mutual TLS Authentication](/docs/tasks/security/mutual-tls/) between the sidecar proxies of
    your application pods and the egress gateway, use the following command. (You may want to enable mutual TLS to let
    the egress gateway monitor the identity of the source pods and to enable Mixer policy enforcement based on that
    identity.)

    {{< tabset cookie-name="mtls" >}}

    {{< tab name="mutual TLS enabled" cookie-value="enabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - $MONGODB_HOST
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: $MONGODB_HOST
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - $MONGODB_HOST
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: $MONGODB_HOST
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" cookie-value="disabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - $MONGODB_HOST
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-mongo
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: mongo
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - $MONGODB_HOST
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - $MONGODB_HOST
        route:
        - destination:
            host: $MONGODB_HOST
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1. [Verify that the traffic is directed though the egress gateway](#verify-that-egress-traffic-is-directed-through-the-egress-gateway)

#### Cleanup directing TLS Egress traffic through an egress gateway

{{< text bash >}}
$ kubectl delete serviceentry mongo
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-mongo-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-mongo
{{< /text >}}

### Enable MongoDB TLS egress traffic to arbitrary wildcarded domains

Sometimes you want to configure egress traffic to multiple hostnames from the same domain, for example traffic to all
MongoDB services from `*.<your company domain>.com`. You do not want to create multiple configuration items, one for
each and every MongoDB service in your company. To configure access to all the external services from the same domain by
a single configuration, you use *wildcarded* hosts.

In this section you configure egress traffic for a wildcarded domain. I used a MongoDB instance at `composedb.com`
domain, so configuring egress traffic for `*.com` worked for me (I could have used `*.composedb.com` as well).
You can pick a wildcarded domain according to your MongoDB host.

To configure egress gateway traffic for a wildcarded domain, you will first need to deploy a custom egress
gateway with
[an additional SNI proxy](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains).
This is needed due to current limitations of Envoy, the proxy used by the standard Istio egress gateway.

#### Prepare a new egress gateway with an SNI proxy

In this subsection you deploy an egress gateway with an SNI proxy, in addition to the standard Istio Envoy proxy. You
can use any SNI proxy that is capable of routing traffic according to arbitrary, not-preconfigured SNI values; we used
[Nginx](http://nginx.org) to achieve this functionality.

1.  Create a configuration file for the Nginx SNI proxy. You may want to edit the file to specify additional Nginx
    settings, if required.

    {{< text bash >}}
    $ cat <<EOF > ./sni-proxy.conf
    user www-data;

    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # tcp forward proxy by SNI
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:$MONGODB_PORT;
        proxy_pass   \$ssl_preread_server_name:$MONGODB_PORT;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1.  Create a Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to hold the configuration of the Nginx SNI proxy:

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1.  The following command will generate `istio-egressgateway-with-sni-proxy.yaml` to edit and deploy.

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/role.yaml -x charts/gateways/templates/rolebindings.yaml --set global.mtls.enabled=true --set global.istioNamespace=istio-system -f - > ./istio-egressgateway-with-sni-proxy.yaml
    gateways:
      enabled: true
      istio-ingressgateway:
        enabled: false
      istio-egressgateway:
        enabled: false
      istio-egressgateway-with-sni-proxy:
        enabled: true
        labels:
          app: istio-egressgateway-with-sni-proxy
          istio: egressgateway-with-sni-proxy
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        cpu:
          targetAverageUtilization: 80
        serviceAnnotations: {}
        type: ClusterIP
        ports:
          - port: 443
            name: https
        secretVolumes:
          - name: egressgateway-certs
            secretName: istio-egressgateway-certs
            mountPath: /etc/istio/egressgateway-certs
          - name: egressgateway-ca-certs
            secretName: istio-egressgateway-ca-certs
            mountPath: /etc/istio/egressgateway-ca-certs
        configVolumes:
          - name: sni-proxy-config
            configMapName: egress-sni-proxy-configmap
        additionalContainers:
        - name: sni-proxy
          image: nginx
          volumeMounts:
          - name: sni-proxy-config
            mountPath: /etc/nginx
            readOnly: true
    EOF
    {{< /text >}}

1.  Deploy the new egress gateway:

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway-with-sni-proxy.yaml
    serviceaccount "istio-egressgateway-with-sni-proxy-service-account" created
    role "istio-egressgateway-with-sni-proxy-istio-system" created
    rolebinding "istio-egressgateway-with-sni-proxy-istio-system" created
    service "istio-egressgateway-with-sni-proxy" created
    deployment "istio-egressgateway-with-sni-proxy" created
    horizontalpodautoscaler "istio-egressgateway-with-sni-proxy" created
    {{< /text >}}

1.  Verify that the new egress gateway is running. Note that the pod has two containers (one is the Envoy proxy and the
    second one is the SNI proxy).

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1.  Create a service entry with a static address equal to 127.0.0.1 (`localhost`), and disable mutual TLS on the traffic directed to the new
    service entry:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: sni-proxy
    spec:
      hosts:
      - sni-proxy.local
      location: MESH_EXTERNAL
      ports:
      - number: $MONGODB_PORT
        name: tcp
        protocol: TCP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: disable-mtls-for-sni-proxy
    spec:
      host: sni-proxy.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

#### Configure access to `*.com` using the new egress gateway

1.  Define a `ServiceEntry` for `*.com`:

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: mongo
    spec:
      hosts:
      - "*.com"
      ports:
      - number: 443
        name: tls
        protocol: TLS
      - number: $MONGODB_PORT
        name: tls-mongodb
        protocol: TLS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Create an egress `Gateway` for _*.com_, port 443, protocol TLS, a destination rule to set the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) for the gateway, and Envoy filters to prevent tampering
    with SNI by a malicious application (the filters verify that the SNI issued by the application is the SNI reported
    to Mixer).

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway-with-sni-proxy
    spec:
      selector:
        istio: egressgateway-with-sni-proxy
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - "*.com"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: mtls-for-egress-gateway
    spec:
      host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
      subsets:
        - name: mongo
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: ISTIO_MUTUAL
    ---
    # The following filter is used to forward the original SNI (sent by the application) as the SNI of the mutual TLS
    # connection.
    # The forwarded SNI will be reported to Mixer so that policies will be enforced based on the original SNI value.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: forward-downstream-sni
    spec:
      filters:
      - listenerMatch:
          portNumber: $MONGODB_PORT
          listenerType: SIDECAR_OUTBOUND
        filterName: forward_downstream_sni
        filterType: NETWORK
        filterConfig: {}
    ---
    # The following filter verifies that the SNI of the mutual TLS connection (the SNI reported to Mixer) is
    # identical to the original SNI issued by the application (the SNI used for routing by the SNI proxy).
    # The filter prevents Mixer from being deceived by a malicious application: routing to one SNI while
    # reporting some other value of SNI. If the original SNI does not match the SNI of the mutual TLS connection, the
    # filter will block the connection to the external service.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: egress-gateway-sni-verifier
    spec:
      workloadLabels:
        app: istio-egressgateway-with-sni-proxy
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: GATEWAY
        filterName: sni_verifier
        filterType: NETWORK
        filterConfig: {}
    EOF
    {{< /text >}}

1.  Route the traffic destined for _*.com_ to the egress gateway and from the egress gateway to the SNI proxy.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-mongo-through-egress-gateway
    spec:
      hosts:
      - "*.com"
      gateways:
      - mesh
      - istio-egressgateway-with-sni-proxy
      tls:
      - match:
        - gateways:
          - mesh
          port: $MONGODB_PORT
          sni_hosts:
          - "*.com"
        route:
        - destination:
            host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
            subset: mongo
            port:
              number: 443
          weight: 100
      tcp:
      - match:
        - gateways:
          - istio-egressgateway-with-sni-proxy
          port: 443
        route:
        - destination:
            host: sni-proxy.local
            port:
              number: $MONGODB_PORT
          weight: 100
    EOF
    {{< /text >}}

1.  Refresh the web page of the application again and verify that the ratings are still displayed correctly.

1.  [Enable Envoy’s access logging](/docs/tasks/telemetry/logs/access-log/#enable-envoy-s-access-logging)

1.  Check the log of the egress gateway's Envoy proxy. If Istio is deployed in the `istio-system` namespace, the command
    to print the log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
    {{< /text >}}

    You should see lines similar to the following:

    {{< text plain >}}
    [2019-01-02T17:22:04.602Z] "- - -" 0 - 768 1863 88 - "-" "-" "-" "-" "127.0.0.1:28543" outbound|28543||sni-proxy.local 127.0.0.1:49976 172.30.146.115:443 172.30.146.118:58510 <your MongoDB host>
    [2019-01-02T17:22:04.713Z] "- - -" 0 - 1534 2590 85 - "-" "-" "-" "-" "127.0.0.1:28543" outbound|28543||sni-proxy.local 127.0.0.1:49988 172.30.146.115:443 172.30.146.118:58522 <your MongoDB host>
    {{< /text >}}

1.  Check the logs of the SNI proxy. If Istio is deployed in the `istio-system` namespace, the command to print the
    log is:

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [23/Aug/2018:03:28:18 +0000] TCP [<your MongoDB host>]200 1863 482 0.089
    127.0.0.1 [23/Aug/2018:03:28:18 +0000] TCP [<your MongoDB host>]200 2590 1248 0.095
    {{< /text >}}

#### Understanding what happened

In this section you configured egress traffic to your MongoDB host using a wildcarded domain. While for a single MongoDB
host there is no gain in using wildcarded domains (an exact hostname can be specified), it could be beneficial for
cases when the applications in the cluster access multiple MongoDB hosts that match some wildcarded domain. For example,
if the applications access `mongodb1.composedb.com`, `mongodb2.composedb.com` and `mongodb3.composedb.com`, the egress
traffic can be configured by a single configuration for the wildcarded domain `*.composedb.com`.

I will leave it as an exercise for the reader to verify that no additional Istio configuration is required when you
configure an app to use another instance of MongoDB with a hostname that matches the wildcarded domain used in this
section.

#### Cleanup of configuration for MongoDB TLS egress traffic to arbitrary wildcarded domains

1.  Delete the configuration items for _*.com_:

    {{< text bash >}}
    $ kubectl delete serviceentry mongo
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-mongo-through-egress-gateway
    $ kubectl delete destinationrule mtls-for-egress-gateway
    $ kubectl delete envoyfilter forward-downstream-sni egress-gateway-sni-verifier
    {{< /text >}}

1.  Delete the configuration items for the `egressgateway-with-sni-proxy` `Deployment`:

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f ./istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1.  Remove the configuration files you created:

    {{< text bash >}}
    $ rm ./istio-egressgateway-with-sni-proxy.yaml
    $ rm ./nginx-sni-proxy.conf
    {{< /text >}}

## Cleanup

1.  Drop the `bookinfo` user:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.dropUser("bookinfo");
    EOF
    {{< /text >}}

1. Drop the _ratings_ collection:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.ratings.drop();
    EOF
    {{< /text >}}

1.  Unset the environment variables you used:

    {{< text bash >}}
    $ unset MONGO_ADMIN_PASSWORD BOOKINFO_PASSWORD MONGODB_HOST MONGODB_PORT MONGODB_IP
    {{< /text >}}

1.  Remove the virtual services:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    Deleted config: virtual-service/default/reviews
    Deleted config: virtual-service/default/ratings
    {{< /text >}}

1.  Undeploy _ratings v2-mongodb_:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    deployment "ratings-v2" deleted
    {{< /text >}}

## Conclusion

In this blog post I demonstrated various options for MongoDB egress traffic control. You can control the MongoDB egress
traffic on a TCP or TLS level where applicable. In both TCP and TLS cases, you can direct the traffic from the sidecar
proxies directly to the external MongoDB host, or direct the traffic through an egress gateway, according to your
organization's security requirements. In the latter case, you can also decide to apply or disable mutual TLS
authentication between the sidecar proxies and the egress gateway. If you want to control MongoDB egress traffic on the
TLS level by specifying wildcarded domains like `*.com` and you need to direct the traffic through the egress gateway,
you must deploy a custom egress gateway with an SNI proxy.

Note that the configuration and considerations described in this blog post for MongoDB are rather the same for other
non-HTTP protocols on top of TCP/TLS.
