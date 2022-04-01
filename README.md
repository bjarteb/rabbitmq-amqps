
# generate folders and certificates
./setup.sh

# startup service
docker compose up -d

# create vhost "rs"
docker compose exec rabbitmq bash -c "rabbitmqctl add_vhost rs"
docker compose exec rabbitmq bash -c "rabbitmqctl set_permissions -p rs guest '.*' '.*' '.*'"

# producer
. env.sh
python send.py

# consumer
. env.sh
python receive.py

# Web UI (insecure)
open http://localhost:15672
username: guest
password: guest

# cleanup untracked files and folders
git clean -d -fx
