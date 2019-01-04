---
title: Is it possible to send x-request-id back when using Istio with ZipKin?
weight: 120
---

Istio doesn't know when you make outbound calls from your application for which original request it was for unless you copy the headers.
If you copy the headers, you can include it in your response headers too.

