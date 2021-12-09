---
title: Why is my CORS configuration not working?
weight: 40
---

After applying [CORS configuration](/docs/reference/config/networking/virtual-service/#CorsPolicy), you may find that seemingly nothing happened and wonder what went wrong.
CORS is a commonly misunderstood HTTP concept that often leads to confusion when configuring.

To understand this, it helps to take a step back and look at [what CORS is](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) and when it should be used.
By default, browsers have restrictions on "cross origin" requests initiated by scripts.
This prevents, for example, a website `attack.example.com` from making a JavaScript request to `bank.example.com` and stealing a users sensitive information.

In order to allow this request, `bank.example.com` must allow `attack.example.com` to perform cross origin requests.
This is where CORS comes in. If we were serving `bank.example.com` in an Istio enabled cluster, we could configure a `corsPolicy` to allow this:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bank
spec:
  hosts:
  - bank.example.com
  http:
  - corsPolicy:
      allowOrigins:
      - exact: https://attack.example.com
...
{{< /text >}}

In this case we explicitly allow a single origin; wildcards are common for non-sensitive pages.

Once we do this, a common mistake is to send a request like `curl bank.example.com -H "Origin: https://attack.example.com"`, and expect the request to be rejected.
However, curl and many other clients will not see a rejected request, because CORS is a browser constraint.
The CORS configuration simply adds `Access-Control-*` headers in the response; it is up to the client (browser) to reject the request if the response is not satisfactory.
In browsers, this is done by a [Preflight request](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests).
