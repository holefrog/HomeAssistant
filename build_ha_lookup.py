# build_ha_lookup.py v1
# 读取脚本同级 .storage 目录，生成 ha_lookup.json
# 包含：device_id -> 设备信息+实体列表，entity_id -> 实体信息
# 用法：python build_ha_lookup.py

import json
import os
from pathlib import Path

STORAGE_DIR = Path(__file__).parent / ".storage"
OUTPUT_FILE = Path(__file__).parent / "ha_lookup.json"


def load_json_file(path: Path) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_lookup():
    # --- 读取 area registry ---
    area_map = {}  # area_id -> area_name
    area_file = STORAGE_DIR / "core.area_registry"
    if area_file.exists():
        data = load_json_file(area_file)
        for area in data.get("data", {}).get("areas", []):
            area_map[area["id"]] = area.get("name", "")

    # --- 读取 device registry ---
    device_map = {}  # device_id -> device info dict
    device_file = STORAGE_DIR / "core.device_registry"
    if device_file.exists():
        data = load_json_file(device_file)
        for dev in data.get("data", {}).get("devices", []):
            device_id = dev.get("id")
            if not device_id:
                continue
            area_id = dev.get("area_id")
            device_map[device_id] = {
                "name": dev.get("name_by_user") or dev.get("name") or "",
                "name_by_user": dev.get("name_by_user"),
                "manufacturer": dev.get("manufacturer"),
                "model": dev.get("model"),
                "area": area_map.get(area_id, "") if area_id else "",
                "entities": [],  # 后面填充
            }

    # --- 读取 entity registry ---
    entity_map = {}  # entity_id -> entity info dict
    entity_file = STORAGE_DIR / "core.entity_registry"
    if entity_file.exists():
        data = load_json_file(entity_file)
        for ent in data.get("data", {}).get("entities", []):
            entity_id = ent.get("entity_id")
            if not entity_id:
                continue
            device_id = ent.get("device_id")
            area_id = ent.get("area_id")

            # friendly_name 构建：优先用户自定义名，其次整合名，最后用 entity_id slug
            user_name = ent.get("name")  # 用户在 UI 里改过的名字
            original_name = ent.get("original_name") or ""
            device_name = device_map.get(device_id, {}).get("name", "") if device_id else ""

            if user_name:
                friendly_name = user_name
            elif device_name and original_name:
                friendly_name = f"{device_name} {original_name}"
            elif device_name:
                friendly_name = device_name
            elif original_name:
                friendly_name = original_name
            else:
                friendly_name = entity_id.split(".")[-1].replace("_", " ").title()

            # 确定实体归属的 area（实体 area 优先，否则继承设备 area）
            if area_id:
                entity_area = area_map.get(area_id, "")
            elif device_id:
                entity_area = device_map.get(device_id, {}).get("area", "")
            else:
                entity_area = ""

            entity_map[entity_id] = {
                "friendly_name": friendly_name,
                "device_id": device_id,
                "area": entity_area,
                "platform": ent.get("platform", ""),
                "disabled_by": ent.get("disabled_by"),
            }

            # 把实体挂到设备上
            if device_id and device_id in device_map:
                device_map[device_id]["entities"].append(entity_id)

    # --- 输出 ---
    output = {
        "devices": device_map,
        "entities": entity_map,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    print(f"完成：{len(device_map)} 个设备，{len(entity_map)} 个实体")
    print(f"输出文件：{OUTPUT_FILE}")


if __name__ == "__main__":
    if not STORAGE_DIR.exists():
        print(f"错误：找不到 .storage 目录：{STORAGE_DIR}")
        exit(1)
    build_lookup()
