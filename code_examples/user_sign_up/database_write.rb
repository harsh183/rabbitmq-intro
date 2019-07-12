require 'bunny'
load 'utility.rb'

def write_to_database(email)
  sleep 0.1
  puts "#{email} written to database"
end

channel = setup_rabbitmq_channel
database_write_queue = queue_for_exchange('validated', 
                                          'database_write', 
                                          channel)
  
unvalidated_queue.subscribe(block: true, manual_ack: true) do |info, metadata, payload|
  write_to_database(payload)
  default_exchange.publish "User saved!",
                           routing_key: metadata[:reply_to],
                           correlation_id: metadata[:correlation_id]
end

