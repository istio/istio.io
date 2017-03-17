---
bodyclass: docs
layout: docs
headline: Android Java Quickstart
sidenav: doc-side-quickstart-nav.html
type: markdown
---
<p class="lead">This guide gets you started with gRPC in Android Java with a simple
working example.</p>

<div id="toc"></div>

## Before you begin

### Prerequisites

* `JDK`: version 7 or higher
* Android SDK

## Download the example

You'll need a local copy of the example code to work through this quickstart.
Download the example code from our Github repository (the following command
clones the entire repository, but you just need the examples for this quickstart
and other tutorials):

```sh
$ # Clone the repository at the latest release to get the example code:
$ git clone -b {{ site.data.config.grpc_java_release_tag }} https://github.com/grpc/grpc-java
$ # Navigate to the Java examples:
$ cd grpc-java/examples
```

## Run a gRPC application

1. Compile the server

   ```sh
   $ ./gradlew installDist
   ```

2. Run the server

   ```sh
   $ ./build/install/examples/bin/hello-world-server
   ```

3. In another terminal, compile and run the client

   ```sh
   $ cd android/helloworld
   $ ./gradlew installDebug
   ```

Congratulations! You've just run a client-server application with gRPC.

## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [gRPC Basics: Android Java][]. For now all you need to know is that both the
server and the client "stub" have a `SayHello` RPC method that takes a
`HelloRequest` parameter from the client and returns a `HelloResponse` from the
server, and that this method is defined like this:


```
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```
Let's update this so that the `Greeter` service has two methods. Edit
`src/main/proto/helloworld.proto` and update it with a new `SayHelloAgain`
method, with the same request and response types:

```
// The greeting service definition.
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  // Sends another greeting
  rpc SayHelloAgain (HelloRequest) returns (HelloReply) {}
}

// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

(Don't forget to save the file!)

## Update and run the application

When we recompile the example, normal compilation will regenerate
`GreeterGrpc.java`, which contains our generated gRPC client and server classes.
This also regenerates classes for populating, serializing, and retrieving our
request and response types.

However, we still need to implement and call the new method in the human-written
parts of our example application.

### Update the server

Check out the Java quickstart [here](/docs/quickstart/java.md#update-the-server).

### Update the client

In the same directory, open
`app/src/main/java/io/grpc/helloworldexample/HelloworldActivity.java`. Call the new
method like this:

```
    try {
        HelloRequest message = HelloRequest.newBuilder().setName(mMessage).build();
        HelloReply reply = stub.sayHello(message);
        reply = stub.sayHelloAgain(message);
    } catch (Exception e) {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        pw.flush();
        return "Failed... : " + System.lineSeparator() + sw;
    }
```

### Run!

Just like we did before, from the `examples` directory:

1. Compile the server

   ```sh
   $ ./gradlew installDist
   ```

2. Run the server

   ```sh
   $ ./build/install/examples/bin/hello-world-server
   ```

3. In another terminal, compile and run the client

   ```sh
   $ cd android/helloworld
   $ ./gradlew installDebug
   ```

## What's next

- Read a full explanation of this example and how gRPC works in our
  [Overview](http://www.grpc.io/docs/)
- Work through a more detailed tutorial in [gRPC Basics: Android Java][]
- Explore the gRPC Java core API in its [reference
  documentation](http://www.grpc.io/grpc-java/javadoc/)

[gRPC Basics: Android Java]:http://www.grpc.io/docs/tutorials/basic/android.html

