---
title: Outlier detection with Istio
overview: Mitigate faults related to intermittent failures by Istio.

weight: 130

---

In the case a microservice starts to fail multiple times, it is beneficial to stop sending
requests to the failing microservice for some period of time, since it will probably fail to handle them anyway.
You do not want to flood the failing microservice with requests since it will not be able to handle them.
You want to give the faulty microservice time to recuperate, and then to start sending the requests to it again.

1.  Deploy the version of _ratings_ which becomes unavailable for 60 seconds from time to time:

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
      name: ratings-v-unavailable
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: ratings
            version: v-unavailable
        spec:
          containers:
          - name: ratings
            image: vadimeisenbergibm/examples-bookinfo-ratings-v-unavailable:1.10.4
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: ratings
    spec:
      host: ratings
      subsets:
      - name: v1
        labels:
          version: v1
      - name: v-unavailable
        labels:
          version: v-unavailable
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
        outlierDetection:
          consecutiveErrors: 20
          interval: 30s
          baseEjectionTime: 30s
    EOF
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    {{< tip >}}
    Switch the fetching interval to `5s`, so you will see what happens more precisely.
    {{< /tip >}}

    Note the two versions of _ratings_, _v1_ and _v-unavailable_, handling the requests successfully.

    {{< image width="80%"
        link="images/kiali-ratings-unavailable.png"
        caption="Kiali Graph Tab with ratings v-unavailable"
        >}}

1.  Wait for about a minute. You will notice that _v-unavailable_ starts returning errors. It's box turns red, the
    box of the whole _ratings_ microservice turns red, the box of the _reviews_ becomes orange.

    {{< image width="80%"
        link="images/kiali-ratings-unavailable-failing.png"
        caption="Kiali Graph Tab with ratings v-unavailable failing"
        >}}

1.  Wait for about half minute for Istio to detect the failing version. (For the sake of the tutorial the outlier
    detection interval was set to 30 seconds, in real life you would use much smaller interval). Once Istio detects
    that _ratings v-unavailable_ starts to consecutively return errors, it will stop directing traffic to it. You will
    see that the incoming edge into _ratings v-unavailable_ will become grey and all the traffic will flow to
    _ratings v1_.

    {{< image width="80%"
        link="images/kiali-ratings-unavailable-detected.png"
        caption="Kiali Graph Tab with traffic not routed to ratings v-unavailable"
        >}}

1.  After about another half minute, Istio will start sending traffic to _ratings v-unavailable_ again.
    _ratings v-unavailable_ will return successful results for about a minute. After that, it will start failing again,
    and after some time will detected by Istio as failing and Istio will stop sending traffic to it. You may want to
    observe the process for several cycles.

1.  Remove the _unavailable_ version of _ratings_ and recreate the destination rule and the virtual service to route to
    _ratings v1_:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete deployment ratings-v-unavailable
    {{< /text >}}
