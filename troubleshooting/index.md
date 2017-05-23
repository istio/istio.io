---
title: Troubleshooting Guide
overview: Practical advice on practical problems with Istio
layout: troubleshooting
type: markdown
---
{% include home.html %}

# Troubleshooting Guide

Oh no! You have some problems? Let us help.

## Envoy won't connect to my HTTP/1.0 service

Envoy requires HTTP/1.1 or HTTP/2 traffic for upstream services. For example, when using [NGINX](https://www.nginx.com/) for serving traffic behind Envoy, you will need to set the [proxy_http_version](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version) directive in your NGINX config to be "1.1", since the NGINX default is 1.0

Example config:	

```
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
```

## Running multiple replicas of Mixer does not work as expected 

For the {{site.data.istio.version}} release, Mixer **must** be configured to run as a single instance within a cluster. We are working on improvements at the protocol, configuration, and deployment levels to support multiple instance and high-availability deployments. We expect to remove this limitation shortly after the initial {{site.data.istio.version}} release.

Running multiple replicas of Mixer will lead to issues with configuration updates not propagating properly and improperly-enforced quotas (for the memQuota adapter).

## The Mixer pod was restarted and I lost my configuration updates

For the {{site.data.istio.version}} release, Mixer configuration is stored in a local file system-based store. By default, Mixer is not configured to use a Kubernetes persistent volume.

There are a few possible workarounds:

1.  Save configuration updates to a common location and script the application of these updates via istioctl.
1.  Configure a persistent volume and update the Mixer deployment specs to use that volume for the file system store.

Work is ongoing to provide a highly-available, persistent configuration store for Mixer. We expect this to work to land immediately following the initial {{site.data.istio.version}} release.

### Configuring a persistent volume for Mixer config

A Mixer deployment can be modified to use Kubernetes [`ConfigMaps`](https://kubernetes.io/docs/tasks/configure-pod-container/configmap/) to provide persistent access to Mixer config. Kubernetes `ConfigMaps` are preserved across restarts and allow running multiple replicas of Mixer.

Note: `istioctl` is not usable for runtime updates to Mixer configuration when this approach is used (the updates will not persist).

Here is an example ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mixer-config2
data:
  adapters.yml: |-
    # Config-map
    subject: global
    adapters:
      …
  descriptors.yml: |-
    subject: namespace:ns
    revision: "2022"
    …

apiVersion: v1
kind: ConfigMap
metadata:
  name: mixer-configsubjects
data:
  rules.yml: |-
    …
     …

 lifecycle:
            postStart:
              exec:
                command: ["/bin/sh", "-c", "cp /etc/opt/mixer2/configroot/scopes/global/adapters.yml /etc/opt/mixer/configroot/scopes/global/adapters.yml; cp /etc/opt/mixer2/configroot/scopes/global/descriptors.yml /etc/opt/mixer/configroot/scopes/global/descriptors.yml; cp /etc/opt/mixer2/configroot/scopes/subjects/rules.yml /etc/opt/mixer/configroot/scopes/global/subjects/global/rules.yml" ]
 
      volumeMounts:
          - mountPath: /etc/opt/mixer2/configroot/scopes/subjects
            name: configsubjects
          - mountPath: /etc/opt/mixer2/configroot/scopes/global
            name: config
      volumes:
        - name: config
          configMap:
            name: mixer-config2
        - name: configsubjects
          configMap:
            name: mixer-configsubjects
```

## I need to debug an issue with the service mesh. How do I debug?

### With [GDB](https://www.gnu.org/software/gdb/)

To debug Istio with `gdb`, you will need to run the debug images of Envoy / Mixer / Manager. A recent `gdb` and the golang extensions (for Mixer/Manager or other golang components) is required.

1.  Kubectl exec -it PODNAME -c [proxy | mixer | manager]
1.  Find process ID: ps ax 
1.  gdb -p PID binary
1.  For go: info goroutines, goroutine x bt

### With [Tcpdump](http://www.tcpdump.org/tcpdump_man.html)

Tcpdump doesn't work in the sidecar pod - the container doesn't run as root. However any other container in the same pod will see all the packets, since the network namespace is shared. `iptables` will also see the pod-wide config. 

Communication between Envoy and the app happens on 127.0.0.1, and is not encrypted. 

## Envoy is crashing under load

Check your `ulimit -a`. Many systems have a 1024 open file descriptor limit by default which will cause Envoy to assert and crash with:

```bash
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
```

Make sure to raise your ulimit. Example: `ulimit -n 16384`
