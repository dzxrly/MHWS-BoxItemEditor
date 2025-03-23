from datetime import datetime, timezone, timedelta

import requests
import yaml

NEXUSMODS_GAME_4095_CSV = 'https://staticstats.nexusmods.com/live_download_counts/mods/6993.csv'
MOD_INDEX = 102


def get_content_by_requests(
        url: str,
        headers=None,
        decode=True,
):
    if headers is None:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36 Edg/127.0.0.0',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
            'Accept-Encoding': 'gzip, deflate, br, zstd',
            'Accept-Language': 'zh-TW,zh-CN;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6',
            'Cache-Control': 'no-cache',
            'Dnt': '1',
            'Sec-Ch-Ua': '"Not)A;Brand";v="99", "Microsoft Edge";v="127", "Chromium";v="127"',
            'Sec-Fetch-Platform': 'Windows',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Sec-Fetch-User': '?1',
            'Upgrade-Insecure-Requests': '1',
            'Pragma': 'no-cache',
            'priority': 'u=0, i',
        }
    try:
        # send request
        response = requests.get(url, headers=headers)
        # get response content
        content = response.content.decode(response.encoding) if decode else response.content
    except Exception as e:
        return ''
    return content


def number_formatter(
        number: int,
) -> str:
    """
    format number int to str,
    if number >= 1000, add K to the end of number,
    elif number >= 1000000, add M to the end of number,
    elif number >= 1000000000, add B to the end of number,
    else return number as str (keep 1 decimal place)
    :param number:
    :return:
    """
    if number >= 1000000000:
        return '{:.1f}B'.format(number / 1000000000)
    elif number >= 1000000:
        return '{:.1f}M'.format(number / 1000000)
    elif number >= 1000:
        return '{:.1f}K'.format(number / 1000)
    else:
        return str(number)


if __name__ == '__main__':
    try:
        response = get_content_by_requests(
            NEXUSMODS_GAME_4095_CSV,
            decode=True,
        )
        total_download_count = -1
        unique_download_count = -1
        views_count = -1
        for row in response.split('\n'):
            mod_id, total_download_count, unique_download_count, views_count = row.strip().split(',')
            if int(mod_id) == MOD_INDEX:
                break
        with open('mod_info.yaml', 'w', encoding='utf-8') as f:
            yaml.safe_dump({
                'total_download_count': number_formatter(int(total_download_count)),
                'unique_download_count': number_formatter(int(unique_download_count)),
                'views_count': number_formatter(int(views_count)),
                'id': int(MOD_INDEX),
                'update_time': datetime.utcnow().astimezone(
                    timezone(timedelta(hours=8))
                ).strftime('%Y-%m-%d %H:%M:%S')
            }, f, allow_unicode=True)
            f.close()
    except Exception as e:
        print(e)
