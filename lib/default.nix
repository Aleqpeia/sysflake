{ lib, ... }:
{
  # Helper functions for the configuration
  
  # Check if a path exists (useful for optional imports)
  pathExistsOrNull = path:
    if builtins.pathExists path then path else null;

  # Filter null values from a list
  filterNulls = list:
    builtins.filter (x: x != null) list;

  # Merge multiple attribute sets recursively
  recursiveMerge = attrList:
    lib.foldl' lib.recursiveUpdate {} attrList;

  # Create a host configuration with defaults
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    mode ? "standalone",
    username ? "efyis",
    profiles ? [ "base" ],
  }: {
    inherit system mode username profiles;
  };
}
