---
title: Istio-Manager
type: markdown
---
Istio-Manager serves as an interface between the user and Istio, collecting and validating configuration and propagating it to the
various Istio components. It abstracts environment-specific implementation details from Mixer and Envoy, providing them with an
abstract representation of the user’s services 
that is independent of the underlying platform.
