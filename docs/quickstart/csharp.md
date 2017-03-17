---
bodyclass: docs
headline: C# Quick Start
layout: docs
sidenav: doc-side-quickstart-nav.html
type: markdown
---

<h1 class="page-header">C# Quickstart</h1>

<p class="lead">This guide gets you started with gRPC in C# with a simple
working example.</p>

<div id="toc"></div>

## Before you begin

### Prerequisites

Whether you're using Windows, OS X, or Linux, you can follow this
example by using either an IDE and its build tools,
or by using the the .NET Core SDK command line tools.

Using the .NET Core SDK on Windows, OS X, or Linux, you'll need:

* The .NET Core SDK command line tools. 
* The .NET framework 4.5 (for OS X and Linux, the open source .NET Framework implementation, "Mono", at version 4+, is suitable) 
* Git (to download the sample code)

On Windows, using Visual Studio, you'll need: 

* .NET Framework 4.5+
* Visual Studio 2013 or 2015.
* Git (to download the sample code)

On OS X, using Xamarin Studio, you'll need:

* Mono 4.4.2+ (or Mono 4+ is sufficient if you manually update NuGet to version 2.12+) 
* Xamarin Studio 6.0+ 
* Git (to download the sample code)

On Linux, using the Monodevelop IDE, you'll need:

