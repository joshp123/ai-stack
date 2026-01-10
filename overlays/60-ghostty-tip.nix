{ }:
final: prev: {
  ghostty-bin = prev.ghostty-bin.overrideAttrs (_old: {
    version = "tip";
    src = prev.fetchurl {
      url = "https://github.com/ghostty-org/ghostty/releases/download/tip/Ghostty.dmg";
      hash = "sha256-YE3XkB0Vii4XJ7NDp0WVoKXESiZKdmOaV8U0sB35gTE=";
    };
  });
}
