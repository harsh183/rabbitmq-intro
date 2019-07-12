require 'bunny'

amqp_conn = Bunny.new
amqp_conn.start
channel = amqp_conn.create_channel

cube_queue = channel.queue('to_cube')  # input
output_queue = channel.queue('output') # output

cube_queue.subscribe(block: true) do |_delivery_info, _metadata, payload|
  number = payload.to_f
  result = number**3
  puts "#{number} becomes #{result}"
  output_queue.publish(result.to_s, routing_key: cube_queue) 
end

