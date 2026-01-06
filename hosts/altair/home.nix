{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for altair
  # EndevourOS workstation for development, PDF/LaTeX editing, and data analysis

  home.packages = with pkgs; [
    # === LaTeX Support ===
    # Full TeXLive distribution with all packages
    texliveFull
    # Alternatively, for a smaller install:
    # texlive.combined.scheme-medium

    # LaTeX editors
    texstudio          # Full-featured LaTeX IDE
    # texmaker         # Alternative LaTeX editor

    # LaTeX utilities
    latexrun          # Simplified LaTeX compilation
    rubber            # LaTeX build automation


    # PDF editors
    xournalpp         # PDF annotation and note-taking
    pdfarranger       # PDF page manipulation (split, merge, rotate)

    # PDF tools
    poppler-utils     # pdfinfo, pdftotext, pdfunite, pdfseparate
    qpdf              # PDF transformation and encryption
    pdftk             # PDF toolkit
    ghostscript       # PDF processing

    # === Data Analysis ===
    # Python data science stack with all packages in one environment
    (python3.withPackages (ps: with ps; [
      # Core data science
      numpy
      pandas
      matplotlib
      seaborn
      scipy
      scikit-learn
      
      # Jupyter
      jupyterlab
      notebook
      ipython
      
      # Fast dataframes
      polars
      
      # Visualization
      plotly
      bokeh
      
      # Data formats
      openpyxl      # Excel support
      xlrd
      h5py          # HDF5 support
      pyarrow       # Parquet/Arrow support
    ]))

    # Julia for numerical computing
    julia

    # === Development Tools ===
    # Additional dev tools for altair
    # gromacs  # if you need nix version

    # === Printing Support ===
    # Note: CUPS service must be installed via system package manager
    # On EndevourOS: sudo pacman -S cups
    # Then enable: sudo systemctl enable --now cups.service

    # CUPS utilities for user space
    system-config-printer  # CUPS GUI configuration
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "standalone";

    # LaTeX environment
    TEXMFHOME = "$HOME/.texmf";

    # Jupyter configuration
    JUPYTER_CONFIG_DIR = "$HOME/.config/jupyter";

    # Force English for all commands
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    LANGUAGE = "en_US:en";
  };

  # Host-specific program overrides
  # programs.alacritty.settings.font.size = 12;

  # Git configuration for data science work
  programs.git.ignores = [
    # Jupyter
    ".ipynb_checkpoints/"
    "*.ipynb_checkpoints"

    # Python
    "__pycache__/"
    "*.pyc"
    ".venv/"
    "venv/"

    # R
    ".Rhistory"
    ".RData"
    ".Rproj.user/"

    # LaTeX
    "*.aux"
    "*.log"
    "*.out"
    "*.toc"
    "*.bbl"
    "*.blg"
    "*.synctex.gz"
    "*.fdb_latexmk"
    "*.fls"

    # Data files (large)
    "*.csv"
    "*.parquet"
    "*.h5"
    "*.hdf5"
  ];
}
