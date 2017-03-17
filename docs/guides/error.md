---
bodyclass: docs
headline: Error Handling
layout: docs
sidenav: doc-side-guides-nav.html
title: Error Handling
type: markdown
---
<p class="lead"> This page describes how gRPC deals with errors, including gRPC's built-in error codes.</p>

<div id="toc" class="toc mobile-toc"></div>

## Error model

As you'll have seen in our concepts document and examples, when a gRPC call
completes successfully the server returns an `OK` status to the client
(depending on the language the `OK` status may or may not be directly used in
your code). But what happens if the call isn't successful?

If an error occurs, gRPC returns one of its error status codes instead, with an
optional string error message that provides further details about what happened.
Error information is available to gRPC clients in all supported languages.

## Error status codes

Errors are raised by gRPC under various circumstances, from network failures to
unauthenticated connections, each of which is associated with a particular
status code. The following error status codes are supported in all gRPC
languages.

### General errors

Case | Status code
-----|-----------
Client application cancelled the request | GRPC&#95;STATUS&#95;CANCELLED
Deadline expired before server returned status | GRPC&#95;STATUS&#95;DEADLINE_EXCEEDED
Method not found on server | GRPC&#95;STATUS&#95;UNIMPLEMENTED
Server shutting down | GRPC&#95;STATUS&#95;UNAVAILABLE
Server threw an exception (or did something other than returning a status code to terminate the RPC) | GRPC&#95;STATUS&#95;UNKNOWN


### Network failures

Case | Status code
-----|-----------
No data transmitted before deadline expires. Also applies to cases where some data is transmitted and no other failures are detected before the deadline expires | GRPC&#95;STATUS&#95;DEADLINE_EXCEEDED
Some data transmitted (for example, the request metadata has been written to the TCP connection) before the connection breaks | GRPC&#95;STATUS&#95;UNAVAILABLE


### Protocol errors

Case | Status code
-----|-----------
Could not decompress but compression algorithm supported | GRPC&#95;STATUS&#95;INTERNAL
Compression mechanism used by client not supported by the server | GRPC&#95;STATUS&#95;UNIMPLEMENTED
Flow-control resource limits reached | GRPC&#95;STATUS&#95;RESOURCE_EXHAUSTED
Flow-control protocol violation | GRPC&#95;STATUS&#95;INTERNAL
Error parsing returned status | GRPC&#95;STATUS&#95;UNKNOWN
Unauthenticated: credentials failed to get metadata | GRPC&#95;STATUS&#95;UNAUTHENTICATED
Invalid host set in authority metadata | GRPC&#95;STATUS&#95;UNAUTHENTICATED
Error parsing response protocol buffer | GRPC&#95;STATUS&#95;INTERNAL
Error parsing request protocol buffer | GRPC&#95;STATUS&#95;INTERNAL
