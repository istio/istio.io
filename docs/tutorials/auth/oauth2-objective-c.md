---
bodyclass: docs
layout: docs
headline: OAuth2 on gRPC - Objective-C
sidenav: doc-side-tutorial-nav.html
type: markdown
---
<p class="lead">This example demonstrates how to use OAuth2 on gRPC to make
authenticated API calls on behalf of a user.</p>

By walking through it you'll also learn how to use the Objective-C gRPC API to:

- Initialize and configure a remote call object before the RPC is started.
- Set request metadata elements on a call, which are semantically equivalent to
  HTTP request headers.
- Read response metadata from a call, which is equivalent to HTTP response
  headers and trailers.

It assumes you know the basics on how to make gRPC API calls using the
Objective-C client library, as shown in [gRPC Basics:
Objective-C](/docs/tutorials/basic/objective-c.html) and the
[overview](/docs/index.html), and are familiar with OAuth2 concepts like _access
token_.

<div id="toc"></div>

<a name="setup"></a>

## Example code and setup

The example code for our tutorial is in
[gprc/examples/objective-c/auth_sample](https://github.com/grpc/grpc/tree/
{{ site.data.config.grpc_release_branch }}/examples/objective-c/auth_sample). To
download the example, clone this repository by running the following commands:

```
$ git clone -b {{ site.data.config.grpc_release_branch }} https://github.com/grpc/grpc
$ cd grpc
$ git submodule update --init
```

Then change your current directory to `examples/objective-c/auth_sample`:

```
$ cd examples/objective-c/auth_sample
```

Our example is a simple application with two views. The first view lets a user
sign in and out using the OAuth2 flow of Google's [iOS SignIn
library](https://developers.google.com/identity/sign-in/ios/). (Google's library
is used in this example because the test gRPC service we are going to call
expects Google account credentials, but neither gRPC nor the Objective-C client
library is tied to any specific OAuth2 provider). The second view makes a gRPC
request to the test server, using the access token obtained by the first view.

Note: OAuth2 libraries need the application to register and obtain an ID from
the identity provider (in the case of this example app, Google). The app's XCode
project is configured using that ID, so you shouldn't copy this project "as is"
for your own app: it would result in your app being identified in the consent
screen as "gRPC-AuthSample", and not having access to real Google services.
Instead, configure your own XCode project following the [instructions
here](https://developers.google.com/identity/sign-in/ios/).

As with the other Objective-C examples, you also should have
[Cocoapods](https://cocoapods.org/#install) installed, as well as the relevant
tools to generate the client library code. You can obtain the latter by
following [these setup instructions](https://github.com/grpc/homebrew-grpc).


<a name="try"></a>

## Try it out!

To try the sample app, first have Cocoapods generate and install the client library for our .proto
files:

```
$ pod install
```

(This might have to compile OpenSSL, which takes around 15 minutes if Cocoapods
doesn't have it yet on your computer's cache).

Finally, open the XCode workspace created by Cocoapods, and run the app.

The first view, `SelectUserViewController.h/m`, asks you to sign in with your
Google account, and to give the "gRPC-AuthSample" app the following permissions:

- View your email address.
- View your basic profile info.
- "Test scope for access to the Zoo service".

This last permission, corresponding to the scope
`https://www.googleapis.com/auth/xapi.zoo` doesn't grant any real capability:
it's only used for testing. You can log out at any time.

The second view, `MakeRPCViewController.h/m`, makes a gRPC request to a test
server at https://grpc-test.sandbox.google.com, sending the access token along
with the request. The test service simply validates the token and writes in its
response which user it belongs to, and which scopes it gives access to. (The
client application already knows those two values; it's a way to verify that
everything went as expected).

The next sections guide you step-by-step through how the gRPC call in
`MakeRPCViewController` is performed. You can see the complete code in
[MakeRPCViewController.m](https://github.com/grpc/grpc/blob/{{ site.data.config.grpc_release_branch }}/examples/objective-c/auth_sample/MakeRPCViewController.m).

<a name="rpc-object"></a>

## Create an RPC object

The other basic tutorials show how to invoke an RPC by calling an asynchronous
method in a generated client object. However, to make an authenticated call you
need to initialize an object that represents the RPC, and configure it _before_
starting the network request. First let's look at how to create the RPC object.

Assume you have a proto service definition like this:

```protobuf
option objc_class_prefix = "AUTH";

service TestService {
  rpc UnaryCall(Request) returns (Response);
}
```

A `unaryCallWithRequest:handler:` method, with which you're already familiar, is
generated for the `AUTHTestService` class:

```objective-c
[client unaryCallWithRequest:request handler:^(AUTHResponse *response, NSError *error) {
  ...
}];
```

In addition, an `RPCToUnaryCallWithRequest:handler:` method is generated, which returns a
not-yet-started RPC object:

```objective-c
#import <ProtoRPC/ProtoRPC.h>

ProtoRPC *call =
    [client RPCToUnaryCallWithRequest:request handler:^(AUTHResponse *response, NSError *error) {
      ...
    }];
```

You can start the RPC represented by this object at any later time like this:

```objective-c
[call start];
```
<a name="request-metadata"></a>

## Setting request metadata: Auth header with an access token

Now let's look at how to configure some settings on the RPC object. The
`ProtoRPC` class has a `requestHeaders` property (inherited from `GRPCCall`)
defined like this:

```objective-c
@property(atomic, readonly) id<GRPCRequestHeaders> requestHeaders
```

You can think of the `GRPCRequestHeaders` protocol as equivalent to the
`NSMutableDictionary` class. Setting elements of this dictionary of metadata
keys and values means this metadata will be sent on the wire when the call is
started. gRPC metadata are pieces of information about the call sent by the
client to the server (and vice versa). They take the form of key-value pairs and
are essentially opaque to gRPC itself.

For convenience, the property is initialized with an empty
`NSMutableDictionary`, so that request metadata elements can be set like this:

```objective-c
call.requestHeaders[@"My-Header"] = @"Value for this header";
call.requestHeaders[@"Another-Header"] = @"Its value";
```

A typical use of metadata is for authentication details, as in our example. If
you have an access token, OAuth2 specifies it is to be sent in this format:

```objective-c
call.requestHeaders[@"Authorization"] = [@"Bearer " stringByAppendingString:accessToken];
```

<a name="response-metadata"></a>

## Getting response metadata: Auth challenge header

The `ProtoRPC` class also inherits a pair of properties, `responseHeaders` and
`responseTrailers`, analogous to the request metadata we just looked at but sent
back by the server to the client. They are defined like this:

```objective-c
@property(atomic, readonly) NSDictionary *responseHeaders;
@property(atomic, readonly) NSDictionary *responseTrailers;
```

In OAuth2, if there's an authentication error the server will send back a
challenge header. This is returned in the RPC's response headers. To access
this, as in our example's error-handling code, you write:

```objective-c
call.responseHeaders[@"www-authenticate"]
```

Note that, as gRPC metadata elements are mapped to HTTP/2 headers (or trailers),
the keys of the response metadata are always ASCII strings in lowercase.

Many uses cases of response metadata involve getting more details about an RPC
error. For convenience, when a `NSError` instance is passed to an RPC handler
block, the response headers and trailers dictionaries can also be accessed this
way:

```objective-c
error.userInfo[kGRPCHeadersKey] == call.responseHeaders
error.userInfo[kGRPCTrailersKey] == call.responseTrailers
```

