#!/usr/bin/env python3
"""Read-only Foundation metadata; never dispatch commands or mutate runtime."""
import argparse
import json
import math
from pathlib import Path
import re
import sys

import apex_foundation as legacy

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs" / "foundation"
LIMIT = 2 * 1024 * 1024
TYPES = {"string": str, "integer": int, "object": dict, "array": list,
         "boolean": bool, "null": type(None)}
KEYS = {"type", "enum", "pattern", "minLength", "properties", "required",
        "additionalProperties", "items", "uniqueItems"}

def pairs(rows):
    result = {}
    for key, value in rows:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result

def bad_constant(value):
    raise ValueError("invalid JSON constant: " + value)

def finite_float(value):
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("nonfinite JSON number")
    return number

def read(path):
    with Path(path).open("rb") as handle:
        raw = handle.read(LIMIT + 1)
    if len(raw) > LIMIT:
        raise ValueError("JSON size limit")
    return json.loads(raw.decode("utf-8"), object_pairs_hook=pairs,
                      parse_constant=bad_constant, parse_float=finite_float)

def schema_check(schema):
    if not isinstance(schema, dict) or set(schema) - KEYS or "type" not in schema:
        raise ValueError("unsupported schema keyword or missing type")
    types = schema["type"]
    types = [types] if isinstance(types, str) else types
    if not isinstance(types, list) or not types or any(t not in TYPES for t in types):
        raise ValueError("unsupported schema type")
    if "object" in types:
        if schema.get("additionalProperties") is not False:
            raise ValueError("object schema must be closed")
        if set(schema["required"]) != set(schema["properties"]):
            raise ValueError("all properties must be required in v1 dialect")
        for child in schema["properties"].values():
            schema_check(child)
    if "array" in types:
        schema_check(schema["items"])
    if "pattern" in schema:
        re.compile(schema["pattern"])

def check(value, schema, at="$"):
    types = schema["type"]
    types = [types] if isinstance(types, str) else types
    if not any(type(value) is TYPES[t] for t in types):
        raise ValueError(at + ": wrong type")
    if "enum" in schema and not any(type(value) is type(v) and value == v for v in schema["enum"]):
        raise ValueError(at + ": invalid enum")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            raise ValueError(at + ": empty string")
        if "pattern" in schema and not re.fullmatch(schema["pattern"], value):
            raise ValueError(at + ": invalid format")
    if isinstance(value, dict):
        props = schema["properties"]
        if set(value) != set(props):
            raise ValueError(at + ": missing or unknown property")
        for key, item in value.items():
            check(item, props[key], at + "." + key)
    if isinstance(value, list):
        if schema.get("uniqueItems") and len({json.dumps(v, sort_keys=True) for v in value}) != len(value):
            raise ValueError(at + ": duplicate item")
        for index, item in enumerate(value):
            check(item, schema["items"], f"{at}[{index}]")

def load_registry():
    return read(DOCS / "registry.json"), read(DOCS / "schemas.json")

def unique(rows):
    indexed = {row["id"]: row for row in rows}
    if len(indexed) != len(rows):
        raise ValueError("duplicate registry ID")
    return indexed

def safe_entry(path):
    p = Path(path)
    if p.is_absolute() or "\\" in path or ".." in p.parts or str(p) != path:
        raise ValueError("unsafe entrypoint: " + path)
    resolved = (ROOT / p).resolve(strict=True)
    if ROOT not in resolved.parents or not resolved.is_file():
        raise ValueError("entrypoint outside repository: " + path)

