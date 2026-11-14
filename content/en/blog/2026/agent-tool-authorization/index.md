---
title: "Service Identity and Least-Privilege Authorization for AI-Agent Tools"
description: "Control access to a tool with Istio, then authorize its arguments in application code."
weight: 0
keywords: [security, authorization, service-identity, ai-agents]
aliases: []
publishdate: 2026-10-10
attribution: "Tejesh Vaish"
target_release: "1.31"
---

{{< warning >}}
Draft status: Live policy verification is pending. Checks below describe expected outcomes.
{{< /warning >}}

A synthetic agent worker requests `create_followup` for support ticket `ticket-1042` in tenant `alpha`. The clients run no model. An accepted request's entire effect is one committed row in a local `SQLite` ledger.

Permission to call an AI-agent tool does not establish permission for the tenant, resource, or operation in its arguments. An agent's proposed arguments can name a resource its caller may not access.

Istio's destination sidecar authorizes workload identity, HTTP method, path, and port. The tool application parses, validates, and authorizes the arguments on every invocation before forwarding.

## Before you begin

Use an isolated Istio environment with control-plane and sidecar processes. The example targets Istio 1.31.1. These policy and application excerpts aren't a full deployment guide. Supply your own application workloads and Kubernetes Services before trying the checks.

The policies assume namespace `agent-tools`, trust domain `cluster.local`, and the separate service accounts listed below. Access to deploy or modify workloads using these service accounts must be controlled. Label the tool application `app: tool-gateway` and the sink `app: action-sink`. Both applications must listen for HTTP on workload port 8080, with HTTP-named Service ports. For the ledger checks, the sink's entire effect must be a committed row, and you need an independent observer.

The isolated example uses `meshConfig.pathNormalization.normalization: NONE`, and the tool application compares the literal request target. Review the path probes and router warning below before using this configuration elsewhere.

## How the example works

`tool-gateway` is the tool application's workload and ServiceAccount name. The `gateway` role and policy names (`gateway-*` and `sink-allow-gateway`) refer to this application. It runs without an Istio Gateway or agentgateway.

The sidecar policy permits one workload identity to call one HTTP operation. The tool application asks a separate service to commit the follow-up only after authorizing the tenant, resource, and operation.

Run the workloads in sidecar mode with separate Kubernetes service accounts:

| Workload | Service account | Permitted role |
| --- | --- | --- |
| `agent-alpha` | `agent-alpha` | Call the tool application's follow-up route |
| `agent-untrusted` | `agent-untrusted` | No access to that route |
| `tool-gateway` | `tool-gateway` | Validate arguments and call the action sink |
| `action-sink` | `action-sink` | Commit one validated follow-up row |

Istio's [identity and certificate flow](/docs/concepts/security/#pki) ties workload certificates to their service identity. The trusted client's principal in this cluster is:

{{< text plain >}}
cluster.local/ns/agent-tools/sa/agent-alpha
{{< /text >}}

The policy uses the principal established by peer authentication. Sending `X-Service-Account: agent-alpha` won't change an untrusted client's certificate identity.

Requests travel from `agent-alpha → tool-gateway`, then from `tool-gateway → action-sink`. Each connection has its own peer identity, so the sink's sidecar authenticates the tool application on the second hop. Delegating an end user's authority across that hop would require a separate authenticated contract.

<div style="max-width: 480px; margin: 0 auto;">
{{< image width="100%" link="./assets/request-boundaries.svg" alt="Two mTLS hops with Istio sidecar policies, tool application argument checks, and the sink's independent effect ledger" >}}
</div>

[Open the SVG diagram](./assets/request-boundaries.svg).

## Configure peer authentication and sidecar authorization

First, require mTLS throughout the namespace, without a port exception:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: require-mtls
  namespace: agent-tools
spec:
  mtls:
    mode: STRICT
{{< /text >}}

[`STRICT` peer authentication](/docs/reference/config/security/peer_authentication/) requires mesh mutual TLS. The destination sidecar enforces authorization policies to determine which authenticated workloads may invoke the tool.

