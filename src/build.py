import argparse
import json
import os
import re
import shutil
from datetime import datetime, timedelta, timezone

import pandas as pd

CONTRIBUTORS = [
    "Egg Targaryen",
    "TinyStick",
    "RabbitFeet",
    "Blank-1973",
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
        "item_lang": "SimplifiedChinese",
        "save_txt_header": ["[物品ID]", "[物品名]"],
    },
    {
        "tag": "zh-Hant",
        "item_lang": "TraditionalChinese",
        "save_txt_header": ["[物品ID]", "[物品名]"],
    },
    {
        "tag": "en-US",
        "item_lang": "English",
        "save_txt_header": ["[Item ID]", "[Item Name]"],
    },
    {
        "tag": "ja-JP",
        "item_lang": "Japanese",
        "save_txt_header": ["[アイテムID]", "[アイテム名]"],
    },
    {
        "tag": "ko-KR",
        "item_lang": "Korean",
        "save_txt_header": ["[아이템ID]", "[아이템명]"],
    },
]

REF_UNSUPPORTED_FONT_REPLACE = {
    "Ⅰ": "1",
    "Ⅱ": "2",
    "Ⅲ": "3",
    "α": "A",
    "β": "B",
    "γ": "Y",
}

# source file settings
ORIGIN_LUA_FIEL = "src/ItemBoxEditor.lua"
I18N_FILE_DIR = "src/i18n"
ITEM_DATA_JSON = "src/data/ItemData.json"
TEXT_DATA_CSV = "src/data/Item.msg.23.csv"
# action settings
WORK_TEMP_DIR = ".temp"
# save settings
MOD_ROOT_DIR = "reframework"
MOD_NAME = "ItemBoxEditor"
LUA_SAVE_DIR = "{}/{}/{}".format(WORK_TEMP_DIR, MOD_ROOT_DIR, "autorun")
JSON_SAVE_DIR = "{}/{}/{}/{}".format(WORK_TEMP_DIR, MOD_ROOT_DIR, "data", MOD_NAME)
ITEM_ID_TXT_SAVE_PATH = "{}/{}/{}".format(
    WORK_TEMP_DIR, MOD_ROOT_DIR, "ItemEditor_ItemIDs.txt"
)
JSON_FILE_NAME_PREFIX = "ItemBoxEditor"
USER_CONFIG_JSON_FILE_NAME = "UserConfig.json"
VERSION_JSON_SAVE_PATH = "version.json"
ZIP_FILE_PREFIX = "ItemBoxEditor"
# fmm settings
COVER_FILE_NAME = "cover.png"
INI_FILE_NAME = "modinfo.ini"


def get_item_df(
    item_lang: str,
) -> pd.DataFrame:
    # read ITEM_DATA_JSON
    with open(ITEM_DATA_JSON, "r", encoding="utf-8") as f:
        item_data_json = json.load(f)
    item_data = []
    # _ItemId Item Id
    # _RawName Item Name
    # _SortId Sort Index
    # _Type Item Type : 0 消耗品、调和用品; 1
    item_header = [
        "_ItemId",
        "_RawName",
        "_SortId",
        "_Type",
        "_Rare",
        "_Fix",
        "_Shikyu",
        "_Infinit",
        "_Heal",
        "_Battle",
        "_Special",
        "_ForMoney",
        "_OutBox",
    ]
    for item in item_data_json[0]["fields"][0]["value"]:
        item_info = item["fields"]
        _item_id = None
        _raw_name = None
        _item_data = []
        for _field in item_info:
            if _field["name"] in item_header:
                _item_data.append(_field["value"])
        item_data.append(_item_data)
    item_df = pd.DataFrame(item_data, columns=item_header)
    # read TEXT_DATA_CSV
    text_data = pd.read_csv(
        TEXT_DATA_CSV,
        header=0,
        encoding="utf-8",
        usecols=["guid", "entry name", item_lang],
    )
    # replace the char in item_lang column with REF_UNSUPPORTED_FONT_REPLACE
    text_data[item_lang] = text_data[item_lang].apply(
        lambda x: "".join(REF_UNSUPPORTED_FONT_REPLACE.get(char, char) for char in x)
    )
    # remove 'entry name' contains 'EXP' keyword
    text_data = text_data[~text_data["entry name"].str.contains("EXP")]
    # merge text_data to item_df
    item_df = item_df.merge(text_data, left_on="_RawName", right_on="guid", how="left")
    print(item_df)
    return item_df


