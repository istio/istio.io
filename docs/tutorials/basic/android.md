---
layout: docs
bodyclass: docs
headline: gRPC Basics - Android Java
sidenav: doc-side-tutorial-nav.html
type: markdown
---

<p class="lead">This tutorial provides a basic Android Java programmer's introduction to working with gRPC.</p>

By walking through this example you'll learn how to:

- Define a service in a .proto file.
- Generate client code using the protocol buffer compiler.
- Use the Java gRPC API to write a simple mobile client for your service.

It assumes that you have read the [Overview](/docs/index.html) and are familiar with [protocol buffers](https://developers.google.com/protocol-buffers/docs/overview).
This guide also does not cover anything on the server side. You can check the [Java guide](/docs/tutorials/basic/java.md) for more information.

<div id="toc"></div>

## Why use gRPC?

Our example is a simple route mapping application that lets clients get information about features on their route, create a summary of their route, and exchange route information such as traffic updates with the server and other clients.

With gRPC we can define our service once in a .proto file and implement clients and servers in any of gRPC's supported languages, which in turn can be run in environments ranging from servers inside Google to your own tablet - all the complexity of communication between different languages and environments is handled for you by gRPC. We also get all the advantages of working with protocol buffers, including efficient serialization, a simple IDL, and easy interface updating.

## Example code and setup

The example code for our tutorial is in [grpc-java's examples/android](https://github.com/grpc/grpc-java/tree/{{ site.data.config.grpc_release_branch }}/examples/android). To download the example, clone the `grpc-java` repository by running the following command:

```
$ git clone https://github.com/grpc/grpc-java.git
```

Then change your current directory to `grpc-java/examples/android`:

```
$ cd grpc-java/examples/android
```

You also should have the relevant tools installed to generate the client interface code - if you don't already, follow the setup instructions in [the Java README](https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/README.md).


## Defining the service

Our first step (as you'll know from the [Overview](/docs/index.html)) is to define the gRPC *service* and the method *request* and *response* types using [protocol buffers](https://developers.google.com/protocol-buffers/docs/overview). You can see the complete .proto file in [`routeguide/app/src/main/proto/route_guide.proto`](https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/examples/android/routeguide/app/src/main/proto/route_guide.proto).

As we're generating Java code in this example, we've specified a `java_package` file option in our .proto:

```proto
option java_package = "io.grpc.examples";
```

This specifies the package we want to use for our generated Java classes. If no explicit `java_package` option is given in the .proto file, then by default the proto package (specified using the "package" keyword) will be used. However, proto packages generally do not make good Java packages since proto packages are not expected to start with reverse domain names. If we generate code in another language from this .proto, the `java_package` option has no effect.

To define a service, we specify a named `service` in the .proto file:

```proto
service RouteGuide {
   ...
}
```

Then we define `rpc` methods inside our service definition, specifying their request and response types. gRPC lets you define four kinds of service method, all of which are used in the `RouteGuide` service:

- A *simple RPC* where the client sends a request to the server using the stub and waits for a response to come back, just like a normal function call.

```proto
// Obtains the feature at a given position.
rpc GetFeature(Point) returns (Feature) {}
```

- A *server-side streaming RPC* where the client sends a request to the server and gets a stream to read a sequence of messages back. The client reads from the returned stream until there are no more messages. As you can see in our example, you specify a server-side streaming method by placing the `stream` keyword before the *response* type.

```proto
// Obtains the Features available within the given Rectangle.  Results are
// streamed rather than returned at once (e.g. in a response message with a
// repeated field), as the rectangle may cover a large area and contain a
// huge number of features.
rpc ListFeatures(Rectangle) returns (stream Feature) {}
```

- A *client-side streaming RPC* where the client writes a sequence of messages and sends them to the server, again using a provided stream. Once the client has finished writing the messages, it waits for the server to read them all and return its response. You specify a client-side streaming method by placing the `stream` keyword before the *request* type.

```proto
// Accepts a stream of Points on a route being traversed, returning a
// RouteSummary when traversal is completed.
rpc RecordRoute(stream Point) returns (RouteSummary) {}
```

- A *bidirectional streaming RPC* where both sides send a sequence of messages using a read-write stream. The two streams operate independently, so clients and servers can read and write in whatever order they like: for example, the server could wait to receive all the client messages before writing its responses, or it could alternately read a message then write a message, or some other combination of reads and writes. The order of messages in each stream is preserved. You specify this type of method by placing the `stream` keyword before both the request and the response.

```proto
// Accepts a stream of RouteNotes sent while a route is being traversed,
// while receiving other RouteNotes (e.g. from other users).
rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
```

Our .proto file also contains protocol buffer message type definitions for all the request and response types used in our service methods - for example, here's the `Point` message type:

```proto
// Points are represented as latitude-longitude pairs in the E7 representation
// (degrees multiplied by 10**7 and rounded to the nearest integer).
// Latitudes should be in the range +/- 90 degrees and longitude should be in
// the range +/- 180 degrees (inclusive).
message Point {
  int32 latitude = 1;
  int32 longitude = 2;
}
```


## Generating client code

Next we need to generate the gRPC client interfaces from our .proto
service definition. We do this using the protocol buffer compiler `protoc` with
a special gRPC Java plugin. You need to use the
[proto3](https://github.com/google/protobuf/releases) compiler (which supports
both proto2 and proto3 syntax) in order to generate gRPC services.

The build system for this example is also part of Java gRPC itself's build. You
can refer to the <a
href="https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/README.md">README</a> and
<a href="https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/examples/android/routeguide/app/build.gradle#L26">build.gradle</a> for
how to generate code from your own .proto files.
Note that for Android, we will use protobuf lite which is optimized for mobile usecase.

The following classes are generated from our service definition:

- `Feature.java`, `Point.java`, `Rectangle.java`, and others which contain
   all the protocol buffer code to populate, serialize, and retrieve our request
   and response message types.
- `RouteGuideGrpc.java` which contains (along with some other useful code):
  - a base class for `RouteGuide` servers to implement,
    `RouteGuideGrpc.RouteGuideImplBase`, with all the methods defined in the `RouteGuide`
    service.
  - *stub* classes that clients can use to talk to a `RouteGuide` server.


## Creating the client

In this section, we'll look at creating a Java client for our `RouteGuide` service. You can see our complete example client code in [`routeguide/app/src/main/java/io/grpc/routeguideexample/RouteGuideActivity.java`](https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/examples/android/routeguide/app/src/main/java/io/grpc/routeguideexample/RouteGuideActivity.java).

### Creating a stub

To call service methods, we first need to create a *stub*, or rather, two stubs:

- a *blocking/synchronous* stub: this means that the RPC call waits for the server to respond, and will either return a response or raise an exception.
- a *non-blocking/asynchronous* stub that makes non-blocking calls to the server, where the response is returned asynchronously. You can make certain types of streaming call only using the asynchronous stub.

First we need to create a gRPC *channel* for our stub, specifying the server address and port we want to connect to:
We use a `ManagedChannelBuilder` to create the channel.

```java
mChannel = ManagedChannelBuilder.forAddress(host, port).usePlaintext(true).build();
```

Now we can use the channel to create our stubs using the `newStub` and `newBlockingStub` methods provided in the `RouteGuideGrpc` class we generated from our .proto.

```java
blockingStub = RouteGuideGrpc.newBlockingStub(mChannel);
asyncStub = RouteGuideGrpc.newStub(mChannel);
```

### Calling service methods

Now let's look at how we call our service methods.

#### Simple RPC

Calling the simple RPC `GetFeature` on the blocking stub is as straightforward as calling a local method.

```java
Point request = Point.newBuilder().setLatitude(lat).setLongitude(lon).build();
Feature feature = blockingStub.getFeature(request);
```

We create and populate a request protocol buffer object (in our case `Point`), pass it to the `getFeature()` method on our blocking stub, and get back a `Feature`.

#### Server-side streaming RPC

Next, let's look at a server-side streaming call to `ListFeatures`, which returns a stream of geographical `Feature`s:

```java
Rectangle request =
    Rectangle.newBuilder()
        .setLo(Point.newBuilder().setLatitude(lowLat).setLongitude(lowLon).build())
        .setHi(Point.newBuilder().setLatitude(hiLat).setLongitude(hiLon).build()).build();
Iterator<Feature> features = blockingStub.listFeatures(request);
```

As you can see, it's very similar to the simple RPC we just looked at, except instead of returning a single `Feature`, the method returns an `Iterator` that the client can use to read all the returned `Feature`s.

#### Client-side streaming RPC

Now for something a little more complicated: the client-side streaming method `RecordRoute`, where we send a stream of `Point`s to the server and get back a single `RouteSummary`. For this method we need to use the asynchronous stub. If you've already read [Creating the server](https://github.com/grpc/grpc.github.io/blob/{{ site.data.config.grpc_release_branch }}/docs/tutorials/basic/java.md#creating-the-server) some of this may look very familiar - asynchronous streaming RPCs are implemented in a similar way on both sides.

```java
private String recordRoute(List<Point> points, int numPoints, RouteGuideStub asyncStub)
        throws InterruptedException, RuntimeException {
    final StringBuffer logs = new StringBuffer();
    appendLogs(logs, "*** RecordRoute");

    final CountDownLatch finishLatch = new CountDownLatch(1);
    StreamObserver<RouteSummary> responseObserver = new StreamObserver<RouteSummary>() {
        @Override
        public void onNext(RouteSummary summary) {
            appendLogs(logs, "Finished trip with {0} points. Passed {1} features. "
                    + "Travelled {2} meters. It took {3} seconds.", summary.getPointCount(),
                    summary.getFeatureCount(), summary.getDistance(),
                    summary.getElapsedTime());
        }

        @Override
        public void onError(Throwable t) {
            failed = t;
            finishLatch.countDown();
        }

        @Override
        public void onCompleted() {
            appendLogs(logs, "Finished RecordRoute");
            finishLatch.countDown();
        }
    };

    StreamObserver<Point> requestObserver = asyncStub.recordRoute(responseObserver);
    try {
        // Send numPoints points randomly selected from the points list.
        Random rand = new Random();
        for (int i = 0; i < numPoints; ++i) {
            int index = rand.nextInt(points.size());
            Point point = points.get(index);
            appendLogs(logs, "Visiting point {0}, {1}", RouteGuideUtil.getLatitude(point),
                    RouteGuideUtil.getLongitude(point));
            requestObserver.onNext(point);
            // Sleep for a bit before sending the next one.
            Thread.sleep(rand.nextInt(1000) + 500);
            if (finishLatch.getCount() == 0) {
                // RPC completed or errored before we finished sending.
                // Sending further requests won't error, but they will just be thrown away.
                break;
            }
        }
    } catch (RuntimeException e) {
        // Cancel RPC
        requestObserver.onError(e);
        throw e;
    }
    // Mark the end of requests
    requestObserver.onCompleted();

    // Receiving happens asynchronously
    if (!finishLatch.await(1, TimeUnit.MINUTES)) {
        throw new RuntimeException(
               "Could not finish rpc within 1 minute, the server is likely down");
    }

    if (failed != null) {
        throw new RuntimeException(failed);
    }
    return logs.toString();
}
```

As you can see, to call this method we need to create a `StreamObserver`, which implements a special interface for the server to call with its `RouteSummary` response. In our `StreamObserver` we:

- Override the `onNext()` method to print out the returned information when the server writes a `RouteSummary` to the message stream.
- Override the `onCompleted()` method (called when the *server* has completed the call on its side) to set a `SettableFuture` that we can check to see if the server has finished writing.

We then pass the `StreamObserver` to the asynchronous stub's `recordRoute()` method and get back our own `StreamObserver` request observer to write our `Point`s to send to the server.  Once we've finished writing points, we use the request observer's `onCompleted()` method to tell gRPC that we've finished writing on the client side. Once we're done, we check our `SettableFuture` to check that the server has completed on its side.

#### Bidirectional streaming RPC

Finally, let's look at our bidirectional streaming RPC `RouteChat()`.

```java
private String routeChat(RouteGuideStub asyncStub) throws InterruptedException,
        RuntimeException {
    final StringBuffer logs = new StringBuffer();
    appendLogs(logs, "*** RouteChat");
    final CountDownLatch finishLatch = new CountDownLatch(1);
    StreamObserver<RouteNote> requestObserver =
            asyncStub.routeChat(new StreamObserver<RouteNote>() {
                @Override
                public void onNext(RouteNote note) {
                    appendLogs(logs, "Got message \"{0}\" at {1}, {2}", note.getMessage(),
                            note.getLocation().getLatitude(),
                            note.getLocation().getLongitude());
                }

                @Override
                public void onError(Throwable t) {
                    failed = t;
                    finishLatch.countDown();
                }

                @Override
                public void onCompleted() {
                    appendLogs(logs,"Finished RouteChat");
                    finishLatch.countDown();
                }
            });

    try {
        RouteNote[] requests =
                {newNote("First message", 0, 0), newNote("Second message", 0, 1),
                        newNote("Third message", 1, 0), newNote("Fourth message", 1, 1)};

        for (RouteNote request : requests) {
            appendLogs(logs, "Sending message \"{0}\" at {1}, {2}", request.getMessage(),
                    request.getLocation().getLatitude(),
                    request.getLocation().getLongitude());
            requestObserver.onNext(request);
        }
    } catch (RuntimeException e) {
        // Cancel RPC
        requestObserver.onError(e);
        throw e;
    }
    // Mark the end of requests
    requestObserver.onCompleted();

    // Receiving happens asynchronously
    if (!finishLatch.await(1, TimeUnit.MINUTES)) {
        throw new RuntimeException(
                "Could not finish rpc within 1 minute, the server is likely down");
    }

    if (failed != null) {
        throw new RuntimeException(failed);
    }

    return logs.toString();
}
```

As with our client-side streaming example, we both get and return a `StreamObserver` response observer, except this time we send values via our method's response observer while the server is still writing messages to *their* message stream. The syntax for reading and writing here is exactly the same as for our client-streaming method. Although each side will always get the other's messages in the order they were written, both the client and server can read and write in any order — the streams operate completely independently.


## Try it out!

Follow the instructions in the example directory [README](https://github.com/grpc/grpc-java/blob/{{ site.data.config.grpc_release_branch }}/examples/android/README.md) to build and run the client and server.

