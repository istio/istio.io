---
title: "Consuming External TCP Services"
overview: Describes a simple scenario based on Istio Bookinfo sample
publish_date: February 6, 2018
subtitle: Egress rules for TCP traffic
attribution: Vadim Eisenberg

order: 94

layout: blog
type: markdown
redirect_from: "/blog/egress-tcp.html"
---
{% include home.html %}

## Motivation
Some Istio-enabled applications must access external services, for example legacy systems. In many cases, the access is not performed over HTTP or HTTPS protocols. Other TCP protocols are used, for example database specific protocols like [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/) to communicate with external databases.

Note that in case of access to external HTTPS services, as described in the [control egress TCP traffic]({{home}}/docs/tasks/traffic-management/egress.html) task, an application must issue HTTP requests to the external service. The Envoy sidecar proxy attached to the pod or the VM, will intercept the requests and will open an HTTPS connection to the external service. The traffic will be unencrypted inside the pod or the VM, but it will leave the pod or the VM encrypted.

However, sometimes this approach cannot work due to the following reasons:
* The code of the application is configured to use an HTTPS URL and cannot be changed
* The code of the application uses some library to access the external service and that library uses HTTPS only
* There are compliance requirements that do not allow unencrypted traffic, even if the traffic is unencrypted only inside the pod or the VM

In this case, HTTPS can be treated by Istio as _opaque TCP_ and can be handled in the same way as other TCP non-HTTP protocols.

## Egress rules for TCP traffic
The egress rules for enabling TCP traffic to a specific port must specify `TCP` as the protocol of the port. Additional non-HTTP TCP protocol currently supported is `MONGO`, the [MongoDB Wire Protocol](https://docs.mongodb.com/manual/reference/mongodb-wire-protocol/).

For the `destination.service` field of the rule, an IP or a block of IPs in [CIDR](https://tools.ietf.org/html/rfc2317) notation must be used.

To enable TCP traffic to an external service by its hostname, all the IPs of the hostname must be specified. Each IP must be specified by a CIDR block or as a single IP, each block or IP in a separate egress rule.

Note that all the IPs of an external service are not always known. To enable TCP traffic by IPs, as opposed to the traffic by a hostname, only the IPs that are used by the applications must be specified.

To read more about Istio Egress Traffic control, see [Control Egress Traffic Task]({{home}}/docs/tasks/traffic-management/egress.html).
