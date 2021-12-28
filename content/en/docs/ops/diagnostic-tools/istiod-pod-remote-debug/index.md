---
title: Remote Debugging of Istiod Pod
description: Describes procedure to remote debug istiod pod using an IDE like IntelliJ or GoLand.
weight: 20
keywords: [debug,remote,istiod,pod,pilot]
aliases:
    - /docs/ops/troubleshooting/istiod-pod-remote-debug
owner: istio/wg-user-experience-maintainers
test: no
---

Istio deploys its control plane as a container/pod on Kubernetes. Debugging in a container environment can be hard, and as developers we often tend to use very tedious methods to debug issues which is time consuming. As an example, imagine that you have a case where the traffic is not managed in the right way in a customer deployment, or you are trying to develop a new feature on Istio and hits an issue due to wrong configuration being pushed to the sidecar.

For the production cluster issue or even the local feature development issue, a developer would try to
write some additional debug code in the form of logs, build a new debug image, and deploy it on a local cluster to check the output and logs. This procedure is often tedious, and wastes a lot of debugging
and development cycles. A more efficient way is to use a debugger to attach to the Kubernetes pod, and set a breakpoint in the relevant code areas to analyze the behavior by executing tests.

This document explains how to run a debugger on istiod through the [`IntelliJ GoLand IDE`](https://www.jetbrains.com/go/download/). We will see how to set up remote debugging in order to step through and debug the Istio Pilot code as we deploy applications and apply service mesh configurations. The principles and procedures will be more or less same on the Pilot side for other IDEs like [`Visual Studio Code (VS Code)`](https://code.visualstudio.com/download), and even other pods in Istio like ingress/egress gateway.

## Prerequisites and environment options

This section describes the environment that was used to setup the debug environment being discussed in the document. However any other Istio supported environments must work in the same way with similar procedure.

* Operating system: macOS Big Sur 11.6
* A Kubernetes cluster with Docker Desktop: 4.3.1
* Istio service mesh
* kubectl
* Delve (the debugger for Go)
* IntelliJ GoLand as IDE

## Pilot Dockerfile Configuration for Delve

Delve is the official debugger for the Go programming language. Delve should be easy to invoke and use, and provides a simple, full-featured debugging tool for Go. To debug the istiod pod remotely,
it is important to make some changes in the container configuration so that it supports Delve based debugging.

* Clone the [`istio repository`](https://github.com/istio/istio.git)
* To add the Delve binary to the docker image, and start the executable with delve debugging, include
the below additional lines to the pilot [`Dockerfile`]({{<github_blob>}}//pilot/docker/Dockerfile.pilot) :

{{< text bash >}}
$ git diff pilot/docker/Dockerfile.pilot
@@ -7,6 +7,9 @@ ARG BASE_VERSION=latest
 # The following section is used as base image if BASE_DISTRIBUTION=debug
 FROM gcr.io/istio-release/base:${BASE_VERSION} as debug

+FROM gcr.io/istio-testing/build-tools:latest as build-env
+RUN go get github.com/go-delve/delve/cmd/dlv
+
 # The following section is used as base image if BASE_DISTRIBUTION=distroless
 FROM gcr.io/istio-release/distroless:${BASE_VERSION} as distroless

@@ -17,10 +20,13 @@ FROM ${BASE_DISTRIBUTION:-debug}
 ARG TARGETARCH
 COPY ${TARGETARCH:-amd64}/pilot-discovery /usr/local/bin/pilot-discovery

+COPY --from=build-env /gobin/dlv /usr/local/bin/dlv
+
 # Copy templates for bootstrap generation.
 COPY envoy_bootstrap.json /var/lib/istio/envoy/envoy_bootstrap_tmpl.json
 COPY gcp_envoy_bootstrap.json /var/lib/istio/envoy/gcp_envoy_bootstrap_tmpl.json

 USER 1337:1337
-
-ENTRYPOINT ["/usr/local/bin/pilot-discovery"]
+EXPOSE 40000
+ENTRYPOINT ["/usr/local/bin/dlv", "--continue", "--accept-multiclient", "--listen=:40000", "--check-go-version=false", "--headless=true", "--api-version=2", "--log=true", "--log-output=debugger,debuglineerr,gdbwire,lldbout,rpc", "exec", "/usr/local/bin/pilot-discovery", "--"]
{{< /text >}}

Note that the additional debug and log lines in the ENTRYPOINT are needed only for delve debugging in case
anything is not working as expected.

* Build a debug image of Pilot by using the below command from the repository root.
`make DEBUG=1 docker.pilot`

* Use the newly built debug image in your Istio deployment.

## Istiod Deployment File Changes for Delve Debugging

* Edit the istiod deployment to set `readOnlyRootFilesystem` to false. This can be even done during the
  build and install time by changing the value at [`deployment.yaml`]({{<github_blob>}}//manifests/charts/istio-control/istio-discovery/templates/deployment.yaml#L166).
  If not done during the installation time, follow the below procedure to edit the deployment file at runtime by running the below command and saving the file after making the change.

  {{< text yaml >}}

  $ kubectl edit deployment istiod -n istio-system

        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            drop:
            - ALL
          `readOnlyRootFilesystem: false`
          runAsGroup: 1337
          runAsNonRoot: true
          runAsUser: 1337

  {{< /text >}}

* Make sure the istiod pod has started in debug mode by inspecting the logs.

 {{< text bash >}}
    $ `kubectl get pods -n istio-system`
    NAME                                    READY   STATUS    RESTARTS       AGE
    istio-egressgateway-8787466f6-pkn9b     1/1     Running   0              12d
    istio-ingressgateway-7dc657bdfb-vcnw5   1/1     Running   0              12d
    `istiod-7d46956dbb-77vtc`               1/1     Running   1 (6d3h ago)   6d21h
    $
    $ `kubectl logs -n istio-system istiod-7d46956dbb-77vtc | head`
    2021-12-22T11:01:21Z warning layer=rpc Listening for remote connections (connections are not authenticated nor encrypted)
    2021-12-22T11:01:21Z debug layer=rpc API server pid = 1
    2021-12-22T11:01:21Z `info layer=debugger launching process with args: [/usr/local/bin/pilot-discovery discovery` --monitoringAddr=:15014 --log_output_level=default:info --domain cluster.local --keepaliveMaxServerConnectionAge 30m]
    API server listening at: [::]:40000
    2021-12-22T11:01:23Z debug layer=rpc serving JSON-RPC on new connection
    2021-12-22T11:01:23Z debug layer=rpc <- RPCServer.SetApiVersion(api.SetAPIVersionIn{"APIVersion":2})
    2021-12-22T11:01:23Z debug layer=rpc -> *api.SetAPIVersionOut{} error: ""
    2021-12-22T11:01:23Z debug layer=rpc (async 2) <- RPCServer.Command(api.DebuggerCommand{"name":"continue","ReturnInfoLoadConfig":null})
    2021-12-22T11:01:23Z debug layer=debugger continuing
 {{< /text >}}

## Attach Go(Delve) to istiod pod

We use Kubernetes port forwarding to attach to the running istiod pod in the Kubernetes cluster in order to debug it. We need to forward the host port to the pilot pod 40000 port on which delve is listening. Please
note that the port being used here will be the listen port that was used in the ENTRYPOINT of Pilot Dockerfile.

 {{< text bash >}}
    $ `kubectl port-forward --address localhost deployment.apps/istiod 40000:40000`
 {{< /text >}}

## Debugging istiod remotely from IDE

Once you have the whole configuration ready, open the Istio source code in IntelliJ GoLand.
* Click on Run/Debug Configuration, and then click on the '+' icon to add a new Go Remote Configuration.
  Specify the right host and port based on where your istiod pod is running, in the current case it will be
  localhost and 40000.

  {{< image width="80%" link="./goland-add-config.png" caption="Add Go Remote Debug Configuration For Istiod" >}}

* Now set a breakpoint in the code from the IDE. The breakpoint would depend on the functionality you are going to test and the code area you want to debug.

* Start the Go Remote Debugger from the IDE as shown in the below diagram. If port forwarding is working correctly, and if the container is built properly with Delve debug configuration, the Debugger will attach to the istiod remote pod.
  {{< image width="80%" link="./goland-start-debugger.png" caption="Start the Debugger" >}}

* Apply some Istio configuration. For example, you can create any resource from the [`bookinfo application`](/docs/examples/bookinfo/#deploying-the-application). Now you would be able to see the respective breakpoint in the code getting hit, and you can step through the code as needed.
  {{< image width="80%" link="./goland-breakpoint-hit.png" caption="Hitting the listener Breakpoint on Configuration" >}}
