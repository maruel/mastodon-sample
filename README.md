# Setup

1. Make a *private* fork of this repository.
1. git clone it on your server.
1. Install docker-compose.
1. Run this script to help you configure application.env and database.env: `./gen_keys.sh`
1. Finish application.env configuration:
  1. Replace <DOMAIN> with your domain name.
  1. Set your sendgrid.com password.
1. Setup [Caddy](https://caddyserver.com) with the sample Caddyfile.
1. Once everything is configured, including sendgrid, run: `./setup.sh`


I wrote it quickly post-hoc, so it is possible that there are errors. Please
send me a PR if you find a mistake!

Made by [maruel](https://github.com/maruel).
