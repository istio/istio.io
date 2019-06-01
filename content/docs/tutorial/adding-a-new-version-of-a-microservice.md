---
title: Add a new version of reviews
overview: Deploy and release a new version of a microservice.

weight: 50

---

In this module you deploy a new version of the `reviews` microservice, namely _v2_, the one that will return the ratings
provided by reviewers, as a number of stars, with the color of stars. In real life, you would perform lint tests,
unit tests, integration tests, end-to-end tests and tests in a staging environment, before the deployment.

1.  Deploy the new version of the `reviews` microservice without the `app=reviews` label. Without that label, the new
    version will not be selected to provide the `reviews` service. As such, it will not be called by the production code.
    Run the following command to deploy the `reviews` microservice version 2, while replacing the label `app=reviews` by `app=reviews_test`:

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | sed 's/app: reviews/app: reviews_test/' | kubectl apply -l app=reviews_test,version=v2 -f -
    deployment "reviews-v2" created
    {{< /text >}}

1.  Access your application and see that the deployed microservice did not disrupt it. So far so good.

1.  Test the new version of your microservice from inside the cluster. Use the testing container you deployed
    earlier. Note that your new version hits the production pods of the `ratings` microservice during the test. Also
    note that you have to access your new version of the microservice by its pod IP, since it is not selected for the
    `reviews` service.

    1.  Get the IP of the pod:

        {{< text bash >}}
        $ REVIEWS_V2_POD_IP=$(kubectl get pod -l app=reviews_test,version=v2 -o jsonpath='{.items[0].status.podIP}')
        {{< /text >}}

    1.  Send a request to the pod and see that it returns the correct result:

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl $REVIEWS_V2_POD_IP:9080/reviews/7
        {"id": "7","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
        {{< /text >}}

    1.  Perform primitive _load testing_ by sending a request 10 times in a row:

        {{< text bash >}}
        $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do curl -o /dev/null -s -w '%{http_code}\n' $REVIEWS_V2_POD_IP:9080/reviews/7; done"
        200
        200
        ...
        {{< /text >}}

1.  Now you are rather confident that your new version of `reviews` will work and you can release it.
    You will release a single replica of it into production so the real production traffic will arrive to your new
    version. With the current setting, 75% of the traffic will arrive to the old version (three pods of the old
    version) and 25% will arrive to the new version (one pod).

    To release _reviews v2_ redeploy the new version with the `app=reviews` label, so it will become addressable by
    the `reviews` service.

    {{< text bash >}}
    $ kubectl label pods -l version=v2 app=reviews --overwrite
    pod "reviews-v2-79c8c8c7c5-4p4mn" labeled
    {{< /text >}}

1.  Now you access the application web page and observe that the black stars appear for ratings! You can hit the page
    several times and notice that sometimes the page is returned with stars (approximately 25% of the time) and
    sometimes without stars (approximately 75% of the time).

1.  If you encounter any problems you can quickly undeploy the new version, so only the old version will be used:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v2
    $ kubectl delete pod -l app=reviews,version=v2
    deployment "reviews-v2" deleted
    pod "reviews-v2-79c8c8c7c5-4p4mn" deleted
    {{< /text >}}

    To put the new version back:

    {{< text bash >}}
    $ kubectl apply -l app=reviews,version=v2 -f {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml
    deployment "reviews-v2" created
    {{< /text >}}

1.  Next you increase the replicas of your new version. You can do it gradually, carefully checking that the number of
    errors does not increase:

    {{< text bash >}}
    $ kubectl scale deployment reviews-v2 --replicas=3
    deployment "reviews-v2" scaled
    {{< /text >}}

1.  Now you can decommission the old version:

    {{< text bash >}}
    $ kubectl delete deployment reviews-v1
    deployment "reviews-v1" deleted
    {{< /text >}}

1.  Accessing the web page of the application will return reviews with black stars only.

You performed the update of `reviews` pretty well. First, you deployed the new version without directing to it any
production traffic. You tested it in the production environment, on test traffic.
You checked that the new version new version provides correct results. You released the new version,
gradually increasing the production traffic to it. Finally, You decommissioned the old version.

It all went well, however you want to improve your release strategy. First, you want to allow your testers to test the
new version end-to-end in production.
For that you need an ability to drive traffic to your new version by request parameters, for example by the user name
stored in a cookie. In addition, you would like to perform _shadowing_ of the production traffic to your new version and
checking if your new version provides incorrect results or produces any errors. Finally, you would like to be more
fine-grained with your rollout. You would like to release your new version to 10% of the users and then increase it by
10%. Kubernetes is unable to help with any of these tasks in a straightforward way.

Now you have two choices:

1. Implement the required functionality in the application code.
Most of the functionality is already available in various libraries, for example in the Netflix's
[Hystrix](https://github.com/Netflix/Hystrix) library  for the Java programming language.
However, now You have to change your code to call the functions from the libraries.
You have to put additional effort, your code will bloat, business logic will be mixed with reporting, routing, policies,
networking logic.
Since your microservices use different programming languages You have to learn, use, update multiple libraries.
You are not happy with this option.

1. Use a _service mesh_. In a service mesh, you put all the reporting, routing, policies, security logic in _sidecar_
proxies, injected into your pods *transparently* to your application. The business logic remains in the code of the
application, no changes are required to the application code.

Enters [Istio service mesh](/). Istio can perform the tasks mentioned here and much more.
In the next modules you will explore various features Istio provides.
