# cua-driver's part of the AI tools bundle. Its app and its skill pack must
# match the binary, so both come from the package; content/ links the skill
# pack by a fixed path (the pi collection tools/cua-driver).
mkdir -p "$out/Applications" "$out/bin" "$out/share"

ln -s "$cuaShare" "$out/share/cua-driver"

# CuaDriver.app hard-codes /Applications/CuaDriver.app, so update-ai-tools
# copies this bundle there; bin/cua-driver points at that installed copy, never
# at the store copy (running the store copy taints it with com.apple.macl).
ln -s "$cuaApp" "$out/Applications/CuaDriver.app"
ln -s /Applications/CuaDriver.app/Contents/MacOS/cua-driver "$out/bin/cua-driver"