* Mono 4.4.2+ (or Mono 4+ is sufficient if you manually update nuget to version 2.12+) 
* MonoDevelop 5.9+
* A NuGet executable, at version 2.12+ (you'll need to restore NuGet package dependencies from the command line)
* Git (to download the sample code)

## Download the example

You'll need a local copy of the example code to work through this quickstart.
Download the example code from our Github repository (the following command
clones the entire repository, but you just need the examples for this quickstart
and other tutorials):

```sh
$ # Clone the repository to get the example code:
$ git clone -b v1.0.x https://github.com/grpc/grpc 
$ cd grpc
```

#### Using Visual Studio, Xamarin Studio, or Mondevelop IDEs

* The examples are in the directory, `examples/csharp/helloworld`.

#### Using the .NET Core SDK

* A .NET Core SDK version of the hello world examples are in the directory, `examples/csharp/helloworld-from-cli`.

The example in this walkthrough already adds the necessary
dependencies for you (Grpc, Grpc.Tools and Google.Protobuf NuGet packages).

## Build the example

### Using Visual Studio
* Open the solution `Greeter.sln` with Visual Studio.
* Build the solution (this will automatically download NuGet dependencies)

### Using Xamarin Studio
* Open the solution `Greeter.sln` with Xamarin Studio.
* Project->"Restore NuGet Packages"
* Build the solution (this will automatically download NuGet dependencies)

### Using .NET Core SDK from the command line
From the `examples/csharp/helloworld-from-cli` directory:

```
> dotnet restore
> dotnet build **/project.json
```

### Using the Monodevelop IDE
Using the Monodevelop IDE, you can build and edit a solution that uses gRPC 
without issues, but unfortunately a workaround is necessary in order to initially restore
a NuGet dependency on C# gRPC.

The problem is that C# gRPC package currently depends on 
System.Interactive.Async 3.0.0, which requires NuGet 2.12+ to install.
The NuGet included on the latest versions of Monodevelop is too old to install gRPC C#.

If you don't want to change the version of NuGet that you're using, 
a possible workaround to get these files is to download the NuGet 
package and unzip without a NuGet client, as follows.

* Install NuGet 2.12+ so that it's available from the command line.
* From the `examples/csharp/helloworld` directory, run `/path/to/nuget restore`. 
* Now that the NuGet dependencies are restored into their proper package folders, build
  the solution from the Monodevelop IDE.
  
## Run a gRPC application

### Using Visual Studio, Xamarin Studio, or Monodevelop IDEs
From the `examples/csharp/helloworld` directory:

* Run the server

```
> cd GreeterServer/bin/Debug
> GreeterServer.exe
```

* In another terminal, run the client

```
> cd GreeterClient/bin/Debug
> GreeterClient.exe
```

You'll need to run the above executables with "mono" if building on Xamarin Studio for OS X.

###  Using the .NET Core SDK

* Run the server

```
> cd GreeterServer
> dotnet run
```


* In another terminal, run the client

```
> cd GreeterClient
> dotnet run
```

Congratulations! You've just run a client-server application with gRPC.

## Update a gRPC service

Now let's look at how to update the application with an extra method on the
server for the client to call. Our gRPC service is defined using protocol
buffers; you can find out lots more about how to define a service in a `.proto`
file in [gRPC Basics: C#][]. For now all you need to know is that both the
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

Next we need to update the gRPC code used by our application to use the new service definition. 

The `Grpc.Tools` NuGet package contains the protoc and protobuf C# plugin binaries you will need to generate the code. 

### Obtaining the Grpc.Tools NuGet package

#### Using Visual Studio

This example project already depends on the `Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}` NuGet package, so it should be included in `examples/csharp/helloworld/packages` when the `Greeter.sln` solution is built from your IDE, 
or when you restore packages via `/path/to/nuget restore` on the command line.

#### If you have a NuGet client that is __not__ at version 2.12

```
$ mkdir packages && cd packages
$ /path/to/nuget install Grpc.Tools
```

#### If you have a NuGet client that is at version 2.12

NuGet 2.12 does not install the files from the `Grpc.Tools` package necessary on Linux and OS X.
Without changing the version of NuGet that you're using, a possible workaround to obtaining the binaries included in the `Grpc.Tools` package 
is by simply downloading the NuGet package and unzipping without a NuGet client, as follows.
From your example directory:

```
$ temp_dir=packages/Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}/tmp
$ curl_url=https://www.nuget.org/api/v2/package/Grpc.Tools/{{ Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}
$ mkdir -p $temp_dir && cd $temp_dir && curl -sL $curl_url > tmp.zip; unzip tmp.zip && cd .. && cp -r tmp/tools . && rm -rf tmp && cd ../..
```

### Commands to generate the gRPC code
Note that you may have to change the `platform_architecture` directory names (e.g. windows_x86, linux_x64) in the commands below based on your environment.

Note that you may also have to change the permissions of the protoc and protobuf
binaries in the `Grpc.Tools` package under `examples/csharp/helloworld/packages`
to executable in order to run the commands below.

From the `examples/csharp/helloworld` directory, or the `examples/csharp/helloworld-from-cli` directory if using the .NET Core SDK:

**Windows**

```
> packages\Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}\tools\windows_x86\protoc.exe -I../../protos --csharp_out Greeter --grpc_out Greeter ../../protos/helloworld.proto --plugin=protoc-gen-grpc=packages/Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}/tools/windows_x86/grpc_csharp_plugin.exe
```

**Linux (or OS X by using macosx_x64 directory)**

```
$ packages/Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}/tools/linux_x64/protoc -I../../protos --csharp_out Greeter --grpc_out Greeter ../../protos/helloworld.proto --plugin=protoc-gen-grpc=packages/Grpc.Tools.{{ site.data.config.grpc_release_branch | remove_first: "v" }}/tools/linux_x64/grpc_csharp_plugin
```

Running the appropriate command for your OS regenerates the following files in
the directory:

* Greeter/Helloworld.cs contains all the protocol buffer code to populate,
  serialize, and retrieve our request and response message types
* Greeter/HelloworldGrpc.cs provides generated client and server classes,
  including:
    * an abstract class Greeter.GreeterBase to inherit from when defining
      Greeter service implementations
    * a class Greeter.GreeterClient that can be used to access remote Greeter
      instances
    
## Update and run the application

We now have new generated server and client code, but we still need to implement
and call the new method in the human-written parts of our example application.

### Update the server

With the `Greeter.sln` open in your IDE, open `GreeterServer/Program.cs`.
Implement the new method by editing the GreeterImpl class like this:

```
class GreeterImpl : Greeter.GreeterBase
{
    // Server side handler of the SayHello RPC
    public override Task<HelloReply> SayHello(HelloRequest request, ServerCallContext context)
    {
        return Task.FromResult(new HelloReply { Message = "Hello " + request.Name });
    }

    // Server side handler for the SayHelloAgain RPC
    public override Task<HelloReply> SayHelloAgain(HelloRequest request, ServerCallContext context)
    {
        return Task.FromResult(new HelloReply { Message = "Hello again " + request.Name });
    }
}
```

### Update the client

With the same `Greeter.sln` open in your IDE, open `GreeterClient/Program.cs`.
Call the new method like this:

```
public static void Main(string[] args)
{
    Channel channel = new Channel("127.0.0.1:50051", ChannelCredentials.Insecure);

    var client = new Greeter.GreeterClient(channel);
    String user = "you";

    var reply = client.SayHello(new HelloRequest { Name = user });
    Console.WriteLine("Greeting: " + reply.Message);
    
    var secondReply = client.SayHelloAgain(new HelloRequest { Name = user });
    Console.WriteLine("Greeting: " + secondReply.Message);

    channel.ShutdownAsync().Wait();
    Console.WriteLine("Press any key to exit...");
    Console.ReadKey();
}
```

### Rebuild the modified example

Rebuild the newly modified example just like we first built the original
example:

* With solution Greeter.sln open from Visual Studio, Monodevelop (on Linux) or Xamarin Studio (on OS X)
* Build the solution 

### Run!

Just like we did before, from the `examples/csharp/helloworld` directory:

* Run the server

```
> cd GreeterServer/bin/Debug
> GreeterServer.exe
```

* In another terminal, run the client

```
> cd GreeterClient/bin/Debug
> GreeterClient.exe
```

Or if using the .NET Core SDK, from the `examples/csharp/helloworld-from-cli` directory:

* Run the server

```
> cd GreeterServer
> dotnet run
```

* In another terminal, run the client

```
> cd GreeterClient
> dotnet run
```

## What's next

- Read a full explanation of this example and how gRPC works in our
  [Overview](http://www.grpc.io/docs/)
- Work through a more detailed tutorial in [gRPC Basics: C#][]
- Explore the gRPC C# core API in its [reference
  documentation](http://www.grpc.io/grpc/csharp/)

[helloworld.proto]:../protos/helloworld.proto
[gRPC Basics: C#]:http://www.grpc.io/docs/tutorials/basic/csharp.html
