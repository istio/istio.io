---
title: Rate limiting with Istio
overview: Mitigate failures stemming from overloading a microservice with requests

weight: 140

---

There could be cases when one microservice, due to a bug or maliciously or due to incorrect service usage planning,
might start sending too much requests to other microservices. Those, in turn, can start sending even more requests to
the microservices they call. If uncontrolled, one misbehaving microservice can overload the whole application, causing
more failures and making the application or parts of it unavailable.

1.  Deploy the version of `productpage` that sends 100 unnecessary requests to `reviews`:

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
      name: productpage-v-flooding
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: productpage
            version: v-flooding
        spec:
          containers:
          - name: productpage
            image: vadimeisenbergibm/examples-bookinfo-productpage-v-flooding:1.10.22
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    EOF
    {{< /text >}}

1.  Update the destination rule of `productpage` to include the subset of the faulty `productpage`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: productpage
    spec:
      host: productpage
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
      subsets:
      - name: v1
        labels:
          version: v1     
      - name: v-flooding
        labels:
          version: v-flooding
    EOF
    {{< /text >}}

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.  Create an environment variable for

    {{< text bash >}}
    $ export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
    $ echo $MY_INGRESS_GATEWAY_HOST
    istio.tutorial.bookinfo.com
    {{< /text >}}

1.  Reconfigure the virtual service of the Istio Ingress Gateway to use the buggy version:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      hosts:
      - $MY_INGRESS_GATEWAY_HOST
      gateways:
      - bookinfo-gateway.$NAMESPACE.svc.cluster.local
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            subset: v-flooding
            port:
              number: 9080
    EOF
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Notice the _v-flooding_ version of `productpage`

    {{< image width="80%"
        link="images/kiali-productpage-flooding.png"
        caption="Kiali Graph Tab with productpage v-flooding"
        >}}

    Wait to see the outgoing traffic rate of `productpage` growing to about 100 times the incoming traffic rate.
    While the application continues to operate successfully, you may want to limit the usage of the `reviews` service to
    prevent overloading it or abusing its computing resources and its billing budget. You also do not want the excessive
    traffic to propagate to further microservices, in this case to the `ratings` service.

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
                  destination: reviews
                maxAmount: 3
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
          - name: reviews
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

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    {{< image width="80%"
        link="images/kiali-productpage-flooding-rate-limiting.png"
        caption="Kiali Graph Tab with productpage v-flooding and rate limiting enabled"
        >}}

    Note that now the `reviews` service returns an error to the most of the requests. The errors are returned by the
    sidecar of the `reviews` microservice, the traffic does not arrive to the container of `reviews`. Note that the
    traffic from `reviews` to `ratings` is reduced comparing to the traffic from `productpage` to `reviews`. So, you
    significantly reduced the traffic that arrives to the application container of `reviews`, and did not allow the
    excessive traffic to proceed to `ratings`. You localized the problem to `productpage` and `reviews`, and did not let
    to cascade to `ratings`.  

1.  Clean the rate limiting configuration:

    {{< text bash >}}
    $ kubectl delete rule.config.istio.io/quota
    $ kubectl delete handler.config.istio.io/quotahandler
    $ kubectl delete quotaspecbinding.config.istio.io/request-count
    $ kubectl delete quotaspec.config.istio.io/request-count
    $ kubectl delete instance.config.istio.io/requestcountquota
    {{< /text >}}

1.  Reconfigure the virtual service of the Istio Ingress Gateway to use the `v1` version of `productpage`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      hosts:
      - $MY_INGRESS_GATEWAY_HOST
      gateways:
      - bookinfo-gateway.$NAMESPACE.svc.cluster.local
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            exact: /login
        - uri:
            exact: /logout
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            subset: v1
            port:
              number: 9080
    EOF
    {{< /text >}}

1.  Remove the _flooding_ version of `productpage` and recreate the destination rule and the virtual services to route to
    _productpage v1_:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete deployment productpage-v-flooding
    {{< /text >}}
