---
marp: true
theme: uncover
---
RabbitMQ Programming

Ruby and JavaScript

---
All the code on this presentation is available in the `code_examples/` directory from Github.

<!-- Link to github and clone url -->

---
Prerequistes

- Ruby 

- NodeJS

- Docker

--- 
RabbitMQ - Simple docker setup

For now here is a simple `Dockerfile` with some additional config for `StompJS`

```
FROM rabbitmq:3.7.7-alpine

run rabbitmq-plugins enable --offline rabbitmq_web_stomp

run \
    echo 'loopback_users.guest = false' >> /etc/rabbitmq/rabbitmq.conf && \
    echo 'web_stomp.ws_frame = binary' >> /etc/rabbitmq/rabbitmq.conf

EXPOSE 15674
```

Then run

```
docker build -t rabbit .
```

---
Simple queue chain

RabbitMQ is based around messages arriving in queues. Here we show how to chain them together into asimple chained pipeline.

<!-- Better explaination and maybe a picture -->

---
The application will

* 

--- 
See also: 

- [harsh183 gist with RabbitMQ Simple Queue Chain](https://gist.github.com/harsh183/87ee406fd88c753ddc18a1eba0f7791e) 

- [Official docker image with RabbitMQ](https://github.com/docker-library/rabbitmq) 

- [Bunny Github](https://github.com/ruby-amqp/bunny) - the quick start is a decent example

- [Bunny getting started](http://rubybunny.info/articles/getting_started.html) - Has quite a bit of decent tutorial stuff for common patterns

