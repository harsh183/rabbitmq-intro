require 'bunny'
load 'utility.rb'

channel = setup_rabbitmq_channel

unvalidated_queue = queue_for_exchange('unvalidated', 
                                       'email_signups', 
                                       channel)
validated_exchange = channel.fanout('validated')
  
unvalidated_queue.subscribe(block: true, manual_ack: true) do |info, metadata, payload|
  if payload.include?('@')
    validated_exchange.publish(payload,
                                       reply_to: metadata[:reply_to],
                                       correlation_id: metadata[:correlation_id])

    # The second param if false acknowledges only this one if true acknowledges all
    channel.acknowledge(info.delivery_tag, false) 
    p "Accepted #{payload}"
  else
    # Second param is if to requeue
    channel.reject(info.delivery_tag, false)
    p "Rejected #{payload}"
  end 
end
