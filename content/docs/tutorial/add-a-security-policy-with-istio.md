---
title: Access policies with Kubernetes and Istio
overview: Apply Kubernetes Network Policies and Istio RBAC

weight: 170

---

Note that in your current setting, any microservice can access any other microservice.
If any of the microservices is compromised, the hackers can attack all the other microservices.
You want to specify policies to limit access similar to the
[Need to know](https://en.wikipedia.org/wiki/Need_to_know#In_computer_technology]) principle: only the microservices
that need to access other microservices should be allowed to access the microservices they need.

In your case, `ratings` microservice can be accessed by `reviews` only. Access from `productpage` and from `details`
should be denied.
`productpage` and `details` should not be able to access `ratings`, neither accidentally nor intentionally.

In the same way, the following access must be allowed:

* `productpage` can access `reviews` and `details`
* `reviews` can access `ratings`
* the testing pod, _sleep_, can access any microservice
* all the access is read-only, which means that only HTTP GET method can be applied on `ratings`.
HTTP POST method must be prohibited.
* all other access must be prohibited

In this module you add access policies to enforce the access requirements above.

1.  Verify that any microservice can access any microservice, including sending POST requests to `ratings`.

    1.  GET request from `ratings` to `reviews`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl reviews:9080/reviews/0
        {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}
        {{< /text >}}

    1.  GET request from `ratings` to `details`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl details:9080/details/0
        {"id":0,"author":"William Shakespeare","year":1595,"type":"paperback","pages":200,"publisher":"PublisherA","language":"English","ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
        {{< /text >}}

    1.  POST request from _sleep_ to `ratings`

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":1,"Reviewer2":1}'
        {"id":0,"ratings":{"Reviewer1":1,"Reviewer2":1}}
        {{< /text >}}

        Access the application's webpage. You see one-star ratings from both reviewers! Fix it ASAP so no fake
        ratings will be displayed in production.

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":5,"Reviewer2":4}'
        {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
        {{< /text >}}

## Kubernetes Network Policies

1.  Define the policies:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: NetworkPolicy
    apiVersion: networking.k8s.io/v1
    metadata:
      name: reviews
    spec:
      podSelector:
        matchLabels:
          app: reviews
      ingress:
        - from:
          - podSelector:
              matchLabels:
                app: productpage
          - podSelector:
              matchLabels:
                app: sleep
    ---
    kind: NetworkPolicy
    apiVersion: networking.k8s.io/v1
    metadata:
      name: ratings
    spec:
      podSelector:
        matchLabels:
          app: ratings
      ingress:
        - from:
          - podSelector:
              matchLabels:
                app: reviews
          - podSelector:
              matchLabels:
                app: sleep
    ---
    kind: NetworkPolicy
    apiVersion: networking.k8s.io/v1
    metadata:
      name: details
    spec:
      podSelector:
        matchLabels:
          app: details
      ingress:
        - from:
          - podSelector:
              matchLabels:
                app: productpage
          - podSelector:
              matchLabels:
                app: sleep
    EOF
    {{< /text >}}

1.  Check that unauthorized access is denied.

    1.  GET request from `ratings` to `reviews`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl reviews:9080/reviews/0
        upstream connect error or disconnect/reset before headers
        {{< /text >}}

    1.  GET request from `ratings` to `details`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl details:9080/details/0
        upstream connect error or disconnect/reset before headers
        {{< /text >}}

    1.  POST request from _sleep_ to `ratings`

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":1,"Reviewer2":1}'
        {"id":0,"ratings":{"Reviewer1":1,"Reviewer2":1}}
        {{< /text >}}

    The unauthorized access is denied as expected in the first and the second checks, but not in the third one!
    You spoiled ratings data in production! This is because Kubernetes Network Policies can only specify which
    pod/namespace can access which pod. They cannot specify HTTP methods that the pods can apply. In your case you
    want to provide read-only access for the _sleep_ pod. However, in the case of Kubernetes Network Policies it is
    either read-write, or nothing. Similarly, you cannot allow/deny traffic based on other HTTP parameters, like
    HTTP Path. To specify access policies based on HTTP parameters you have to use Istio policies.

    Delete the Kubernetes Network Policies in the next subsection and proceed to define Istio policies.

### Clean Kubernetes Network Policies

{{< text bash >}}
$ kubectl delete networkpolicy reviews ratings details
{{< /text >}}

## Istio RBAC

In this section you apply Istio [Role-based Access Control (RBAC)](/docs/concepts/security/#authorization).

1.   Secure access control in Istio is based on
     [Kubernetes Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/),
     which serve as as the [identities](https://en.wikipedia.org/wiki/Digital_identity) of the pods.
     Add Kubernetes Service Accounts to `productpage` and `reviews`.

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml
    serviceaccount "bookinfo-productpage" created
    deployment "productpage-v1" configured
    serviceaccount "bookinfo-reviews" created
    deployment "reviews-v2" configured
    deployment "reviews-v3" configured
    {{< /text >}}

1.  Store the name of your namespace in the `NAMESPACE` environment variable.
    You will need it to recognize your microservices in the logs:

    {{< text bash >}}
    $ export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    $ echo $NAMESPACE
    tutorial
    {{< /text >}}

1.   Create Istio service roles for read access to `productpage`, `reviews`, `ratings` and `details`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: productpage-viewer
    spec:
      rules:
      - services: ["productpage.$NAMESPACE.svc.cluster.local"]
        methods: ["GET"]
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: reviews-viewer
    spec:
      rules:
      - services: ["reviews.$NAMESPACE.svc.cluster.local"]
        methods: ["GET"]
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: ratings-viewer
    spec:
      rules:
      - services: ["ratings.$NAMESPACE.svc.cluster.local"]
        methods: ["GET"]
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRole
    metadata:
      name: details-viewer
    spec:
      rules:
      - services: ["details.$NAMESPACE.svc.cluster.local"]
        methods: ["GET"]
    EOF
    {{< /text >}}

1.  Create role bindings to enable read access to microservices according to the requirements of the application:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: productpage-viewer
    spec:
      subjects:
      - user: "*"
      roleRef:
        kind: ServiceRole
        name: productpage-viewer
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: reviews-viewer
    spec:
      subjects:
      - user: "cluster.local/ns/${NAMESPACE}/sa/bookinfo-productpage"
      - user: "cluster.local/ns/${NAMESPACE}/sa/sleep"
      roleRef:
        kind: ServiceRole
        name: reviews-viewer
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: details-viewer
    spec:
      subjects:
      - user: "cluster.local/ns/${NAMESPACE}/sa/bookinfo-productpage"
      - user: "cluster.local/ns/${NAMESPACE}/sa/sleep"
      roleRef:
        kind: ServiceRole
        name: details-viewer
    ---
    apiVersion: rbac.istio.io/v1alpha1
    kind: ServiceRoleBinding
    metadata:
      name: ratings-viewer
    spec:
      subjects:
      - user: "cluster.local/ns/${NAMESPACE}/sa/bookinfo-reviews"
      - user: "cluster.local/ns/${NAMESPACE}/sa/sleep"
      roleRef:
        kind: ServiceRole
        name: ratings-viewer
    EOF
    {{< /text >}}

1.  Ask the instructor (write access to the `istio-system` namespace is required) to enable
    [Istio RBAC](/docs/concepts/security/#authorization) on your namespace:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
      namespace: istio-system
    spec:
      mode: ON_WITH_INCLUSION
      inclusion:
        namespaces: [ "$NAMESPACE" ]
    EOF
    {{< /text >}}

    To enable Istio RBAC on multiple namespaces, list them in the `namespaces` field, separated by commas.

    {{< warning >}}
    After Istio RBAC is enabled on a namespace, all the traffic to microservices in the namespace is blocked unless
    explicitly allowed. This is the recommended mode according to some compliance standards.
    {{< /warning >}}

1.  Access the application's webpage and verify that the application continues to work, which would mean that the
    authorized access is allowed and you configured your policy rules correctly.

1.  Check that unauthorized access is denied.

    1.  GET request from `ratings` to `reviews`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl reviews:9080/reviews/0
        RBAC: access denied
        {{< /text >}}

    1.  GET request from `ratings` to `details`

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl details:9080/details/0
        RBAC: access denied
        {{< /text >}}

    1.  POST request from _sleep_ to `ratings`

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":1,"Reviewer2":1}'
        RBAC: access denied
        {{< /text >}}

    The unauthorized access is denied as expected.

    1.  Note that `GET` access is allowed for `sleep`:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X GET ratings:9080/ratings/0
    {"id":0,"ratings":{"Reviewer1":5,"Reviewer2":4}}
    {{< /text >}}

In this module you used Kubernetes Network Policies and Istio RBAC rules to enforce access control requirements for your
application. Note that Istio RBAC provides more flexibility than Kubernetes Network Policies since it allows to specify
HTTP parameters of the access, in your case which HTTP method which microservice is allowed to apply on which
microservice. Also note that you can follow the
[Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) principle and apply Kubernetes
Network Policies together with Istio RBAC.
