---
title: Liveness probes with Kubernetes
overview: Mitigate faults that are reported by microservices.

weight: 115

---

While you inject faults to test how your microservices cope with networks problems and with issues with the
microservices they call, sometimes real faults and bugs happen. Sometimes the microservices can detect the problematic
situation themselves. For example, there might be some deadlock situation in which a microservice runs but cannot
make any progress. In such a situation it is better to restart the microservice. Kubernetes can do it automatically via
[liveness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).

[HTTP liveness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-http-request) work in the following way: a microservice defines an HTTP endpoint on which it reports its
health status. Then the operator who deploys the microservice provides in the deployment spec instructions for
Kubernetes to probe the HTTP endpoint once in a while. Once the microservice reports an unhealthy status, it is
restarted automatically by Kubernetes.

In this module you deploy a faulty `ratings` microservice, which will become unhealthy and unavailable (will return
HTTP code `500`) after 15 minutes from its start. It will continue to be unhealthy and unavailable for the next 15
minutes.

{{<  warning >}}
This module requires observing microservice behavior for one hour. You may want to perform this module in parallel with
your other activities. You may want to skip this module and proceed to the next one, and to get back to this
one later.
{{<  /warning >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that everything is green and there are no errors shown on the right panel, 100% success.

    {{< image width="80%"
        link="images/kiali-successful-ratings.png"
        caption="Kiali Graph Tab with ratings without errors"
        >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard).
    In the top left drop-down menu, select _Istio Service Dashboard_. Select the `ratings` service of your namespace.
    Notice 100% client and server success rate.

    {{< image width="80%"
        link="images/dashboard-successful-ratings.png"
        caption="Istio Service Dashboard for the ratings microservice with 100% success rate"
        >}}

1.  Deploy the faulty version of `ratings`:

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
      name: ratings-v-unhealthy
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: ratings
            version: v-unhealthy
        spec:
          containers:
          - name: ratings
            image: istio/examples-bookinfo-ratings-v-unhealthy:latest
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    EOF
    {{< /text >}}

1.  Direct the traffic to the faulty `ratings`:

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
      subsets:
      - name: v-unhealthy
        labels:
          version: v-unhealthy
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
    spec:
      hosts:
        - ratings
      http:
      - route:
        - destination:
            host: ratings
            subset: v-unhealthy
    EOF
    {{< /text >}}

1.  Set the fetching interval for 30 minutes in your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), in the graph of your namespace.

    Select `last 30 minutes` in the fetching interval drop down menu at the top right.

    {{< image width="80%"
        link="images/kiali-set-last-30-minutes.png"
        caption="Kiali Graph Tab, setting the fetching interval for the last 30 minutes"
        >}}

1.  Set the fetching interval for 30 minutes in your Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard). In your Istio Service Dashboard of the `ratings` service of your namespace, select `last 30 minutes` in
    the fetching interval drop down menu at the top right.

    {{< image width="80%"
        link="images/dashboard-set-last-30-minutes.png"
        caption="Istio Service Dashboard, setting the fetching interval for the last 30 minutes"
        >}}

1.  Wait for 15 minutes for the errors from the unhealthy ratings to appear. Time for a coffee.

1.  After about 15 minutes the `ratings` service will become unhealthy and you will see first errors in Kiali and in the
    Istio Dashboard.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that `reviews` and `ratings` became orange, the `v-unhealthy` version became red,
    the success rate on the right panel is less than 100%.

    {{< image width="80%"
        link="images/kiali-first-ratings-errors.png"
        caption="Kiali Graph Tab with first errors in ratings"
        >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard).
    In _Istio Service Dashboard_, the `ratings` service of your namespace, notice less than 100% client and server
    success rate.

    {{< image width="80%"
        link="images/dashboard-first-ratings-errors.png"
        caption="Istio Service Dashboard with first errors in ratings"
        >}}

1.  Access your application's webpage. Notice the `ratings unavailable` message. Despite the failing `ratings`
    microservice, you have **graceful service degradation**: as you can see, the book details and reviews are displayed correctly, and the application is still useful. You provide
    partial functionality to the user in the face of occurring failures and it is good.

    {{< image width="80%"
        link="images/bookinfo-ratings-unavailable.png"
        caption="Bookinfo application: ratings unavailable"
        >}}

1.  Wait for another 15 minutes. During that period, check Kiali and the Istio dashboard, note that the error rates
    grow constantly.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Click on the `ratings` service. Note that the error rate on the right panel is about 50%.

    {{< image width="80%"
        link="images/kiali-50-percent-ratings-error.png"
        caption="Kiali Graph Tab with 50% errors in ratings"
        >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard).
    In _Istio Service Dashboard_, the `ratings` service of your namespace, notice less about 50% client and server
    success rate.

    {{< image width="80%"
        link="images/dashboard-50-percent-ratings-error.png"
        caption="Istio Service Dashboard with 51% errors in ratings"
        >}}

1.  Deploy the faulty version of `ratings` with liveness probe:

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
      name: ratings-v-unhealthy
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: ratings
            version: v-unhealthy
        spec:
          containers:
          - name: ratings
            image: istio/examples-bookinfo-ratings-v-unhealthy:latest
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
            livenessProbe:
              httpGet:
                path: /health
                port: 9080
              initialDelaySeconds: 5
              periodSeconds: 5
    EOF
    {{< /text >}}

1.  Wait for another 30 minutes. This time the `ratings` microservice will be healthy for 15 minutes and then it will
    become unhealthy. However, since you defined a liveness probe, Kubernetes will restart its pod and the microservice
    will become healthy again.

1.  Check the unhealthy pod's status and see that it was restarted:

    {{< text bash >}}
    $ kubectl get pod -l version=v-unhealthy
    NAME                                   READY   STATUS    RESTARTS   AGE
    ratings-v-unhealthy-67b4bcb44d-8bn8w   2/2     Running   1          30m
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Click on the `ratings` service. Note that this time the error rate on the right panel is small and the color of
    `ratings` is orange.

    {{< image width="80%"
        link="images/kiali-ratings-with-liveness-probe.png"
        caption="Kiali Graph Tab, ratings with the liveness probe"
        >}}

1.  Access the Istio dashboard at
    [http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard](http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard).
    In _Istio Service Dashboard_, the `ratings` service of your namespace, note that the client and server
    success rate is almost 100%. Note the drop in the success rate that happened about 15 minutes ago.

    {{< image width="80%"
        link="images/dashboard-ratings-with-liveness-probe.png"
        caption="Istio Service Dashboard, ratings with the liveness probe"
        >}}

1.  Remove the _v-unhealthy_ version of `ratings` and recreate the destination rule and the virtual service to route to
    _ratings v1_:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete virtualservice ratings
    $ kubectl delete deployment ratings-v-unhealthy
    {{< /text >}}

1.  Reduce the interval of Kiali and of the Istio dashboard to the last five minutes since the next modules do not
    require large intervals.
