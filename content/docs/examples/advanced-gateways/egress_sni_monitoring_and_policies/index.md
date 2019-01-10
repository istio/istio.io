---
title: SNI Monitoring and Policies for TLS Egress Traffic
description: Describes how to configure SNI monitoring and apply policies on TLS egress traffic.
keywords: [traffic-management,egress,telemetry,policies]
weight: 51
---

The [Configure Egress Traffic using Wildcard Hosts](/docs/examples/advanced-gateways/wildcard-egress-hosts/) example
describes how to enable TLS egress traffic for a set of hosts in a common domain, in that case `*.wikipedia.org`. This
example extends that example to show how to configure SNI monitoring and apply policies on TLS egress traffic.

{{< boilerplate before-you-begin-egress >}}

*  Configure traffic to `*.wikipedia.org` by following
   [the steps](/docs/examples/advanced-gateways/wildcard-egress-hosts#wildcard-configuration-for-arbitrary-domains) in
   [Configure Egress Traffic using Wildcard Hosts](/docs/examples/advanced-gateways/wildcard-egress-hosts/) example,
   **with mTLS enabled**.

## SNI monitoring and access policies

Since you configured the egress traffic to flow through the egress gateway, you can apply monitoring and access policy
enforcement on the egress traffic, **securely**. In this section you will define a log entry and an access policy for
the egress traffic to _*.wikipedia.org_.

1.  Create the `logentry`, `rules` and `handlers`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    # Log entry for egress access
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: egress-access
      namespace: istio-system
    spec:
      severity: '"info"'
      timestamp: context.time | timestamp("2017-01-01T00:00:00Z")
      variables:
        connectionEvent: connection.event | ""
        source: source.labels["app"] | "unknown"
        sourceNamespace: source.namespace | "unknown"
        sourceWorkload: source.workload.name | ""
        sourcePrincipal: source.principal | "unknown"
        requestedServerName: connection.requested_server_name | "unknown"
        destinationApp: destination.labels["app"] | ""
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Handler for info egress access entries
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: egress-access-logger
      namespace: istio-system
    spec:
      severity_levels:
        info: 0 # output log level as info
      outputAsJson: true
    ---
    # Rule to handle access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && connection.event == "open"
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'; done
    {{< /text >}}

1.  Define a policy that will allow access to the hostnames matching `*.wikipedia.org` except for Wikipedia in
    English:

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org"]  # overrides provide a static list
      blacklist: true
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: requested-server-name
      namespace: istio-system
    spec:
      value: connection.requested_server_name
    ---
    # Rule to check access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == ""
      actions:
      - handler: wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    EOF
    {{< /text >}}

1.  Send an HTTPS request to the blacklisted [https://en.wikipedia.org](https://en.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

1.  Send HTTPS requests to some other sites, for example [https://es.wikipedia.org](https://es.wikipedia.org) and
    [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### Cleanup of monitoring and policy enforcement

{{< text bash >}}
$ kubectl delete rule handle-wikipedia-access check-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker wikipedia-checker -n istio-system
{{< /text >}}

## Cleanup

1.  Perform
    [the cleanup steps](/docs/examples/advanced-gateways/wildcard-egress-hosts#cleanup-wildcard-configuration-for-arbitrary-domains)
    from [Configure Egress Traffic using Wildcard Hosts](/docs/examples/advanced-gateways/wildcard-egress-hosts/)
    example.

1.  Shutdown the [sleep]({{<github_tree>}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}
