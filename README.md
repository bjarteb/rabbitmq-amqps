# RabbitMQ configured with TLS

This projects include all the steps to bring up a rabbitmq container configured with TLS in order
to test client communication over protocol AMQPS

## generate folders and certificates
```
./setup.sh
```

## startup service
```
docker compose up -d
```

## create vhost "rs"
```
docker compose exec rabbitmq bash -c "rabbitmqctl add_vhost rs"
docker compose exec rabbitmq bash -c "rabbitmqctl set_permissions -p rs guest '.*' '.*' '.*'"
```

## producer (python lib 'pika')
```
. env.sh
python send.py
```

## consumer (python lib 'pika')
```
. env.sh
python receive.py
```

## Web UI (insecure, username: guest, password: guest)
```
open http://localhost:15672
```

## Verify certificate
```
openssl s_client -connect $(hostname):5671 -showcerts 2> /dev/null | grep 'subject='

# output
subject=/CN=MacBook-Pro.local/O=server
```

## Run application (java)
```
cd clients/java/rabbitmq-demo
mvn install
mvn exec:java -Dexec.workingdir="target" -Dexec.mainClass="com.example.rabbitmqdemo.RabbitmqDemoApplication"
```

## stop and cleanup untracked files and folders
```
docker compose down
git clean -d -fx
```
