final: prev: {
  # cm - robot-friendly wrapper around cass (defaults to machine output).
  cm = prev.writeShellScriptBin "cm" ''
    set -euo pipefail

    cass_bin="${final.cass}/bin/cass"

    if [[ $# -eq 0 ]]; then
      exec "$cass_bin" robot-docs guide
    fi

    cmd="$1"
    shift || true

    case "$cmd" in
      search)
        exec "$cass_bin" search "$@" --robot
        ;;
      view)
        exec "$cass_bin" view "$@" --json
        ;;
      expand)
        exec "$cass_bin" expand "$@" --json
        ;;
      capabilities)
        exec "$cass_bin" capabilities "$@" --json
        ;;
      *)
        exec "$cass_bin" "$cmd" "$@"
        ;;
    esac
  '';
}
