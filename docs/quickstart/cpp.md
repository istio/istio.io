---
bodyclass: docs
layout: docs
headline: C++ Quickstart
sidenav: doc-side-quickstart-nav.html
type: markdown
---
<p class="lead">This guide gets you started with gRPC in C++ with a simple
working example.</p>

<div id="toc"></div>

## Before you begin

### Prerequisites

#### Install gRPC

To install gRPC on your system, follow the instructions to build from source
[here](https://github.com/grpc/grpc/blob/master/INSTALL.md).

#### Install Protocol Buffers v3

While not mandatory, gRPC usually leverages Protocol Buffers v3 for service
definitions and data serialization. If you don't already have it installed on
your system, you can install the version cloned alongside gRPC. First ensure
that you are running these commands from within your cloned gRPC repository
from the previous step.

```sh
$ git submodule update --init
$ cd grpc/third_party/protobuf
$ ./autogen.sh
$ ./configure
$ make
$ sudo make install
```

See [the official Protocol Buffers install
guide](https://github.com/google/protobuf/blob/master/src/README.md) for
details.

Note that you also need `pkg-config` installed on your system. On Ubuntu/Debian
systems, this can be done via `sudo apt-get install pkg-config`.


## Build the example

Always assuming you have gRPC properly installed, go into the example's
directory:

```sh
$ cd examples/cpp/helloworld/
```

Let's build the example client and server:
```sh
$ make
```

Most failures at this point are a result of a faulty installation (or having
installed gRPC to a non-standard location. Check out [the installation
instructions for details](https://github.com/grpc/grpc/blob/master/INSTALL.md)).

## Try it!

From the `examples/cpp/helloworld` directory, run the server, which will listen
on port 50051:
```sh
$ ./greeter_server
```

From a different terminal, run the client:
```sh
$ ./greeter_client
```

If things go smoothly, you will see the `Greeter received: Hello world` in the
client side output.

Congratulations! You've just run a client-server application with gRPC.


## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [What is gRPC?](http://www.grpc.io/docs/#what-is-grpc) and [gRPC Basics:
C++][]. For now all you need to know is that both the server and the client
"stub" have a `SayHello` RPC method that takes a `HelloRequest` parameter from
the client and returns a `HelloResponse` from the server, and that this method
is defined like this:


```protobuf
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
`examples/protos/helloworld.proto` (from the root of the cloned repository) and
update it with a new `SayHelloAgain` method, with the same request and response
types:


```protobuf
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

## Generate gRPC code

Next we need to update the gRPC code used by our application to use the new
service definition. From the `examples/cpp/helloworld` directory:

```sh
$ make
```

This regenerates `helloworld.pb.{h,cc}` and `helloworld.grpc.pb.{h,cc}`, which
contains our generated client and server classes, as well as classes for
populating, serializing, and retrieving our request and response types.

## Update and run the application

We now have new generated server and client code, but we still need to implement
and call the new method in the human-written parts of our example application.

### Update the server

In the same directory, open `greeter_server.cc`. Implement the new method like
this:


```
class GreeterServiceImpl final : public Greeter::Service {
  Status SayHello(ServerContext* context, const HelloRequest* request,
                  HelloReply* reply) override {
     // ... (pre-existing code)
  }

  Status SayHelloAgain(ServerContext* context, const HelloRequest* request
                       HelloReply* reply) override {
    std::string prefix("Hello again ");
    reply->set_message(prefix + request->name());
    return Status::OK;
  }
};

```

### Update the client

A new `SayHelloAgain` method is now available in the stub. We'll follow the same
pattern as for the already present `SayHello` and add a new `SayHelloAgain`
method to `GreeterClient`:

```
class GreeterClient {
 public:
  // ...
  std::string SayHello(const std::string& user) {
     // ...
  }

  std::string SayHelloAgain(const std::string& user) {
    // Follows the same pattern as SayHello.
    HelloRequest request;
    request.set_name(user);
    HelloReply reply;
    ClientContext context;

    // Here we can the stub's newly available method we just added.
    Status status = stub_->SayHelloAgain(&context, request, &reply);
    if (status.ok()) {
      return reply.message();
    } else {
      std::cout << status.error_code() << ": " << status.error_message()
                << std::endl;
      return "RPC failed";
    }
  }

```

Finally, we exercise this new method in `main`:

```
int main(int argc, char** argv) {
  // ...
  std::string reply = greeter.SayHello(user);
  std::cout << "Greeter received: " << reply << std::endl;

  reply = greeter.SayHelloAgain(user);
  std::cout << "Greeter received: " << reply << std::endl;

  return 0;
}

```

### Run!

Just like we did before, from the `examples/cpp/helloworld` directory:

1. Build the client and server after having made changes:
   ```sh
   $ make
   ```

1. Run the server

   ```sh
   $ ./greeter_server
   ```

2. On a different terminal, run the client

   ```sh
   $ ./greeter_client
   ```

   You should see the updated output:
   ```
   $ ./greeter_client
   Greeter received: Hello world
   Greeter received: Hello again world
   ```

## What's next

- Read a full explanation of this example and how gRPC works in our
  [Overview](http://www.grpc.io/docs/)
- Work through a more detailed tutorial in [gRPC Basics: C++][]
- Explore the gRPC C++ core API in its [reference
  documentation](http://www.grpc.io/grpc/cpp/)

[gRPC Basics: C++]:http://www.grpc.io/docs/tutorials/basic/c.html
