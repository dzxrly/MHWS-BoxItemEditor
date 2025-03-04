import json
import os.path
import re

import pandas as pd

LANG_LIST = [
    {
        'tag': 'ZH-Hans',
        'item_i18n_tag': 'SimplifiedChinese',
        'save_txt_header': ['[物品ID]', '[物品名]'],
    },
    {
        'tag': 'EN-US',
        'item_i18n_tag': 'English',
        'save_txt_header': ['[Item ID]', '[Item Name]'],
    }
]

ORIGIN_LUA_FIEL = 'res/ItemBoxEditor.lua'
LUA_SAVE_DIR = 'reframework/autorun'
TXT_SAVE_DIR = 'reframework'
TXT_SAVE_PREFIX = 'Items_'
JSON_SAVE_DIR = 'reframework/data'
JSON_FILE_NAME_PREFIX = 'ItemBoxEditor_item_dict_'
I18N_FILE_DIR = 'res/i18n'
ITEM_DATA_JSON = 'res/ItemData.json'
TEXT_DATA_CSV = 'res/Item.msg.23.csv'
VERSION_JSON_SAVE_PATH = 'version.json'


def get_item_df(
        lang_tag: str,
) -> pd.DataFrame:
    # read ITEM_DATA_JSON
    with open(ITEM_DATA_JSON, 'r', encoding='utf-8') as f:
        item_data_json = json.load(f)
    item_data = []
    item_header = ['_ItemId', '_RawName']
    for item in item_data_json[0]['fields'][0]['value']:
        item_info = item['fields']
        _item_id = None
        _raw_name = None
        for _field in item_info:
            if _field['name'] == '_ItemId':
                _item_id = _field['value']
            if _field['name'] == '_RawName':
                _raw_name = _field['value']
        item_data.append([_item_id, _raw_name])
    # to DataFrame
    item_df = pd.DataFrame(item_data, columns=item_header)
    # read TEXT_DATA_CSV
    text_data = pd.read_csv(TEXT_DATA_CSV, header=0, encoding='utf-8',
                            usecols=['guid', 'entry name', lang_tag])
    # remove 'entry name' contains 'EXP' keyword
    text_data = text_data[~text_data['entry name'].str.contains('EXP')]
    # merge text_data to item_df
    item_df = item_df.merge(text_data, left_on='_RawName', right_on='guid', how='left')
    print(item_df)
    return item_df


def get_lua_i18n_json(
        tag: str,
) -> dict:
    with open(os.path.join(I18N_FILE_DIR, f'{tag}.json'), 'r', encoding='utf-8') as f:
        i18n_json = json.load(f)
    return i18n_json


def read_origin_lua() -> (str, str, str):
    with open(ORIGIN_LUA_FIEL, 'r', encoding='utf-8') as f:
        lua_str = f.read()
    # match local INTER_VERSION = "xxx" row and read the content in the double quotes
    mod_ver_match = re.search(r"local INTER_VERSION\s*=\s*['\"]([^'\"]+)['\"]", lua_str)
    mod_ver = mod_ver_match.group(1) if mod_ver_match else 'Unknown'
    # match local MAX_VERSION = "1.0.1.0" row and read the content in the double quotes
    max_ver_match = re.search(r"local MAX_VERSION\s*=\s*['\"]([^'\"]+)['\"]", lua_str)
    max_ver = max_ver_match.group(1) if max_ver_match else 'Unknown'
    return lua_str, mod_ver, max_ver


def save_txt(
        tag: str,
        lang_tag: str,
        item_df: pd.DataFrame,
        header: list[str],
        data_ver: str = 'Unknown',
) -> None:
    save_path = os.path.join(TXT_SAVE_DIR, f'{TXT_SAVE_PREFIX}{tag}.txt')
    item_df = item_df[['_ItemId', lang_tag]]
    item_df.to_csv(save_path, sep='\t', header=header, index=False, encoding='utf-8')
    # write data version to file at the top
    with open(save_path, 'r', encoding='utf-8') as f:
        data = f.read()
    with open(save_path, 'w', encoding='utf-8') as f:
        f.write(f'Data Version: {data_ver}\n\n')
        f.write(data)


def save_json(
        tag: str,
        lang_tag: str,
        item_df: pd.DataFrame,
        lua_i18n_json: dict,
) -> None:
    item_dict = dict(zip(item_df['_ItemId'], item_df[lang_tag]))
    final_json = {
        'I18N': lua_i18n_json,
        'ItemName': item_dict,
    }
    save_path = os.path.join(JSON_SAVE_DIR, f'{JSON_FILE_NAME_PREFIX}{tag}.json')
    with open(save_path, 'w', encoding='utf-8') as f:
        json.dump(final_json, f, ensure_ascii=False, indent=4)


def create_lua_by_i18n(
        tag: str,
) -> (str, str, str):
    lua_str, mod_ver, max_support_ver = read_origin_lua()
    # match 'local ITEM_NAME_JSON_PATH = ""' row and replace the content in the double quotes
    lua_str = lua_str.replace('local ITEM_NAME_JSON_PATH = ""',
                              f'local ITEM_NAME_JSON_PATH = "{JSON_FILE_NAME_PREFIX}{tag}.json"')
    # match 'local LANG = ""' row and replace the content in the double quotes
    lua_str = lua_str.replace('local LANG = ""', f'local LANG = "{tag}"')
    # save lua file
    save_path = os.path.join(LUA_SAVE_DIR, f'ItemBoxEditor_{tag}.lua')
    with open(save_path, 'w', encoding='utf-8') as f:
        f.write(lua_str)
    return lua_str, mod_ver, max_support_ver


if __name__ == '__main__':
    mod_version = 'Unknown'
    max_support_version = 'Unknown'
    for lang in LANG_LIST:
        item_df = get_item_df(lang['item_i18n_tag'])
        lua_i18n_json = get_lua_i18n_json(lang['tag'])
        _, mod_version, max_support_version = create_lua_by_i18n(lang['tag'])
        save_txt(lang['tag'], lang['item_i18n_tag'], item_df, lang['save_txt_header'], max_support_version)
        save_json(lang['tag'], lang['item_i18n_tag'], item_df, lua_i18n_json)
    # save version.json
    version_json = {
        'version': mod_version,
        'max': max_support_version,
    }
    with open(VERSION_JSON_SAVE_PATH, 'w', encoding='utf-8') as f:
        json.dump(version_json, f, ensure_ascii=False, indent=4)
    print('Done!')
