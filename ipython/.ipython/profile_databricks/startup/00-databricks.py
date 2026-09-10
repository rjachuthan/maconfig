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
import configparser
import os


def _configured_profiles():
    """Section names in ~/.databrickscfg, so a typo'd DATABRICKS_CONFIG_PROFILE
    can be caught before hitting the SDK's much less specific error."""
    path = os.path.expanduser("~/.databrickscfg")
    if not os.path.isfile(path):
        return []
    cfg = configparser.ConfigParser()
    cfg.read(path)
    return [s for s in cfg.sections() if s not in ("DEFAULT", "__settings__")]


def _init_spark():
    try:
        from databricks.connect import DatabricksSession
    except ImportError:
        return None, (
            "`databricks-connect` isn't installed in the active venv. Fix: "
            "pip install databricks-connect==<the cluster's exact DBR runtime version>"
        )

    profile = os.environ.get("DATABRICKS_CONFIG_PROFILE")
    if profile:
        known = _configured_profiles()
        if known and profile not in known:
            return None, (
                f"DATABRICKS_CONFIG_PROFILE={profile!r} has no matching section in "
                f"~/.databrickscfg (found: {', '.join(known)}). Fix: correct the "
                f"env var (likely in this project's .env), or run "
                f"`databricks auth login --profile {profile}` to create it."
            )

    if not os.environ.get("DATABRICKS_CLUSTER_ID") and not (
        profile and _profile_has(profile, "cluster_id")
    ):
        print(
            "Databricks Connect: no DATABRICKS_CLUSTER_ID set (env var or "
            "cluster_id in the profile) -- getOrCreate() will fall back to "
            "serverless/default compute, which may not be the cluster you want."
        )

    try:
        return DatabricksSession.builder.getOrCreate(), None
    except Exception as exc:
        return None, f"{exc}\n\nFix the issue above, then restart the REPL (<leader>rR)."


def _profile_has(profile, key):
    path = os.path.expanduser("~/.databrickscfg")
    if not os.path.isfile(path):
        return False
    cfg = configparser.ConfigParser()
    cfg.read(path)
    return cfg.has_option(profile, key)


class _SparkUnavailable:
    """Stands in for `spark` when init fails, so touching it raises a clear,
    repeatable error instead of a bare NameError the first time it scrolls
    off screen."""

    def __init__(self, reason):
        self._reason = reason

    def __getattr__(self, _name):
        raise RuntimeError(f"`spark` failed to initialize: {self._reason}")


_spark, _error = _init_spark()
if _spark is not None:
    spark = _spark
    print("Databricks Connect: spark ready")
else:
    spark = _SparkUnavailable(_error)
    print(f"Databricks Connect: spark session not started\n  {_error}")
