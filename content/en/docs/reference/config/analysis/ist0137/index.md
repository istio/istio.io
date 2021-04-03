---
title: DeploymentConflictingPorts
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two services select the same workload with the same `targetPort` but different `port`s.

## An example

Consider an Istio mesh with the following services:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx-a
spec:
  ports:
    - port: 8080
      protocol: TCP
      targetPort: 80
  selector:
    app: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-b
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: nginx
{{< /text >}}

In this example, service `nginx-a` and service `nginx-b` select the same workload `nginx` with the same `targetPort` but different `port`s.

## How to resolve

This may be fixed in one of two ways:

- Make both services use the same `port`. This will require reconfiguring the clients of one of the services to connect to a different `port`.
- Make both services use different `targetPort`s. This will require configuring the workload pods of one of the services to listen on the same `targetPort` as the other service.
