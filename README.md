
# generate folders and certificates
./setup.sh

# startup service
docker compose up -d

# producer
. env.sh
python send.py

# consumer
. env.sh
python receive.py

# cleanup untracked files and folders
git clean -d -fx
