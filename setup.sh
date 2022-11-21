#!/bin/bash
# Copyright 2022 Marc-Antoine Ruel. All rights reserved.
# Use of this source code is governed under the Apache License, Version 2.0
# that can be found in the LICENSE file.

# Some of this is similar to
#   docker-compose run --rm web bundle exec rake mastodon:setup
# but I had some challenges with it. I prefer to do it as steps, so that if you
# mess up one step, you don't have to start from scratch every single time.
#
# Starting from scratch:
#   docker stop mastodon_db && sudo rm -rf postgres && docker restart mastodon_db && docker restart mastodon_redis
#   docker start mastodon_web && docker start mastodon_sidekiq && docker start mastodon_streaming
#
# Cleanup, this doesn't delete data so this is safe:
#   docker-compose stop
#   docker-compose rm

set -eu

if [ "$EUID" -eq 0 ]; then
  echo "Please do not run as root; the script will sudo instead."
  exit 1
fi

cd "$(dirname $0)"


LOCAL_DOMAIN=$(grep LOCAL_DOMAIN= ./application.env | awk -F= '{print $2}')
if [ "$LOCAL_DOMAIN" = "<DOMAIN>" ]; then
  echo "Make sure to configure your domain in application.env and sendgrid!"
  exit 1
fi


echo "- Update Caddyfile"
set -i "s/DOMAIN/$LOCAL_DOMAIN/g" Caddyfile
echo "  Don't forget to start Caddy! Look at https://caddyserver.com"


echo "- Setup the mastodon path"
mkdir -p public/system
sudo chown -R 991:$USER public/system


function docker_wait_healthy {
  local CONTAINERNAME=$1
  until [ "`docker inspect -f {{.State.Health.Status}} $CONTAINERNAME`"=="healthy" ]; do
    sleep 0.1;
  done;
  echo "$CONTAINERNAME is up"
}


echo "- Start DB and Redis"
docker-compose up -d db redis


echo "- Waiting for containers to be healthy"
docker_wait_healthy mastodon_redis
docker_wait_healthy mastodon_db


echo "- Forcing DB setup"
docker-compose run --rm shell bundle exec rake db:setup
docker-compose run --rm shell bundle exec rake db:migrate


echo "- Starting everything now"
docker-compose up -d


echo "- Waiting for remaining containers to be healthy"
docker_wait_healthy mastodon_streaming
docker_wait_healthy mastodon_sidekiq
docker_wait_healthy mastodon_web


echo "- Creating admin account with email admin@$LOCAL_DOMAIN."
echo "  Note the password!"
docker-compose run --rm shell bin/tootctl accounts create \
  Administrateur --email admin@$LOCAL_DOMAIN --confirmed --role Admin


echo "- Disabling registration. Enable it in the UI once your are with the setup"
docker-compose run --rm shell bin/tootctl settings registrations close


echo "- Setting up Systemd services"
for i in rsc/*.service; do
  echo $i
  CONTENT="$(cat $i)"
  # Replace USER with the current user.
  CONTENT="$(echo "$CONTENT" | sed -e s/USER/$USER/g)"
  # Replace /PATH/TO with the current path.
  CONTENT="$(echo "$CONTENT" | sed -e s#/PATH/TO/MASTODON#$PWD#g)"
  echo "$CONTENT" | sudo tee /etc/systemd/system/$i
done
sudo cp rsc/*.timer /etc/systemd/system


echo "- Enabling and starting services"
sudo systemctl daemon-reload
sudo systemctl enable mastodon-preview_cards-remove.timer
sudo systemctl enable mastodon-media-remove.timer
sudo systemctl enable mastodon.service
sudo systemctl start mastodon.service


# TODO: Share static content via Caddy.
