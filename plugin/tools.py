"""Allowlisted Omarchy CLI wrapper.

Never shells out. Never forwards a raw argv. Mutating plugin verbs always
include --yes. Theme/pkg/sudo/update/system are not in the map.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

OMARCHY_TIMEOUT = {
  "plugin_add": 120,
  "plugin_update": 120,
  "theme_set": 90,
  "screenshot": 60,
}

SCREENSHOT_MODES = ("smart", "region", "windows", "fullscreen")
SCREENSHOT_OUTPUTS = ("copy", "save")
BAR_SECTIONS = ("left", "center", "right")

# verb -> argv template. Placeholders: name, extra, mode, output, section
VERBS: dict[str, list[str]] = {
  "theme_list": ["theme", "list"],
  "theme_current": ["theme", "current"],
  "theme_set": ["theme", "set", "{name}"],
  "plugin_list": ["plugin", "list", "--json"],
  "plugin_enable": ["plugin", "enable", "{name}"],
  "plugin_disable": ["plugin", "disable", "{name}"],
  "plugin_add": ["plugin", "add", "{name}", "--yes"],
  "plugin_remove": ["plugin", "remove", "{name}", "--yes"],
  "plugin_update": ["plugin", "update", "{name}", "--yes"],
  "bar_move": ["bar", "move", "{name}", "--section", "{section}"],
  "menu_summon": ["menu", "summon", "{name}"],
  "menu_toggle": ["menu", "toggle", "{name}"],
  "menu_close": ["menu", "close"],
  "screenshot": ["capture", "screenshot", "{mode}", "{output}"],
  "shell_ping": ["shell", "shell", "ping"],
}

NEEDS_NAME = {
  "theme_set",
  "plugin_enable",
  "plugin_disable",
  "plugin_add",
  "plugin_remove",
  "plugin_update",
  "bar_move",
  "menu_summon",
  "menu_toggle",
}

OMARCHY_SCHEMA = {
  "name": "omarchy",
  "description": (
    "Run an allowlisted Omarchy desktop verb. Use this instead of a raw "
    "terminal for theme, shell plugins, bar layout, menu, screenshot, and "
    "shell ping. Plugin add/remove/update always pass --yes. There is no "
    "update/pkg/sudo/system path here."
  ),
  "parameters": {
    "type": "object",
    "properties": {
      "verb": {
        "type": "string",
        "enum": sorted(VERBS),
        "description": "Allowlisted Omarchy verb",
      },
      "name": {
        "type": "string",
        "description": "Theme name, plugin id or git URL, bar widget id, or menu route",
      },
      "section": {
        "type": "string",
        "enum": list(BAR_SECTIONS),
        "description": "Bar section for bar_move (left/center/right)",
      },
      "mode": {
        "type": "string",
        "enum": list(SCREENSHOT_MODES),
        "description": "Screenshot mode; default fullscreen",
      },
      "output": {
        "type": "string",
        "enum": list(SCREENSHOT_OUTPUTS),
        "description": "Screenshot destination; default copy",
      },
    },
    "required": ["verb"],
  },
}


def omarchy_available() -> bool:
  if shutil.which("omarchy") is None:
    return False
  path = os.environ.get("OMARCHY_PATH") or "/usr/share/omarchy"
  return Path(path).is_dir()


def _fill(template: list[str], params: dict[str, Any]) -> list[str] | str:
  verb = params.get("verb")
  name = str(params.get("name") or "").strip()
  extra = {
    "name": name,
    "section": str(params.get("section") or "").strip(),
    "mode": str(params.get("mode") or "fullscreen").strip(),
    "output": str(params.get("output") or "copy").strip(),
  }
  if extra["mode"] not in SCREENSHOT_MODES:
    return f"invalid screenshot mode: {extra['mode']}"
  if extra["output"] not in SCREENSHOT_OUTPUTS:
    return f"invalid screenshot output: {extra['output']}"
  if extra["section"] and extra["section"] not in BAR_SECTIONS:
    return f"invalid bar section: {extra['section']}"
  if verb in NEEDS_NAME and not extra["name"]:
    return f"verb {verb} requires name"
  if verb == "bar_move" and not extra["section"]:
    return "bar_move requires section"
  argv = []
  for token in template:
    if token.startswith("{") and token.endswith("}"):
      key = token[1:-1]
      value = extra.get(key, "")
      if not value:
        return f"missing {key}"
      argv.append(value)
    else:
      argv.append(token)
  return argv


def build_argv(params: dict[str, Any]) -> list[str] | str:
  verb = params.get("verb")
  if verb not in VERBS:
    return f"unsupported verb: {verb}"
  return _fill(VERBS[verb], params)


def run_omarchy(argv: list[str], timeout: int) -> dict[str, Any]:
  omarchy = shutil.which("omarchy")
  if omarchy is None:
    return {"ok": False, "error": "omarchy not on PATH"}
  try:
    proc = subprocess.run(
      [omarchy, *argv],
      capture_output=True,
      text=True,
      timeout=timeout,
      check=False,
    )
  except subprocess.TimeoutExpired:
    return {"ok": False, "error": f"timed out after {timeout}s", "argv": argv}
  stdout = (proc.stdout or "").strip()
  stderr = (proc.stderr or "").strip()
  return {
    "ok": proc.returncode == 0,
    "code": proc.returncode,
    "argv": argv,
    "stdout": stdout,
    "stderr": stderr,
  }


def handle_omarchy(params: dict[str, Any], **kwargs: Any) -> str:
  del kwargs
  if not omarchy_available():
    return json.dumps({"ok": False, "error": "not on Omarchy (OMARCHY_PATH / omarchy CLI missing)"})
  built = build_argv(params or {})
  if isinstance(built, str):
    return json.dumps({"ok": False, "error": built})
  timeout = OMARCHY_TIMEOUT.get(str((params or {}).get("verb")), 30)
  return json.dumps(run_omarchy(built, timeout))
