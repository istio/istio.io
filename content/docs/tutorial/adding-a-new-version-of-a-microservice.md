---
title: Add a new version of reviews
overview: Deploy and release a new version of a microservice.

weight: 05

---

Let's deploy a new version of the _reviews_ microservice, the one that will return the ratings provided by reviewers, as a number of stars, with the color of stars. In real life, we would perform lint tests, unit tests, integration tests, end-to-end tests and tests in a staging environment.

1. Deploy the new version of the _reviews_ microservice without the `app` label. Without the `app` label, our new version of the microservice will not be selected to provide the _reviews_ service. As such, it will not be called by the production code.
   ```bash
   kubectl apply -f samples/bookinfo/istio.io-tutorial/bookinfo-reviews-v2-without-app-label.yaml
   ```

2. Let's access our application and see that the deployed microservice did not disrupt it. So far so good.

3. Now let's test the new version of our microservice from inside the cluster. We will use the `sleep` container we deployed earlier. Note that our new version hits the production pods of the _ratings_ microservice during the test. Also note that we have to access our new version of the microservice by its pod IP, since it is not selected for the _reviews_ service.

  1. Get the IP of the pod:
     ```bash
     DETAILS_V2_POD_IP=$(kubectl get pod -l version=v2 -o jsonpath='{.items[0].status.podIP}')
     ```
  2. Send a request to the pod and see that it returns the correct result:
    ```bash
    kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl $DETAILS_V2_POD_IP:9080/reviews/7
    ```
  3. Perform primitive _load testing_ by sending a request 10 times in a row:
     ```bash
     kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') bash
     for i in {1..10}; do curl -o /dev/null -s -w "%{http_code}\n" <the value of DETAILS_V2_POD_IP>:9080/reviews/7; done
     ```
4. Now we are rather confident that our new version of _reviews_ will work and we will release it. We will release a single replica of it into production - the real production traffic will arrive to our new version. With the current setting, 75% of the traffic will arrive to the old version (three pods of the old version) and 25% will arrive to the new version (one pod).

   To release _reviews v2_ we will undeploy our new version and redeploy it with the _app_ label, so it will become addressable by the _reviews_ service.

   ```bash
   kubectl delete -f samples/bookinfo/istio.io-tutorial/bookinfo-reviews-v2-without-app-label.yaml
   kubectl apply -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml
   ```

   We can check the labels of our pod:
   ```
   kubectl get pods --show-labels -l version=v2
   ```
5. Now we access the application web page and observe that the black stars appear for ratings! We will hit the page several times and notice that sometimes the page is returned with stars (approximately 25% of the time) and sometimes without stars (approximately 75% of the time).

6. If we encounter any problems we can quickly undeploy the new version, so only the old version will be used:
   ```bash
   kubectl delete -f samples/bookinfo/kube/bookinfo-reviews-v2.yaml
   ```

7. Next we will increase the replicas of our new version. We can do it gradually, carefully checking that the number of errors does not increase:
   ```bash
   kubectl scale deployment reviews-v2 --replicas=3
   ```
8. Now we decommission the old version
   ```bash
   kubectl delete deployment reviews-v1
   ```

9. Accessing the web page of the application will return reviews with black stars only.

We performed the update of _reviews_ pretty well. First, we deployed the new version without directing to it any production traffic. We tested it in the production environment, on test traffic. We checked that the new version new version provides correct results. We released the new version, gradually increasing the production traffic to it. Finally, we decommissioned the old version.

It all went well, however we want to improve our release strategy. First, we want to allow our testers to test the new version end-to-end in production. For that we need an ability to drive traffic to our new version by request parameters, for example by the user name stored in a cookie. In addition, we would like to perform _shadowing_ of the production traffic to our new version and checking if our new version provides incorrect results or produces any errors. Finally, we would like to be more fine-grained with our rollout. We would like to release our new version to 10% of the users and then increase it by 10%. Kubernetes is unable to help with any of these tasks in a straightforward way.

Now we have two choices:
1. Implement the required functionality in the code. Most of the functionality is already available in various libraries, for example in the Netflix's [Hystrix](https://github.com/Netflix/Hystrix) library  for the Java programming language. However, now we have to change our code to call the functions from the libraries. We have to put additional effort, our code will bloat, business logic will be mixed with reporting, routing, policies, networking logic. Since our microservices use different programming languages we have to learn, use, update multiple libraries. We are not happy with this option.
2. Use a service mesh. In a service mesh, we put all the reporting, routing, policies, security logic in _sidecar_ proxies, injected into our pods *transparently* to our application. The business logic remains in the code of the application, no changes are required to the application code.

Enters [Istio service mesh]({{home}}). Istio can perform the tasks mentioned here and much more. In the next modules we will explore various features Istio provides.

