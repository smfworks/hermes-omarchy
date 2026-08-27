#!/usr/bin/env python3
"""Allowlist tests for the Omarchy Hermes plugin (no Omarchy host required)."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "plugin" / "tools.py"

spec = importlib.util.spec_from_file_location("omarchy_plugin_tools", TOOLS)
assert spec is not None and spec.loader is not None
tools = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tools)


class BuildArgvTests(unittest.TestCase):
  def test_theme_list(self):
    self.assertEqual(tools.build_argv({"verb": "theme_list"}), ["theme", "list"])

  def test_theme_set_requires_name(self):
    self.assertEqual(tools.build_argv({"verb": "theme_set"}), "verb theme_set requires name")

  def test_theme_set(self):
    self.assertEqual(
      tools.build_argv({"verb": "theme_set", "name": "Tokyo Night"}),
      ["theme", "set", "Tokyo Night"],
    )

  def test_plugin_add_always_yes(self):
    argv = tools.build_argv({"verb": "plugin_add", "name": "https://example.com/p.git"})
    self.assertEqual(argv[:3], ["plugin", "add", "https://example.com/p.git"])
    self.assertIn("--yes", argv)

  def test_plugin_remove_always_yes(self):
    argv = tools.build_argv({"verb": "plugin_remove", "name": "acme.weather"})
    self.assertIn("--yes", argv)

  def test_unknown_verb(self):
    self.assertEqual(tools.build_argv({"verb": "update"}), "unsupported verb: update")

  def test_no_raw_system(self):
    self.assertEqual(tools.build_argv({"verb": "pkg"}), "unsupported verb: pkg")

  def test_bar_move(self):
    self.assertEqual(
      tools.build_argv({"verb": "bar_move", "name": "omarchy.clock", "section": "right"}),
      ["bar", "move", "omarchy.clock", "--section", "right"],
    )

  def test_bar_move_needs_section(self):
    self.assertEqual(
      tools.build_argv({"verb": "bar_move", "name": "omarchy.clock"}),
      "bar_move requires section",
    )

  def test_shell_ping(self):
    self.assertEqual(tools.build_argv({"verb": "shell_ping"}), ["shell", "shell", "ping"])

  def test_screenshot_defaults(self):
    self.assertEqual(
      tools.build_argv({"verb": "screenshot"}),
      ["capture", "screenshot", "fullscreen", "copy"],
    )

  def test_schema_has_no_update_pkg(self):
    verbs = set(tools.OMARCHY_SCHEMA["parameters"]["properties"]["verb"]["enum"])
    self.assertNotIn("update", verbs)
    self.assertNotIn("pkg", verbs)
    self.assertNotIn("sudo", verbs)


class AvailabilityTests(unittest.TestCase):
  def test_missing_binary_is_unavailable(self):
    which = tools.shutil.which
    tools.shutil.which = lambda name: None
    try:
      self.assertFalse(tools.omarchy_available())
    finally:
      tools.shutil.which = which


if __name__ == "__main__":
  unittest.main()
