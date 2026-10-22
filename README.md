# Notifiarr Workers

This is where you'll find the scripts and github action that create the worker package(s) for Notifiarr.

There's nothing very useful in this repo for the public.

## System Package

[build.sh](build.sh) turns the [root/](root/) folder into a deb package. [release.yml](.github/workflows/release.yml) builds it, and a release tag uploads it to packagecloud. See [Cut a release](#cut-a-release).

- The package installs a number of dependencies, including `telegraf`, PHP 8.5 (minimum is `PHP_VERSION` in [build.sh](build.sh)), `supervisor` and `nfs-client`.
- Also installed is a user named `abc` with an [authorized_keys ssh](root/home/abc/.ssh/authorized_keys)
    file and a [sudoers](root/etc/sudoers.d/workers) entry that allows the website to restart supervisor.
- The [systemd unit override](root/etc/systemd/system/supervisor.service.d/notifiarr.conf)
    allows us to create [dynamic symlinks](root/config/supervisor/prestart.sh) to the supervisor config files for this host.
- The unit also overrides the [supervisord.conf](root/config/supervisor/supervisord.conf) file so we can fully control
    the service and include php-built configs from `/share`.
- Telegraf is also [fully configured](root/etc/telegraf/telegraf.d/notifiarr.conf) during package installation.

## Cut a release

A `v*` tag publishes the package. A merge to `main` builds an artifact and stops there.

The latest tag is `v1.2.0`. From an up-to-date checkout of `main`, after the [build-and-release](https://github.com/Notifiarr/workers/actions/workflows/release.yml) workflow is green:

```bash
git checkout main
git pull
gh release create v1.2.1 --target main --generate-notes
```

Use the next version instead of `v1.2.1`. That command opens the GitHub release and pushes the tag. The release page is the changelog. Workers install the deb from packagecloud.

Then watch the workflow run for that tag. The jobs are `test`, **Make Release Assets**, and **Deploy Nonpublic PackageCloud**. The last job uploads the deb to the [golift/nonpublic](https://packagecloud.io/golift/nonpublic) apt repo, distribution `ubuntu/focal`. [install.sh](install.sh) points workers at that repo. Hosts install it on the next `apt upgrade` (the daily cron does this). `abc` can also run:

```bash
sudo apt update
sudo apt install -y notifiarr-worker
```

[build.sh](build.sh) sets the package version from the newest `v*` tag in the clone, with the `v` removed. The Debian revision is the number of commits. Tag the `main` commit you are shipping, and make that the newest tag. The filename looks like `notifiarr-worker_1.2.1-<commits>_amd64.deb`.

Deploy uses the `PACKAGECLOUD_TOKEN` secret. The build signs the deb with `debsigs` when `GPG_SIGNING_KEY` is the signing key named in [build.sh](build.sh).

## Build and test

The workflow file is [release.yml](.github/workflows/release.yml). Every job runs on `ubuntu-24.04`, the same release as the worker hosts.

| Event | `test` | Deb artifact | Packagecloud |
| --- | --- | --- | --- |
| Pull request into `main` or `unstable` | yes | | |
| Push to `main` or `unstable` | yes | yes | |
| Tag `v*` | yes | yes | yes |

`test` runs [.github/scripts/test-package.sh](.github/scripts/test-package.sh). That script builds the deb, installs it, and checks that PHP is at least `PHP_VERSION` from [build.sh](build.sh) and that the PHP modules load. The branch protection check is named `test`.

A push to `unstable` builds the artifact only. Download that deb from the Actions run when you want to try a package before tagging.

To build a deb on a machine that already has the tags:

```bash
sudo apt install -y fakeroot ruby ruby-dev build-essential
sudo gem install --no-document fpm
bash build.sh
```

The deb is written in the repo root and is gitignored.

Renovate updates the pinned GitHub Actions, and it bumps `PHP_VERSION` in [build.sh](build.sh) for PHP 8.5 patch releases. Those pull requests automerge after `test` passes. Cut a release when a change under `root/`, the maintainer scripts, or the PHP minimum should reach the workers.

## Use

First make sure the new Ubuntu 24.04 server's IP has access to the NFS `/share`.

Then run the included install script. Like this:

```bash
curl -sL https://raw.githubusercontent.com/Notifiarr/workers/main/install.sh | sudo bash
```

In addition to installing the [notifiarr-worker](https://packagecloud.io/app/golift/nonpublic/search?q=notifiarr-worker)
package, the [install.sh](install.sh) script installs and configures:

- [Notifiarr Client](https://github.com/Notifiarr/notifiarr)
- [PPA for ondrej/php](https://launchpad.net/~ondrej/+archive/ubuntu/php)
- [Influx APT Repo](https://docs.influxdata.com/influxdb/v1/introduction/install/#installing-influxdb-oss)
- NFS `/share` mount

## License

- This software is Copyright Notifiarr, LLC.
- Read the [GPLv2 license](LICENSE) if you intend to make copies.
