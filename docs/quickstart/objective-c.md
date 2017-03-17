---
bodyclass: docs
layout: docs
headline: Objective-C Quickstart
sidenav: doc-side-quickstart-nav.html
type: markdown
---
<p class="lead">This guide gets you started with gRPC on the iOS platform in
Objective-C with a simple working example.</p>

<div id="toc"></div>

## Before you begin

### System requirement
OS X El Capitan (version 10.11) or above is required to build and run this
Quickstart.

### Prerequisites

* `CocoaPods`: version 1.0 or higher

   * Check status and version of CocoaPods on your system with command `pod
     --version`.
   * If CocoaPods is not installed, follow the install instructions on CocoaPods
     [website](https://cocoapods.org).

* `Xcode`: version 7.2 or higher

   * Check your Xcode version by running Xcode from Lauchpad, then select
     "Xcode->About Xcode" in the menu.
   * Make sure the command line developer tools are installed:
   ```sh
   [sudo] xcode-select --install
   ```

* `Homebrew`
   * Check status and version of Homebrew on your system with command `brew
     --version`.
   * If Homebrew is not installed, install with:
   ```sh
   /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   ```

* `autoconf`, `automake`, `libtool`, `pkg-config`
   * Install with Homebrew
   ```sh
   brew install autoconf automake libtool pkg-config
   ```

## Download the example

You'll need a local copy of the sample app source code to work through this
Quickstart. Copy the source code from Github
[repository](https://github.com/grpc/grpc):

```sh
$ git clone https://github.com/grpc/grpc.git
```

## Install gRPC plugins and libraries
```sh
$ cd grpc
$ git submodule update --init
$ make
$ [sudo] make install
```

## Install protoc compiler
```sh
$ brew tap grpc/grpc
$ brew install google-protobuf
```

## Run the server

For this sample app, we need a gRPC server running on the local machine. gRPC
Objective-C API supports creating gRPC clients but not gRPC servers. Therefore 
instead we build and run the C++ server in the same repository:

```sh
$ cd examples/cpp/helloworld
$ make
$ ./greeter_server &
```

## Run the client

### Generate client libraries and dependencies

Have CocoaPods generate and install the client library from our .proto files, as
well as installing several dependencies:

```sh
$ cd ../../objective-c/helloworld
$ pod install
```

(This might have to compile OpenSSL, which takes around 15 minutes if Cocoapods
doesn't have it yet on your computer's cache.)

### Run the client app

Open the Xcode workspace created by CocoaPods:

```sh
$ open HelloWorld.xcworkspace
```

This will open the app project with Xcode. Run the app in an iOS simulator
by pressing the Run button on the top left corner of Xcode window. You can check
the calling code in `main.m` and see the results in Xcode's console.

The code sends a `HLWHelloRequest` containing the string "Objective-C" to a
local server. The server responds with a `HLWHelloResponse`, which contains a
string "Hello Objective-C" that is then output to the console.

Congratulations! You've just run a client-server application with gRPC.

## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using Protocol
Buffers; you can find out lots more about how to define a service in a `.proto`
file in Protocol Buffers 
[website](https://developers.google.com/protocol-buffers/). For now all you 
need to know is that both the server and the client "stub" have a `SayHello`
RPC method that takes a `HelloRequest` parameter from the client and returns a
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

## Update the client and server

We now have a new gRPC service definition, but we still need to implement and
call the new method in the human-written parts of our example application.

### Update the server

As you remember, gRPC doesn't provide a server API for Objective-C. Instead, we
need to update the C++ sample server. Open
`examples/cpp/helloworld/greeter_server.cc`. Implement the new method like this:

```
class GreeterServiceImpl final : public Greeter::Service {
  Status SayHello(ServerContext* context, const HelloRequest* request,
                  HelloReply* reply) override {
    std::string prefix("Hello ");
    reply->set_message(prefix + request->name());
    return Status::OK;
  }
  Status SayHelloAgain(ServerContext* context, const HelloRequest* request,
                  HelloReply* reply) override {
    std::string prefix("Hello again ");
    reply->set_message(prefix + request->name());
    return Status::OK;
  }
};
```

### Update the client

Edit `examples/objective-c/helloworld/main.m` to call the new method like this:

```
int main(int argc, char * argv[]) {
  @autoreleasepool {
    [GRPCCall useInsecureConnectionsForHost:kHostAddress];
    [GRPCCall setUserAgentPrefix:@"HelloWorld/1.0" forHost:kHostAddress];

    HLWGreeter *client = [[HLWGreeter alloc] initWithHost:kHostAddress];

    HLWHelloRequest *request = [HLWHelloRequest message];
    request.name = @"Objective-C";

    [client sayHelloWithRequest:request handler:^(HLWHelloReply *response, NSError *error) {
      NSLog(@"%@", response.message);
    }];
    [client sayHelloAgainWithRequest:request handler:^(HLWHelloReply *response, NSError *error) {
      NSLog(@"%@", response.message);
    }];

    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
```

## Build and run

First terminate the server process already running in the background:
```sh
$ pkill greeter_server
```

Then in directory `examples/cpp/helloworld`, build and run the updated server
with the following commands:

```sh
$ make
$ ./greeter_server &
```

Change directory to `examples/objective-c/helloworld`, then clean up and
reinstall Pods for the client app with the following commands:

```sh
$ rm -Rf Pods
$ rm Podfile.lock
$ rm -Rf HelloWorld.xcworkspace
$ pod install
```

This regenerates files in `Pods/HelloWorld` based on the new proto file we wrote
above. Open the client Xcode project in Xcode:

```sh
$ open HelloWorld.xcworkspace
```
and run the client app. If you look at the console messages, you should see two RPC calls,
one to SayHello and one to SayHelloAgain.

## Troubleshooting

**When installing CocoaPods, error prompt `activesupport requires Ruby version >= 2.2.2.`**

Install an older version of `activesupport`, then install CocoaPods:
```sh
[sudo] gem install activesupport -v 4.2.6
[sudo] gem install cocoapods
```

**Compiler error when compiling `objective_c_plugin.cc`**

Removing `google-protobuf` package with Homebrew before building gRPC may solve
this problem. We are working on a more elegant fix.

**When building HellowWorld, error prompt `ld: unknown option: --no-as-needed`**

This problem is due to linker `ld` in Apple LLVM not supporting the
--no-as-needed option. We are working on a fix right now and will merge the fix
very soon.

**When building grpc, error prompt `cannot find install-sh install.sh or shtool`**

Remove the gRPC directory, clone a new one and try again. It is likely that some
auto generated files are corrupt; remove and rebuild may solve the problem.

**When building grpc, error prompt `Can't exec "aclocal"`**

The package `automake` is missing. Install `automake` should solve this problem.

**When building grpc, error prompt `possibly undefined macro: AC_PROG_LIBTOOL`**

The package `libtool` is missing. Install `libtool` should solve this problem.

**When building grpc, error prompt `cannot find install-sh, install.sh, or shtool`**

Some of the auto generated files are corrupt. Remove the entire gRPC directory, 
clone from Github, and build again.

**Cannot find `protoc` when building HelloWorld**

Run `brew install google-protobuf` to get `protoc` compiler.
