---
title: DeploymentConflictingPorts
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when two services selecting the same workload with same `targetPort` but different ports.

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

In this example, service `nginx-a` and service `nginx-b` selecting the same workload `nginx` with same `targetPort` but different ports.

## How to resolve

This must be fixed one of two ways. Make both services use the same `port`, or make both services use different `targetPorts`.

Selecting the former option will require reconfiguring the clients of one of the services to connect to a different port. Selecting the latter option will require configuring the workload pods of one of the services to listen on the same target port as the other service.
