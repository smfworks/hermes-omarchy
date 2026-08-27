"""Omarchy desktop plugin — registration.

Tools stay hidden off Omarchy hosts via check_fn (OMARCHY_PATH or
/usr/share/omarchy, plus `omarchy` on PATH).
"""

from __future__ import annotations

from .tools import OMARCHY_SCHEMA, handle_omarchy, omarchy_available


def register(ctx) -> None:
  ctx.register_tool(
    name="omarchy",
    toolset="omarchy",
    schema=OMARCHY_SCHEMA,
    handler=handle_omarchy,
    check_fn=omarchy_available,
  )
