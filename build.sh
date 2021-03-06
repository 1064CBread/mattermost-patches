#!/usr/bin/env bash

set -e
mattermostRepo='https://github.com/mattermost/platform'
mattermostSshRepo='ssh://git@ssh.github.com:443/mattermost/platform' # In case HTTPS is being weird
mattermostCommit='f189bc2073cf800c5f4506a69bdb51d7065269bf'
patchesDir='patches'
confirmedNonAutoSetupFile="$HOME"'/.config/mattermost-patches-1064/.setup-ok'

function abs_path() {
  perl -MCwd -le '
    for (@ARGV) {
      if ($p = Cwd::abs_path $_) {
        print $p;
      } else {
        warn "abs_path: $_: $!\n";
        $ret = 1;
      }
    }
    exit $ret' "$@"
}

function cdp() {
    cd "$@"
    echo '>>> [Changing directory to '"$(pwd)"']'
}

sourceWorkDir="$(pwd)"

patchedGoPath="$(abs_path ./mattergopatched)"
patchedPath="$PATH:$patchedGoPath/bin"

export GOPATH="$(abs_path ./mattergo)"
export PATH="$PATH:$GOPATH/bin"

mattermostCloneDir="$GOPATH/src/github.com/mattermost/platform"
mattermostCopyDir="$patchedGoPath/src/github.com/mattermost/platform"

if [[ ! -f "$confirmedNonAutoSetupFile" ]]; then
    echo ">>> Please ensure that you have setup your build env as http://docs.mattermost.com/developer/developer-setup.html says."
    echo ">>> Once you are ready, hit enter to continue."
    echo -n ">>> "
    read dummy
    mkdir -p "$(dirname $confirmedNonAutoSetupFile)" || true # ok if it exists
    touch "$confirmedNonAutoSetupFile"
fi

# Setup GO
mkdir -p "$GOPATH"
ulimit -n 8096

if [[ "x$1" != "xy" ]]; then
    echo ">>> Assuming you have nodejs."
    echo ">>> Assuming you have ruby and compass."
    echo -n ">>> Are the above assumptions correct [Y/n]? "
    read ok
    if [[ "x$ok" == "x" ]]; then
        ok=y
    fi
    if [[ "x$ok" != "xy" ]]; then
        echo ">>> Aborting!"
        exit 1
    fi
fi

# Check clone dir
echo ">>> Checking '$mattermostCloneDir'"
mkdir -p "$mattermostCloneDir" || true # ok if it exists
cdp "$mattermostCloneDir"
    if [ ! -d ./.git ]; then
        # Clone it
        echo ">>> Cloning mattermost"
        git clone "$mattermostRepo" . || git clone "$mattermostSshRepo" .
    fi
    if ! git status --porcelain >/dev/null 2>&1; then
        echo '>>> Clean up '"$mattermostCloneDir"' please.'
        exit 1
    fi
    # Checkout specific commit for patches
    git checkout "$mattermostCommit"
cdp "$sourceWorkDir"


echo ">>> Copy-cloning '$mattermostCloneDir' to '$mattermostCopyDir'"
# Copy clone dir, removing to prevent patch weirdness
rm -rf "$mattermostCopyDir" && git clone "$mattermostCloneDir" "$mattermostCopyDir"
cdp "$mattermostCopyDir"
    # Apply patches
    echo ">>> Applying patches"
    find "$sourceWorkDir/$patchesDir" -name '*.patch' | sort | xargs -n1 "$sourceWorkDir/apply-patch.sh"
    echo ">>> Building patched mattermost."
    export GOPATH="$patchedGoPath"
    export PATH="$patchedPath"
    if [[ "x$MP_RUN_TESTS" == "x" ]] || [[ "x$MP_RUN_TESTS" == "x1" ]]; then
        echo 'Running tests...'
        make test
    fi
    make run
cdp "$sourceWorkDir"
echo ">>> All done!"
