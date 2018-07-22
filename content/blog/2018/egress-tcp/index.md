---
title: Consuming External TCP Services
description: Describes a simple scenario based on Istio Bookinfo sample
publishdate: 2018-02-06
subtitle: Mesh-external Service Entries for TCP traffic
attribution: Vadim Eisenberg
weight: 92
aliases:
  - /docs/tasks/traffic-management/egress-tcp/
keywords: [traffic-management,egress,tcp]
---

> Note: This blog post was updated on July 19, 2018 to use the new
[v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in
the next Istio release. If you need to use the old version, follow the docs
[here](https://archive.istio.io/v0.7/blog/2018/egress-tcp.html).

In my previous blog post, [Consuming External Web Services](/blog/2018/egress-https/), I described how external services
 can be consumed by in-mesh Istio applications via HTTPS. In this post, I demonstrate you consuming external services
 over TCP. You will use the [Istio Bookinfo sample application](/docs/examples/bookinfo/), the version in which the book
  ratings data is persisted in a MySQL database. You deploy this database outside the cluster and configure the
  _ratings_ microservice to use it. You define a
 [Service Entry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) to allow the in-mesh applications to
 access the external database.

## Bookinfo sample application with external ratings database

First, you set up a MySQL database instance to hold book ratings data, outside of your Kubernetes cluster. Then you
modify the [Bookinfo sample application](/docs/examples/bookinfo/) to use your database.

### Setting up the database for ratings data

For this task you set up an instance of [MySQL](https://www.mysql.com). You can use any MySQL instance; I used
[Compose for MySQL](https://www.ibm.com/cloud/compose/mysql). I used `mysqlsh`
([MySQL Shell](https://dev.mysql.com/doc/mysql-shell/en/)) as a MySQL client to feed the ratings data.

1.  To initialize the database, run the following command entering the password when prompted. The command is
performed with the credentials of the  `admin` user, created by default by
[Compose for MySQL](https://www.ibm.com/cloud/compose/mysql).

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>
    {{< /text >}}

    _**OR**_

    When using the `mysql` client and a local MySQL database, run:

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -p
    {{< /text >}}

1.  Create a user with the name _bookinfo_ and grant it _SELECT_ privilege on the `test.ratings` table:

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    _**OR**_

    For `mysql` and the local database, the command is:

    {{< text bash >}}
    $ mysql -u root -p -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    {{< /text >}}

    Here you apply the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege). This
    means that you do not use your _admin_ user in the Bookinfo application. Instead, you create a special user for the
    Bookinfo application , _bookinfo_, with minimal privileges. In this case, the _bookinfo_ user only has the `SELECT`
    privilege on a single table.

    After running the command to create the user, you may want to clean your bash history by checking the number of the last
    command and running `history -d <the number of the command that created the user>`. You don't want the password of the
     new user to be stored in the bash history. If you're using `mysql`, remove the last command from
     `~/.mysql_history` file as well. Read more about password protection of the newly created user in [MySQL documentation](https://dev.mysql.com/doc/refman/5.5/en/create-user.html).

1.  Inspect the created ratings to see that everything worked as expected:

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u bookinfo -p --host <the database host> --port <the database port> -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

    _**OR**_

    For `mysql` and the local database:

    {{< text bash >}}
    $ mysql -u bookinfo -p -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    {{< /text >}}

1.  Set the ratings temporarily to 1 to provide a visual clue when our database is used by the Bookinfo _ratings_
service:

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    _**OR**_

    For `mysql` and the local database:

    {{< text bash >}}
    $ mysql -u root -p -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    {{< /text >}}

    You used the _admin_ user (and _root_ for the local database) in the last command since the _bookinfo_ user does not
    have the _UPDATE_ privilege on the `test.ratings` table.

Now you are ready to deploy a version of the Bookinfo application that will use your database.

### Initial setting of Bookinfo application

To demonstrate the scenario of using an external database, you start with a Kubernetes cluster with [Istio installed](/docs/setup/kubernetes/quick-start/#installation-steps). Then you deploy the
[Istio Bookinfo sample application](/docs/examples/bookinfo/). This application uses the _ratings_ microservice to fetch
 book ratings, a number between 1 and 5. The ratings are displayed as stars for each review. There are several versions
 of the _ratings_ microservice. Some use [MongoDB](https://www.mongodb.com), others use [MySQL](https://www.mysql.com)
 as their database.

The example commands in this blog post work with Istio 0.8+, with or without
[mutual TLS](/docs/concepts/security/#mutual-tls-authentication) enabled.

As a reminder, here is the end-to-end architecture of the application from the
[Bookinfo sample application](/docs/examples/bookinfo/).

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The original Bookinfo application"
    >}}

### Use the database for ratings data in Bookinfo application

1.  Modify the deployment spec of a version of the _ratings_ microservice that uses a MySQL database, to use your
database instance. The spec is in [samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml](https://github.com/istio/istio/blob/release-1.0/samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml)
of an Istio releasearchive. Edit the following lines:

    {{< text yaml >}}
    - name: MYSQL_DB_HOST
      value: mysqldb
    - name: MYSQL_DB_PORT
      value: "3306"
    - name: MYSQL_DB_USER
      value: root
    - name: MYSQL_DB_PASSWORD
      value: password
    {{< /text >}}

    Replace the values in the snippet above, specifying the database host, port, user, and password. Note that the
    correct way to work with passwords in container's environment variables in Kubernetes is [to use secrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables). For this
     example task only, you may want to write the password directly in the deployment spec.  **Do not do it** in a real
     environment! I also assume everyone realizes that `"password"` should not be used as a password...

1.  Apply the modified spec to deploy the version of the _ratings_ microservice, _v2-mysql_, that will use your
    database.

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" created
    {{< /text >}}

1.  Route all the traffic destined to the _reviews_ service to its _v3_ version. You do this to ensure that the
_reviews_ service always calls the _ratings_ service. In addition, route all the traffic destined to the _ratings_
service to _ratings v2-mysql_ that uses your database.

Specify the routing for both services above by adding two
[virtual services](/docs/reference/config/istio.networking.v1alpha3/#VirtualService).
These virtual services are specified in `samples/bookinfo/networking/virtual-service-ratings-mysql.yaml` of an Istio
release archive.

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    Created config route-rule/default/ratings-test-v2-mysql at revision 1918799
    Created config route-rule/default/reviews-test-ratings-v2 at revision 1918800
    {{< /text >}}

The updated architecture appears below. Note that the blue arrows inside the mesh mark the traffic configured according
 to the virtual services we added. According to the virtual services, the traffic is sent to _reviews v3_ and
 _ratings v2-mysql_.

{{< image width="80%" ratio="59.31%"
    link="./bookinfo-ratings-v2-mysql-external.svg"
    caption="The Bookinfo application with ratings v2-mysql and an external MySQL database"
    >}}

Note that the MySQL database is outside the Istio service mesh, or more precisely outside the Kubernetes cluster. The
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

### Mesh-external service entry for an external MySQL instance

TCP mesh-external service entries come to our rescue. Copy the following YAML spec to a text file (let's call it
`service-entry-mysql.yaml`) and edit it to specify the IP of your database instance and its port.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: mysql-external
spec:
  hosts:
  - <MySQL instance hostname> # is ignored for mesh-external TCP traffic
  addresses:
  - <MySQL instance IP>
  ports:
  - name: tcp
    number: <MySQL instance port>
    protocol: tcp
  location: MESH_EXTERNAL
{{< /text >}}

Run `istioctl` to add the service entry to the service mesh:

{{< text bash >}}
$ istioctl create -f egress-rule-mysql.yaml
Created config egress-rule/default/mysql at revision 1954425
{{< /text >}}

Note that for a TCP service entry, you specify `tcp` as the protocol of a port of the entry. Also note that you have to
specify the IP of the external service in the list of addresses. I will talk more about TCP service entries
[below](#service-entries-for-tcp-traffic). For now, verify that the service entry we added fixed the problem. Access the
webpage and see if the stars are back.

It worked! Accessing the web page of the application displays the ratings without error:

{{< image width="80%" ratio="36.69%"
    link="./externalMySQLRatings.png"
    caption="Book Ratings Displayed Correctly"
    >}}

Note that you see a one-star rating for both displayed reviews, as expected. You changed the ratings to be one star to
provide us with a visual clue that our external database is indeed being used.

As with service entries for HTTP/HTTPS, you can delete and create service entries for TCP using `istioctl`, dynamically.

## Motivation for egress TCP traffic control

Some in-mesh Istio applications must access external services, for example legacy systems. In many cases, the access is
not performed over HTTP or TLS protocols. Other TCP protocols are used, such as database-specific protocols like
[MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/) and [MySQL Client/Server Protocol](https://dev.mysql.com/doc/internals/en/client-server-protocol.html) to communicate with external databases.

Next let me provide more details about the service entries for TCP traffic.

## Service entries for TCP traffic

The service entries for enabling TCP traffic to a specific port must specify `TCP` as the protocol of the port.
Additionally, for the [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/), the
protocol can be specified as `MONGO`, instead of `TCP`.

For the `addresses` field of the entry, an IP or a block of IPs in [CIDR](https://tools.ietf.org/html/rfc2317)
notation must be used. Note that the `hosts` field is ignored for TCP service entries.

To enable TCP traffic to an external service by its hostname, all the IPs of the hostname must be specified. Each IP
must be specified by a CIDR block or as a single IP.

Note that all the IPs of an external service are not always known. To enable egress TCP traffic, only the IPs that are
used by the applications must be specified.

Also note that the IPs of an external service are not always static, for example in the case of
[CDNs](https://en.wikipedia.org/wiki/Content_delivery_network). Sometimes the IPs are static most of the time, but can
be changed from time to time, for example due to infrastructure changes. In these cases, if the range of the possible
IPs is known, you should specify the range by CIDR blocks. If the range of the possible IPs is not known, service
entries for TCP cannot be used and
[the external services must be called directly](/docs/tasks/traffic-management/egress/#calling-external-services-directly),
bypassing the sidecar proxies.

## Relation to mesh expansion

Note that the scenario described in this post is different from the mesh expansion scenario, described in the
[Integrating Virtual Machines](/docs/examples/integrating-vms/) example. In that scenario, a MySQL instance runs on an
external
(outside the cluster) machine (a bare metal or a VM), integrated with the Istio service mesh. The MySQL service becomes
a first-class citizen of the mesh with all the beneficial features of Istio applicable. Among other things, the service
becomes addressable by a local cluster domain name, for example by `mysqldb.vm.svc.cluster.local`, and the communication
 to it can be secured by
[mutual TLS authentication](/docs/concepts/security/#mutual-tls-authentication). There is no need to create an egress
rule to access this service; however, the service must be registered with Istio. To enable such integration, Istio
components (_Envoy proxy_, _node-agent_, _istio-agent_) must be installed on the machine and the Istio control plane
(_Pilot_, _Mixer_, _Citadel_) must be accessible from it. See the
[Istio Mesh Expansion](/docs/setup/kubernetes/mesh-expansion/) instructions for more details.

In our case, the MySQL instance can run on any machine or can be provisioned as a service by a cloud provider. There is
no requirement to integrate the machine with Istio. The Istio control plane does not have to be accessible from the
machine. In the case of MySQL as a service, the machine which MySQL runs on may be not accessible and installing on it
the required components may be impossible. In our case, the MySQL instance is addressable by its global domain name,
which could be beneficial if the consuming applications expect to use that domain name. This is especially relevant when
 that expected domain name cannot be changed in the deployment configuration of the consuming applications.

## Cleanup

1.  Drop the _test_ database and the _bookinfo_ user:

    {{< text bash >}}
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> \
    -e "drop database test; drop user bookinfo;"
    {{< /text >}}

    _**OR**_

    For `mysql` and the local database:

    {{< text bash >}}
    $ mysql -u root -p -e "drop database test; drop user bookinfo;"
    {{< /text >}}

1.  Remove the virtual services:

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-ratings-mysql.yaml@
    Deleted config: route-rule/default/ratings-test-v2-mysql
    Deleted config: route-rule/default/reviews-test-ratings-v2
    {{< /text >}}

1.  Undeploy _ratings v2-mysql_:

    {{< text bash >}}
    $ kubectl delete -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" deleted
    {{< /text >}}

1.  Delete the service entry:

    {{< text bash >}}
    $ istioctl delete serviceentry mysql-external -n default
    Deleted config: serviceentry mysql-external
    {{< /text >}}

## Future work

In my next blog posts, I will show examples of combining virtual services and mesh-external service entries, and also
examples of accessing external services via Kubernetes _ExternalName_ services.

## Conclusion

In this blog post, I demonstrated how the microservices in an Istio service mesh can consume external services via TCP.
By default, Istio blocks all the traffic, TCP and HTTP, to the hosts outside the cluster. To enable such traffic for
TCP, TCP mesh-external service entries must be created for the service mesh.
