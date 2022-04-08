#!/usr/bin/env python
import os
import ssl
import pika

amqp_endpoint = os.environ['RABBITMQ_ENDPOINT']
username = os.environ['RABBITMQ_USERNAME']
password = os.environ['RABBITMQ_PASSWORD']
vhost = os.environ['RABBITMQ_VHOST']

context = ssl.create_default_context(cafile="./../../certs/testca/ca_certificate.pem")
context.load_cert_chain("./../../certs/client/client_certificate.pem", "./../../certs/client/private_key.pem")

# login information
credentials = pika.PlainCredentials(username, password)
# the / means default virtual host
connection = pika.BlockingConnection(pika.ConnectionParameters(
    host=amqp_endpoint,
    port=5671,
    virtual_host=vhost,
    credentials=credentials,
    ssl_options = pika.SSLOptions(context,amqp_endpoint)
  )
)

channel = connection.channel()


channel.queue_declare(queue='hello', durable=True)

def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)

channel.basic_consume(on_message_callback=callback,
                      queue='hello',
                      auto_ack=True)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
