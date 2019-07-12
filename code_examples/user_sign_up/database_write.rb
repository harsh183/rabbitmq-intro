require 'bunny'
load 'utility.rb'

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

