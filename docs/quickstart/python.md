---
bodyclass: docs
layout: docs
headline: Python Quickstart
sidenav: doc-side-quickstart-nav.html
type: markdown
---
<p class="lead">This guide gets you started with gRPC in Python with a simple
working example.</p>

<div id="toc"></div>

## Before you begin

### Prerequisites

Ensure you have `pip` version 8 or higher:

```sh
$ python -m pip install --upgrade pip
```

If you cannot upgrade `pip` due to a system-owned installation, you can
run the example in a virtualenv:

```sh
$ python -m pip install virtualenv
$ virtualenv venv
$ source venv/bin/activate
$ python -m pip install --upgrade pip
```

### Install gRPC

Install gRPC:

```sh
$ python -m pip install grpcio
```

Or, to install it system wide:

```sh
$ sudo python -m pip install grpcio
```

On El Capitan OSX, you may get the following error:

```sh
$ OSError: [Errno 1] Operation not permitted: '/tmp/pip-qwTLbI-uninstall/System/Library/Frameworks/Python.framework/Versions/2.7/Extras/lib/python/six-1.4.1-py2.7.egg-info'
```

You can work around this using:

```sh
$ python -m pip install grpcio --ignore-installed
```

### Install gRPC tools

Python's gRPC tools include the protocol buffer compiler `protoc` and the
special plugin for generating server and client code from `.proto` service
definitions. For the first part of our quickstart example, we've already
generated the server and client stubs from
[helloworld.proto](https://github.com/grpc/grpc/tree/{{site.data.config.grpc_release_branch}}/examples/protos/helloworld.proto),
but you'll need the tools for the rest of our quickstart, as well as later
tutorials and your own projects.

To install gRPC tools, run:

```sh
$ python -m pip install grpcio-tools
```

## Download the example

You'll need a local copy of the example code to work through this quickstart.
Download the example code from our Github repository (the following command
clones the entire repository, but you just need the examples for this quickstart
and other tutorials):

```sh
$ # Clone the repository to get the example code:
$ git clone https://github.com/grpc/grpc
$ # Navigate to the "hello, world" Python example:
$ cd grpc/examples/python/helloworld
```

## Run a gRPC application

From the `examples/python/helloworld` directory:

1. Run the server

   ```sh
   $ python greeter_server.py
   ```

2. In another terminal, run the client

   ```sh
   $ python greeter_client.py
   ```

Congratulations! You've just run a client-server application with gRPC.

## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [What is gRPC?]() and [gRPC Basics: Python][]. For now all you need
to know is that both the server and the client "stub" have a `SayHello` RPC
method that takes a `HelloRequest` parameter from the client and returns a
`HelloResponse` from the server, and that this method is defined like this:


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
`examples/protos/helloworld.proto` and update it with a new `SayHelloAgain`
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

## Generate gRPC code

Next we need to update the gRPC code used by our application to use the new
service definition. 

From the `examples/python/helloworld` directory, run:

```sh
$ python -m grpc_tools.protoc -I../../protos --python_out=. --grpc_python_out=. ../../protos/helloworld.proto
```

This regenerates `helloworld_pb2.py` which contains our generated request and
response classes and `helloworld_pb2_grpc.py` which contains our generated
client and server classes.

## Update and run the application

We now have new generated server and client code, but we still need to implement
and call the new method in the human-written parts of our example application.

### Update the server

In the same directory, open `greeter_server.py`. Implement the new method like
this:

```
class Greeter(helloworld_pb2_grpc.GreeterServicer):

  def SayHello(self, request, context):
    return helloworld_pb2.HelloReply(message='Hello, %s!' % request.name)

  def SayHelloAgain(self, request, context):
    return helloworld_pb2.HelloReply(message='Hello again, %s!' % request.name)
...
```

### Update the client

In the same directory, open `greeter_client.py`. Call the new method like this:

```
def run():
  channel = grpc.insecure_channel('localhost:50051')
  stub = helloworld_pb2_grpc.GreeterStub(channel)
  response = stub.SayHello(helloworld_pb2.HelloRequest(name='you'))
  print("Greeter client received: " + response.message)
  response = stub.SayHelloAgain(helloworld_pb2.HelloRequest(name='you'))
  print("Greeter client received: " + response.message)
```

### Run!

Just like we did before, from the `examples/python/helloworld` directory:

1. Run the server

   ```sh
   $ python greeter_server.py
   ```

2. In another terminal, run the client

   ```sh
   $ python greeter_client.py
   ```

## What's next

- Read a full explanation of this example and how gRPC works in our
  [Overview](http://www.grpc.io/docs/)
- Work through a more detailed tutorial in [gRPC Basics: Python][]
- Explore the gRPC Python core API in its [reference
  documentation](http://www.grpc.io/grpc/python/)

[helloworld.proto]:../protos/helloworld.proto
[gRPC Basics: Python]:http://www.grpc.io/docs/tutorials/basic/python.html

