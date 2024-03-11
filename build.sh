# GitHub Actions runs this script to build a deb package.
# You can run this locally, you just need to gem install fpm.
# See the release.yml workflow file for a command to do that.

MAINT="David Newhall II <captain at golift dot io>"
DESC="Official Worker for Notifiarr.com"
LICENSE="GPLv2"
# Used for source links in package metadata.
SOURCE_URL="https://github.com/Notifiarr/workers"
VENDOR="Go Lift <code@golift.io>"

DATE="$(date -u +%Y-%m-%dT%H:%M:00Z)"
VERSION=$(git describe --abbrev=0 --tags $(git rev-list --tags --max-count=1) 2>/dev/null | tr -d v)
[ "$VERSION" != "" ] || VERSION=development
# This produces a 0 in some environments (like Homebrew), but it's only used for packages.
ITERATION=$(git rev-list --count --all || echo 0)
COMMIT="$(git rev-parse --short HEAD || echo 0)"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD || echo unknown)"
BRANCH="${GIT_BRANCH:-${GITHUB_REF_NAME}}"

SIGNING_KEY=B93DD66EF98E54E2EAE025BA0166AD34ABC5A57C
PACKAGE_NAME="notifiarr-worker"

read -r -d '' DEPENDS <<- DEPENDS
    --depends supervisor
    --depends nfs-client
    --depends telegraf
    --depends software-properties-common
    --depends sudo
    --depends php8.3-redis
    --depends php8.3-memcached
    --depends php8.3-mysql
    --depends php8.3-mbstring
    --depends php8.3-curl
    --depends php8.3-xml
    --depends mysql-client-core-8.0
DEPENDS

read -r -d '' PACKAGE_ARGS <<- PACKAGE_ARGS
    --before-install before-install.sh
    --after-install after-install.sh
    --before-remove before-remove.sh
    --name ${PACKAGE_NAME}
    --deb-no-default-config-files
    --iteration ${ITERATION}
    --license ${LICENSE}
    --url ${SOURCE_URL}
    --maintainer='${MAINT}'
    --vendor='${VENDOR}'
    --description='${DESC}'
PACKAGE_ARGS

mkdir -p root/var/log/workers
rm -f ${PACKAGE_NAME}_${VERSION}-${ITERATION}_amd64.deb
echo fpm -s dir -t deb ${PACKAGE_ARGS} ${DEPENDS} -a amd64 -v ${VERSION} -C root/
eval fpm -s dir -t deb ${PACKAGE_ARGS} ${DEPENDS} -a amd64 -v ${VERSION} -C root/
echo
ls -l

# Sign the package if the signing key is in the gpg keychain.
if gpg --list-keys 2>/dev/null | grep -q "${SIGNING_KEY}" ; then
    debsigs --default-key="${SIGNING_KEY}" --sign=origin ${PACKAGE_NAME}_${VERSION}-${ITERATION}_amd64.deb
fi