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
