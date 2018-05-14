---
title: Control Egress TCP Traffic
overview: Describes how to configure Istio to route TCP traffic from services in the mesh to external services.

order: 41

layout: docs
type: markdown
---
{% include home.html %}

The [Control Egress Traffic]({{home}}/docs/tasks/traffic-management/egress.html) task demonstrated how external (outside the Kubernetes cluster) HTTP and HTTPS services can be accessed from applications inside the mesh. A quick reminder: by default, Istio-enabled applications are unable to access URLs outside the cluster. To enable such access, [egress rules]({{home}}/docs/reference/config/istio.routing.v1alpha1.html#EgressRule) must be defined, or, alternatively, [direct access to external services]({{home}}/docs/tasks/traffic-management/egress.html#calling-external-services-directly) must be configured.

This task describes how to configure Istio to expose external TCP services to applications inside the Istio service mesh.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Start the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) sample application which will be used as a test source for external calls.

  ```bash
  kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
  ```

  **Note**: any pod that you can execute `curl` from is good enough.

## Using Istio egress rules for external TCP traffic
In this task we access `wikipedia.org` by HTTPS originated by the application. This task demonstrates the use case when the application cannot use HTTP with TLS origination by the sidecar proxy. Using HTTP with TLS origination by the sidecar proxy is described in the [Control Egress Traffic]({{home}}/docs/tasks/traffic-management/egress.html) task. In that task, `https://google.com` was accessed by issuing HTTP requests to `http://www.google.com:443`.

The HTTPS traffic originated by the application will be treated by Istio as _opaque_ TCP. To enable such traffic, we define a TCP egress rule on port 443.

In TCP egress rules as opposed to HTTP-based egress rules, the destinations are specified by IPs or by blocks of IPs in [CIDR notation](https://tools.ietf.org/html/rfc2317).

Let's assume for the sake of the example that we want to access `wikipedia.org` by the domain name. This means that we have to specify all the IPs of `wikipedia.org` in our TCP egress rules. Fortunately, the IPs of `wikipedia.org` are published [here]( https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses). It is a list of IP blocks in [CIDR notation](https://tools.ietf.org/html/rfc2317): `91.198.174.192/27`, `103.102.166.224/27`, and more. We must define an egress rule per each IP block.

Alternatively, if we want to access `wikipedia.org` by an IP, just a single egress rule for that IP must be defined.

## Creating egress rules
Let's create egress rules to enable TCP access to `wikipedia.org`:
```bash
cat <<EOF | istioctl create -f -
kind: EgressRule
metadata:
  name: wikipedia-range1
spec:
  destination:
      service: 91.198.174.192/27
  ports:
      - port: 443
        protocol: tcp
---
kind: EgressRule
metadata:
  name: wikipedia-range2
spec:
  destination:
      service: 103.102.166.224/27
  ports:
      - port: 443
        protocol: tcp
---
kind: EgressRule
metadata:
  name: wikipedia-range3
spec:
  destination:
      service: 198.35.26.96/27
  ports:
      - port: 443
        protocol: tcp
---
kind: EgressRule
metadata:
  name: wikipedia-range4
spec:
  destination:
      service: 208.80.153.224/27
  ports:
      - port: 443
        protocol: tcp
---
kind: EgressRule
metadata:
  name: wikipedia-range5
spec:
  destination:
      service: 208.80.154.224/27
  ports:
      - port: 443
        protocol: tcp
EOF
```

This command will create five egress rules, a rule per different block of IPs of `wikipedia.org`. Note the `---` (three dashes) separator between the egress rules. This is the [YAML separator between documents](http://www.yaml.org/spec/1.2/spec.html#id2760395) in a stream. It allows us to create multiple configuration artifacts using a single `istioctl` command.

## Access wikipedia.org by HTTPS

1. `kubectl exec` into the pod to be used as the test source. If you are using the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) application, run the following command:

   ```bash
   kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep bash
   ```

2. Make a request and verify that we can access https://www.wikipedia.org successfully:

   ```bash
   curl -o /dev/null -s -w "%{http_code}\n" https://www.wikipedia.org
   ```
   ```bash
   200
   ```

   We should see `200` printed as the output, which is the HTTP code _OK_.

3. Now let's fetch the current number of the articles available on Wikipedia in the English language:
   ```bash
   curl -s https://en.wikipedia.org/wiki/Main_Page | grep articlecount | grep 'Special:Statistics'
   ```

   The output should be similar to:

   ```bash
   <div id="articlecount" style="font-size:85%;"><a href="/wiki/Special:Statistics" title="Special:Statistics">5,563,121</a> articles in <a  href="/wiki/English_language" title="English language">English</a></div>
   ```

  This means there were 5,563,121 articles in Wikipedia in English when this task was written.

## Cleanup

1. Remove the egress rules we created.

   ```bash
   istioctl delete egressrule wikipedia-range1 wikipedia-range2 wikipedia-range3 wikipedia-range4 wikipedia-range5 -n default
   ```

1. Shutdown the [sleep](https://github.com/istio/istio/tree/master/samples/sleep) application.

   ```bash
   kubectl delete -f samples/sleep/sleep.yaml
   ```

## What's next

* The [Egress Rules]({{home}}/docs/concepts/traffic-management/rules-configuration.html#egress-rules) reference.

* The [Control Egress Traffic]({{home}}/docs/tasks/traffic-management/egress.html) task, for HTTP and HTTPS.
