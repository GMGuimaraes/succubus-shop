#!/usr/bin/env python3
"""Valida export_presets.cfg para itch.io: campos de versao sao Windows-only e o preset Web crava thread_support=false.

Uso: python check_export_presets.py [export_presets.cfg]
Somente leitura; sai com codigo != 0 em qualquer FAIL.
"""
import re
import sys

WINDOWS_ONLY = ("application/file_version", "application/product_version")
SECTION_RE = re.compile(r"^\[(preset\.\d+)(?:\.(options))?\]\s*$")


def parse(path):
    presets, section = {}, None
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            m = SECTION_RE.match(raw.strip())
            if m:
                section = (m.group(1), bool(m.group(2)))
                presets.setdefault(section[0], {"main": {}, "options": {}})
                continue
            if section is None or "=" not in raw:
                continue
            key, value = raw.split("=", 1)
            slot = presets[section[0]]["options"] if section[1] else presets[section[0]]["main"]
            slot[key.strip()] = value.strip().strip('"')
    return presets


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "export_presets.cfg"
    try:
        presets = parse(path)
    except OSError as exc:
        print(f"FAIL nao foi possivel ler {path}: {exc}")
        return 1

    failures = 0

    def check(ok, label):
        nonlocal failures
        print(f"{'PASS' if ok else 'FAIL'} {label}")
        if not ok:
            failures += 1

    def preset_ids():
        return sorted(presets, key=lambda p: int(p.split(".")[1]))

    for pid in preset_ids():
        main_ = presets[pid]["main"]
        check(bool(main_.get("name")) and bool(main_.get("platform")) and bool(main_.get("export_path")),
              f"{pid}: name/platform/export_path presentes")

    win = [p for p in preset_ids() if presets[p]["main"].get("platform") == "Windows Desktop"]
    check(len(win) == 1, f"exatamente 1 preset 'Windows Desktop' (achados: {len(win)})")
    for pid in win:
        for field in WINDOWS_ONLY:
            value = presets[pid]["options"].get(field, "")
            check(bool(value), f"{pid} ({presets[pid]['main'].get('name')}): {field} PRESENTE e nao vazio")

    for pid in preset_ids():
        platform = presets[pid]["main"].get("platform")
        if platform == "Windows Desktop":
            continue
        for field in WINDOWS_ONLY:
            check(field not in presets[pid]["options"],
                  f"{pid} ({platform}): {field} AUSENTE (campo Windows-only)")

    web = [p for p in preset_ids() if presets[p]["main"].get("platform") == "Web"]
    check(len(web) >= 1, "existe preset 'Web'")
    for pid in web:
        opts = presets[pid]["options"]
        check(opts.get("variant/thread_support") == "false",
              f"{pid}: variant/thread_support=false (sem exigencia de SharedArrayBuffer)")
        check(opts.get("variant/extensions_support", "false") in ("false", "true"),
              f"{pid}: variant/extensions_support definido (confirmar se ha extensoes)")
        both = (opts.get("vram_texture_compression/for_desktop") == "true"
                and opts.get("vram_texture_compression/for_mobile") == "true")
        print(f"{'WARN' if both else 'PASS'} {pid}: "
              f"{'for_desktop E for_mobile ligados -> dois conjuntos de compressao, .pck pode dobrar (medir com measure_png_budget.py)' if both else 'compression set unico'}")

    print(f"\n{failures} falha(s)" + (" -- nao exportar ainda" if failures else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
