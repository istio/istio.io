---
title: Security policies with Istio
overview: Apply RBAC policies with Istio

weight: 170

---

Note that in your current setting, any microservice can access any other microservice.
If any of the microservices is compromised, the hackers can attack all the other microservices.
You want to specify policies to limit access similar to the
[Need to know](https://en.wikipedia.org/wiki/Need_to_know#In_computer_technology]) principle: only the microservices
that need to access other microservices should be allowed to access the microservices they need.

In our case, _ratings_ microservice can be accessed by _reviews_ only. Access from _productpage_ and from _details_
should not be allowed.
_productpage_ and _details_ should not be able to access _ratings_, neither accidentally nor intentionally.

In the same way, the following access must be allowed:

* _productpage_ can access _reviews_ and _details_
* _reviews_ can access _ratings_
* the testing pod, _sleep_, can access any microservice
* all the access is read-only, which means that only HTTP GET method can be applied on _ratings_.
HTTP POST method must be prohibited.
* all other access must be prohibited

In this module you add security policies to enforce the access requirements above.

1.  Verify that any microservice can access any microservice, including sending POST requests to _ratings_.

    1.  GET request from _ratings_ to _reviews_

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl reviews:9080/reviews/0
        {"id": "0","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}
        {{< /text >}}

    1.  GET request from _ratings_ to _details_

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl details:9080/details/0
        {"id":0,"author":"William Shakespeare","year":1595,"type":"paperback","pages":200,"publisher":"PublisherA","language":"English","ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
        {{< /text >}}

    1.  POST request from _sleep_ to _ratings_

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":1,"Reviewer2":1}'
        {"id":0,"ratings":{"Reviewer1":1,"Reviewer2":1}}
        {{< /text >}}

        Access the application's webpage. You see one-star ratings from both reviewers! Fix it ASAP so no fake
        ratings will be displayed in production.

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":5,"Reviewer2":4}'
        {"id":0,"ratings":{"Reviewer1":1,"Reviewer2":1}}
        {{< /text >}}

1.   Secure access control in Istio is based on
     [Kubernetes Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
     as the identities of the pods. Add Kubernetes Service Accounts to _productpage_ and _reviews_.

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml
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

1.   Create Istio service roles for read access to _productpage_, _reviews_, _ratings_ and _details_.

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
    kind: RbacConfig
    metadata:
      name: default
      namespace: istio-system
    spec:
      mode: ON_WITH_INCLUSION
      inclusion:
        namespaces: [ "$NAMESPACE" ]
    EOF
    {{< /text >}}

1.  Access the application's webpage and verify that the application continues to work, which would mean that the
    authorized access is allowed and you configured your policy rules correctly.

1.  Check that unauthorized access is denied.

    1.  GET request from _ratings_ to _reviews_

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl reviews:9080/reviews/0
        RBAC: access denied
        {{< /text >}}

    1.  GET request from _ratings_ to _details_

        {{< text bash >}}
        $  kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl details:9080/details/0
        RBAC: access denied
        {{< /text >}}

    1.  POST request from _sleep_ to _ratings_

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep -- curl -X POST ratings:9080/ratings/0 -d '{"Reviewer1":1,"Reviewer2":1}'
        RBAC: access denied
        {{< /text >}}

    The unauthorized access is denied as expected.
