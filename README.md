# Common Files

This repository contains build-related files used by several Istio repos.

Within repos that use files from this repo, just run `make update-common` or
`make update-common-protos` to grab the latest versions of the files from the
`files/common` or `common-protos` directories, respectively. In addition to
copying the latest versions of the files from this repo, the make commands
will also update the `.commonfiles.sha` file within their respective
directories to contain the SHA representing the exact set of common files
copied into the repo.