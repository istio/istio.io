---
title: Deploy a custom ingress gateway using cert-manager
description: Describes how to deploy a custom ingress gateway using cert-manager manually.
weight: 89
keywords: [ingress,traffic-management]
---

This post provides instructions to manually create a custom ingress [gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) with automatic provisioning of certificates based on cert-manager.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide](/docs/setup/).
* Setup `cert-manager` with helm [chart](https://github.com/helm/charts/tree/master/stable/cert-manager#installing-the-chart)

## Configuring the custom ingress gateway

1. Check if [cert-manager](https://github.com/helm/charts/tree/master/stable/cert-manager) was installed using Helm with the following command:

    {{< text bash >}}
    $ helm ls
    {{< /text>}}

    The output should be similar to the example below and show cert-manager with a `STATUS` of `DEPLOYED`:

    {{< text plain >}}
    NAME   REVISION UPDATED                  STATUS   CHART                     APP VERSION   NAMESPACE
    istio     1     Thu Oct 11 13:34:24 2018 DEPLOYED istio-1.0.2               1.0.2         istio-system
    cert      1     Wed Oct 24 14:08:36 2018 DEPLOYED cert-manager-v0.6.0-dev.2 v0.6.0-dev.2  istio-system
    {{< /text >}}

1. To create the cluster's issuer, apply the following configuration:

    {{< info_icon >}} Change the cluster's [issuer](https://cert-manager.readthedocs.io/en/latest/reference/issuers.html#issuers) provider with your own configuration values. The example uses the values under `route53`.

    {{< text yaml >}}
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-demo
      namespace: kube-system
    spec:
      acme:
        # The ACME server URL
        server: https://acme-v02.api.letsencrypt.org/directory
        # Email address used for ACME registration
        email: <REDACTED>
        # Name of a secret used to store the ACME account private key
        privateKeySecretRef:
          name: letsencrypt-demo
        dns01:
          # Here we define a list of DNS-01 providers that can solve DNS challenges
          providers:
          - name: your-dns
            route53:
              accessKeyID: <REDACTED>
              region: eu-central-1
              secretAccessKeySecretRef:
                name: prod-route53-credentials-secret
                key: secret-access-key
    {{< /text >}}

1. If you use the `route53` [provider](https://cert-manager.readthedocs.io/en/latest/reference/issuers/acme/dns01.html#amazon-route53), you must provide a secret to perform DNS ACME Validation. To create the secret, apply the following configuration file:

    {{< text yaml >}}
    apiVersion: v1
    kind: Secret
    metadata:
      name: prod-route53-credentials-secret
    type: Opaque
    data:
      secret-access-key: <REDACTED BASE64>
    {{< /text >}}

1. Create your own certificate:

    {{< text yaml >}}
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: Certificate
    metadata:
      name: demo-certificate
      namespace: istio-system
    spec:
      acme:
        config:
        - dns01:
            provider: your-dns
          domains:
          - '*.mydemo.com'
      commonName: '*.mydemo.com'
      dnsNames:
      - '*.mydemo.com'
      issuerRef:
        kind: ClusterIssuer
        name: letsencrypt-demo
      secretName: istio-customingressgateway-certs
    {{< /text >}}

    Make a note of the value of `secretName` since a future step requires it.

1. To scale automatically, declare a new horizontal pod autoscaler with the following configuration:

    {{< text yaml >}}
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
      name: my-ingressgateway
      namespace: istio-system
    spec:
      maxReplicas: 5
      minReplicas: 1
      scaleTargetRef:
        apiVersion: apps/v1beta1
        kind: Deployment
        name: my-ingressgateway
      targetCPUUtilizationPercentage: 80
    status:
      currentCPUUtilizationPercentage: 0
      currentReplicas: 1
      desiredReplicas: 1
    {{< /text >}}

1. Apply your deployment with declaration bellow.

    {{< info_icon >}} The annotations used, for example `aws-load-balancer-type`, only apply for AWS.

    Declare your `ingressgateway-custom-certs` with the secret name you generated before. In our example, `secretName: istio-customingressgateway-certs`.

    {{< text yaml >}}
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: my-ingressgateway-service-account
      labels:
        app: my-ingressgateway
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: my-ingressgateway
      labels:
        app: my-ingressgateway
        istio: my-ingressgateway
    spec:
      replicas: 3
      template:
        metadata:
          labels:
            app: my-ingressgateway
            istio: my-ingressgateway
          annotations:
            sidecar.istio.io/inject: "false"
            scheduler.alpha.kubernetes.io/critical-pod: ""
        spec:
          serviceAccountName: my-ingressgateway-service-account
          containers:
            - name: ingressgateway
              image: "gcr.io/istio-release/proxyv2:1.0.0"
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                - containerPort: 443
                - containerPort: 31400
                - containerPort: 15011
                - containerPort: 8060
                - containerPort: 15030
                - containerPort: 15031
              args:
              - proxy
              - router
              - -v
              - "2"
              - --discoveryRefreshDelay
              - '1s' #discoveryRefreshDelay
              - --drainDuration
              - '45s' #drainDuration
              - --parentShutdownDuration
              - '1m0s' #parentShutdownDuration
              - --connectTimeout
              - '10s' #connectTimeout
              - --serviceCluster
              - my-ingressgateway
              - --zipkinAddress
              - zipkin.istio-system:9411
              - --statsdUdpAddress
              - istio-statsd-prom-bridge.istio-system:9125
              - --proxyAdminPort
              - "15000"
              - --controlPlaneAuthPolicy
              - NONE
              - --discoveryAddress
              - istio-pilot.istio-system:8080
              resources:
                requests:
                  cpu: 10m
              volumeMounts:
              - mountPath: /etc/certs
                name: istio-certs
                readOnly: true
              - mountPath: /etc/istio/ingressgateway-certs
                name: ingressgateway-custom-certs
                readOnly: true
              - mountPath: /etc/istio/ingressgateway-ca-certs
                name: ingressgateway-ca-certs
                readOnly: true
              env:
              - name: POD_NAME
                valueFrom:
                  fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.name
              - name: POD_NAMESPACE
                valueFrom:
                  fieldRef:
                    apiVersion: v1
                    fieldPath: metadata.namespace
              - name: INSTANCE_IP
                valueFrom:
                  fieldRef:
                    apiVersion: v1
                    fieldPath: status.podIP
              - name: ISTIO_META_POD_NAME
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
          volumes:
          - name: istio-certs
            secret:
              defaultMode: 420
              optional: true
              secretName: istio.istio-ingressgateway-service-account
          - name: ingressgateway-custom-certs
            secret:
              defaultMode: 420
              optional: true
              secretName: istio-customingressgateway-certs
          - name: ingressgateway-ca-certs
            secret:
              defaultMode: 420
              optional: true
              secretName: istio-ingressgateway-ca-certs
          affinity:
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: beta.kubernetes.io/arch
                    operator: In
                    values:
                    - amd64
                    - ppc64le
                    - s390x
              preferredDuringSchedulingIgnoredDuringExecution:
              - weight: 2
                preference:
                  matchExpressions:
                  - key: beta.kubernetes.io/arch
                    operator: In
                    values:
                    - amd64
              - weight: 2
                preference:
                  matchExpressions:
                  - key: beta.kubernetes.io/arch
                    operator: In
                    values:
                    - ppc64le
              - weight: 2
                preference:
                  matchExpressions:
                  - key: beta.kubernetes.io/arch
                    operator: In
                    values:
                    - s390x
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - my-ingressgateway
                topologyKey: kubernetes.io/hostname
    {{< /text >}}

1. Create your service:

    {{< warning_icon >}} The `NodePort` used needs to be an available Port.

    {{< text yaml >}}
    apiVersion: v1
    kind: Service
    metadata:
      name: my-ingressgateway
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
      labels:
        app: my-ingressgateway
        istio: my-ingressgateway
    spec:
      type: LoadBalancer
      selector:
        app: my-ingressgateway
        istio: my-ingressgateway
      ports:
        -
          name: http2
          nodePort: 32380
          port: 80
          targetPort: 80
        -
          name: https
          nodePort: 32390
          port: 443
        -
          name: tcp
          nodePort: 32400
          port: 31400
    {{< /text >}}

1. Create your Istio custom gateway configuration object:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      annotations:
      name: istio-custom-gateway
      namespace: default
    spec:
      selector:
        istio: my-ingressgateway
      servers:
      - hosts:
        - '*.mydemo.com'
        port:
          name: http
          number: 80
          protocol: HTTP
        tls:
          httpsRedirect: true
      - hosts:
        - '*.mydemo.com'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    {{< /text >}}

1. Link your `istio-custom-gateway` with your `VirtualService`

1. Correct certificate is returned by the server and it is successfully verified (_SSL certificate verify ok_ is printed)

    {{< text bash >}}
    $ curl -v `https://demo.mydemo.com`
    Server certificate:
      SSL certificate verify ok.
    {{< /text >}}

**Congratulations!** You can now use your custom `istio-custom-gateway` [gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) configuration object.