# This file recieves the numbers into the first queue from RabbitMQ
require 'bundler/setup'
require 'bunny'

amqp_conn = Bunny.new
amqp_conn.start
channel = amqp_conn.create_channel

square_queue = channel.queue('to_square') # input
cube_queue = channel.queue('to_cube')     # output

# Subscribe to messages in the input queue
# RabbitMQ also does load balancing out of the box
square_queue.subscribe(block: true) do |_delivery_info, _metadata, payload|
  number = payload.to_f
  result = number**2
  puts "#{number} becomes #{result}"

  # publish changes in the output queue
  cube_queue.publish(result.to_s, routing_key: cube_queue) 
end
