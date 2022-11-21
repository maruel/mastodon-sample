#!/bin/sh
# Copyright 2022 Marc-Antoine Ruel. All rights reserved.
# Use of this source code is governed under the Apache License, Version 2.0
# that can be found in the LICENSE file.

# Resets ownership.

set -eu

if [ "$EUID" -eq 0 ]; then
  echo "Please do not run as root; the script will sudo instead."
  exit 1
fi

cd "$(dirname $0)"

sudo chown -R 70:$USER postgres
sudo chown -R 991:$USER public
sudo chown -R systemd-coredump:$USER redis
sudo chmod -R g+rX postgres
sudo chmod -R g+rX public
sudo chmod -R g+rX redis

echo "Disk usage:"
du -h -s .
