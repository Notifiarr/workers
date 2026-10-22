#!/usr/bin/env bash
# Build the worker deb, install it, and check PHP 8.5 plus the modules it depends on.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

if [ "$(id -u)" -eq 0 ]; then
  asroot() { "$@"; }
else
  asroot() { sudo "$@"; }
fi

export DEBIAN_FRONTEND=noninteractive
php_min=$(sed -n 's/^PHP_VERSION=//p' build.sh)
[ -n "$php_min" ] || { echo "PHP_VERSION is missing from build.sh" >&2; exit 1; }
echo "required php >= ${php_min}"

asroot apt-get update
asroot apt-get install -y ruby ruby-dev build-essential fakeroot git curl ca-certificates gnupg software-properties-common
# GitHub's Ubuntu image ships PHP 8.3. Workers only use 8.5.
mapfile -t php83 < <(dpkg-query -W -f '${Package}\n' 'php8.3*' 2>/dev/null || true)
if [ "${#php83[@]}" -gt 0 ]; then
  echo "removing preinstalled php 8.3: ${php83[*]}"
  asroot apt-get purge -y "${php83[@]}"
  asroot apt-get autoremove -y
fi
# A mounted checkout can be owned by another user. This only affects this job.
git config --global --add safe.directory "$root"
asroot gem install --no-document fpm

rm -f notifiarr-worker_*.deb
bash build.sh
deb=$(echo notifiarr-worker_*.deb)
[ -f "$deb" ] || { echo "deb was not built" >&2; exit 1; }
echo "built ${deb}"
dpkg-deb -I "$deb"

depends=$(dpkg-deb -f "$deb" Depends)
for pkg in cli curl mbstring mysql xml; do
  needle="php8.5-${pkg} (>= ${php_min})"
  if ! grep -F -q "$needle" <<<"$depends"; then
    echo "missing dependency: ${needle}" >&2
    echo "$depends" >&2
    exit 1
  fi
done
for pkg in memcached redis; do
  if ! grep -Eq "(^|, )php8\.5-${pkg}(,|$)" <<<"$depends"; then
    echo "missing dependency: php8.5-${pkg}" >&2
    echo "$depends" >&2
    exit 1
  fi
done
if grep -q 'php8.3' <<<"$depends"; then
  echo "package still depends on php8.3" >&2
  exit 1
fi

asroot install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | asroot tee /etc/apt/keyrings/influxdata-archive.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" | asroot tee /etc/apt/sources.list.d/influxdata.list >/dev/null
asroot add-apt-repository -y ppa:ondrej/php
asroot apt-get update
asroot apt-get install -y "./${deb}"

php -v
PHP_MIN="$php_min" php -r 'exit(version_compare(PHP_VERSION, getenv("PHP_MIN"), ">=") ? 0 : 1);'
echo "php $(php -r 'echo PHP_VERSION;') satisfies >= ${php_min}"
if dpkg-query -W -f '${Package}\n' 'php8.3*' 2>/dev/null | grep -q .; then
  echo "php 8.3 is still installed" >&2
  dpkg-query -W -f '${Package} ${Version}\n' 'php8.3*' >&2 || true
  exit 1
fi

for mod in curl mbstring memcached mysqli redis xml; do
  if ! php -m | grep -qx "$mod"; then
    echo "php module ${mod} is not loaded" >&2
    php -m >&2
    exit 1
  fi
  echo "php module ${mod} ok"
done

check() {
  if ! asroot "$@"; then
    echo "check failed: $*" >&2
    exit 1
  fi
}
check test -f /etc/sudoers.d/workers
check test -f /etc/systemd/system/supervisor.service.d/notifiarr.conf
check test -f /etc/telegraf/telegraf.d/notifiarr.conf
check test -x /config/supervisor/prestart.sh
check test -f /home/abc/.ssh/authorized_keys
check id abc
echo "package install ok"
