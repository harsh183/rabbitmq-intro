---
marp: true
theme: uncover
---
RabbitMQ Programming

Ruby and JavaScript

<!-- TODO: Things in js -->

---
All the code on this presentation is available in the `code_examples/` directory from [Github](https://github.com/harsh183/rabbitmq-intro)


```
$ git clone git@github.com:harsh183/rabbitmq-intro.git
$ cd code_examples
```

---
Prerequistes

- Ruby 

- NodeJS

- Docker

--- 
RabbitMQ - Setup

---

`Dockerfile` with StompJS support

```Dockerfile
FROM rabbitmq:3.7.7-alpine

run rabbitmq-plugins enable --offline rabbitmq_web_stomp

run \
    echo 'loopback_users.guest = false' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'web_stomp.ws_frame = binary' >> /etc/rabbitmq/rabbitmq.conf

EXPOSE 15674
```

---

```
$ ./setup-rabbit.sh
```

```bash
#!/usr/bin/env bash
docker build -t rabbit .
```

---

```
$ ./start-rabbit.sh
```

```bash
#!/usr/bin/env bash

NAME=rabbitmq
docker rm -f $NAME
docker run \
    -d \
    --hostname $NAME \
    --name $NAME \
    -p 5672:5672 \
    -p 15671:15671 \
    -p 15672:15672 \
    -p 15674:15674 \
    -p 15670:15670 \
    -p 61613:61613 \
    rabbit
```

---

`$ npm install amqplib`

`$ gem install bunny`

---
# Demo 1: Simple queue chain

RabbitMQ is based around messages arriving in queues. Here we show how to chain them together into a simple chained pipeline.  

---
The example application takes in numbers as inputs and first squares then and then cubes them.

Split into layers it is

1. Sending the numbers into `RabbitMQ`

2. Squaring them and sending to the next layer.

3. Cubing them and sending onward.

---

`sender.rb`

```ruby
require 'bundler/setup'
require 'bunny'

# Bunny is our Ruby RabbitMQ adapter
amqp_conn = Bunny.new
amqp_conn.start

# Channels are how to talk to RabbitMQ - not thread safe
channel = amqp_conn.create_channel

# Publish into the queue
square_queue = channel.queue('to_square')

50.times do |n|
  square_queue.publish(n.to_s, routing_key: square_queue)
end

amqp_conn.close
```

---

`square.rb`

```ruby
require 'bundler/setup'
require 'bunny'

amqp_conn = Bunny.new
amqp_conn.start
channel = amqp_conn.create_channel

square_queue = channel.queue('to_square') # input
cube_queue = channel.queue('to_cube')     # output

# subscribe to queue for inputs
square_queue.subscribe(block: true) do |_info, _metadata, payload|
  number = payload.to_f
  result = number**2
  p "#{number} becomes #{result}"
  cube_queue.publish(result.to_s, routing_key: cube_queue)
end
```

---

`cube.rb`

```ruby
require 'bundler/setup'
require 'bunny'

amqp_conn = Bunny.new
amqp_conn.start
channel = amqp_conn.create_channel

cube_queue = channel.queue('to_cube')  # input
output_queue = channel.queue('output') # output

cube_queue.subscribe(block: true) do |_info, _metadata, payload|
  number = payload.to_f
  result = number**2
  puts "#{number} becomes #{result}"
  output_queue.publish(result.to_s, routing_key: cube_queue)
end
```

---

Run

1. Start two instances of `$ ruby cube.rb`

2. Start three instances of `$ ruby square.rb`

3. To trigger the system run `$ ruby sender.rb`

---

# Load Balancing

* And as you could see the `cube` and `square` workers had an almost perfect split of inputs distributed between them. RabbitMQ does good load balancing out of the box. 

* As each part of the pipeline can be scaled independly, we can scale around bottlenecks.

---

# Low latency
Try increasing the input size.

Even with high loads, RabbitMQ's messaging is highly performant allowing fast systems and high capacity.

```ruby
50000.times do |n|
  square_queue.publish(n.to_s, routing_key: square_queue)
end
```

---

# Fault tolerant

RabbitMQ systems are quite tolerant of workers going offline and online out of the box.

```ruby
50.times do |n|
  sleep 1 # Adding a sleep command
  square_queue.publish(n.to_s, routing_key: square_queue)
end
```

---

# Fault tolerant

* Now a few seconds later use Ctrl+C to close one of the `square.rb` instances.

* RabbitMQ automatically detects it and adjusts the load between the remaining workers automatically. 

* After a few more seconds start it again with `$ ruby square.rb` and it starts sharing the load again automaticaly.

---

# Demo 2: Example user signup flow

This demo shows the outline of a flow with emails. 

* Emails will be sent as input

* The emails will be validated by a format. 

* Parallel the a welcome email will be sent and a database record will be created. The User will also get a success message back. 



---

`utility.rb`

```ruby
# Sets up a channel to the RabbitMQ broker using Bunny
def setup_rabbitmq_channel
  amqp_conn = Bunny.new
  amqp_conn.start
  amqp_conn.create_channel
end

# Maps an input queue to an existing exchange
def queue_for_exchange(queue_name, exchange_name, channel)
  exchange = channel.fanout(exchange_name)
  named_queue = channel.queue(queue_name)
  named_queue.bind(exchange)
  named_queue
end
```
---

`validate_email.rb`

```ruby
require 'bunny'
load 'utility.rb'

channel = setup_rabbitmq_channel

unvalidated_queue = queue_for_exchange('unvalidated',
                                       'email_signups',
                                       channel)
validated_exchange = channel.fanout('validated')

unvalidated_queue.subscribe(block: true, manual_ack: true) do |info, metadata, payload|
  if payload.include?('@')
    validated_exchange.publish(payload,
                                       reply_to: metadata[:reply_to],
                                       correlation_id: metadata[:correlation_id])

    # The second param if false acknowledges only this one if true acknowledges all
    channel.acknowledge(info.delivery_tag, false)
    p "Accepted #{payload}"
  else
    # Second param is if to requeue
    channel.reject(info.delivery_tag, false)
    p "Rejected #{payload}"
  end
end
```

---

`signup.js`

```js
var amqp = require('amqplib/callback_api');
amqp.connect('amqp://localhost', (err, conn) => {
    conn.createChannel((err, ch) => {
        ch.assertQueue('', {exclusive: true}, (err, q) => {
            var corr = Math.random().toString(); // identifies current process
            payload = 'harsh@example.com'
            ch.publish('email_signups', '', new Buffer(payload),
                {correlationId: corr, replyTo: q.queue });

            ch.consume(q.queue, msg => {
                if (msg.properties.correlationId = corr) {
                    console.log( msg.content.toString());
                }
            }, {noAck: true});

        });
    });
});
```


---

# Acknowledgements

* Acknowledgements can let us wrap conditional logic around pipelines

* valid email like 'harsh@example.com' it gives an acknowlegement and pushes it further down the queue.

*  But if we give an email like 'invalid.com' then it rejects the message and it's not requeued again.

* In many cases, sometimes we use rejections when one worker could not process it and it should be requeued for another worker to handle.

---

`database_write.rb`

```ruby
def write_to_database(email)
  sleep 0.1
  puts "#{email} written to database"
end

channel = setup_rabbitmq_channel
database_write_queue = queue_for_exchange('database_write',
                                          'validated',
                                          channel)
database_write_queue.subscribe(block: true) do |info, metadata, payload|
  write_to_database(payload)
  channel.default_exchange.publish "User saved!",
                           routing_key: metadata[:reply_to],
                           correlation_id: metadata[:correlation_id]
end
```

---

`send_email.rb`

```ruby
def send_email(email)
  sleep 5
  puts "Sent email to #{email}"
end

channel = setup_rabbitmq_channel
welcome_queue = queue_for_exchange('welcome',
                                   'validated',
                                    channel)
welcome_queue.subscribe(block: true) do |info, metadata, payload|
  send_email(payload)
  channel.default_exchange.publish "Check your inbox!",
                           routing_key: metadata[:reply_to],
                           correlation_id: metadata[:correlation_id]
end
```

---

# Fan out exchanges

These demo is using exchanges to publish the outputs, and queues that are bound to each.

* This lets the application be more modular and loosely coupled

* The routing key syntax is not required any more.

---

# RPC

Like how sending letters to a postman with a return address we use

* `routing_key` to indicate which client to return to

* `correlation_id` which process to return to - here we use a UUID but it can be quite arbritary

* As ruby's asynchronous abilities are limited we have to do this in JavaScript with the outputs
returning back to the queue in the client side using those two values

---

See also: 

- [Official docker image with RabbitMQ](https://github.com/docker-library/rabbitmq) 

- [Bunny Github](https://github.com/ruby-amqp/bunny) - the quick start is a decent example

- [Bunny getting started](http://rubybunny.info/articles/getting_started.html) - Has quite a bit of decent tutorial stuff for common patterns

- [Javascript RPC on RabbitMQ](https://www.rabbitmq.com/tutorials/tutorial-six-javascript.html)