Apply an ALLOW policy with no rules to the tool application:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: gateway-allow-nothing
  namespace: agent-tools
spec:
  selector:
    matchLabels:
      app: tool-gateway
  action: ALLOW
{{< /text >}}

Add a second ALLOW policy for the permitted operation:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: gateway-allow-followup
  namespace: agent-tools
spec:
  selector:
    matchLabels:
      app: tool-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/agent-tools/sa/agent-alpha
    to:
    - operation:
        ports: ["8080"]
        methods: ["POST"]
        paths: ["/tools/followups"]
{{< /text >}}

Keep the principal and HTTP operation in the same rule: both must match. Putting them in separate rules would let either rule authorize a request.

When no ALLOW policy applies, requests are allowed unless another policy action denies them. Once an ALLOW policy applies, a request needs at least one matching rule.

ALLOW policies are additive. A broad rule in another policy would widen access even with allow-nothing in place. An empty rules list matches nothing, while an empty rule matches everything. See the [Istio 1.31.1 authorization API](https://github.com/istio/api/blob/1.31.1/security/v1beta1/authorization_policy.proto).

Match the destination workload's port in the policy even when the Service maps a different port to it.

The selector applies only to `app: tool-gateway`. Check its scope with a separate test service that has a different label; it should remain reachable over mTLS. To restrict the whole namespace, use a namespace-wide policy and review every workload it selects.

## Authorize the tool application to call the sink

Apply the same empty-rules ALLOW pattern to the sink with selector `app: action-sink`, then allow the tool application's principal to call the effect endpoint:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: sink-allow-gateway
  namespace: agent-tools
spec:
  selector:
    matchLabels:
      app: action-sink
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/agent-tools/sa/tool-gateway
    to:
    - operation:
        ports: ["8080"]
        methods: ["POST"]
        paths: ["/effects"]
{{< /text >}}

Don't give the trusted agent direct permission to call `/effects`, because that would bypass the tool application's argument checks.

Probe the sink through its Service DNS name and directly through its Pod IP. Direct Pod-IP traffic may pass through without full Istio functionality, including mTLS. Under STRICT peer authentication, a connection without mTLS should fail at the transport boundary; that failure does not demonstrate an authorization-policy denial. See [Application Requirements: outbound traffic](/docs/ops/deployment/application-requirements/#outbound-traffic).

Any code in the tool application's workload can use the sink connection, including code running after the workload is compromised. The example doesn't establish protection from cluster administrators, stolen workload credentials, or privileged bypass of traffic interception.

## Validate arguments in the tool application

Use this body for the permitted request:

{{< text json >}}
{
  "tenant_id": "alpha",
  "resource_id": "ticket-1042",
  "operation": "create_followup",
  "request_id": "case-valid-01"
}
{{< /text >}}

Once the sidecar allows the request, the tool application checks the JSON structure. It requires an object with exactly the four keys above, no duplicate keys, and valid types.

On every invocation, the tool application then authorizes the tenant, resource, and operation against its fixed grant before making a downstream request.

The Istio policies above don't inspect the JSON body. `ALLOWED` is a fixed module constant for tenant `alpha`, resource `ticket-1042`, and operation `create_followup`. It applies to every caller admitted by the sidecar; this example admits only `agent-alpha`.

Admitting more callers would not create caller-specific grants. Different caller permissions require a separately authenticated identity-to-grant contract, which is not implemented here. The application doesn't derive caller identity or permissions from JSON or headers, and it doesn't look up ownership.

The `validation.py` module handles parsing and the fixed-grant check:

{{< text python >}}
import json
import re

KEYS = frozenset(("tenant_id", "resource_id", "operation", "request_id"))
ALLOWED = {"tenant_id": "alpha", "resource_id": "ticket-1042", "operation": "create_followup"}
REQUEST_ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}\Z", re.ASCII)


class AuthorizationDenied(Exception):
    """Arguments fall outside the tool application's fixed grant."""


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate key")
        result[key] = value
    return result


def bounded_string(value):
    return isinstance(value, str) and 0 < len(value) <= 128


def parse(raw):
    try:
        body = json.loads(raw.decode("utf-8"), object_pairs_hook=unique_object)
    except RecursionError as error:
        raise ValueError("invalid JSON nesting") from error
    if not isinstance(body, dict):
        raise ValueError("JSON object required")
    if frozenset(body) != KEYS:
        raise ValueError("exact required keys")
    if not all(bounded_string(value) for value in body.values()):
        raise ValueError("bounded strings required")
    if REQUEST_ID.fullmatch(body["request_id"]) is None:
        raise ValueError("unsafe request ID")
    return body


def authorize(body):
    if any(body[key] != value for key, value in ALLOWED.items()):
        raise AuthorizationDenied("arguments unauthorized")
    return body
{{< /text >}}

The HTTP handler calls the parsing and authorization functions before invoking the downstream operation:

{{< text python >}}
import http.client
from http.server import BaseHTTPRequestHandler
from validation import AuthorizationDenied, authorize, parse


class Handler(BaseHTTPRequestHandler):
    def arguments(self):
        length = int(self.headers["Content-Length"])
        raw = self.rfile.read(length)
        if len(raw) != length:
            raise ValueError("incomplete body")
        return parse(raw)

    def action(self, correlation):
        try:
            body = self.arguments()
            authorize(body)
        except (ValueError, UnicodeError) as error:
            self.reject(400, correlation, str(error))
            return
        except AuthorizationDenied as error:
            self.reject(403, correlation, str(error))
            return
        except (OSError, http.client.HTTPException, RuntimeError) as error:
            self.reject(502, correlation, type(error).__name__)
            return
        try:
            write_audit("accepted", correlation, arguments=body)
            operations = {"gateway": downstream, "sink": sink_action}
            operations[self.server.role](body, correlation)
            self.reply(201, body)
        except (OSError, http.client.HTTPException, RuntimeError, ValueError, UnicodeError) as error:
            self.reject(502, correlation, type(error).__name__)
{{< /text >}}

Before calling `action()`, `dispatch()` checks the literal route, content type, framing, and body-size limit. In the `gateway` role, `downstream()` posts to `/effects` and requires a 201 response containing the same body. The remaining HTTP plumbing, downstream implementation, sink, and deployment manifests are omitted.

The `accepted` audit event precedes downstream execution; it does not prove that the sink committed a row.

The tool application should return these responses when it rejects a request:

| Rejection | HTTP status |
| --- | ---: |
| Malformed request JSON, duplicate, missing or extra keys, invalid shape or values | 400 |
| Unsupported content type | 415 |
| Body larger than 8 `KiB` | 413 |
| Valid JSON for another tenant, resource outside the fixed grant, or disallowed operation | 403 |

For an accepted request, the tool application should forward the arguments to the sink and return 201 only after the sink commits the row and reports success.

## Check request enforcement

Live verification is pending; these are expected outcomes. The example covers serial requests; it doesn't implement general idempotency or a concurrent execution protocol.

### Use one procedure for all probes

Vary the caller, arguments, route, and policy as described in each probe. An independent test observer reads the ledger, so a client error can't hide a committed row.

Read the `SQLite` file directly through the privileged test observer, separately from the application's request path. The application exposes no exempt observer route at `/admin` or `/count`. The observer is test instrumentation outside the application's authorization model.

1. Use a unique JSON `request_id` for each call to match it to its audit and ledger evidence. In your test setup, associate it with the handler's `correlation` value and the request identifier recorded in the proxy log.
1. Use the independent observer to record the ledger count and complete sorted rows before and after each request. Record the response and compare the ledger snapshots with the expected result.
1. For a probe expected to be rejected before commitment, independently require zero added rows and an unchanged complete sorted row set. An unexpected committed row fails the check.
1. For a permitted request to count as successful, require 201 and exactly its matching new row. A failed sink acknowledgement can produce 502 after the sink commits; it does not undo the row. Record the response and ledger result separately in that case.
1. After each group of denied requests, make one fresh permitted call and apply step 4. A failed positive control invalidates the enforcement check. Without this control, a broken or unreachable sink could look like successful authorization enforcement.

Use [Envoy access logs](/docs/tasks/observability/logs/access-log/) and the effective proxy configuration to identify mesh authorization denials. Correlate requests with recorded peer-identity metadata without exporting private keys. Use application audit records to distinguish tool application validation from downstream POSTs.

### Argument checks

Send each request below from `agent-alpha` to `POST /tools/followups`, following the shared procedure. Only the arguments change:

| Tenant | Resource | Operation | Expected response | Expected committed rows added |
| --- | --- | --- | ---: | ---: |
| `alpha` | `ticket-1042` | `create_followup` | 201 | 1 |
| `beta` | `ticket-1042` | `create_followup` | 403 | 0 |
| `alpha` | `ticket-9001` | `create_followup` | 403 | 0 |
| `alpha` | `ticket-1042` | `delete_ticket` | 403 | 0 |

All four calls should reach the tool application because the caller and HTTP route are permitted. Its argument checks should reject the last three without sending a downstream POST or adding a row.

### Workload identity and transport

Send forged identity headers from an untrusted client with a valid mesh certificate. Envoy should deny the request before the tool application's handler runs. A tenant rejection should happen inside the tool application, after sidecar authorization.

Also try a client without a sidecar, deliberately given the trusted ServiceAccount name. Under STRICT mTLS, the request should fail at the transport boundary without returning HTTP 403. Kubernetes metadata alone doesn't authenticate a network peer. An injected client's `http://` URL also doesn't prove plaintext traffic: its proxy can establish mTLS to the destination proxy.

### Methods, paths, and direct sink access

Try GET, PUT, DELETE, an admin path, and direct sink calls. Apply the shared procedure to each probe; a response status alone could miss a row committed before an error.

Check trailing slashes, doubled slashes, dot segments, encoded separators, and query strings. Before using the normalization setting elsewhere, review Istio's [path normalization guidance](/docs/ops/best-practices/security/#understand-path-normalization-in-authorization-policy) alongside your application's router. Disabling normalization isn't a general recommendation.

Istio's [authorization policy path matching](/docs/reference/config/security/normalization/) ignores the query, but the backend still receives it. In this example, the literal dispatcher should reject `/tools/followups?x=1` before `action()` runs, without forwarding or adding a row.

From the permitted `tool-gateway` workload, send a valid request to the sink's Service DNS name as a positive control under the shared procedure.

Repeat the direct Pod-IP probe, recording the caller, request authority (`Host`), and effective routing. A Service `Host` header can select service routing despite a Pod-IP destination; that result does not establish coverage of direct Pod-IP passthrough.

Use proxy evidence to distinguish transport rejection from authenticated RBAC denial. An error status, reset, or timeout cannot identify the rejecting boundary. If a permitted direct-address request succeeds, apply step 4 of the shared procedure, then establish the actual transport and authorization path before drawing a conclusion.

### Policy revocation

Use a fresh HTTP connection for each step, leaving existing connections and streams untested. Start with a permitted call that meets the shared procedure's success conditions.

Remove the narrow ALLOW policy for the tool application and leave allow-nothing in place. Wait until the destination proxy receives the changed configuration before sending a fresh valid request from the same trusted workload. After propagation, the proxy should deny the request before the tool application runs, leaving the sink unchanged. Apply the denial check in step 3.

Restore the exact narrow policy and wait for proxy convergence. Then send a fresh valid request: it should meet the success conditions in step 4, confirming that the request path still works.

These checks cover enforcement after observed policy propagation. Deleting a policy in the API server doesn't prove that the data plane has enforced the change. The checks don't establish instantaneous revocation, cancellation of an in-flight request, or invalidation of Kubernetes credentials.

## Scope and limits

The topology has no ingress or egress gateway deployment, ambient configuration, model inference, or production workload. The ledger covers serial requests whose entire effect is a committed row. If you add a notification or another provider call, each added effect needs its own authorization and recovery handling.
