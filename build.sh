export GIT_CACHE_PATH="${HOME}/.git_cache"
export SCCACHE_BUCKET="electronjs-sccache"
export SCCACHE_TWO_TIER=true
export CHROMIUM_BUILDTOOLS_PATH="${HOME}/electron-gn/src/buildtools"
export GN_EXTRA_ARGS="${GN_EXTRA_ARGS} cc_wrapper=\"${HOME}/electron-gn/src/electron/external_binaries/sccache\""

rm -rf $HOME/electron-gn/src/out/Release

cd $HOME/depot_tools
git stash
git pull

cd $HOME/electron-gn/src/electron
git stash
git pull
gclient sync -f

cd $HOME/electron-gn/src
gn gen out/Release --args="import(\"//electron/build/args/release.gn\") $GN_EXTRA_ARGS"
ninja -C out/Release electron
electron/script/strip-binaries.py -d out/Release
ninja -C out/Release electron:electron_dist_zip

cd $HOME/electron-gn/src/out/Release
ELECTRON_VERSION=`cat version`
mv dist.zip electron-v$ELECTRON_VERSION-linux-x64.zip
sha256sum -b electron-v$ELECTRON_VERSION-linux-x64.zip > SHASUMS256.txt

jfrog rt u ./electron-v$ELECTRON_VERSION-linux-x64.zip www-cache/edu-electron/$ELECTRON_VERSION/ --url https://bin.barco.com/artifactory --user=$ARTIFACTORY_ACCOUNT_USR --password=$ARTIFACTORY_ACCOUNT_PSW
jfrog rt u ./SHASUMS256.txt www-cache/edu-electron/$ELECTRON_VERSION/ --url https://bin.barco.com/artifactory --user=$ARTIFACTORY_ACCOUNT_USR --password=$ARTIFACTORY_ACCOUNT_PSW
