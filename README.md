
# generate folders and certificates
./setup.sh

# startup service
docker compose up -d

# produce
. env.sh
python send.py

# consume
. env.sh
python receive.py
