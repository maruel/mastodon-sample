# Mastodon docker-compose based server setup

## Setup

1. Decide on your server.
1. Buy a domain name.
1. Setup the IP redirect right away. Hosting at home totally works if ports 80
   and 443 are not blocked by your ISP.
1. Make a *private* fork of this repository.
1. git clone it on your server.
1. Install docker-compose.
1. Run this script to help you configure application.env and database.env: `./gen_keys.sh`
1. Finish application.env configuration:
  1. Replace <DOMAIN> with your domain name.
  1. Set your sendgrid.com password.
1. Setup [Caddy](https://caddyserver.com) with the sample Caddyfile. Wait for
   LetsEncrypt to accept the request.
1. Once everything is configured, including sendgrid, run: `./setup.sh`


## Resources

The configuration is slightly optimized to reduce memory usage, by limiting the
number of processes. Expect relatively low CPU usage (a shared core VM is
probably sufficient) but relatively high memory and disk usage. A single user
instance will likely hover at around 1.0GiB to 2.5GiB of RAM use and about 10GiB
of disk usage. A [Google Cloud Compute
Engine](https://cloud.google.com/compute/docs/general-purpose-machines#e2-shared-core)
e2-micro is probably not enough, a e2-small is maybe fine, a e2-medium is
definitely enough. Coupled with the free 30GiB disk, monthly cost should over at
12.23$ (e2-small VM) plus a few bucks/month of bandwidth.


## Notes

I wrote it quickly post-hoc, so it is possible that there are errors. Please
send me a PR if you find a mistake!

Made by [maruel](https://github.com/maruel).
