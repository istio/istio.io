---
title: Does Istio Auth support authorization?
order: 110
type: markdown
---
{% include home.html %}

Not currently - but we are working on it. At the moment, we only support the kubernetes service account as the principal identity in Istio Auth. We are investigating using [JWT](https://jwt.io/) together with mutual TLS to support enhanced authentication and authorization.
