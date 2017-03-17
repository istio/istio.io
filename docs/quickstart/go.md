---
bodyclass: docs
headline: Go Quick Start
layout: docs
sidenav: doc-side-quickstart-nav.html
type: markdown
---

<p class="lead">This guide gets you started with gRPC in Go with a simple
working example.</p>

<div id="toc"></div>

## Before you begin

### Prerequisites

#### Go version

gRPC works with Go 1.5 or higher.

```sh
$ go version
```

For installation instructions, follow this guide: [Getting Started - The Go Programming Language](https://golang.org/doc/install)

#### Install gRPC

Use the following command to install gRPC.

```sh
$ go get google.golang.org/grpc
```

#### Install Protocol Buffers v3

Install the protoc compiler that is used to generate gRPC service code. The simplest way to do this is to download pre-compiled binaries for your platform(`protoc-<version>-<platform>.zip`) from here: [https://github.com/google/protobuf/releases](https://github.com/google/protobuf/releases)

  * Unzip this file.
  * Update the environment variable `PATH` to include the path to the protoc binary file.

Next, install the protoc plugin for Go

```
$ go get -u github.com/golang/protobuf/{proto,protoc-gen-go}
```

The compiler plugin, protoc-gen-go, will be installed in $GOBIN, defaulting to $GOPATH/bin. It must be in your $PATH for the protocol compiler, protoc, to find it.  

```
$ export PATH=$PATH:$GOPATH/bin
```

## Download the example

The grpc code that was fetched with `go get google.golang.org/grpc` also contains the examples. They can be found under the examples dir: `$GOPATH/src/google.golang.org/grpc/examples`.

## Build the example

Change to the example directory

```
$ cd $GOPATH/src/google.golang.org/grpc/examples/helloworld
```

gRPC services are defined in a proto file, which is used to generate a corresponding .pb.go. This file is already generated for the helloworld example code and can be found under this directory: `$GOPATH/src/google.golang.org/grpc/examples/helloworld/helloworld`

This `helloworld.pb.go` file contains:

  * Generated client and server code.
  * Code for populating, serializing, and retrieving our `HelloRequest` and `HelloReply` message types.

## Try it!

To compile and run the server and client code, the `go run` command can be used.
In the examples directory:

```
$ go run greeter_server/main.go
```

From a different terminal:

```
$ go run greeter_client/main.go
```

If things go smoothly, you will see the `Greeting: Hello world` in the client side output.

Congratulations! You've just run a client-server application with gRPC.

## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [What is gRPC?](http://www.grpc.io/docs/#what-is-grpc) and [gRPC Basics:
Go][]. For now all you need to know is that both the server and the client
"stub" have a `SayHello` RPC method that takes a `HelloRequest` parameter from
the client and returns a `HelloReply` from the server, and that this method
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

Let's update this so that the `Greeter` service has two methods. Make sure you are in the same examples dir as above (`$GOPATH/src/google.golang.org/grpc/examples/helloworld`) 

Edit `helloworld/helloworld.proto` and update it with a new `SayHelloAgain` method, with the same request and response
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

## Generate gRPC code

Next we need to update the gRPC code used by our application to use the new
service definition. From the same examples dir as above (`$GOPATH/src/google.golang.org/grpc/examples/helloworld`)

```sh
$ protoc -I helloworld/ helloworld/helloworld.proto --go_out=plugins=grpc:helloworld
```

This regenerates the helloworld.pb.go with our new changes.

## Update and run the application

We now have new generated server and client code, but we still need to implement
and call the new method in the human-written parts of our example application.

### Update the server

Edit `greeter_server/main.go` and add the following function to it:

```go
func (s *server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
        return &pb.HelloReply{Message: "Hello again " + in.Name}, nil
}
```

### Update the client

Edit `greeter_client/main.go` to add the following code to the main function.

```go
r, err = c.SayHelloAgain(context.Background(), &pb.HelloRequest{Name: name})
if err != nil {
        log.Fatalf("could not greet: %v", err)
}
log.Printf("Greeting: %s", r.Message)
```

### Run!

Run the server 

```
$ go run greeter_server/main.go
```

On a different terminal, run the client 

```
$ go run greeter_client/main.go
```

You should see the updated output:

```
$ go run greeter_client/main.go
Greeting: Hello world
Greeting: Hello again world
```

## What's next

- Read a full explanation of this example and how gRPC works in our
  [Overview](http://www.grpc.io/docs/)
- Work through a more detailed tutorial in [gRPC Basics: Go][]
- Explore the gRPC Go core API in its [reference
  documentation](https://godoc.org/google.golang.org/grpc)

[gRPC Basics: Go]:http://www.grpc.io/docs/tutorials/basic/go.html
