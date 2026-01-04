{ lib, pkgs, ... }:
{
  programs.zsh = {
    enable = lib.mkDefault true;
    autocd = lib.mkDefault false;
    cdpath = lib.mkDefault [ "~/Projects" ];

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ../config/zsh;
        file = "p10k.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
      {
        name = "fzf-key-bindings";
        src = pkgs.fzf;
        file = "share/fzf/key-bindings.zsh";
      }
      {
        name = "fzf-completion";
        src = pkgs.fzf;
        file = "share/fzf/completion.zsh";
      }
    ];

    initContent = lib.mkBefore (builtins.readFile ../config/zsh/init-public.zsh);
  };
}
