function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

# Do not regen Docker images on CI.
# Docker images will be pulled by CI.
function ciopt() {
    [[ "$CI" == "true" ]]\
      && echo ${1}-no-img-regen \
      || echo ${1}
}

# Use the nightly Docker image when running the tests on CI.
# Use the latest Docker image when running the tests locally.
function img_tag {
    [[ "$CI" == "true" ]]\
      && echo "nightly" \
      || echo "latest"
}

source "$(dirname "${BASH_SOURCE[0]}")/bats-assert/load.bash"
source "$(dirname "${BASH_SOURCE[0]}")/bats-support/load.bash"

. "$(dirname ${BASH_SOURCE[0]})/bats-utils/helpers"
set_bats_test_suite_name "${BASH_SOURCE[0]%/*}"
remove_bats_test_dirs

source "$(dirname "${BASH_SOURCE[0]}")/bats-utils/background-process"

source "$(dirname "${BASH_SOURCE[0]}")/many.bash"
source "$(dirname "${BASH_SOURCE[0]}")/ledger.bash"
