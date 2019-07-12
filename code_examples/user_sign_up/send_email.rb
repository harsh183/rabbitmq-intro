require 'bunny'
load 'utility.rb'

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

