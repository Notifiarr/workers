# Notifiarr Workers

This is where you'll find the scripts and github action that create the worker package(s) for Notifiarr.

There's nothing very useful in this repo for the public.

## System Package

GitHub Actions runs the [build.sh](build.sh) script which turns the [root/](root/) folder into a deb package we install on our worker servers.

- The package installs a number of dependencies, including `telegraf`, `php`, `supervisor` and `nfs-client`.
- Also installed is a user named `abc` with an [authorized_keys ssh](root/home/abc/.ssh/authorized_keys)
    file and a [sudoers](root/etc/sudoers.d/workers) entry that allows the website to restart supervisor.
- The [systemd unit override](root/etc/systemd/system/supervisor.service.d/notifiarr.conf)
    allows us to create dynamic symlinks to the supervisor config files for this host.
- Telegraf is also [fully configured](root/etc/telegraf/telegraf.d/notifiarr.conf) during package installation.

## Use

First make sure the new Ubuntu 22.04 server's IP has access to the NFS `/share`.

Then run the included install script. Like this:
```bash
curl -sL https://raw.githubusercontent.com/Notifiarr/workers/main/install.sh | sudo bash
```

In addition to installing the [notifiarr-worker](https://packagecloud.io/app/golift/nonpublic/search?q=notifiarr-worker)
package, the [install.sh](install.sh) script installs and configures:

- [Notifiarr Client](https://github.com/Notifiarr/notifiarr)
- [PPA for ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php)
- NFS `/share` mount
- [Datadog Agent](https://app.datadoghq.com/account/settings/agent/latest?platform=ubuntu)

# License

- This software is Copyright 2024 Notifiarr, LLC.
- Read the [license](LICENSE) if you intend to make copies.