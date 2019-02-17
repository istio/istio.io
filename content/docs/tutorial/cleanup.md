---
title: Cleanup
overview: Remove the participant's namespace, ingress and roles.

weight: 990

---

1.  Delete the tutorial's namespace:

    {{< text bash >}}
    $ kubectl delete namespace $NAMESPACE
    {{< /text >}}

2.  Delete the tutorial-related resources in the `istio-system` namespace (requires write access to `istio-system`):

    {{< text bash >}}
    $ kubectl delete ingress istio-system -n istio-system
    $ kubectl delete role istio-system-access -n istio-system
    $ kubectl delete rolebinding $NAMESPACE-istio-system-access -n istio-system
    {{< /text >}}
