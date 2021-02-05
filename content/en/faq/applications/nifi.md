---
title: Can I run Apache NiFi inside an Istio mesh?
description: How to run Apache NiFi with Istio.
weight: 50
keywords: [nifi]
---

[Apache NiFi](https://nifi.apache.org) poses some challenges to get it running on Istio. These challenges come from the clustering
requirements it has. For example, there is a requirement that cluster components must be uniquely addressable using cluster-wide
host names. This requirement conflicts with Istio's requirement that workloads bind and listen on `0.0.0.0` within
the pod.

There are different ways to work around these issues based on your configuration requirements for your NiFi deployment. NiFi has
at least three ways to specify what hostname should be used for cluster networking:

* [`nifi.remote.input.host`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#site_to_site_properties) -
the host name that will be given out to clients to connect to this NiFi instance for Site-to-Site communication. By default, it is
the value from `InetAddress.getLocalHost().getHostName()`. On UNIX-like operating systems, this is typically the output from the
hostname command.

* [`nifi.web.https.host`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties) - The HTTPS host.
It is blank by default. The jetty server will run on this hostname and it needs to be addressable across the cluster for replication
with other nodes.

* [`nifi.cluster.node.address`](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#cluster_node_properties) - The
fully qualified address of the node. It is blank by default. This is used for cluster coordination as well and needs to be uniquely
addressable within the cluster.

Some considerations:

* Using a blank or `localhost` setting for `nifi.web.https.host` doesn't work in this case because of the networking requirements for
  unique addressing mentioned above.
* Unless you're okay with all of your users having all access roles in your NiFi deployment, HTTP is not a viable solution as [NiFi does not
  perform user authentication over HTTP](https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#user_authentication).
* Explicitly specifying the networking interfaces that NiFi should use can help work around the issues and allow NiFi to work:
  Modify `nifi.properties` where `xxx` is the network interface that corresponds with the worker IP (differs based on environment/cloud provider)
and `yyy` was the loopback interface (I.e `lo`) for the container/pod:

  {{< text plain >}}
    nifi.web.https.network.interface.default=xxx
    nifi.web.https.network.interface.lo=yyy
  {{< /text >}}

  A real-world example (valid for IBM Cloud, maybe others) would look like this:

  {{< text plain >}}
    nifi.web.https.network.interface.default=eth0
    nifi.web.https.network.interface.lo=lo
  {{< /text >}}

