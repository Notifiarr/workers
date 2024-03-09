MAINT="David Newhall II <captain at golift dot io>"
DESC="Official Worker for Notifiarr.com"
LICENSE="GPLv2"
# Used for source links in package metadata and docker labels.
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

# Import this signing key only if it's in the keyring.
if gpg --list-keys 2>/dev/null | grep -q B93DD66EF98E54E2EAE025BA0166AD34ABC5A57C; then
    export SIGNING_KEY=B93DD66EF98E54E2EAE025BA0166AD34ABC5A57C
fi

PACKAGE_SCRIPTS="--before-install before-install.sh \
    --after-install after-install.sh \
    --before-remove before-remove.sh"

PACKAGE_NAME="notifiarr-worker"
PACKAGE_ARGS="${PACKAGE_SCRIPTS} \
    --name ${PACKAGE_NAME} \
    --deb-no-default-config-files \
    --rpm-os linux \
    --iteration ${ITERATION} \
    --license ${LICENSE} \
    --url ${SOURCE_URL} \
    --maintainer \"${MAINT}\" \
    --vendor \"${VENDOR}\" \
    --description \"${DESC}\" \
    --freebsd-origin \"${SOURCE_URL}\""

DEPENDS="--depends supervisor \
    --depends nfs-client \
    --depends telegraf \
    --depends software-properties-common \
    --depends php8.3-redis \
    --depends php8.3-memcached \
    --depends php8.3-mysql \
    --depends php8.3-mbstring \
    --depends php8.3-curl \
    --depends php8.3-xml \
    --depends mysql-client-core-8.0"

echo fpm -s dir -t deb ${PACKAGE_ARGS} -a amd64 -v ${VERSION} -C root/ ${DEPENDS}
[ "${SIGNING_KEY}" = "" ] || debsigs --default-key="${SIGNING_KEY}" --sign=origin ${PACKAGE_NAME}_${VERSION}-${ITERATION}_amd64.deb
