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
    # Python data science stack
    python3Packages.numpy
    python3Packages.pandas
    python3Packages.matplotlib
    python3Packages.seaborn
    python3Packages.scipy
    python3Packages.scikit-learn
    python3Packages.jupyterlab
    python3Packages.notebook
    python3Packages.polars     # Fast dataframe library


    # Julia for numerical computing
    julia

    # Data visualization
    python3Packages.plotly
    python3Packages.bokeh

    # Data formats
    python3Packages.openpyxl   # Excel support
    python3Packages.xlrd
    python3Packages.h5py       # HDF5 support
    python3Packages.pyarrow    # Parquet/Arrow support

    # === Development Tools ===
    # Additional dev tools for altair
    # gromacs  # if you need nix version

    # === Printing Support ===
    # CUPS utilities (system service needs to be enabled separately)
    cups              # Common Unix Printing System
    system-config-printer  # CUPS GUI configuration

    # Samba support for network printing
    samba             # SMB/CIFS support
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
