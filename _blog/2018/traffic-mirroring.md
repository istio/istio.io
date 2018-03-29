---
title: "Traffic Mirroring with Istio for Testing in Production"
overview: An introduction to safer, lower-risk deployments and release to production
publish_date: February 8, 2018
subtitle: Routing rules for HTTP traffic
attribution: Christian Posta

order: 91

layout: blog
type: markdown
redirect_from: "/blog/traffic-mirroring.html"
---
{% include home.html %}

Trying to enumerate all the possible combinations of test cases for testing services in non-production/test environments can be daunting. In some cases, you'll find that all of the effort that goes into cataloging these use cases doesn't match up to real production use cases. Ideally, we could use live production use cases and traffic to help illuminate all of the feature areas of the service under test that we might miss in more contrived testing environments. 

Istio can help here. With the release of [Istio 0.5.0]({{home}}/about/notes/0.5.html), Istio can mirror traffic to help test your services. You can write route rules similar to the following to enable traffic mirroring:


```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: mirror-traffic-to-httbin-v2
spec:
  destination:
    name: httpbin
  precedence: 11
  route:
  - labels:
      version: v1
    weight: 100
  - labels: 
      version: v2
    weight: 0
  mirror:
    name: httpbin
    labels:
      version: v2
``` 

A few things to note here:

* When traffic gets mirrored to a different service, that happens outside the critical path of the request
* Responses to any mirrored traffic is ignored; traffic is mirrored as "fire-and-forget"
* You'll need to have the 0-weighted route to hint to Istio to create the proper Envoy cluster under the covers; [this should be ironed out in future releases](https://github.com/istio/istio/issues/3270).

Learn more about mirroring by visiting the [Mirroring Task]({{home}}/docs/tasks/traffic-management/mirroring.html) and see a more
[comprehensive treatment of this scenario on my blog](https://blog.christianposta.com/microservices/traffic-shadowing-with-istio-reduce-the-risk-of-code-release/).