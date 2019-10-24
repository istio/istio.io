---
title: Provisioning Identity through SDS
description: Shows how to enable SDS (secret discovery service) for Istio identity provisioning.
weight: 70
keywords: [security,auth-sds]
---

This task shows how to enable
[SDS (secret discovery service)](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration)
for Istio identity provisioning.

Prior to Istio 1.1, the keys and certificates of Istio workloads were generated
by Citadel and distributed to sidecars through secret-volume mounted files,
this approach has the following minor drawbacks:

* Performance regression during certificate rotation:
  When certificate rotation happens, Envoy is hot restarted to pick up the new
  key and certificate, causing performance regression.

* Potential security vulnerability:
  The workload private keys are distributed through Kubernetes secrets,
  with known
  [risks](https://kubernetes.io/docs/concepts/configuration/secret/#risks).

These issues are addressed in Istio 1.1 through the SDS identity provision flow.
The workflow can be described as follows.

1. The workload sidecar Envoy requests the key and certificates from the Citadel
   agent: The Citadel agent is a SDS server, which runs as per-node `DaemonSet`.
   In the request, Envoy passes a Kubernetes service account JWT to the agent.

1. The Citadel agent generates a key pair and sends the CSR request to Citadel:
   Citadel verifies the JWT and issues the certificate to the Citadel agent.

1. The Citadel agent sends the key and certificate back to the workload sidecar.

This approach has the following benefits:

* The private key never leaves the node: It is only in the Citadel agent
  and Envoy sidecar's memory.

* The secret volume mount is no longer needed: The reliance on the Kubernetes
  secrets is eliminated.

* The sidecar Envoy is able to dynamically renew the key and certificate
  through the SDS API: Certificate rotations no longer require Envoy to restart.

## Before you begin

* Set up Istio by following the instructions using
  [Helm](/docs/setup/install/helm/) with SDS setup and global mutual
  TLS enabled.

## Service-to-service mutual TLS using key/certificate provisioned through SDS

Follow the [authentication policy task](/docs/tasks/security/authn-policy/) to
setup test services.

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
{{< /text >}}

Verify all mutual TLS requests succeed:

{{< text bash >}}
$ for from in "foo" "bar"; do for to in "foo" "bar"; do kubectl exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
{{< /text >}}

## Verifying no secret-volume mounted file is generated

To verify that no secret-volume mounted file is generated, access the deployed
workload sidecar container:

{{< text bash >}}
$ kubectl exec -it $(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name}) -c istio-proxy -n foo  -- /bin/bash
{{< /text >}}

As you can see there is no secret file mounted at `/etc/certs` folder.

## Securing SDS with pod security policies

The Istio Secret Discovery Service (SDS) uses the Citadel agent to distribute the certificate to the
Envoy sidecar via a Unix domain socket. All pods running in the same Kubernetes node share the Citadel
agent and Unix domain socket.

To prevent unexpected modifications to the Unix domain socket, enable the [pod security policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)
to restrict the pod's permission on the Unix domain socket. Otherwise, a malicious user who has the
permission to modify the deployment could hijack the Unix domain socket to break the SDS service or
steal the identity credentials from other pods running on the same Kubernetes node.

To enable the pod security policy, perform the following steps:

1. The Citadel agent fails to start unless it can create the required Unix domain socket. Apply the
   following pod security policy to only allow the Citadel agent to modify the Unix domain socket:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: istio-nodeagent
    spec:
      allowedHostPaths:
      - pathPrefix: "/var/run/sds"
      seLinux:
        rule: RunAsAny
      supplementalGroups:
        rule: RunAsAny
      runAsUser:
        rule: RunAsAny
      fsGroup:
        rule: RunAsAny
      volumes:
      - '*'
    ---
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-nodeagent
      namespace: istio-system
    rules:
    - apiGroups:
      - extensions
      resources:
      - podsecuritypolicies
      resourceNames:
      - istio-nodeagent
      verbs:
      - use
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: istio-nodeagent
      namespace: istio-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: istio-nodeagent
    subjects:
    - kind: ServiceAccount
      name: istio-nodeagent-service-account
      namespace: istio-system
    EOF
    {{< /text >}}

1. To stop other pods from modifying the Unix domain socket, change the `allowedHostPaths` configuration
   for the the path the Citadel agent uses for the Unix domain socket to `readOnly: true`.

    {{< warning >}}
    The following pod security policy assumes no other pod security policy was applied before. If you
    already applied another pod security policy, add the following configuration values to the existing
    policies instead of applying the configuration directly.
    {{< /warning >}}

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: istio-sds-uds
    spec:
     # Protect the unix domain socket from unauthorized modification
     allowedHostPaths:
     - pathPrefix: "/var/run/sds"
       readOnly: true
     # Allow the istio sidecar injector to work
     allowedCapabilities:
     - NET_ADMIN
     seLinux:
       rule: RunAsAny
     supplementalGroups:
       rule: RunAsAny
     runAsUser:
       rule: RunAsAny
     fsGroup:
       rule: RunAsAny
     volumes:
     - '*'
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: istio-sds-uds
    rules:
    - apiGroups:
      - extensions
      resources:
      - podsecuritypolicies
      resourceNames:
      - istio-sds-uds
      verbs:
      - use
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: istio-sds-uds
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: istio-sds-uds
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:serviceaccounts
    EOF
    {{< /text >}}