def get_lua_i18n_json(
    tag: str,
) -> dict:
    with open(os.path.join(I18N_FILE_DIR, f"{tag}.json"), "r", encoding="utf-8") as f:
        i18n_json = json.load(f)
    return i18n_json


def read_origin_lua() -> (str, str, str):
    with open(ORIGIN_LUA_FIEL, "r", encoding="utf-8") as f:
        lua_str = f.read()
    # match local INTER_VERSION = "xxx" row and read the content in the double quotes
    mod_ver_match = re.search(r"local INTER_VERSION\s*=\s*['\"]([^'\"]+)['\"]", lua_str)
    mod_ver = mod_ver_match.group(1) if mod_ver_match else "Unknown"
    # match local MAX_VERSION = "1.0.1.0" row and read the content in the double quotes
    max_ver_match = re.search(r"local MAX_VERSION\s*=\s*['\"]([^'\"]+)['\"]", lua_str)
    max_ver = max_ver_match.group(1) if max_ver_match else "Unknown"
    return lua_str, mod_ver, max_ver


def create_release_lua() -> (str, str, str):
    lua_str, mod_ver, max_support_ver = read_origin_lua()
    # match 'local ITEM_NAME_JSON_PATH = ""' row and replace the content in the double quotes
    lua_str = lua_str.replace(
        'local ITEM_NAME_JSON_PATH = ""',
        f'local ITEM_NAME_JSON_PATH = "{MOD_NAME}/{JSON_FILE_NAME_PREFIX}.json"',
    )
    # math 'local USER_CONFIG_PATH = ""' row and replace the content in the double quotes
    lua_str = lua_str.replace(
        'local USER_CONFIG_PATH = ""',
        f'local USER_CONFIG_PATH = "{MOD_NAME}/{USER_CONFIG_JSON_FILE_NAME}"',
    )
    # save lua file
    save_path = os.path.join(LUA_SAVE_DIR, f"ItemBoxEditor.lua")
    with open(save_path, "w", encoding="utf-8") as f:
        f.write(lua_str)
    return lua_str, mod_ver, max_support_ver


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
    create_dir(JSON_SAVE_DIR)


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
    max_support_version = "Unknown"
    json_file = {}
    init_dir()
    _, mod_version, max_support_version = create_release_lua()
    item_list_txt = {}
    for lang in LANG_LIST:
        _item_list = []
        item_df = get_item_df(lang["item_lang"])
        item_dict = (
            item_df.rename(columns={lang["item_lang"]: "_Name", "_ItemId": "fixedId"})
            .drop(columns=["_RawName", "guid", "entry name"])
            .to_dict(orient="records")
        )
        json_file[lang["tag"]] = {
            "I18N": get_lua_i18n_json(lang["tag"]),
            "ItemName": item_dict,
        }
        for item in item_dict:
            # add item to item_list_txt
            _item_list.append("{}\t{}\n".format(item["fixedId"], item["_Name"]))
        item_list_txt[lang["tag"]] = _item_list
    with open(
        os.path.join(JSON_SAVE_DIR, f"{JSON_FILE_NAME_PREFIX}.json"),
        "w",
        encoding="utf-8",
    ) as f:
        json.dump(json_file, f, ensure_ascii=False, indent=4)
    create_fmm_config(mod_version, FMM_CONFIG, WORK_TEMP_DIR)
    with open(
        ITEM_ID_TXT_SAVE_PATH,
        "w",
        encoding="utf-8",
    ) as f:
        f.write(f"# Item IDs for Item Box Editor\n")
        f.write(f"# Version: {mod_version}\n\n")
        for lang in LANG_LIST:
            f.write(f"# Language: {lang['tag']}\n")
            f.write("".join(item_list_txt[lang["tag"]]))
            f.write("\n")
    # create zip
    create_zip(mod_version, ZIP_FILE_PREFIX)
    # del dir
    force_del_dir(WORK_TEMP_DIR, enable_debug)
    if not enable_debug and args.create_version_json:
        # save version.json
        version_json = {
            "version": mod_version,
            "max": max_support_version,
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
