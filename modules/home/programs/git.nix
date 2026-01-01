{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    # Override these in private/hosts/<host>/home.nix
    settings = {
      user = {
        name = lib.mkDefault "Mykyta";
        email = lib.mkDefault "";
      };
      init.defaultBranch = "main";
      
      pull.rebase = true;
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      
      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      merge = {
        conflictstyle = "zdiff3";
        tool = "nvimdiff";
      };

      diff = {
        colorMoved = "default";
        algorithm = "histogram";
      };

      core = {
        editor = "nvim";
        whitespace = "trailing-space,space-before-tab";
      };

      # Reuse recorded resolution
      rerere = {
        enabled = true;
        autoUpdate = true;
      };

      # Better fetch behavior
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Signing (configure key in private config)
      # commit.gpgsign = true;
      # tag.gpgsign = true;

      # URL shortcuts
      url = {
        "git@github.com:" = {
          insteadOf = "gh:";
          pushInsteadOf = "https://github.com/";
        };
        "git@gitlab.com:" = {
          insteadOf = "gl:";
        };
      };

      # Column output for branch/status
      column.ui = "auto";
      branch.sort = "-committerdate";

      # Aliases
      alias = {
        # Status
        st = "status -sb";
        s = "status -sb";

        # Branches
        co = "checkout";
        cob = "checkout -b";
        br = "branch";
        brd = "branch -d";
        brD = "branch -D";

        # Commits
        ci = "commit";
        cia = "commit --amend";
        ciane = "commit --amend --no-edit";
        fixup = "commit --fixup";

        # Staging
        a = "add";
        aa = "add --all";
        ap = "add --patch";
        unstage = "reset HEAD --";

        # Diffing
        d = "diff";
        ds = "diff --staged";
        dc = "diff --cached";

        # Logging
        last = "log -1 HEAD --stat";
        lg = "log --oneline --graph --decorate -20";
        lga = "log --oneline --graph --decorate --all";
        ll = "log --pretty=format:'%C(yellow)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' -20";

        # History exploration
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";

        # Working with changes
        wip = "!git add -A && git commit -m 'WIP'";
        unwip = "reset HEAD~1";

        # Stash
        ss = "stash save";
        sp = "stash pop";
        sl = "stash list";

        # Remote
        f = "fetch --all --prune";
        pl = "pull";
        ps = "push";
        psf = "push --force-with-lease";

        # Cleanup
        cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d";

        # Find
        find = "!git ls-files | grep -i";

        # Blame with ignoring whitespace
        blame-w = "blame -w -C -C -C";

        # Interactive rebase shortcuts
        ri = "rebase -i";
        rim = "rebase -i main";
        rc = "rebase --continue";
        ra = "rebase --abort";

        # Cherry-pick
        cp = "cherry-pick";
        cpc = "cherry-pick --continue";
        cpa = "cherry-pick --abort";
      };
    };

    ignores = [
      # OS
      ".DS_Store"
      "Thumbs.db"

      # Editors
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      ".vscode/"
      "*.sublime-*"

      # Nix
      ".direnv/"
      ".envrc"
      "result"
      "result-*"

      # Python
      "__pycache__/"
      "*.py[cod]"
      ".venv/"
      "venv/"
      ".python-version"

      # Rust
      "target/"

      # Node
      "node_modules/"

      # Build artifacts
      "*.o"
      "*.a"
      "*.so"
      "*.dylib"

      # Logs
      "*.log"
    ];
  };

  # Delta for better git diffs
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Dracula";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
