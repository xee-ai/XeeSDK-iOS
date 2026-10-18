#!/usr/bin/env python3
"""Renames Adapty to Xee across the package. Safe to run twice."""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIRS = ["Sources", "Sources.Logger", "Tests"]
CODE = {".swift", ".h", ".xcprivacy", ".yaml", ".cue"}
ATTRIBUTION = "// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)\n"

# Documentation links in comments. There is no Xee documentation site yet, so use a reserved host.
DOC_URL = re.compile(r"https?://(?:docs\.|app\.)?adapty\.io[^\s\"')>\]]*")
# Any other Adapty host, such as the media CDN in the fixtures (found by the audit).
HOST = re.compile(r"https?://[a-z0-9.-]*adapty\.io")
RULES = [
    (re.compile(r"\bio\.adapty\b"), "ai.xee"),
    (re.compile(r"\bADAPTY_"), "XEE_"),  # the KIDS_MODE compile flag
    (re.compile(r"\badapty\.sdk\b"), "xee.sdk"),  # the app-support file name
    (re.compile(r"\bAdapty(?=[A-Z0-9_])"), "Xee"),  # AdaptyProfile, AdaptySDK, AdaptyError
    (re.compile(r"\bAdapty\b"), "Xee"),  # the module and entry type
    # A lowercase prefix before Adapty, as in `error.asAdaptyError` and `asAdaptyProduct` (found by the
    # audit in Sources/StoreKit/*: "throw error.asAdaptyError").
    (re.compile(r"(?<=[a-z])Adapty(?=[A-Z0-9_]|\b)"), "Xee"),
    (re.compile(r"\badapty(?=[A-Z])"), "xee"),  # adaptyProductId, adaptyErrorCode
    (re.compile(r"\badapty-"), "xee-"),  # HTTP header names
    (re.compile(r"\badapty\.(?=[a-z_]+\.(?:schema\.)?(?:yaml|cue)\b)"), "xee."),
]


def files(suffixes):
    for d in DIRS:
        for p in (ROOT / d).rglob("*"):
            if p.is_file() and p.suffix in suffixes:
                yield p


def rewrite(text):
    text = DOC_URL.sub("https://xee.invalid/docs", text)
    text = HOST.sub("https://xee.invalid", text)
    for pattern, replacement in RULES:
        text = pattern.sub(replacement, text)
    return text


# 1. Contents. Fixtures only get the host replaced: their JSON keys are wire data.
for p in files(CODE):
    original = p.read_text()
    updated = rewrite(original)
    if p.suffix == ".swift" and "Derived from Adapty iOS SDK" not in updated:
        updated = ATTRIBUTION + updated
    if updated != original:
        p.write_text(updated)
for p in files({".json"}):
    original = p.read_text()
    updated = HOST.sub("https://xee.invalid", DOC_URL.sub("https://xee.invalid/docs", original))
    if updated != original:
        p.write_text(updated)

pkg = ROOT / "Package.swift"
pkg.write_text(rewrite(pkg.read_text()))

# 2. Names. Deepest first, so a renamed directory does not hide its files.
paths = sorted((p for d in DIRS for p in (ROOT / d).rglob("*") if "Adapty" in p.name),
               key=lambda p: len(p.parts), reverse=True)
for p in paths:
    p.rename(p.with_name(p.name.replace("Adapty", "Xee")))
print("renamed")
