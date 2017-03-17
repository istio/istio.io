---
bodyclass: docs
headline: gRPC Concepts
layout: docs
sidenav: doc-side-guides-nav.html
title: gRPC Concepts
type: markdown
---
<p class="lead">This document introduces some key gRPC concepts with an overview
of gRPC's architecture and RPC life cycle.</p> 

It assumes that you've read [What is gRPC?]({{site.baseurl}}/docs/guides). For
language-specific details, see the Quick Start, tutorial, and reference
documentation for your chosen language(s), where available (complete reference
docs are coming soon).

<div id="toc" class="toc mobile-toc"></div>

## Overview

### Service definition

Like many RPC systems, gRPC is based around the idea of defining a service,
specifying the methods that can be called remotely with their parameters and
return types. By default, gRPC uses [protocol
buffers](https://developers.google.com/protocol-buffers/) as the Interface
Definition Language (IDL) for describing both the service interface and the
structure of the payload messages. It is possible to use other alternatives if
desired.

```
service HelloService {
  rpc SayHello (HelloRequest) returns (HelloResponse);
}

message HelloRequest {
  string greeting = 1;
}

message HelloResponse {
  string reply = 1;
}
```


gRPC lets you define four kinds of service method:

- Unary RPCs where the client sends a single request to the server and gets a
  single response back, just like a normal function call.

```
rpc SayHello(HelloRequest) returns (HelloResponse){
}
```

- Server streaming RPCs where the client sends a request to the server and gets
  a stream to read a sequence of messages back. The client reads from the
  returned stream until there are no more messages.

```
rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse){
}
```

- Client streaming RPCs where the client writes a sequence of messages and sends
  them to the server, again using a provided stream. Once the client has
  finished writing the messages, it waits for the server to read them and return
  its response.

```
rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse) {
}
```

- Bidirectional streaming RPCs where both sides send a sequence of messages
  using a read-write stream. The two streams operate independently, so clients
  and servers can read and write in whatever order they like: for example, the
  server could wait to receive all the client messages before writing its
  responses, or it could alternately read a message then write a message, or
  some other combination of reads and writes. The order of messages in each
  stream is preserved.

```
rpc BidiHello(stream HelloRequest) returns (stream HelloResponse){
}
```

We'll look at the different types of RPC in more detail in the RPC life cycle section below.

### Using the API surface

Starting from a service definition in a .proto file, gRPC provides protocol
buffer compiler plugins that generate client- and server-side code. gRPC users
typically call these APIs on the client side and implement the corresponding API
on the server side.

- On the server side, the server implements the methods declared by the service
  and runs a gRPC server to handle client calls. The gRPC infrastructure decodes
  incoming requests, executes service methods, and encodes service responses.
- On the client side, the client has a local object known as *stub* (for some
  languages, the preferred term is *client*) that implements the same methods as
  the service. The client can then just call those methods on the local object,
  wrapping the parameters for the call in the appropriate protocol buffer
  message type - gRPC looks after sending the request(s) to the server and
  returning the server's protocol buffer response(s).

### Synchronous vs. asynchronous

Synchronous RPC calls that block until a response arrives from the server are
the closest approximation to the abstraction of a procedure call that RPC
aspires to. On the other hand, networks are inherently asynchronous and in many
scenarios it's useful to be able to start RPCs without blocking the current
thread.

The gRPC programming surface in most languages comes in both synchronous and
asynchronous flavors. You can find out more in each language's tutorial and
reference documentation (complete reference docs are coming soon).

## RPC life cycle

Now let's take a closer look at what happens when a gRPC client calls a gRPC
server method. We won't look at implementation details, you can find out more
about these in our language-specific pages.

### Unary RPC

First let's look at the simplest type of RPC, where the client sends a single request and gets back a single response.

- Once the client calls the method on the stub/client object, the server is
  notified that the RPC has been invoked with the client's [metadata](#metadata)
  for this call, the method name, and the specified [deadline](#deadlines) if
  applicable.
- The server can then either send back its own initial metadata (which must be
  sent before any response) straight away, or wait for the client's request
  message - which happens first is application-specific.
- Once the server has the client's request message, it does whatever work is
  necessary to create and populate its response. The response is then returned
  (if successful) to the client together with status details (status code and
  optional status message) and optional trailing metadata.
- If the status is OK, the client then gets the response, which completes the
  call on the client side.

### Server streaming RPC

A server-streaming RPC is similar to our simple example, except the server sends
back a stream of responses after getting the client's request message. After
sending back all its responses, the server's status details (status code and
optional status message) and optional trailing metadata are sent back to
complete on the server side. The client completes once it has all the server's
responses.

### Client streaming RPC

A client-streaming RPC is also similar to our simple example, except the client
sends a stream of requests to the server instead of a single request. The server
sends back a single response, typically but not necessarily after it has
received all the client's requests, along with its status details and optional
trailing metadata.

### Bidirectional streaming RPC

In a bidirectional streaming RPC, again the call is initiated by the client
calling the method and the server receiving the client metadata, method name,
and deadline. Again the server can choose to send back its initial metadata or
wait for the client to start sending requests.

What happens next depends on the application, as the client and server can read
and write in any order - the streams operate completely independently. So, for
example, the server could wait until it has received all the client's messages
before writing its responses, or the server and client could "ping-pong": the
server gets a request, then sends back a response, then the client sends another
request based on the response, and so on.

<a name="deadlines"></a>

### Deadlines

gRPC allows clients to specify a deadline value when calling a remote method.
This specifies how long the client wants to wait for a response from the server
before the RPC finishes with the error `DEADLINE_EXCEEDED`. On the server side,
the server can query the deadline to see if a particular method has timed out,
or how much time is left to complete the method.

How the deadline is specified varies from language to language - for example, a
deadline value is always required in Python, and not all languages have a
default deadline.


### RPC termination

In gRPC, both the client and server make independent and local determinations of
the success of the call, and their conclusions may not match. This means that,
for example, you could have an RPC that finishes successfully on the server side
("I have sent all my responses!") but fails on the client side ("The responses
arrived after my deadline!"). It's also possible for a server to decide to
complete before a client has sent all its requests.

### Cancelling RPCs

Either the client or the server can cancel an RPC at any time. A cancellation
terminates the RPC immediately so that no further work is done. It is *not* an
"undo": changes made before the cancellation will not be rolled back. Of course,
RPCs invoked via a synchronous RPC method call cannot be cancelled because
program control is not returned to the application until after the RPC has
terminated.

<a name="metadata"></a>

### Metadata

Metadata is information about a particular RPC call (such as <a href="
{{ site.baseurl }}/docs/guides/auth.html">authentication details</a>) in the
form of a list of key-value pairs, where the keys are strings and the values are
typically strings (but can be binary data). Metadata is opaque to gRPC itself -
it lets the client provide information associated with the call to the server
and vice versa.

Access to metadata is language-dependent.

### Channels

A gRPC channel provides a connection to a gRPC server on a specified host and
port and is used when creating a client stub (or just "client" in some
languages). Clients can specify channel arguments to modify gRPC's default
behaviour, such as switching on and off message compression. A channel has
state, including <code>connected</code> and <code>idle</code>.

How gRPC deals with closing down channels is language-dependent. Some languages
also permit querying channel state.

