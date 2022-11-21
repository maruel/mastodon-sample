#!/bin/bash
# Copyright 2022 Marc-Antoine Ruel. All rights reserved.
# Use of this source code is governed under the Apache License, Version 2.0
# that can be found in the LICENSE file.

# Generate keys for application.env and database.env

set -eu

if [ "$EUID" -eq 0 ]; then
  echo "Please do not run as root."
  exit 1
fi

cd "$(dirname $0)"


echo "Configuring most of application.env:"

# Same as: openssl rand -hex 64
echo "- Setting up SECRET_KEY_BASE and OTP_SECRET."
PWBASE=$(docker-compose run --rm shell bundle exec rake secret)
PWOTP=$(docker-compose run --rm shell bundle exec rake secret)
sed -i "s/^SECRET_KEY_BASE=.\+/SECRET_KEY_BASE=$PWBASE/" ./application.env
sed -i "s/^OTP_SECRET=.\+/OTP_SECRET=$PWOTP/" ./application.env

# Same as:
#  openssl ecparam -name prime256v1 -genkey -noout -out vapid_private_key.pem
#  openssl ec -in vapid_private_key.pem -pubout -out vapid_public_key.pem
#  cat vapid_private_key.pem
#  cat vapid_public_key.pem
#  echo -n VAPID_PRIVATE_KEY=;cat vapid_private_key.pem | sed -e "1 d" -e "$ d" | tr -d "\n"; echo
#  echo -n VAPID_PUBLIC_KEY=;cat vapid_public_key.pem | sed -e "1 d" -e "$ d" | tr -d "\n"; echo
for line in $(docker-compose run --rm shell bundle exec rake mastodon:webpush:generate_vapid_key); do
  echo "Line: $line"
  key=$(echo $line | cut -f 1 -d =)
  sed -i "s/^$key=.\+/$line/" ./application.env
done


echo "Updating database.env:"
# We could use apg -m 16, let's use the same rake secret command than above to
# not depend on more packages than strictly necessary.
PWDB=$(docker-compose run --rm shell bundle exec rake secret)
sed -i "s/<DB_PASSWORD>/$PWDB/g" ./database.env


echo "There is two things left to configure in application.env!"
echo "- Replace <DOMAIN> with your domain name."
echo "- Replace SMTP_PASSWORD= with the password from sendgrid.com."
