# This file sends the first push out to the rabbitMQ (Message Queue) that we have set up
require 'bundler/setup'
require 'bunny'

# Bunny is our Ruby RabbitMQ adapter
amqp_conn = Bunny.new
amqp_conn.start

# Channel to be only in one thread, 
channel = amqp_conn.create_channel

# Publish into the queue
square_queue = channel.queue('to_square')

# Increase n to try out load balancing
5000.times do |n|
  square_queue.publish(n.to_s, routing_key: square_queue)
end

amqp_conn.close
