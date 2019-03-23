---
title: Retries with Istio
overview: Mitigate faults related to intermittent failures by Istio.

weight: 125

---

In this module you check another fault mitigation mechanism of Istio. You deploy a faulty _ratings_ microservice, which
misbehaves half the time. With the probability of one half it returns the _503_ error, all other times it succeeds.

To mitigate such a fault, you perform a retry of 3 times on the call to _ratings_.

1.  Deploy the faulty version of _ratings_:

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
      name: ratings-v-faulty
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: ratings
            version: v-faulty
        spec:
          containers:
          - name: ratings
            image: vadimeisenbergibm/examples-bookinfo-ratings-v-faulty:1.10.3
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    EOF
    {{< /text >}}

1.  Direct the traffic to the faulty _ratings_:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: ratings
    spec:
      host: ratings
      subsets:
      - name: v-faulty
        labels:
          version: v-faulty
        trafficPolicy:
          tls:
            mode: ISTIO_MUTUAL
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
            subset: v-faulty
    EOF
    {{< /text >}}

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that now _`productpage`_ turned orange while _reviews_ and _ratings_ turned red. Notice the red edges and the
    error rate of the HTTP traffic on the right.

    {{< image width="80%"
        link="images/kiali-faulty-ratings.png"
        caption="Kiali Graph Tab with faulty ratings"
        >}}

1.  Access the webpage of your application in a browser several times. Once in a while you will get an error about
    _reviews_ being unavailable.

    {{< image width="80%"
        link="images/bookinfo-ratings-unavailable.png"
        caption="Bookinfo application: ratings unavailable"
        >}}

1.  Mitigate the problem with the help of Istio. Define retries on the call from _reviews_ to _ratings_.
    Let _reviews_ try to call _ratings_ 5 times, with a quarter of a second delay between the calls.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
            subset: v-faulty
        retries:
          attempts: 5
          perTryTimeout: 0.25s
    EOF
    {{< /text >}}

1.  Access your application's webpage several times. Now you will receive the _ratings unavailable_ error very seldom if
    at all.

1.  Check your Kiali console,
    [http://my-kiali.io/kiali/console](http://my-kiali.io/kiali/console), the graph of your namespace.

    Note that the HTTP error rate is reduced.

    {{< image width="80%"
        link="images/kiali-retry-to-ratings.png"
        caption="Kiali Graph Tab with retry to ratings"
        >}}

1.  Remove the _faulty_ version of _ratings_ and recreate the destination rule and the virtual service to route to
    _ratings v1_:

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all-mtls.yaml
    $ kubectl delete virtualservice ratings
    $ kubectl delete deployment ratings-v-faulty
    {{< /text >}}
