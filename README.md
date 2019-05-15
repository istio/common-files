# Common Files

This repository contains build-related files used by several Istio repos.

Within repos that use files from this repo, just run scripts/updatecommonfiles.sh to
grab the latest versions of these files. In addition to copying the latest versions of
the files from this repo's file directory, the script will also update
`scripts/updatecommonfiles.latest` to contain the SHA representing the exact set of common files
copied into the repo.
