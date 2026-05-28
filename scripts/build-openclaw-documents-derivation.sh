set -euo pipefail

# Nix derivation builder for programs.openclaw.documents. The actual document
# composition logic stays in build-openclaw-documents.sh so it can be linted and
# understood outside the Nix expression.
bash @buildOpenclawDocuments@ \
  @documentsDir@ \
  @openclawUpstreamAgents@ \
  @joshAgents@ \
  "$out"
