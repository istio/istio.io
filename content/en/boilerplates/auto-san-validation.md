---
---
{{< tip >}}
Istio has `auto_sni` and `auto_san_validation` enabled by default. This means, whenever there is no explicit `sni` set in your `DestinationRule`, transport socket SNI for new upstream connections will be set based on the downstream HTTP host/authority header. If there are no `subjectAltNames` set in the `DestinationRule` when `sni` is unset, `auto_san_validation` will kick in, and the upstream-presented certificate for new upstream connections will be automatically validated based on the downstream HTTP host/authority header.
{{< /tip >}}
