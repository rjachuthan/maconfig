# Runs only under `ipython --profile=databricks` (iron.nvim's Databricks
# Connect REPL uses this profile), never under plain `ipython`/profile_default
# -- so it can't slow down or break unrelated Python work on this machine.
#
# Auth comes from the environment, never from this file or this repo:
#   - DATABRICKS_HOST / DATABRICKS_TOKEN / DATABRICKS_CLUSTER_ID env vars, or
#   - a profile in ~/.databrickscfg (DATABRICKS_CONFIG_PROFILE to pick one)
#
# `databricks-connect` must be installed in the active venv, pinned to the
# target cluster's exact Databricks Runtime version.
try:
    from databricks.connect import DatabricksSession

    spark = DatabricksSession.builder.getOrCreate()
    print("Databricks Connect: spark ready")
except Exception as exc:
    print(f"Databricks Connect: spark session not started ({exc})")