1. Enable pod security policies for your platform. Each supported platform enables pod security
   policies differently. Please refer to the pertinent documentation for your platform. If you are
   using the Google Kubernetes Engine (GKE), you must [enable the pod security policy controller](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#enabling_podsecuritypolicy_controller).

    {{< warning >}}
    Grant all needed permissions in the pod security policy before enabling it. Once the policy is
    enabled, pods won't start if they require any permissions not granted.
    {{< /warning >}}

1. Run the following command to restart the Citadel agents:

    {{< text bash >}}
    $ kubectl delete pod -l 'app=nodeagent' -n istio-system
    pod "istio-nodeagent-dplx2" deleted
    pod "istio-nodeagent-jrbmx" deleted
    pod "istio-nodeagent-rz878" deleted
    {{< /text >}}

1. To verify that the Citadel agents work with the enabled pod security policy, wait a few seconds
   and run the following command to confirm the agents started successfully:

    {{< text bash >}}
    $ kubectl get pod -l 'app=nodeagent' -n istio-system
    NAME                    READY   STATUS    RESTARTS   AGE
    istio-nodeagent-p4p7g   1/1     Running   0          4s
    istio-nodeagent-qdwj6   1/1     Running   0          5s
    istio-nodeagent-zsk2b   1/1     Running   0          14s
    {{< /text >}}

1. Run the following command to start a normal pod.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: normal
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: normal
      template:
        metadata:
          labels:
            app: normal
        spec:
          containers:
          - name: normal
            image: pstauffer/curl
            command: ["/bin/sleep", "3650d"]
            imagePullPolicy: IfNotPresent
    EOF
    {{< /text >}}

1. To verify that the normal pod works with the pod security policy enabled, wait a few seconds and
   run the following command to confirm the normal pod started successfully.

    {{< text bash >}}
    $ kubectl get pod -l 'app=normal'
    NAME                      READY   STATUS    RESTARTS   AGE
    normal-64c6956774-ptpfh   2/2     Running   0          8s
    {{< /text >}}

1. Start a malicious pod that tries to mount the Unix domain socket using a write permission.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: malicious
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: malicious
      template:
        metadata:
          labels:
            app: malicious
        spec:
          containers:
          - name: malicious
            image: pstauffer/curl
            command: ["/bin/sleep", "3650d"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: sds-uds
              mountPath: /var/run/sds
          volumes:
          - name: sds-uds
            hostPath:
              path: /var/run/sds
              type: ""
    EOF
    {{< /text >}}

1. To verify that the Unix domain socket is protected, run the following command to confirm the
   malicious pod failed to start due to the pod security policy:

    {{< text bash >}}
    $ kubectl describe rs -l 'app=malicious' | grep Failed
    Pods Status:    0 Running / 0 Waiting / 0 Succeeded / 0 Failed
      ReplicaFailure   True    FailedCreate
      Warning  FailedCreate  4s (x13 over 24s)  replicaset-controller  Error creating: pods "malicious-7dcfb8d648-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].volumeMounts[0].readOnly: Invalid value: false: must be read-only]
    {{< /text >}}

## Cleanup

1. Clean up the test services and the Istio control plane:

    {{< text bash >}}
    $ kubectl delete ns foo
    $ kubectl delete ns bar
    $ kubectl delete -f istio-auth-sds.yaml
    {{< /text >}}

1. Disable the pod security policy in the cluster using the documentation of your platform. If you are using GKE,
   [disable the pod security policy controller](https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies#disabling_podsecuritypolicy_controller).

1. Delete the pod security policy and the test deployments:

    {{< text bash >}}
    $ kubectl delete psp istio-sds-uds istio-nodeagent
    $ kubectl delete role istio-nodeagent -n istio-system
    $ kubectl delete rolebinding istio-nodeagent -n istio-system
    $ kubectl delete clusterrole istio-sds-uds
    $ kubectl delete clusterrolebinding istio-sds-uds
    $ kubectl delete deploy malicious
    $ kubectl delete deploy normal
    {{< /text >}}

## Caveats

Currently, the SDS identity provision flow has the following caveats:

* SDS support is currently in [Alpha](/about/feature-stages/#security-and-policy-enforcement).

* Smoothly migrating a cluster from using secret volume mount to using
  SDS is a work in progress.
