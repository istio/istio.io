---
title: Troubleshooting Networking Issues
description: Describes tools and techniques that can be used to root cause networking issues
weight: 5
---

The following is a general high-level trouble shooting guide for networking issues in Kubernetes environment.

## Pod reachability issues

Usually, the first thing you want to check is whether or not the pod associated with your app has been allocated a valid IP address. This can be done by examining the pod status with `kubectl get pods -o wide`. In addition, check whether or not the service associated with the app has been properly created with a service IP. Assuming the pod is up and running and an IP is allocated, ping the pod IP and make sure it can be pinged. Otherwise, a few things that may be tried to isolate the issue:

* Where is it that you’d like to access the app: from inside the same cluster or outside the cluster. If it’s outside the cluster, find out if port-forward is needed, if the right service type is configured for the service associated with the app, etc. If port-forward is needed, use the `kubectl port-forward` command to configure it.
* Ping the node where the pod is running.
* Check route table to make sure that there is a route to the pod IP: `ip route` or `route -n`.
* Check to make sure that the return packet path is also properly configured. This involves checking the route tables, iptables, etc, in the node where the pod is running.
* Check iptables to make sure that packets are not dropped.

## Service naming and service discovery

If service discovery fails,

* check if the service name associated with the app can be properly resolved: login to any other pod’s shell, use `nslookup` or `dig`, to find out if the name can be resolved. Otherwise, check to make sure that
    * `kube-dns` (if used) is running properly
    * `/etc/resolve.conf` is properly configured
* check if the port associated with the app has been opened in the pod: login to the pod or its namespace, and use `netstat` to find out.

## Connection issues

If your app runs a web service, you can `curl` the URLs that the app supports. If it returns errors such as ‘connection refused’, or empty content,

* check if `mTLS` has been enabled. And if it is, the flags in your curl command are correct. Refer to [Mutual TLS](docs/tasks/security/mutual-tls/#verifying-keys-and-certificates-installation).
* verify that the port used is correct and has been opened for communication.
* verify that the services that the app is calling are accessible and return successfully. This can be done by checking the sidecar logs of the app and the services with `kubectl log`.
* verify that iptables has been properly configured for the service associated with the app.
* verify that the app's envoy sidecar is up and running. Especially, verify that the sidecar has been successfully connected with istio Pilot. Refer to [Verifying connectivity to Istio Pilot](help/ops/misc/#verifying-connectivity-to-istio-pilot).
* verify that the app's envoy sidecar has no significant errors in its log, especially errors with regard to mesh configuration.
* check Pilot's log and make sure that it doesn't contain errors related to the app.
* verify that envoy has been configured properly for the service associated with the app to work. Refer to [Debugging Envoy and Pilot](help/ops/traffic-management/proxy-cmd/) on using `istioctl proxy-status` and `istioctl proxy-config` to do so.

Another useful tool to check connection issues is `nc` or `netcat`, which may be useful for gRPC applications.
