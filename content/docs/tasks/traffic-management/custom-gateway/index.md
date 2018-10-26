---
title: Add a new Custom IngressGateway
description: Describes how to add a new custom ingress gateway manually.
weight: 89
keywords: [ingress,traffic-management]
---

This post provides instructions to manually create a new custom ingress gateway with automatic provisioning of certificates based on cert-manager.
This task was validated on AWS Infrastructure.

## Prerequisites

cert-manager: Install cert-manager using [chart](https://github.com/helm/charts/tree/master/stable/cert-manager)

## Check cert-manager installation

1. Check if cert-manager was installed using Helm with the following command:

{{< text bash >}}
$ helm ls
{{< /text>}}

The output should be similar to the example below and show cert-manager with a `STATUS` of `DEPLOYED`:

{{< text bash >}}
NAME         	REVISION	UPDATED                 	STATUS  	CHART                    	APP VERSION 	NAMESPACE
istio        	1       	Thu Oct 11 13:34:24 2018	DEPLOYED	istio-1.0.2              	1.0.2       	istio-system
cert        	1       	Wed Oct 24 14:08:36 2018	DEPLOYED	cert-manager-v0.6.0-dev.2	v0.6.0-dev.2	istio-system
{{< /text >}}

## Create cluster issuer

{{< warning_icon >}} Adapt cluster issuer provider with your own configuration, in our example we use `route53`

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
      - name: aws-dns
        route53:
          accessKeyID: <REDACTED>
          region: eu-central-1
          secretAccessKeySecretRef:
            name: prod-route53-credentials-secret
            key: secret-access-key
{{< /text >}}

## Create secret

If you use provider `route53` you must provide secret in order to perform DNS ACME Validation.

{{< text yaml >}}
apiVersion: v1
kind: Secret
metadata:
  name: prod-route53-credentials-secret
type: Opaque
data:
  secret-access-key: <REDACTED BASE64>
{{< /text >}}

## Create Certificate

Create your own certificate:

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
        provider: aws-dns
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

Have a look of `secretName`, it will be used in next section.

## Create Horizontal Pod Autoscaler

In order to have scalability you need to declare a new Horizontal Pod Autoscaler:

{{< text yaml >}}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: istio-internal-custom
  namespace: istio-system
spec:
  maxReplicas: 5
  minReplicas: 1
  scaleTargetRef:
    apiVersion: apps/v1beta1
    kind: Deployment
    name: istio-internal-custom
  targetCPUUtilizationPercentage: 80
status:
  currentCPUUtilizationPercentage: 0
  currentReplicas: 1
  desiredReplicas: 1
{{< /text >}}

## Create Deployment

Apply your deployment with declaration bellow.

{{< warning_icon >}} Usage of annotations `aws-load-balancer-type` only applied for AWS cloud provider

{{< text yaml >}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: istio-internal-custom-service-account
  labels:
    app: istio-internal-custom
---
apiVersion: v1
kind: Service
metadata:
  name: istio-internal-custom
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
  labels:
    app: istio-internal-custom
    istio: istio-internal-custom
spec:
  type: LoadBalancer
  selector:
    app: istio-internal-custom
    istio: istio-internal-custom
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
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: istio-internal-custom
  labels:
    app: istio-internal-custom
    istio: istio-internal-custom
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: istio-internal-custom
        istio: istio-internal-custom
      annotations:
        sidecar.istio.io/inject: "false"
        scheduler.alpha.kubernetes.io/critical-pod: ""
    spec:
      serviceAccountName: istio-internal-custom-service-account
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
          - istio-internal-custom
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
                - istio-internal-custom
            topologyKey: kubernetes.io/hostname
{{< /text >}}

Please Note that you have to force a NodePort to an available Port.

You also have to declare your `ingressgateway-custom-certs` with secret name generated before (for example `secretName: istio-customingressgateway-certs`)

## Create Istio gateway

You can now create an Istio custom gateway:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  annotations:
  name: istio-custom-gateway
  namespace: default
spec:
  selector:
    istio: istio-internal-custom
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

You can now use your custom gateway `istio-custom-gateway`