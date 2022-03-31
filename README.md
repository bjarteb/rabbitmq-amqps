
# generate folders and certificates
./setup.sh

# startup service
docker compose up -d

# create vhost "rs"
open localhost:15672
login: guest,guest

# producer
. env.sh
python send.py

# consumer
. env.sh
python receive.py

# cleanup untracked files and folders
git clean -d -fx
