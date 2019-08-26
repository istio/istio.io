---
title: App Identity and Access Adapter
subtitle: Using Istio to Secure Multicloud Kubernetes Applications with Zero Code Changes
description: Using Istio to Secure Multicloud Kubernetes Applications with Zero Code Changes.
publishdate: 2019-09-01
attribution: Anton Aleksandrov (IBM)
keywords: [security,oidc,jwt,policies]
---

Whether your computing environment uses multiple cloud providers, a single cluster, a combination of on- and off-premise solutions, or multiple containers in one cloud, having a centralized identity management can help you to preserve existing infrastructure and avoid vendor lock-in. 

Simply put, if you are running your containerized applications on Kubernetes, you can benefit from using the App Identity and Access Adapter for an abstracted level of security with zero code changes and no redeployments.

With the [App Identity and Access Adapter](https://github.com/ibm-cloud-security/app-identity-and-access-adapter), you can use any OAuth2/OIDC provider, such as IBM Cloud App ID, Auth0, Okta, Ping Identity, AWS Cognito, Azure AD B2C and more. Authentication and control authorization policies can be applied in a streamlined way in all environments — including frontend and backend applications — without any changes to your code or the need to redeploy your application. 

## Understanding Istio and the adapter

[Istio](https://istio.io/docs/concepts/what-is-istio/) is an open source service mesh that layers transparently onto existing distributed applications that can integrate with Kubernetes. To reduce the complexity of deployments Istio provides behavioral insights and operational control over the service mesh as a whole. [See Istio Architecture for more details.](https://istio.io/docs/concepts/what-is-istio/#architecture)

Istio uses a sidecar model with Envoy proxy to mediate all inbound and outbound traffic for all pods in the service mesh. By using the Envoy, Istio extracts information about network traffic, also known as telemetry, that is sent to the Istio component called [Mixer](https://istio.io/docs/concepts/what-is-istio/#mixer), which is responsible for collecting telemetry and enforcing policy decisions. 

The App Identity and Access adapter extends the Mixer functionality by analyzing the telemetry (attributes) against various access control policies across the service mesh. The access control policies can be linked to a particular Kubernetes services and can be finely tuned to specific service endpoints. For more information about policies and telemetry, see the Istio documentation.

When [App Identity and Access Adapter](https://github.com/ibm-cloud-security/app-identity-and-access-adapter) is combined with Istio, it provides a scalable, integrated identity and access solution for multicloud architectures that does not require any custom application code changes. 

## Installation

App Identity and Access adapter can be installed using Helm directly from the github.com repository

```
helm repo add appidentityandaccessadapter https://raw.githubusercontent.com/ibm-cloud-security/app-identity-and-access-adapter/master/helm/appidentityandaccessadapter
helm install --name appidentityandaccessadapter appidentityandaccessadapter/appidentityandaccessadapter
```

Alternatively, you can clone the repo and install the Helm chart locally

```
git clone git@github.com:ibm-cloud-security/app-identity-and-access-adapter.git
helm install ./helm/appidentityandaccessadapter --name appidentityandaccessadapter.
```

## Protecting web applications

Web applications are most commonly protected by the OpenID Connect (OIDC) workflow called `authorization_code`. When an unauthenticated/unauthorized user is detected, they are automatically redirected to the identity service of your choice and presented with the authentication page. When authentication completes, the browser is redirected back to an implicit `/oidc/callback` endpoint intercepted by the adapter. At this point, the adapter obtains access and identity tokens from the identity service and then redirects users back to their originally requiested URL in the web app. 

Authentication state and tokens are maintained by the adapter. Each request processed by the adapter will include the Authorization header bearing both access and identity tokens in the following format:

```
Authorization: Bearer <access_token> <id_token>
```

Developers can read leverage the tokens for application experience adjustments, e.g. displaying user name, adjusting UI based on user role etc. 

In order to terminate the authenticated session and wipe tokens, aka user logout, simply redirect browser to the `/oidc/logout` endpoint under the protected service, e.g. if you're serving your app from `https://example.com/myapp`, redirect users to 

```
https://example.com/myapp/oidc/logout
```

Whenever access token expires, a refresh token is used to automatically acquire new access and identity tokens without your user's needing to re-authenticate. If the configured identity provider returns a refresh token, it is persisted by the adapter and used to retrieve new access and identity tokens when the old ones expire. 

### Applying web application protection

There are two steps to apply the protection - define OIDC client and creating a policy.

#### Define OIDC client

```yaml
apiVersion: "security.cloud.ibm.com/v1"
kind: OidcConfig
metadata:
    name: my-oidc-provider-config
    namespace: sample-namespace
spec:
    discoveryUrl: <discovery-url-from-oidc-provider>
    clientId: <client-id-from-oidc-provider>
    clientSecretRef:
        name: <kubernetes-secret-name>
        key: <kubernetes-secret-key>
```

#### Define a policy to protect web application

```yaml
apiVersion: "security.cloud.ibm.com/v1"
kind: Policy
metadata:
  name:      my-sample-web-policy
  namespace: sample-namespace
spec:
  targets:
  	- serviceName: <kubernetes-service-name-to-protect>
	  paths:
	    - prefix: /webapp
	      method: ALL
	      policies:
	        - policyType: oidc
	          config: my-oidc-provider-config
	          rules: // optional
	            - claim: iss
	              match: ALL
	              source: access_token
	              values:
	                - <expected-issuer-id>
	            - claim: scope
	              match: ALL
	              source: access_token
	              values:
	                - openid
```
[Read more about protecting web applications ](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)

## Protecting backend application and APIs

Backend applications and APIs are protected using the Bearer Token flow, where an incoming token is validated against a particular policy. The Bearer Token authorization flow expects a request to contain the `Authorization` header with a valid access token in JWT format. The expected header structure is `Authorization: Bearer {access_token}`. In case token is successfully validated request will be forwarded to the requested service. In case token validation fails the HTTP 401 will be returned back to the client with a list of scopes that are required to access the API. 

### Applying web application protection

There are two steps to apply the protection - defining JWT config and creating a policy.

#### Define JWT config

```yaml
apiVersion: "security.cloud.ibm.com/v1"
kind: JwtConfig
metadata:
    name: my-jwt-config
    namespace: sample-namespace
spec:
    jwksUrl: <the-jwks-url>
```

#### Define a policy to protect backend/api application

```yaml
apiVersion: "security.cloud.ibm.com/v1"
kind: Policy
metadata:
  name: my-sample-backend-policy
  namespace: sample-namespace
spec:
  targets:
  	- serviceName: <kubernetes-service-name-to-protect>
	  paths:
	    - prefix: /api/files
	      method: ALL
	      policies:
	        - policyType: jwt
	          config: my-oidc-provider-config
	          rules: // optional
	            - claim: iss
	              match: ALL
	              source: access_token
	              values:
	                - <expected-issuer-id>
	            - claim: scope
	              match: ALL
	              source: access_token
	              values:
	                - files.read
	                - files.write
```
[Read more about protecting backend applications](https://github.com/ibm-cloud-security/app-identity-and-access-adapter)

## Summary

When a multicloud strategy is in place, security can become complicated as the environment grows and diversifies. While cloud providers supply protocols and tools to ensure their offerings are safe, the development teams are still responsible for the application-level security, such as API access control with OAuth2, defending against man-in-the-middle attacks with traffic encryption, and providing mutual TLS for service access control. However, this becomes complex in a multicloud environment since you might need to define those security details for each service separately. With proper security protocols in place, those external and internal threats can be mitigated. 

Development teams have spent time making their services portable to different cloud providers, and in the same regard, the security in place should be flexible and not infrastructure-dependent. 

Istio and App Identity and Access Adapter allow you to secure your Kubernetes apps with absolutely zero code changes or redeployments regardless of which programming language and which frameworks you use. Following this approach ensures maximum portability of your apps, and ability to easily enforce same security policies across multiple environments. 

You can read more about the App Identity and Access Adapter in the [release blog](https://www.ibm.com/cloud/blog/using-istio-to-secure-your-multicloud-kubernetes-applications-with-zero-code-change)
