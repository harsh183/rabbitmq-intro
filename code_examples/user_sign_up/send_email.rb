require 'bunny'
load 'utility.rb'

def send_email(email)
  puts "Sent email to #{email}"
end

channel = setup_rabbitmq_channel

welcome_queue = queue_for_exchange('validated', 
                                   'welcome', 
                                    channel)
  
welcome_queue.subscribe(block: true, manual_ack: true) do |info, metadata, payload|
  send_email(payload)
  default_exchange.publish "Check your inbox!",
                           routing_key: metadata[:reply_to],
                           correlation_id: metadata[:correlation_id]
end

