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

`$ bundle `

```ruby
# Gemfile
source 'https://rubygems.org' do
  gem 'bunny'
end
```
---
Simple queue chain

RabbitMQ is based around messages arriving in queues. Here we show how to chain them together into a simple chained pipeline.  

<!-- Better explaination and maybe a picture -->

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

And as you could see the `cube` and `square` workers had an almost perfect split of inputs distributed between them. RabbitMQ does good load balancing out of the box. 

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

# Acknowledgements

---

# Fan out




See also: 

- [Official docker image with RabbitMQ](https://github.com/docker-library/rabbitmq) 

- [Bunny Github](https://github.com/ruby-amqp/bunny) - the quick start is a decent example

- [Bunny getting started](http://rubybunny.info/articles/getting_started.html) - Has quite a bit of decent tutorial stuff for common patterns

