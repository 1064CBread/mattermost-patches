This repo is for applying custom patches to mattermost. `build.sh` will handle cloning, copying, applying patches, and building mattermost.
The only thing you need to do is ensure that your dev environment is setup to build mattermost, as described on http://docs.mattermost.com/developer/developer-setup.html.

Put patches in `./patches` with an extension of `.patch` and they will be applied. Arbitrary nesting is possible, e.g. `./patches/client/channel/name.patch`.

