#!/usr/bin/env node

var amqp = require('amqplib/callback_api');
amqp.connect('amqp://localhost', (err, conn) => {
    conn.createChannel((err, ch) => {
        ch.assertQueue('', {exclusive: true}, (err, q) => {
            var corr = Math.random().toString(); // Corr lets it return to the right process
            payload = 'harsh@example.com' 
            ch.publish('email_signups', '', new Buffer(payload), 
                {correlationId: corr, replyTo: q.queue });

            ch.consume(q.queue, msg => {
                if (msg.properties.correlationId = corr) {
                    // If condition as sanity check check we're the right recipients.
                    console.log( msg.content.toString());
                }
            }, {noAck: true});

        });
    });
});

