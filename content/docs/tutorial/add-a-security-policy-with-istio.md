---
title: Security policy with Istio
overview: Add a whitelist security policy.

weight: 17

---

Note that in our setting, any microservice can access any other microservice. If any of the microservices is compromised, it can attack all the other microservices.
In this module we will add a [security policy]({{home}}/docs/reference/config/istio.mixer.v1.config.html) that states that only _reviews_ microservice can access _ratings_ microservice.

1. Let's see that without a security policy, our _sleep_ microservice can call the _ratings_ microservice.
   ```bash
   kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
   ```

   We will get `{"id":7,"ratings":{"Reviewer1":5,"Reviewer2":4}}` as an output

2. Let's define a security policy (a whitelist) that will allow only the _reviews_ microservice to access the _ratings_ microservice:
   ```bash
   istioctl create -f samples/bookinfo/istio.io-tutorial/whitelist-for-ratings.yaml
   ```

3. Now let's see that the _sleep_ microservice cannot access the _ratings_ microservice, as expected:
   ```bash
   kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
   ```

   This time we will get the following error: `NOT_FOUND:whitelist-for-ratings.listchecker.default:sleep is not whitelisted`, as expected.

4. Access the webpage of the application and check that it works as expected. It will mean that the _reviews_ microservice can still access the _ratings_ microservice, as expected.

