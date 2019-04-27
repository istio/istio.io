---
title: Rate limiting and bulkhead with Istio
overview: Mitigate failures stemming from overloading a microservice with requests

weight: 140

---

There could be cases when one microservice, due to a bug or maliciously or due to incorrect service usage planning,
might start sending too much requests to other microservices. Those, in turn, can start sending even more requests to
the microservices they call. If uncontrolled, one misbehaving microservice can overload the whole application, causing
more failures and making the application or parts of it unavailable.

1.  Deploy the version of `reviews` that sends 100 unnecessary requests to `ratings`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    # Copyright 2017 Istio Authors
    #
    #   Licensed under the Apache License, Version 2.0 (the "License");
    #   you may not use this file except in compliance with the License.
    #   You may obtain a copy of the License at
    #
    #       http://www.apache.org/licenses/LICENSE-2.0
    #
    #   Unless required by applicable law or agreed to in writing, software
    #   distributed under the License is distributed on an "AS IS" BASIS,
    #   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    #   See the License for the specific language governing permissions and
    #   limitations under the License.

    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: reviews-flooding
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: reviews
            version: v-flooding
        spec:
          containers:
          - name: reviews
            image: vadimeisenbergibm/examples-bookinfo-reviews-v-flooding:1.10.15
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    EOF
    {{< /text >}}

1.  Direct the traffic to the faulty `reviews`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: reviews
    spec:
      host: reviews
      subsets:
      - name: v-flooding
        labels:
          version: v-flooding
        trafficPolicy:
          tls:
            mode: ISTIO_MUTUAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
    spec:
      hosts:
        - reviews
      http:
      - route:
        - destination:
            host: reviews
            subset: v-flooding
    EOF
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Notice the _v-flooding_ version of `reviews`

    {{< image width="80%"
        link="images/kiali-reviews-flooding.png"
        caption="Kiali Graph Tab with reviews v-flooding"
        >}}

    Wait to see the outgoing traffic rate of `reviews` growing to almost 1000 times the incoming traffic rate. While the
    application continues to operate successfully, you may want to limit the usage of the `ratings` service to prevent
    overloading it or abusing its computing resources and its billing budget.

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Enable Istio rate limiting. Performs the steps below. There is no need to understand the steps, if you want to
    understand what exactly the steps configure, read the
    [Enabling Rate Limits](/docs/tasks/policy-enforcement/rate-limiting/) task.

    1.  Create a `quota` instance:

        {{< text bash >}}
        $ kubectl apply -f - <<EOF
        apiVersion: config.istio.io/v1alpha2
        kind: instance
        metadata:
          name: requestcountquota
        spec:
          compiledTemplate: quota
          params:
            dimensions:
              destination: destination.labels["app"] | destination.service.name | "unknown"
        EOF
        {{< /text >}}

    1.  Create a handler and a quota spec:

        {{< text bash >}}
        $ kubectl apply -f - <<EOF
        apiVersion: config.istio.io/v1alpha2
        kind: handler
        metadata:
          name: quotahandler
        spec:
          compiledAdapter: memquota
          params:
            quotas:
            - name: requestcountquota.instance.$NAMESPACE
              maxAmount: 500
              validDuration: 1s
              # The first matching override is applied.
              # A requestcount instance is checked against override dimensions.
              overrides:
              - dimensions:
                  destination: ratings
                maxAmount: 50
                validDuration: 1s
        ---
        apiVersion: config.istio.io/v1alpha2
        kind: QuotaSpec
        metadata:
          name: request-count
        spec:
          rules:
          - quotas:
            - charge: 1
              quota: requestcountquota
        EOF
        {{< /text >}}

    1.  Create a quota spec binding and a rule:

        {{< text bash >}}
        $ kubectl apply -f - <<EOF
        apiVersion: config.istio.io/v1alpha2
        kind: QuotaSpecBinding
        metadata:
          name: request-count
        spec:
          quotaSpecs:
          - name: request-count
          services:
          - name: ratings
        ---
        apiVersion: config.istio.io/v1alpha2
        kind: rule
        metadata:
          name: quota
        spec:
          actions:
          - handler: quotahandler
            instances:
            - requestcountquota
        EOF
        {{< /text >}}

1.  Clean the rate limiting configuration:

    {{< text bash >}}
    $ kubectl delete rule.config.istio.io/quota
    $ kubectl delete handler.config.istio.io/quotahandler
    $ kubectl delete quotaspecbinding.config.istio.io/request-count
    $ kubectl delete quotaspec.config.istio.io/request-count
    $ kubectl delete instance.config.istio.io/requestcountquota
    {{< /text >}}

1.  Specify the maximum number of connections for the `ratings` service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: ratings
    spec:
      host: ratings
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
        connectionPool:
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 5
            maxRetries: 3
          tcp:
            maxConnections: 5
    EOF
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that the traffic rate from `ratings` service (the triangle in Kiali's graph) to the `ratings v1` pod
    (the square in Kiali's graph) is reduced and it is less than the flow shown from `reviews` to `ratings`. What
    happens in reality is that some of the requests from the `reviews v-flooding` pod do not actually leave the pod
    but are blocked by the sidecar proxy. The traffic to `ratings` is limited by the sidecar proxy of `reviews` and it
    does not even arrive to `ratings`.

    {{< image width="80%"
        link="images/kiali-reviews-flooding-bulkhead.png"
        caption="Kiali Graph Tab with reviews v-flooding and connection pool configured"
        >}}

1.  Remove the _flooding_ version of `reviews` and recreate the destination rule and the virtual services to route to
    _reviews v2 and v3_:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete virtualservice reviews
    $ kubectl delete deployment reviews-flooding
    {{< /text >}}
