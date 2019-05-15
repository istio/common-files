# The original version of this file is located in the https://github.com/istio/common-files repo.
# If you're looking at this file in a different repo and want to make a change, please go to the
# common-files repo, make the change there and check it in. Then come back to this repo and run the
# scripts/updatecommonfiles.sh script.

lint:
	@scripts/linters.sh

fixlint:
	@scripts/linters.sh --fix

format:
	@scripts/fmt.sh

fmt:
	@scripts/fmt.sh
