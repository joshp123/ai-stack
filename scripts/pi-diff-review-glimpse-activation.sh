set -euo pipefail

# Home Manager activation hook for pi-diff-review's glimpse helper.
# The package ships glimpseui sources; build-glimpse-host.sh caches the host
# binary and rebuilds only when the source path changes.
@bash@ @buildGlimpseHost@ "@piDiffReviewRoot@" "@node@"
