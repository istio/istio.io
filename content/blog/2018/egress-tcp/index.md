---
title: Consuming External TCP Services
description: Describes a simple scenario based on Istio Bookinfo sample
publishdate: 2018-02-06
subtitle: Egress rules for TCP traffic
attribution: Vadim Eisenberg
weight: 92
aliases:
  - /docs/tasks/traffic-management/egress-tcp/
keywords: [traffic-management,egress,tcp]
---

In my previous blog post, [Consuming External Web Services](/blog/2018/egress-https/), I described how external services can be consumed by in-mesh Istio applications via HTTPS. In this post, I demonstrate consuming external services over TCP. I use the [Istio Bookinfo sample application](/docs/examples/bookinfo/), the version in which the book ratings data is persisted in a MySQL database. I deploy this database outside the cluster and configure the _ratings_ microservice to use it. I define an [egress rule](/docs/reference/config/istio.routing.v1alpha1/#EgressRule) to allow the in-mesh applications to access the external database.

## Bookinfo sample application with external ratings database

First, I set up a MySQL database instance to hold book ratings data, outside my Kubernetes cluster. Then I modify the [Bookinfo sample application](/docs/examples/bookinfo/) to use my database.

### Setting up the database for ratings data

For this task I set up an instance of [MySQL](https://www.mysql.com). You can use any MySQL instance; I use [Compose for MySQL](https://www.ibm.com/cloud/compose/mysql).
I use `mysqlsh` ([MySQL Shell](https://dev.mysql.com/doc/refman/5.7/en/mysql-shell-userguide.html)) as a MySQL client to feed the ratings data.

1.  To initialize the database, I run the following command entering the password when prompted. The command is performed with the credentials of the  `admin` user, created by default by [Compose for MySQL](https://www.ibm.com/cloud/compose/mysql).

    ```command
    $ curl -s https://raw.githubusercontent.com/istio/istio/{{<branch_name>}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>
    ```

    _**OR**_

    When using the `mysql` client and a local MySQL database, I would run:

    ```command
    $ curl -s https://raw.githubusercontent.com/istio/istio/{{<branch_name>}}/samples/bookinfo/src/mysql/mysqldb-init.sql | \
    mysql -u root -p
    ```

1.  I then create a user with the name _bookinfo_ and grant it _SELECT_ privilege on the `test.ratings` table:

    ```command
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>  \
    -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    ```

    _**OR**_

    For `mysql` and the local database, the command would be:

    ```command
    $ mysql -u root -p -e \
    "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
    ```

    Here I apply the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege). This means that I do not use my _admin_ user in the Bookinfo application. Instead, I create a special user for the Bookinfo application , _bookinfo_, with minimal privileges. In this case, the _bookinfo_ user only has the `SELECT` privilege on a single table.

    After running the command to create the user, I will clean my bash history by checking the number of the last command and running `history -d <the number of the command that created the user>`. I don't want the password of the new user to be stored in the bash history. If I'm using `mysql`, I'll remove the last command from `~/.mysql_history` file as well. Read more about password protection of the newly created user in [MySQL documentation](https://dev.mysql.com/doc/refman/5.5/en/create-user.html).

1.  I inspect the created ratings to see that everything worked as expected:

    ```command
    $ mysqlsh --sql --ssl-mode=REQUIRED -u bookinfo -p --host <the database host> --port <the database port> \
    -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    ```

    _**OR**_

    For `mysql` and the local database:

    ```command
    $ mysql -u bookinfo -p -e "select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      5 |
    |        2 |      4 |
    +----------+--------+
    ```

1.  I set the ratings temporarily to 1 to provide a visual clue when our database is used by the Bookinfo _ratings_ service:

    ```command
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port>  \
    -e "update test.ratings set rating=1; select * from test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    ```

    _**OR**_

    For `mysql` and the local database:

    ```command
    $ mysql -u root -p -e "update test.ratings set rating=1; select * from  test.ratings;"
    Enter password:
    +----------+--------+
    | ReviewID | Rating |
    +----------+--------+
    |        1 |      1 |
    |        2 |      1 |
    +----------+--------+
    ```

    I used the _admin_ user (and _root_ for the local database) in the last command since the _bookinfo_ user does not have the _UPDATE_ privilege on the `test.ratings` table.

Now I am ready to deploy a version of the Bookinfo application that will use my database.

### Initial setting of Bookinfo application

To demonstrate the scenario of using an external database, I start with a Kubernetes cluster with [Istio installed](/docs/setup/kubernetes/quick-start/#installation-steps). Then I deploy the [Istio Bookinfo sample application](/docs/examples/bookinfo/). This application uses the _ratings_ microservice to fetch book ratings, a number between 1 and 5. The ratings are displayed as stars for each review. There are several versions of the _ratings_ microservice. Some use [MongoDB](https://www.mongodb.com), others use [MySQL](https://www.mysql.com) as their database.

The example commands in this blog post work with Istio 0.3+, with or without [Mutual TLS](/docs/concepts/security/mutual-tls/) enabled.

As a reminder, here is the end-to-end architecture of the application from the [Bookinfo sample application](/docs/examples/bookinfo/).

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The original Bookinfo application"
    >}}

### Use the database for ratings data in Bookinfo application

1.  I modify the deployment spec of a version of the _ratings_ microservice that uses a MySQL database, to use my database instance. The spec is in `samples/bookinfo/kube/bookinfo-ratings-v2-mysql.yaml` of an Istio release archive. I edit the following lines:

    ```yaml
        - name: MYSQL_DB_HOST
          value: mysqldb
        - name: MYSQL_DB_PORT
          value: "3306"
        - name: MYSQL_DB_USER
          value: root
        - name: MYSQL_DB_PASSWORD
          value: password
    ```

    I replace the values in the snippet above, specifying the database host, port, user, and password. Note that the correct way to work with passwords in container's environment variables in Kubernetes is [to use secrets](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables). For this example task only, I write the password directly in the deployment spec. **Do not do it** in a real environment! I also assume everyone realizes that `"password"` should not be used as a password...

1.  I apply the modified spec to deploy the version of the _ratings_ microservice, _v2-mysql_, that will use my database.

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" created
    ```

1.  I route all the traffic destined to the _reviews_ service to its _v3_ version. I do this to ensure that the _reviews_ service always calls the _ratings_
service. In addition, I route all the traffic destined to the _ratings_ service to _ratings v2-mysql_ that uses my database. I add routing for both services above by adding two [route rules](/docs/reference/config/istio.routing.v1alpha1/). These rules are specified in `samples/bookinfo/kube/route-rule-ratings-mysql.yaml` of an Istio release archive.

    ```command
    $ istioctl create -f @samples/bookinfo/kube/route-rule-ratings-mysql.yaml@
    Created config route-rule/default/ratings-test-v2-mysql at revision 1918799
    Created config route-rule/default/reviews-test-ratings-v2 at revision 1918800
    ```

The updated architecture appears below. Note that the blue arrows inside the mesh mark the traffic configured according to the route rules we added. According to the route rules, the traffic is sent to _reviews v3_ and _ratings v2-mysql_.

{{< image width="80%" ratio="59.31%"
    link="./bookinfo-ratings-v2-mysql-external.svg"
    caption="The Bookinfo application with ratings v2-mysql and an external MySQL database"
    >}}

Note that the MySQL database is outside the Istio service mesh, or more precisely outside the Kubernetes cluster. The boundary of the service mesh is marked by a dashed line.

### Access the webpage

Let's access the webpage of the application, after [determining the ingress IP and port](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port).

We have a problem... Instead of the rating stars, the message _"Ratings service is currently unavailable"_ is currently displayed below each review:

{{< image width="80%" ratio="36.19%"
    link="./errorFetchingBookRating.png"
    caption="The Ratings service error messages"
    >}}

As in [Consuming External Web Services](/blog/2018/egress-https/), we experience **graceful service degradation**, which is good. The application did not crash due to the error in the _ratings_ microservice. The webpage of the application correctly displayed the book information, the details, and the reviews, just without the rating stars.

We have the same problem as in [Consuming External Web Services](/blog/2018/egress-https/), namely all the traffic outside the Kubernetes cluster, both TCP and HTTP, is blocked by default by the sidecar proxies. To enable such traffic for TCP, an egress rule for TCP must be defined.

### Egress rule for an external MySQL instance

TCP egress rules come to our rescue. I copy the following YAML spec to a text file (let's call it `egress-rule-mysql.yaml`) and edit it to specify the IP of my database instance and its port.

```yaml
apiVersion: config.istio.io/v1alpha2
kind: EgressRule
metadata:
  name: mysql
  namespace: default
spec:
  destination:
      service: <MySQL instance IP>
  ports:
      - port: <MySQL instance port>
        protocol: tcp
```

Then I run `istioctl` to add the egress rule to the service mesh:

```command
$ istioctl create -f egress-rule-mysql.yaml
Created config egress-rule/default/mysql at revision 1954425
```
Note that for a TCP egress rule, we specify `tcp` as the protocol of a port of the rule. Also note that we use an IP of the external service instead of its domain name. I will talk more about TCP egress rules [below](#egress-rules-for-tcp-traffic). For now, let's verify that the egress rule we added fixed the problem. Let's access the webpage and see if the stars are back.

It worked! Accessing the web page of the application displays the ratings without error:

{{< image width="80%" ratio="36.69%"
    link="./externalMySQLRatings.png"
    caption="Book Ratings Displayed Correctly"
    >}}

Note that we see a one-star rating for both displayed reviews, as expected. I changed the ratings to be one star to provide us with a visual clue that our external database is indeed being used.

As with egress rules for HTTP/HTTPS, we can delete and create egress rules for TCP using `istioctl`, dynamically.

## Motivation for egress TCP traffic control

Some in-mesh Istio applications must access external services, for example legacy systems. In many cases, the access is not performed over HTTP or HTTPS protocols. Other TCP protocols are used, such as database-specific protocols like [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/) and [MySQL Client/Server Protocol](https://dev.mysql.com/doc/internals/en/client-server-protocol.html) to communicate with external databases.

Note that in case of access to external HTTPS services, as described in the [Control Egress TCP Traffic](/docs/tasks/traffic-management/egress/) task, an application must issue HTTP requests to the external service. The Envoy sidecar proxy attached to the pod or the VM, will intercept the requests and open an HTTPS connection to the external service. The traffic will be unencrypted inside the pod or the VM, but it will leave the pod or the VM encrypted.

However, sometimes this approach cannot work due to the following reasons:

* The code of the application is configured to use an HTTPS URL and cannot be changed

* The code of the application uses some library to access the external service and that library uses HTTPS only

* There are compliance requirements that do not allow unencrypted traffic, even if the traffic is unencrypted only inside the pod or the VM

In this case, HTTPS can be treated by Istio as _opaque TCP_ and can be handled in the same way as other TCP non-HTTP protocols.

Next let's see how we define egress rules for TCP traffic.

## Egress rules for TCP traffic

The egress rules for enabling TCP traffic to a specific port must specify `TCP` as the protocol of the port. Additionally, for the [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/), the protocol can be specified as `MONGO`, instead of `TCP`.

For the `destination.service` field of the rule, an IP or a block of IPs in [CIDR](https://tools.ietf.org/html/rfc2317) notation must be used.

To enable TCP traffic to an external service by its hostname, all the IPs of the hostname must be specified. Each IP must be specified by a CIDR block or as a single IP, with each block or IP in a separate egress rule.

Note that all the IPs of an external service are not always known. To enable TCP traffic by IPs, as opposed to the traffic by a hostname, only the IPs that are used by the applications must be specified.

Also note that the IPs of an external service are not always static, for example in the case of [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network). Sometimes the IPs are static most of the time, but can be changed from time to time, for example due to infrastructure changes. In these cases, if the range of the possible IPs is known, you should specify the range by CIDR blocks (even by multiple egress rules if needed). If the range of the possible IPs is not known, egress rules for TCP cannot be used and [the external services must be called directly](/docs/tasks/traffic-management/egress/#calling-external-services-directly), circumventing the sidecar proxies.

## Relation to mesh expansion

Note that the scenario described in this post is different from the mesh expansion scenario, described in the
[Integrating Virtual Machines](/docs/examples/integrating-vms/) example. In that scenario, a MySQL instance runs on an external
(outside the cluster) machine (a bare metal or a VM), integrated with the Istio service mesh. The MySQL service becomes a first-class citizen of the mesh with all the beneficial features of Istio applicable. Among other things, the service becomes addressable by a local cluster domain name, for example by `mysqldb.vm.svc.cluster.local`, and the communication to it can be secured by
[mutual TLS authentication](/docs/concepts/security/mutual-tls/). There is no need to create an egress rule to access this service; however, the
service must be registered with Istio. To enable such integration, Istio components (_Envoy proxy_, _node-agent_, _istio-agent_) must be
installed on the machine and the Istio control plane (_Pilot_, _Mixer_, _CA_) must be accessible from it. See the
[Istio Mesh Expansion](/docs/setup/kubernetes/mesh-expansion/) instructions for more details.

In our case, the MySQL instance can run on any machine or can be provisioned as a service by a cloud provider. There is no requirement to integrate the machine
with Istio. The Istio control plane does not have to be accessible from the machine. In the case of MySQL as a service, the machine which MySQL runs on may be not accessible and installing on it the required components may be impossible. In our case, the MySQL instance is addressable by its global domain name, which could be beneficial if the consuming applications expect to use that domain name. This is especially relevant when that expected domain name cannot be changed in the deployment configuration of the consuming applications.

## Cleanup

1.  Drop the _test_ database and the _bookinfo_ user:

    ```command
    $ mysqlsh --sql --ssl-mode=REQUIRED -u admin -p --host <the database host> --port <the database port> \
    -e "drop database test; drop user bookinfo;"
    ```

    _**OR**_

    For `mysql` and the local database:

    ```command
    $ mysql -u root -p -e "drop database test; drop user bookinfo;"
    ```

1.  Remove the route rules:

    ```command
    $ istioctl delete -f @samples/bookinfo/kube/route-rule-ratings-mysql.yaml@
    Deleted config: route-rule/default/ratings-test-v2-mysql
    Deleted config: route-rule/default/reviews-test-ratings-v2
    ```

1.  Undeploy _ratings v2-mysql_:

    ```command
    $ kubectl delete -f <(istioctl kube-inject -f @samples/bookinfo/kube/bookinfo-ratings-v2-mysql.yaml@)
    deployment "ratings-v2-mysql" deleted
    ```

1.  Delete the egress rule:

    ```command
    $ istioctl delete egressrule mysql -n default
    Deleted config: egressrule mysql
    ```

## Future work

In my next blog posts, I will show examples of combining route rules and egress rules, and also examples of accessing external services via Kubernetes _ExternalName_ services.

## Conclusion

In this blog post, I demonstrated how the microservices in an Istio service mesh can consume external services via TCP. By default, Istio blocks all the traffic, TCP and HTTP, to the hosts outside the cluster. To enable such traffic for TCP, TCP egress rules must be created for the service mesh.

## What's next

To read more about Istio egress traffic control, see [Control Egress Traffic Task](/docs/tasks/traffic-management/egress/).
