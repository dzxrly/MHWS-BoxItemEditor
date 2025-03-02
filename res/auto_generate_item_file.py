import json
import os.path

import pandas as pd

CHN_XLSX = {
    'SAVE_PATH': 'reframework/Items_ZH-Hans.txt',
    'JSON_PATH': 'res/ItemBoxEditor_item_dict_ZH-Hans.json',
    'SAVE_TXT_HEADER': ['[物品ID]', '[物品名]'],
}

ENG_CSV = {
    'SAVE_PATH': 'reframework/Items_EN-US.txt',
    'JSON_PATH': 'res/ItemBoxEditor_item_dict_EN-US.json',
    'SAVE_TXT_HEADER': ['[Item ID]', '[Item Name]'],
}

ITEM_DATA_JSON = os.path.join('res/ItemData.json')
TEXT_DATA_CSV = os.path.join('res/Item.msg.23.csv')
DATA_VER = 'V.1.0.1.0'

if __name__ == '__main__':
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
    print(item_df)

    # read TEXT_DATA_CSV
    text_data = pd.read_csv(TEXT_DATA_CSV, header=0, encoding='utf-8',
                            usecols=['guid', 'entry name', 'English', 'SimplifiedChinese'])
    # remove 'entry name' contains 'EXP' keyword
    text_data = text_data[~text_data['entry name'].str.contains('EXP')]
    print(text_data)

    # merge text_data to item_df
    item_df = item_df.merge(text_data, left_on='_RawName', right_on='guid', how='left')
    print(item_df)

    # save to txt
    item_df_EN_US = item_df[['_ItemId', 'English']]
    item_df_EN_US.to_csv(ENG_CSV['SAVE_PATH'], sep='\t', header=ENG_CSV['SAVE_TXT_HEADER'], index=False,
                         encoding='utf-8')
    item_df_CHN = item_df[['_ItemId', 'SimplifiedChinese']]
    item_df_CHN.to_csv(CHN_XLSX['SAVE_PATH'], sep='\t', header=CHN_XLSX['SAVE_TXT_HEADER'], index=False,
                       encoding='utf-8')

    # write data version to file at the top
    with open(ENG_CSV['SAVE_PATH'], 'r', encoding='utf-8') as f:
        data = f.read()
    with open(ENG_CSV['SAVE_PATH'], 'w', encoding='utf-8') as f:
        f.write(f'Data Version: {DATA_VER}\n\n')
        f.write(data)

    with open(CHN_XLSX['SAVE_PATH'], 'r', encoding='utf-8') as f:
        data = f.read()
    with open(CHN_XLSX['SAVE_PATH'], 'w', encoding='utf-8') as f:
        f.write(f'数据版本: {DATA_VER}\n\n')
        f.write(data)

    # write as json, like {item_id: item_name}
    item_dict = dict(zip(item_df['_ItemId'], item_df['English']))
    with open(ENG_CSV['JSON_PATH'], 'w', encoding='utf-8') as f:
        json.dump(item_dict, f, ensure_ascii=False, indent=4)
    item_dict = dict(zip(item_df['_ItemId'], item_df['SimplifiedChinese']))
    with open(CHN_XLSX['JSON_PATH'], 'w', encoding='utf-8') as f:
        json.dump(item_dict, f, ensure_ascii=False, indent=4)
    print('Done!')
