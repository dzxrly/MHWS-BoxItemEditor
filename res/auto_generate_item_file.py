#  CHN Ver xlsx from @Eigeen本征
#  ENG Ver csv from https://docs.google.com/spreadsheets/d/178o8U97P2cpb0RZbZBvGIoX4bPhUm_lPczg6elfIj9s/edit?gid=1542902078#gid=1542902078
import os.path

import pandas as pd

CHN_XLSX = {
    'FILE_PATH': 'res/1.0.xlsx',
    'SHEET_NAME': 'ItemData',
    'ENUM_ID_COL': 'ItemId',
    'FIXED_ID_INDEX_COL': 'Index',
    'NAME_COL': 'RawName',
    'SAVE_PATH': 'reframework/Items_ZH-Hans.txt',
    'SAVE_TXT_HEADER': ['物品ID', '物品名'],
    'THX': '特别感谢 @Eigeen本征 提供的中文版本表格',
}

ENG_CSV = {
    'FILE_PATH': 'res/MonsterHunterWilds-Items.csv',
    'HEADER': 0,
    'ENUM_ID_COL': 'Enum ID',
    'NAME_COL': 'Name',
    'SAVE_PATH': 'reframework/Items_EN-US.txt',
    'SAVE_TXT_HEADER': ['Item ID', 'Item Name'],
    'THX': 'Special thanks to https://docs.google.com/spreadsheets/d/178o8U97P2cpb0RZbZBvGIoX4bPhUm_lPczg6elfIj9s/edit?gid=1542902078#gid=1542902078',
}

if __name__ == '__main__':
    chn_xlsx_df = pd.read_excel(os.path.join(CHN_XLSX['FILE_PATH']), sheet_name=CHN_XLSX['SHEET_NAME'])
    eng_csv_df = pd.read_csv(os.path.join(ENG_CSV['FILE_PATH']), header=ENG_CSV['HEADER'])

    print(chn_xlsx_df)
    print(eng_csv_df)

    # merge by 'Enum ID'
    merge_df = pd.merge(chn_xlsx_df, eng_csv_df, left_on=CHN_XLSX['ENUM_ID_COL'], right_on=ENG_CSV['ENUM_ID_COL'],
                        how='inner')
    chn_df = merge_df[[CHN_XLSX['FIXED_ID_INDEX_COL'], CHN_XLSX['NAME_COL']]]
    eng_df = merge_df[[CHN_XLSX['FIXED_ID_INDEX_COL'], ENG_CSV['NAME_COL']]]
    # save
    chn_df.to_csv(CHN_XLSX['SAVE_PATH'], sep='\t', index=False, header=CHN_XLSX['SAVE_TXT_HEADER'])
    eng_df.to_csv(ENG_CSV['SAVE_PATH'], sep='\t', index=False, header=ENG_CSV['SAVE_TXT_HEADER'])
    # add thx at the top of the file
    with open(CHN_XLSX['SAVE_PATH'], 'r', encoding='utf-8') as f:
        content = f.read()
    with open(CHN_XLSX['SAVE_PATH'], 'w', encoding='utf-8') as f:
        f.write(CHN_XLSX['THX'] + '\n\n' + content)
    with open(ENG_CSV['SAVE_PATH'], 'r', encoding='utf-8') as f:
        content = f.read()
    with open(ENG_CSV['SAVE_PATH'], 'w', encoding='utf-8') as f:
        f.write(ENG_CSV['THX'] + '\n\n' + content)
