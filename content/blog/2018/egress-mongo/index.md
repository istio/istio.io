---
title: Consuming External MongoDB Services
description: Describes a simple scenario based on Istio's Bookinfo example.
publishdate: 2018-15-08
subtitle: Istio Egress Control Options for MongoDB traffic
attribution: Vadim Eisenberg
weight: 82
keywords: [traffic-management,egress,tcp,mongo]
---

In the [Consuming External TCP Services](/blog/2018/egress-tcp/) blog post, I described how external services
can be consumed by in-mesh Istio applications via TCP. In this post, I demonstrate consuming external MongoDB services.
You use the [Istio Bookinfo sample application](/docs/examples/bookinfo/), the version in which the book
ratings data is persisted in a MongoDB database. You deploy this database outside the cluster and configure the
_ratings_ microservice to use it. You will learn multiple options of controlling external MongoDB services and their
pros and cons.

## Bookinfo sample application with external ratings database

First, you set up a MongoDB database instance to hold book ratings data outside of your Kubernetes cluster. Then you
modify the [Bookinfo sample application](/docs/examples/bookinfo/) to use your database.

### Setting up the database for ratings data

For this task you set up an instance of [MongoDB](https://www.mongodb.com). You can use any MongoDB instance; I used
[Compose for MongoDB](https://www.ibm.com/cloud/compose/mongodb).

1. Set an environment variable for the password of your `admin` user. To prevent the password being preserved in the Bash
   history, remove the command from the history immediately after
   running the command, using [history -d _offset_](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins).

    {{< text bash >}}
    $ export MONGO_ADMIN_PASSWORD=<your MongoDB admin password>
    {{< /text >}}

1.  Set an environment variable for the password of the new user, you will create, namely `bookinfo`.
    Remove the command from the history using
    [history -d _offset_](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Builtins.html#Bash-History-Builtins).

    {{< text bash >}}
    $ export BOOKINFO_PASSWORD=<password>
    {{< /text >}}

1.  Set environment variables for your MongoDB, `MONGODB_HOST` and `MONGODB_PORT`.

1. Create the `bookinfo` user:

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

### Initial setting of Bookinfo application

To demonstrate the scenario of using an external database, you start with a Kubernetes cluster with [Istio installed](/docs/setup/kubernetes/quick-start/#installation-steps). Then you deploy the
[Istio Bookinfo sample application](/docs/examples/bookinfo/) and [apply the default destination rules](/docs/examples/bookinfo/#apply-default-destination-rules).

This application uses the `ratings` microservice to fetch book ratings, a number between 1 and 5. The ratings are
displayed as stars for each review. There are several versions of the `ratings` microservice. You deploy the
version that uses [MongoDB](https://www.mongodb.com) as the ratings database.

The example commands in this blog post work with Istio 1.0, with
[mutual TLS](/docs/concepts/security/#mutual-tls-authentication) enabled.

As a reminder, here is the end-to-end architecture of the application from the
[Bookinfo sample application](/docs/examples/bookinfo/).

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The original Bookinfo application"
    >}}

### Use the database for ratings data in Bookinfo application

1.  Modify the deployment spec of a version of the _ratings_ microservice that uses a mongodb database, to use your
database instance. The spec is in [`samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml`]({{<github_blob>}}/samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml)
of an Istio release archive. Edit the following lines:

    {{< text yaml >}}
    - name: MONGO_DB_URL
      value: mongodb://mongodb:27017/test
    {{< /text >}}

    Replace the values in the snippet above, specifying the database host, port, user, and password. Note that the
    correct way to work with passwords in container's environment variables in Kubernetes is [to use secrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables). For this
     example task only, you may want to write the password directly in the deployment spec.  **Do not do it** in a real
     environment! I also assume everyone realizes that `"password"` should not be used as a password...

1.  Apply the modified spec to deploy the version of the _ratings_ microservice, _v2_, that will use your
    database.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    deployment "ratings-v2" created
    {{< /text >}}

1.  Route all the traffic destined to the _reviews_ service to its _v3_ version. You do this to ensure that the
_reviews_ service always calls the _ratings_ service. In addition, route all the traffic destined to the _ratings_
service to _ratings v2_ that uses your database.

    Specify the routing for both services above by adding two
    [virtual services](/docs/reference/config/istio.networking.v1alpha3/#VirtualService). These virtual services are
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

{{< image width="80%" ratio="59.31%"
    link="./bookinfo-ratings-v2-mysql-external.svg"
    caption="The Bookinfo application with ratings v2 and an external MongoDB database"
    >}}

Note that the mongodb database is outside the Istio service mesh, or more precisely outside the Kubernetes cluster. The
boundary of the service mesh is marked by a dashed line.

### Access the webpage

Access the webpage of the application, after
[determining the ingress IP and port](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port).

You have a problem... Instead of the rating stars, the message _"Ratings service is currently unavailable"_ is currently
 displayed below each review:

{{< image width="80%" ratio="36.19%"
    link="./errorFetchingBookRating.png"
    caption="The Ratings service error messages"
    >}}

As in [Consuming External Web Services](/blog/2018/egress-https/), you experience **graceful service degradation**,
which is good. The application did not crash due to the error in the _ratings_ microservice. The webpage of the
application correctly displayed the book information, the details, and the reviews, just without the rating stars.

You have the same problem as in [Consuming External Web Services](/blog/2018/egress-https/), namely all the traffic
outside the Kubernetes cluster, both TCP and HTTP, is blocked by default by the sidecar proxies. To enable such traffic
 for TCP, a mesh-external service entry for TCP must be defined.

### Mesh-external service entry for an external mongodb instance

TCP mesh-external service entries come to our rescue.

1.  Get the IP address of your mongodb database instance. As an option, you can use the
    [host](https://linux.die.net/man/1/host) command:

    {{< text bash >}}
    $ export mongodb_DB_IP=$(host $mongodb_DB_HOST | grep " has address " | cut -d" " -f4)
    {{< /text >}}

    For a local database, set `mongodb_DB_IP` to contain the IP of your machine, accessible from your cluster.

1.  Define a TCP mesh-external service entry:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3 $mongodb_DB_PORT
    kind: ServiceEntry
    metadata:
      name: mongodb-external
    spec:
      hosts:
      - $mongodb_DB_HOST
      addresses:
      - $mongodb_DB_IP/32
      ports:
      - name: tcp
        number: $mongodb_DB_PORT
        protocol: tcp
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Review the service entry you just created and check that it contains the correct values:

    {{< text bash >}}
    $ kubectl get serviceentry mongodb-external -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
    ...
    {{< /text >}}

Note that for a TCP service entry, you specify `tcp` as the protocol of a port of the entry. Also note that you have to
specify the IP of the external service in the list of addresses, as a [CIDR](https://tools.ietf.org/html/rfc2317) block
with suffix `32`.

I will talk more about TCP service entries
[below](#service-entries-for-tcp-traffic). For now, verify that the service entry we added fixed the problem. Access the
webpage and see if the stars are back.

It worked! Accessing the web page of the application displays the ratings without error:

{{< image width="80%" ratio="36.69%"
    link="./externalMySQLRatings.png"
    caption="Book Ratings Displayed Correctly"
    >}}

Note that you see a one-star rating for both displayed reviews, as expected. You changed the ratings to be one star to
provide us with a visual clue that our external database is indeed being used.

As with service entries for HTTP/HTTPS, you can delete and create service entries for TCP using `kubectl`, dynamically.

## Cleanup

1.  Drop the `bookinfo` user:

    {{< text bash >}}
    $ cat <<EOF | mongo --ssl --sslAllowInvalidCertificates $MONGODB_HOST:$MONGODB_PORT -u admin -p $MONGO_ADMIN_PASSWORD --authenticationDatabase admin
    use test
    db.dropUser("bookinfo");
    EOF
    {{< /text >}}

1.  Unset the environment variables you used:

    {{< text bash >}}
    $ unset MONGO_ADMIN_PASSWORD BOOKINFO_PASSWORD
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

1.  Delete the service entry:

    {{< text bash >}}
    $ kubectl delete serviceentry mongodb-external -n default
    Deleted config: serviceentry mongodb-external
    {{< /text >}}

## Conclusion
