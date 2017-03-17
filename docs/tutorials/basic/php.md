---
bodyclass: docs
layout: docs
headline: gRPC Basics - PHP
sidenav: doc-side-tutorial-nav.html
type: markdown
---
<p class="lead">This tutorial provides a basic PHP programmer's introduction to
working with gRPC.</p>

By walking through this example you'll learn how to:

- Define a service in a .proto file.
- Generate client code using the protocol buffer compiler.
- Use the PHP gRPC API to write a simple client for your service.

It assumes a passing familiarity with [protocol
buffers](https://developers.google.com/protocol-buffers/docs/overview). Note
that the example in this tutorial uses the proto2 version of the protocol
buffers language.

Also note that currently you can only create clients in PHP for gRPC services -
you can find out how to create gRPC servers in our other tutorials, e.g.
[Node.js](/docs/tutorials/basic/node.html).

<div id="toc"></div>

<a name="why-grpc"></a>

## Why use gRPC?

With gRPC you can define your service once in a .proto file and implement
clients and servers in any of gRPC's supported languages, which in turn can be
run in environments ranging from servers inside Google to your own tablet - all
the complexity of communication between different languages and environments is
handled for you by gRPC. You also get all the advantages of working with
protocol buffers, including efficient serialization, a simple IDL, and easy
interface updating.


<a name="setup"></a>

## Example code and setup

The example code for our tutorial is in
[grpc/grpc/examples/php/route_guide](https://github.com/grpc/grpc/tree/{{ site.data.config.grpc_release_branch }}/examples/php/route_guide).
To download the example, clone the `grpc` repository by running the following
command:

```
$ git clone -b {{ site.data.config.grpc_release_branch }} https://github.com/grpc/grpc
```

Then change your current directory to `examples/php/route_guide`:

```
$ cd examples/php/route_guide
```

Our example is a simple route mapping application that lets clients get
information about features on their route, create a summary of their route, and
exchange route information such as traffic updates with the server and other
clients.

You also should have the relevant tools installed to generate the client
interface code (and a server in another language, for testing). You can obtain
the latter by following [these setup
instructions](/docs/tutorials/basic/node.html).


<a name="try"></a>

## Try it out!

To try the sample app, we need a gRPC server running locally. Let's compile and
run, for example, the Node.js server in this repository:

```
$ cd ../../node
$ npm install
$ cd dynamic_codegen/route_guide
$ nodejs ./route_guide_server.js --db_path=route_guide_db.json
```

Run the PHP client (in a different terminal):

```
$ ./run_route_guide_client.sh
```

The next sections guide you step-by-step through how this proto service is
defined, how to generate a client library from it, and how to create a client
stub that uses that library.


<a name="proto"></a>

## Defining the service

First let's look at how the service we're using is defined. A gRPC *service* and
its method *request* and *response* types using [protocol
buffers](https://developers.google.com/protocol-buffers/docs/overview). You can
see the complete .proto file for our example in
[`examples/protos/route_guide.proto`](https://github.com/grpc/grpc/blob/{{ site.data.config.grpc_release_branch }}/examples/protos/route_guide.proto).

To define a service, you specify a named `service` in your .proto file:

```protobuf
service RouteGuide {
   ...
}
```

Then you define `rpc` methods inside your service definition, specifying their
request and response types. Protocol buffers let you define four kinds of
service method, all of which are used in the `RouteGuide` service:

- A *simple RPC* where the client sends a request to the server and receives a
  response later, just like a normal remote procedure call.

```protobuf
// Obtains the feature at a given position.
rpc GetFeature(Point) returns (Feature) {}
```

- A *response-streaming RPC* where the client sends a request to the server and
  gets back a stream of response messages. You specify a response-streaming
  method by placing the `stream` keyword before the *response* type.

```protobuf
// Obtains the Features available within the given Rectangle.  Results are
// streamed rather than returned at once (e.g. in a response message with a
// repeated field), as the rectangle may cover a large area and contain a
// huge number of features.
rpc ListFeatures(Rectangle) returns (stream Feature) {}
```

- A *request-streaming RPC* where the client sends a sequence of messages to the
  server. Once the client has finished writing the messages, it waits for the
  server to read them all and return its response. You specify a
  request-streaming method by placing the `stream` keyword before the *request*
  type.

```protobuf
// Accepts a stream of Points on a route being traversed, returning a
// RouteSummary when traversal is completed.
rpc RecordRoute(stream Point) returns (RouteSummary) {}
```

- A *bidirectional streaming RPC* where both sides send a sequence of messages
  to the other. The two streams operate independently, so clients and servers
  can read and write in whatever order they like: for example, the server could
  wait to receive all the client messages before writing its responses, or it
  could alternately read a message then write a message, or some other
  combination of reads and writes. The order of messages in each stream is
  preserved. You specify this type of method by placing the `stream` keyword
  before both the request and the response.

```protobuf
// Accepts a stream of RouteNotes sent while a route is being traversed,
// while receiving other RouteNotes (e.g. from other users).
rpc RouteChat(stream RouteNote) returns (stream RouteNote) {}
```

Our .proto file also contains protocol buffer message type definitions for all
the request and response types used in our service methods - for example, here's
the `Point` message type:

```protobuf
// Points are represented as latitude-longitude pairs in the E7 representation
// (degrees multiplied by 10**7 and rounded to the nearest integer).
// Latitudes should be in the range +/- 90 degrees and longitude should be in
// the range +/- 180 degrees (inclusive).
message Point {
  int32 latitude = 1;
  int32 longitude = 2;
}
```


<a name="protoc"></a>

## Generating client code

The PHP client stub implementation of the proto files can be generated by the
gRPC PHP Protoc Plugin. To compile the plugin:

```sh
$ make grpc_php_plugin
```

To generate the client stub implementation .php file:

```sh
$ cd grpc
$ protoc --proto_path=examples/protos \
  --php_out=examples/php/route_guide \
  --grpc_out=examples/php/route_guide \
  --plugin=protoc-gen-grpc=bins/opt/grpc_php_plugin \
  ./examples/protos/route_guide.proto
```

A number of files will be generated in the `examples/php/route_guide` directory.
You do not need to modify those files.

To load these generated files, add this section to your `composer.json` file

```json
  "autoload": {
    "psr-4": {
      "": "route_guide/"
    }
  }
```

The file contains:

- All the protocol buffer code to populate, serialize, and retrieve our request
  and response message types.
- A class called `Routeguide\RouteGuideClient` that lets clients call the methods
  defined in the `RouteGuide` service.


<a name="client"></a>

## Creating the client

In this section, we'll look at creating a PHP client for our `RouteGuide`
service. You can see our complete example client code in
[examples/php/route_guide/route_guide_client.php](https://github.com/grpc/grpc/blob/{{ site.data.config.grpc_release_branch }}/examples/php/route_guide/route_guide_client.php).

### Constructing a client object

To call service methods, we first need to create a client object, an instance of
the generated `RouteGuideClient` class. The constructor of the class expects the
server address and port we want to connect to:

```php
$client = new Routeguide\RouteGuideClient('localhost:50051', [
    'credentials' => Grpc\ChannelCredentials::createInsecure(),
]);
```

### Calling service methods

Now let's look at how we call our service methods.

#### Simple RPC

Calling the simple RPC `GetFeature` is nearly as straightforward as calling a
local asynchronous method.

```php
$point = new Routeguide\Point();
$point->setLatitude(409146138);
$point->setLongitude(-746188906);
list($feature, $status) = $client->GetFeature($point)->wait();
```

As you can see, we create and populate a request object, i.e. an
`Routeguide\Point` object. Then, we call the method on the stub, passing it the
request object. If there is no error, then we can read the response information
from the server from our response object, i.e. an `Routeguide\Feature` object.

```php
print sprintf("Found %s \n  at %f, %f\n", $feature->getName(),
              $feature->getLocation()->getLatitude() / COORD_FACTOR,
              $feature->getLocation()->getLongitude() / COORD_FACTOR);
```

#### Streaming RPCs

Now let's look at our streaming methods. Here's where we call the server-side
streaming method `ListFeatures`, which returns a stream of geographical
`Feature`s:

```php
$lo_point = new Routeguide\Point();
$hi_point = new Routeguide\Point();

$lo_point->setLatitude(400000000);
$lo_point->setLongitude(-750000000);
$hi_point->setLatitude(420000000);
$hi_point->setLongitude(-730000000);

$rectangle = new Routeguide\Rectangle();
$rectangle->setLo($lo_point);
$rectangle->setHi($hi_point);

$call = $client->ListFeatures($rectangle);
// an iterator over the server streaming responses
$features = $call->responses();
foreach ($features as $feature) {
  // process each feature
} // the loop will end when the server indicates there is no more responses to be sent.
```

The `$call->responses()` method call returns an iterator. When the server sends
a response, a `$feature` object will be returned in the `foreach` loop, until
the server indiciates that there will be no more responses to be sent.

The client-side streaming method `RecordRoute` is similar, except that we call
`$call->write($point)` for each point we want to write from the client side and
get back a `Routeguide\RouteSummary`.

```php
$call = $client->RecordRoute();

for ($i = 0; $i < $num_points; $i++) {
  $point = new Routeguide\Point();
  $point->setLatitude($lat);
  $point->setLongitude($long);
  $call->write($point);
}

list($route_summary, $status) = $call->wait();
```

Finally, let's look at our bidirectional streaming RPC `routeChat()`. In this
case, we just pass a context to the method and get back a `BidiStreamingCall`
stream object, which we can use to both write and read messages.

```php
$call = $client->RouteChat();
```

To write messages from the client:

```php
foreach ($notes as $n) {
  $route_note = new Routeguide\RouteNote();
  $call->write($route_note);
}
$call->writesDone();
```

To read messages from the server:

```php
while ($route_note_reply = $call->read()) {
  // process $route_note_reply
}
```

Each side will always get the other's messages in the order they were written,
both the client and server can read and write in any order — the streams operate
completely independently.
