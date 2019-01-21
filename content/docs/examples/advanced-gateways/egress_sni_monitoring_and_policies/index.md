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
   **with mutual TLS enabled**.

## SNI monitoring and access policies

Since you configured the egress traffic to flow through the egress gateway, you can apply monitoring and access policy
enforcement on the egress traffic, **securely**. In this section you will define a log entry and an access policy for
the egress traffic to _*.wikipedia.org_.

1.  Create `logentry`, `rules` and `handlers`:

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
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'
    {{< /text >}}

1.  Define a policy that allows access to the hostnames matching `*.wikipedia.org` except for Wikipedia in
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

1.  Send an HTTPS request to the blacklisted [Wikipedia in English](https://en.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

    Access to Wikipedia in English is blocked according to the policy you defined.

1.  Send HTTPS requests to some other Wikipedia sites, for example [https://es.wikipedia.org](https://es.wikipedia.org) and
    [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

    Access to Wikipedia sites in other languages is allowed, as expected.

### Cleanup of monitoring and policy enforcement

{{< text bash >}}
$ kubectl delete rule handle-wikipedia-access check-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker wikipedia-checker -n istio-system
{{< /text >}}

## Monitor the SNI and the source identity, and enforce access policies based on them

Since you enabled mutual TLS between the sidecar proxies and the egress gateway, you can monitor the [service identity](/docs/concepts/what-is-istio/#citadel) of the applications that access external services, and enforce policies
based on the identities of the traffic source.
In Istio on Kubernetes, the identities are based on
[Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). In this
subsection, you deploy two _sleep_ containers, `sleep-us` and `sleep-canada` under two service accounts,
`sleep-us` and `sleep-canada`, respectively. Then you define a policy that allows applications with the `sleep-us`
identity to access the English and the Spanish versions of Wikipedia, and services with `sleep-canada` identity to
access the English and the French versions.

1.  Deploy two _sleep_ containers, `sleep-us` and `sleep-canada`, with `sleep-us` and `sleep-canada` service
    accounts, respectively:

    {{< text bash >}}
    $ sed 's/: sleep/: sleep-us/g' @samples/sleep/sleep.yaml@ | kubectl apply -f -
    $ sed 's/: sleep/: sleep-canada/g' @samples/sleep/sleep.yaml@ | kubectl apply -f -
    serviceaccount "sleep-us" created
    service "sleep-us" created
    deployment "sleep-us" created
    serviceaccount "sleep-canada" created
    service "sleep-canada" created
    deployment "sleep-canada" created
    {{< /text >}}

1.  Create `logentry`, `rules` and `handlers`:

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

1.  Send HTTPS requests to Wikipedia sites in English, German, Spanish and French, from `sleep-us`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

1.  Check the mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'
    {"level":"info","time":"2019-01-10T17:33:55.559093Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"en.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.166227Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"de.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:56.779842Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"es.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {"level":"info","time":"2019-01-10T17:33:57.413908Z","instance":"egress-access.logentry.istio-system","connectionEvent":"open","destinationApp":"","requestedServerName":"fr.wikipedia.org","source":"istio-egressgateway-with-sni-proxy","sourceNamespace":"default","sourcePrincipal":"cluster.local/ns/default/sa/sleep-us","sourceWorkload":"istio-egressgateway-with-sni-proxy"}
    {{< /text >}}

    Note the `requestedServerName` attribute, and `sourcePrincipal`, it must be `cluster.local/ns/default/sa/sleep-us`.

1.  Define a policy that will allow access to Wikipedia in English and Spanish for applications with the `sleep-us`
    service account and to Wikipedia in English and French for applications with the `sleep-canada` service account.
    Access to other Wikipedia sites will be blocked.

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: requested-server-name
      namespace: istio-system
    spec:
      value: connection.requested_server_name
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: us-wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org", "es.wikipedia.org"]
      blacklist: false
    ---
    # Rule to check access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-us-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && source.principal == "cluster.local/ns/default/sa/sleep-us"
      actions:
      - handler: us-wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: canada-wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org", "fr.wikipedia.org"]
      blacklist: false
    ---
    # Rule to check access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-canada-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && source.principal == "cluster.local/ns/default/sa/sleep-canada"
      actions:
      - handler: canada-wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    EOF
    {{< /text >}}

1.  Resend HTTPS requests to Wikipedia sites in English, German, Spanish and French, from `sleep-us`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-us -o jsonpath='{.items[0].metadata.name}') -c sleep-us -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia, la enciclopedia libre</title>
    {{< /text >}}

    Note that only the allowed Wikipedia sites for `sleep-us` service account are allowed, namely Wikipedia in English
    and Spanish.

    > It may take several minutes for the Mixer policy components to synchronize on the new policy. In case you want to
    quickly demonstrate the new policy without waiting until the synchronization is complete, delete the Mixer policy pods:

    {{< text bash >}}
    $ kubectl delete pod -n istio-system -l istio-mixer-type=policy
    {{< /text >}}

1.  Resend HTTPS requests to Wikipedia sites in English, German, Spanish and French, from `sleep-canada`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep-canada -o jsonpath='{.items[0].metadata.name}') -c sleep-canada -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"; curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Accueil_principal | grep -o "<title>.*</title>";:'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipédia, l'encyclopédie libre</title>
    {{< /text >}}

    Note that only the allowed Wikipedia sites for `sleep-canada` service account are allowed, namely Wikipedia in
    English and French.

### Cleanup of monitoring and policy enforcement of SNI and source identity

{{< text bash >}}
$ kubectl delete serviceaccount sleep-us sleep-canada
$ kubectl delete service sleep-us sleep-canada
$ kubectl delete deployment sleep-us sleep-canada
$ kubectl delete rule handle-wikipedia-access check-us-wikipedia-access check-canada-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker us-wikipedia-checker canada-wikipedia-checker -n istio-system
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
