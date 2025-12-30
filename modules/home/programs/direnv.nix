{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    
    # Silence the verbose output
    config = {
      global = {
        warn_timeout = "30s";
        hide_env_diff = true;
      };
    };

    stdlib = ''
      # Custom layout for Python projects
      layout_python() {
        local python=''${1:-python3}
        [[ $# -gt 0 ]] && shift
        unset PYTHONHOME
        if [[ -n $VIRTUAL_ENV ]]; then
          VIRTUAL_ENV=$(cd "$VIRTUAL_ENV" && pwd)
        else
          local venv_path="$PWD/.venv"
          if [[ ! -d $venv_path ]]; then
            $python -m venv "$venv_path"
          fi
          VIRTUAL_ENV="$venv_path"
        fi
        export VIRTUAL_ENV
        PATH_add "$VIRTUAL_ENV/bin"
      }

      # Custom layout for Rust projects
      layout_rust() {
        export CARGO_HOME="$PWD/.cargo"
        export RUSTUP_HOME="$PWD/.rustup"
        PATH_add "$CARGO_HOME/bin"
      }

      # Watch additional files for changes
      watch_file_if_exists() {
        if [[ -f "$1" ]]; then
          watch_file "$1"
        fi
      }

      # Source .env files safely
      dotenv_if_exists() {
        local env_file="''${1:-.env}"
        if [[ -f "$env_file" ]]; then
          dotenv "$env_file"
        fi
      }
    '';
  };
}