def validate_registry(reg, schemas):
    if set(reg) != {"foundation_version", "modules", "capabilities", "compatibility", "contracts"} or reg["foundation_version"] != "0.1.0":
        raise ValueError("unsupported registry format")
    for schema in schemas.values():
        schema_check(schema)
    for key, schema_id in (("modules", "module.v1"), ("capabilities", "capability.v1"), ("compatibility", "compatibility.v1")):
        if type(reg[key]) is not list:
            raise ValueError("registry collection must be list")
        for row in reg[key]:
            check(row, schemas[schema_id])
    modules, caps = unique(reg["modules"]), unique(reg["capabilities"])
    def visit(mid, chain):
        if mid in chain:
            raise ValueError("module dependency cycle")
        for dep in modules[mid]["dependencies"]:
            if dep not in modules:
                raise ValueError("unknown dependency")
            visit(dep, chain | {mid})
    for mid, row in modules.items():
        visit(mid, set())
        for path in row["entrypoints"]:
            safe_entry(path)
    for cap in caps.values():
        if cap["module"] not in modules or modules[cap["module"]]["maturity"] == "planned":
            raise ValueError("capability has no existing provider")
    seen = set()
    for row in reg["compatibility"]:
        if row["left"] not in modules or row["right"] not in modules or row["left"] == row["right"]:
            raise ValueError("invalid compatibility pair")
        pair = pair_key(row["left"], row["left_version"], row["right"], row["right_version"])
        if pair in seen:
            raise ValueError("duplicate compatibility pair")
        seen.add(pair)
    contracts = unique(reg["contracts"])
    for cid, row in contracts.items():
        if row["status"] == "active":
            if set(row) != {"id", "status"} or cid not in schemas:
                raise ValueError("active contract missing schema")
        elif row["status"] != "deferred" or set(row) != {"id", "status", "reason"} or cid in schemas or not row["reason"]:
            raise ValueError("invalid deferred contract")
    if {cid for cid, row in contracts.items() if row["status"] == "active"} != set(schemas):
        raise ValueError("unregistered schema")
    return {"status": "PASS", "scope": "structural metadata only",
            "modules": len(modules), "capabilities": len(caps),
            "active_contracts": len(schemas), "compatibility_pairs": len(seen)}

def pair_key(left, lv, right, rv):
    return tuple(sorted(((left, lv), (right, rv))))

def compatibility(reg, left, lv, right, rv):
    key = pair_key(left, lv, right, rv)
    for row in reg["compatibility"]:
        if key == pair_key(row["left"], row["left_version"], row["right"], row["right_version"]):
            return dict(row, compatible=row["status"] == "PASS", authorized=False)
    return {"status": "BLOCKED", "compatible": False, "authorized": False,
            "reason": "unknown exact pair; validate and plan migration"}

def search(query):
    query = query.strip().casefold()
    if not query or len(query) > 200:
        raise ValueError("query length must be 1..200")
    matches = []
    for filename in ("references.json", "possibilities.json"):
        for row in read(legacy.DOCS / filename)["entries"]:
            if query in json.dumps(row, ensure_ascii=False).casefold():
                matches.append(row)
    return {"status": "PASS", "scope": "offline search only", "matches": matches}

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    subs.add_parser("validate")
    subs.add_parser("list")
    p = subs.add_parser("check")
    p.add_argument("contract")
    p.add_argument("file", type=Path)
    p = subs.add_parser("compatibility")
    for name in ("left", "left_version", "right", "right_version"):
        p.add_argument(name)
    subs.add_parser("search").add_argument("query")
    args = parser.parse_args(argv)
    try:
        reg, schemas = load_registry()
        result = validate_registry(reg, schemas)
        if args.command == "validate":
            result["catalog"] = legacy.validate()
        elif args.command == "list":
            result = reg
        elif args.command == "check":
            if args.contract not in schemas:
                raise ValueError("unknown or deferred contract")
            check(read(args.file), schemas[args.contract])
            result = {"status": "PASS", "scope": "structure only", "contract": args.contract}
        elif args.command == "compatibility":
            result = compatibility(reg, args.left, args.left_version, args.right, args.right_version)
        elif args.command == "search":
            result = search(args.query)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 1 if result.get("compatible") is False else 0
    except (ValueError, TypeError, KeyError, OSError, RecursionError) as exc:
        print(json.dumps({"status": "FAIL", "error": str(exc)[:500]}), file=sys.stderr)
        return 2

if __name__ == "__main__":
    sys.exit(main())
