import argparse
import json
import os
import re
import shutil
from datetime import datetime, timedelta, timezone

CONTRIBUTORS = [
    "Egg Targaryen",
    "TinyStick",
    "RabbitFeet",
    "Ruri73",
    "dtlnor",
]

FMM_CONFIG = {
    "name": "Item Box Editor",
    "description": "Item Box Editor",
    "author": ", ".join(CONTRIBUTORS),
    "screenshot": "src/assets/screenshot.png",
    "category": "Gameplay",
    "homepage": "https://www.nexusmods.com/monsterhunterwilds/mods/102",
}

LANG_LIST = [
    {
        "tag": "zh-Hans",
    },
    {
        "tag": "zh-Hant",
    },
    {
        "tag": "en-US",
    },
    {
        "tag": "ja-JP",
    },
    {
        "tag": "ko-KR",
    },
]

# source file settings
ORIGIN_LUA_FIEL = "src/ItemBoxEditor.lua"
# action settings
WORK_TEMP_DIR = ".temp"
# save settings
MOD_ROOT_DIR = "reframework"
MOD_NAME = "ItemBoxEditor"
LUA_SAVE_DIR = "{}/{}/{}".format(WORK_TEMP_DIR, MOD_ROOT_DIR, "autorun")
MODULE_SRC_DIR = "src/ItemBoxEditor"
MODULE_SAVE_DIR = "{}/{}/{}/{}".format(WORK_TEMP_DIR, MOD_ROOT_DIR, "autorun", MOD_NAME)
VERSION_JSON_SAVE_PATH = "version.json"
ZIP_FILE_PREFIX = "ItemBoxEditor"
# fmm settings
COVER_FILE_NAME = "cover.png"
INI_FILE_NAME = "modinfo.ini"


def read_origin_lua() -> tuple[str, str]:
    with open(ORIGIN_LUA_FIEL, "r", encoding="utf-8") as f:
        lua_str = f.read()
    # match local modVersion = "1.0.1.0" row and read the content in the double quotes
    mod_ver_match = re.search(r"local modVersion\s*=\s*['\"]([^'\"]+)['\"]", lua_str)
    mod_ver = mod_ver_match.group(1) if mod_ver_match else "Unknown"
    return lua_str, mod_ver


def create_release_lua() -> tuple[str, str]:
    lua_str, mod_ver = read_origin_lua()
    # save lua file
    save_path = os.path.join(LUA_SAVE_DIR, f"ItemBoxEditor.lua")
    with open(save_path, "w", encoding="utf-8") as f:
        f.write(lua_str)
    return lua_str, mod_ver


def create_fmm_config(
    version: str,
    fmm_config: dict,
    save_dir: str,
) -> None:
    # cp cover.png to save_dir
    shutil.copyfile(fmm_config["screenshot"], os.path.join(save_dir, COVER_FILE_NAME))
    # create modinfo.ini
    with open(os.path.join(save_dir, INI_FILE_NAME), "w", encoding="utf-8") as f:
        for key, value in fmm_config.items():
            if key == "screenshot":
                f.write(f"{key}={COVER_FILE_NAME}\n")
            else:
                f.write(f"{key}={value}\n")
        f.write(f"version={version}\n")


def create_dir(path: str) -> None:
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)


def init_dir() -> None:
    if os.path.exists(WORK_TEMP_DIR):
        shutil.rmtree(WORK_TEMP_DIR)

    create_dir(os.path.join(WORK_TEMP_DIR, MOD_ROOT_DIR))
    create_dir(LUA_SAVE_DIR)
    create_dir(MODULE_SAVE_DIR)


def copy_module_lua() -> None:
    if not os.path.exists(MODULE_SRC_DIR):
        return
    create_dir(MODULE_SAVE_DIR)
    # copy all files and subdirs in MODULE_SRC_DIR to MODULE_SAVE_DIR
    for item in os.listdir(MODULE_SRC_DIR):
        src_item_path = os.path.join(MODULE_SRC_DIR, item)
        dst_item_path = os.path.join(MODULE_SAVE_DIR, item)
        if os.path.isdir(src_item_path):
            shutil.copytree(src_item_path, dst_item_path)
        else:
            shutil.copy2(src_item_path, dst_item_path)


def force_del_dir(
    path: str,
    debug_mode: bool = False,
) -> None:
    if os.path.exists(path) and not debug_mode:
        shutil.rmtree(path)


def create_zip(
    mod_version: str,
    file_name_prefix: str,
) -> None:
    shutil.make_archive(
        "{}_{}".format(file_name_prefix, mod_version),
        "zip",
        root_dir=WORK_TEMP_DIR,
        base_dir=".",
    )


if __name__ == "__main__":
    args = argparse.ArgumentParser()
    args.add_argument(
        "-d",
        "--debug",
        action="store_true",
        help="Debug mode (Keep reframework dir)",
        default=False,
    )
    args.add_argument(
        "-v",
        "--create_version_json",
        action="store_true",
        help="Create version.json",
        default=False,
    )
    args = args.parse_args()
    enable_debug = args.debug

    mod_version = "Unknown"
    json_file = {}
    init_dir()
    _, mod_version = create_release_lua()
    copy_module_lua()
    create_fmm_config(mod_version, FMM_CONFIG, WORK_TEMP_DIR)
    # create zip
    create_zip(mod_version, ZIP_FILE_PREFIX)
    # del dir
    force_del_dir(WORK_TEMP_DIR, enable_debug)
    if not enable_debug and args.create_version_json:
        # save version.json
        version_json = {
            "version": mod_version,
            # set UTC +8 timezone date
            "build_date": "{} (UTC+8)".format(
                (datetime.now(timezone.utc) + timedelta(hours=8)).strftime(
                    "%Y-%m-%d %H:%M:%S"
                )
            ),
        }
        with open(VERSION_JSON_SAVE_PATH, "w", encoding="utf-8") as f:
            json.dump(version_json, f, ensure_ascii=False, indent=4)
        print("Done!")
