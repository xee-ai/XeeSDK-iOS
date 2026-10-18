#!/usr/bin/env python3
"""Brings the two fallback fixtures up to the format the code reads (version 9).

The 3.17.3 tag ships fixtures in format 8, while its code requires format 9, so Adapty's own
fallback tests fail at that tag. Format 9 adds `access_level_id` and `product_type` to every product.
This adds placeholder values to products that lack them. It changes test data only.
Safe to run twice.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
FIXTURES = ["Tests/Placements/fallback.json", "Tests/Placements/fallback_large.json"]
ACCESS_LEVEL = "premium"
PRODUCT_TYPE = "uncategorised"


def upgrade(node):
    added = 0
    if isinstance(node, dict):
        if "adapty_product_id" in node and "vendor_product_id" in node:
            if "access_level_id" not in node:
                node["access_level_id"] = ACCESS_LEVEL
                added += 1
            if "product_type" not in node:
                node["product_type"] = PRODUCT_TYPE
                added += 1
        for value in node.values():
            added += upgrade(value)
    elif isinstance(node, list):
        for value in node:
            added += upgrade(value)
    return added


for rel in FIXTURES:
    path = ROOT / rel
    data = json.loads(path.read_text())
    data.setdefault("meta", {})["version"] = 9
    added = upgrade(data)
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n")
    print(f"{rel}: version 9, {added} keys added")
