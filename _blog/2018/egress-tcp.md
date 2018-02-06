---
title: "Consuming External TCP Services"
overview: Describes a simple scenario based on Istio Bookinfo sample
publish_date: February 6, 2018
subtitle: Egress rules for TCP traffic
attribution: Vadim Eisenberg

order: 92

layout: blog
type: markdown
redirect_from: "/blog/egress-tcp.html"
---
{% include home.html %}

In my previous blog post, [Consuming External Web Services]({{home}}/blog/2018/egress-https.html), I described how external services can be consumed by in-mesh Istio applications via HTTPS. In this post, I will demonstrate how in-mesh Istio applications can consume external applications over TCP. I will use the [Istio Bookinfo Sample Application]({{home}}/docs/guides/bookinfo.html), the version in which the ratings data is persisted in a MySQL database. I will deploy this database outside of the cluster and will configure the _ratings_ microservice to use it. I will define an [egress rule]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#EgressRule) to allow the in-mesh applications access the external database.

First, I will provide the motivation for egress rules for TCP traffic.

## Motivation
Some in-mesh Istio applications must access external services, for example legacy systems. In many cases, the access is not performed over HTTP or HTTPS protocols. Other TCP protocols are used, for example database specific protocols like [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/) to communicate with external databases.

Note that in case of access to external HTTPS services, as described in the [control egress TCP traffic]({{home}}/docs/tasks/traffic-management/egress.html) task, an application must issue HTTP requests to the external service. The Envoy sidecar proxy attached to the pod or the VM, will intercept the requests and will open an HTTPS connection to the external service. The traffic will be unencrypted inside the pod or the VM, but it will leave the pod or the VM encrypted.

However, sometimes this approach cannot work due to the following reasons:
* The code of the application is configured to use an HTTPS URL and cannot be changed
* The code of the application uses some library to access the external service and that library uses HTTPS only
* There are compliance requirements that do not allow unencrypted traffic, even if the traffic is unencrypted only inside the pod or the VM

In this case, HTTPS can be treated by Istio as _opaque TCP_ and can be handled in the same way as other TCP non-HTTP protocols.

Now let's see how we can define egress rules for TCP traffic.

## Egress rules for TCP traffic
The egress rules for enabling TCP traffic to a specific port must specify `TCP` as the protocol of the port. Additional non-HTTP TCP protocol currently supported is `MONGO`, the [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/).

For the `destination.service` field of the rule, an IP or a block of IPs in [CIDR](https://tools.ietf.org/html/rfc2317) notation must be used.

To enable TCP traffic to an external service by its hostname, all the IPs of the hostname must be specified. Each IP must be specified by a CIDR block or as a single IP, each block or IP in a separate egress rule.

Note that all the IPs of an external service are not always known. To enable TCP traffic by IPs, as opposed to the traffic by a hostname, only the IPs that are used by the applications must be specified.

To read more about Istio Egress Traffic control, see [Control Egress Traffic Task]({{home}}/docs/tasks/traffic-management/egress.html).

## Setting up the database for ratings data
For this task I will set up an instance of MySQL. Any MySQL would do, I used [Compose for MySQL](https://www.ibm.com/cloud/compose/mysql). As a MySQL client to feed the ratings data, I used  [MySQL Shell](https://dev.mysql.com/doc/refman/5.7/en/mysqlsh.html).

1. To initialize the database, I run the following command entering the password when prompted. The command is performed with the credentials of the  `admin` user, created by default by [Compose for MySQL](https://www.ibm.com/cloud/compose/mysql).
  ```bash
   curl -s https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/src/mysql/mysqldb-init.sql | mysqlsh --sql -u admin -p --host <mysql host> --port <mysql port> --ssl-mode=REQUIRED
  ```

  Alternatively, using the `mysql` client and local MySQL database, I would run:
  ```bash
  curl -s https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -p
  ```

2. Then I create a user with the name _bookinfo_ and grant it _SELECT_ privilege on the `test.ratings`:

  ```bash
  mysqlsh --sql -u admin -p --host <mysql host> --port <mysql port> --ssl-mode=REQUIRED -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
  ```

  For `mysql` and the local database, the command would be:
  ```bash
  mysql -u root -p -e "CREATE USER 'bookinfo' IDENTIFIED BY '<password you choose>'; GRANT SELECT ON test.ratings to 'bookinfo';"
  ```
  Here I apply the [principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege). I do not use my _admin_ user in the Bookinfo application. For Bookinfo application I create a special user with minimal privileges, in this case only the `SELECT` privilege and only on a single table.

  After running that command, I will clean my bash history by checking the number of the last command and running `history -d <the number of the command that created the user>`. I do not want the password of the new user to be stored in bash history. If I would use mysql, I would remove the last command from `~/.mysql_history` file as well. Read more about password protection of the newly created user in [MySQL documentation](https://dev.mysql.com/doc/refman/5.5/en/create-user.html).

3. I inspect the created ratings to see that everything worked as expected:
  ```bash
  mysqlsh --sql -u bookinfo -p --host <mysql host> --port <mysql port> --ssl-mode=REQUIRED -e "select * from test.ratings;"
  Enter password:
  +----------+--------+
  | ReviewID | Rating |
  +----------+--------+
  |        1 |      5 |
  |        2 |      4 |
  +----------+--------+
  ```

  For `mysql` and the local database:
  ```bash
  mysql -u bookinfo -p -e "select * from test.ratings;"
  Enter password:
  +----------+--------+
  | ReviewID | Rating |
  +----------+--------+
  |        1 |      5 |
  |        2 |      4 |
  +----------+--------+
  ```

4. I set the ratings temporarily to 1 to provide a visual clue when our database is used by the Bookinfo _ratings_ service:
  ```bash
  mysqlsh --sql -u admin -p --host <mysql host> --port <mysql port> --ssl-mode=REQUIRED -e "update test.ratings set rating=1; select * from test.ratings;"
  Enter password:
  +----------+--------+
  | ReviewID | Rating |
  +----------+--------+
  |        1 |      1 |
  |        2 |      1 |
  +----------+--------+
  ```

  For `mysql` and the local database:
  ```bash
  mysql -u root -p -e "update test.ratings set rating=1; select * from test.ratings;"
  Enter password:
  +----------+--------+
  | ReviewID | Rating |
  +----------+--------+
  |        1 |      1 |
  |        2 |      1 |
  +----------+--------+
  ```
I used the _admin_ user (and _root_ for the local database) in the last command since the _bookinfo_ user does not have the _UPDATE_ privilege on the `test.ratings` table.

## Cleanup
1. Drop the _test_ database and the _bookinfo_ user:
  ```bash
  mysqlsh --sql -u admin -p --host <mysql host> --port <mysql port> --ssl-mode=REQUIRED -e "drop database test; drop user bookinfo;"
  ```

  For `mysql` and the local database:
  ```bash
  mysql -u root -p -e "drop database test; drop user bookinfo;"
  ```
