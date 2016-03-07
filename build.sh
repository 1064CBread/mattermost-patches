#!/usr/bin/env bash

set -e
mattermostRepo='https://github.com/mattermost/platform'
mattermostSshRepo='ssh://git@ssh.github.com:443/mattermost/platform' # In case HTTPS is being weird
mattermostCommit='0387ac799792fdd0684b863bb029813bbb3eccf7'
mattermostCloneDir='mattermost'
mattermostCopyDir="$mattermostCloneDir-patched"
patchesDir='patches'
confirmedNonAutoSetupFile="$HOME"'/.config/mattermost-patches-1064/.setup-ok'

if [[ ! -f "$confirmedNonAutoSetupFile" ]]; then
    echo ">>> Please ensure that you have setup your build env as http://docs.mattermost.com/developer/developer-setup.html says."
    echo ">>> Once you are ready, hit enter to continue."
    echo -n ">>> "
    read dummy
    mkdir -p "$(dirname $confirmedNonAutoSetupFile)" || true # ok if it exists
    touch "$confirmedNonAutoSetupFile"
fi

# Check clone dir

echo ">>> Checking '$mattermostCloneDir'"
mkdir "$mattermostCloneDir" || true # ok if it exists
cd "$mattermostCloneDir"
    if [ ! -d ./.git ]; then
        # Clone it
        echo ">>> Cloning mattermost"
        git clone "$mattermostRepo" . || git clone "$mattermostSshRepo" .
    fi
    if ! git status --porcelain >/dev/null 2>&1; then
        echo '>>> Clean up '"$mattermostCloneDir"' please.'
        exit 1
    fi
cd ".."


echo ">>> Copy-cloning '$mattermostCloneDir' to '$mattermostCopyDir'"
# Copy clone dir
[[ -d "$mattermostCopyDir" ]] || git clone "$mattermostCloneDir" "$mattermostCopyDir"
cd "$mattermostCopyDir"
    # Apply patches
    echo ">>> Applying patches"
    find "../$patchesDir" -name '*.patch' -exec ./../apply-patch.sh {} \;
    echo ">>> Building patched mattermost."

cd ".."
echo ">>> All done!"
