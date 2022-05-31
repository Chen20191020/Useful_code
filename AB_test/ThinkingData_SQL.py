# coding=utf8
import requests
import re
import pandas as pd
from io import StringIO
import json


def get_data(sql, format='csv_header '):
    """
    根据输入的SQL语句，返回数数科技查询结果
    :param sql: SQL语句
    :param format: 默认为'csv-header', 可选择的还有json
    :return: 返回DataFrame
    """
    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
    }

    data = {
        'sql': sql,
        'format': format
    }
    url = 'http://101.32.192.62:8992/querySql?token=bjMIEMvVgCYH3ngtjTw1hngzuKpdqSkI1GoO1A0NkJQdubjrmHmYBGCH8HRE20tU'
    r = requests.post(url, headers=headers, data=data)
    data = StringIO(r.text)  # 将返回数据转化为StringIO对象

    json_head = json.loads(data.readline())  # 获取头数据，并转化为字典
    column_name = json_head['data']['headers']
    column_name = [re.findall('\w.*', k)[0] for k in column_name]  # 去除字段名中的不规范字符

    # 提取行数据，并对格式进行转化
    result = [json.loads(line) for line in data.readlines()]

    # 生成DataFrame
    df = pd.DataFrame(result, columns=column_name).convert_dtypes()

    return df

# table name: ta.v_event_6

if __name__ == '__main__':
    sql = """
    SELECT "$part_event","$part_date","#user_id","#event_name","#event_time","#account_id","#distinct_id","#server_time","channel","platform","#zone_offset","#city","#ip","carid","#lib","totalgamelength","install_time","#province","ailevel","deviceid","version","level","media_source","#country_code","revenue_in_selected_currency","event_time","cost_in_selected_currency","#country","#lib_version","country_code","app_version","campaign","totallogintimes","aiprogress","turntablerwad_times","levelgamelength","averagelevelfps","victoryfinishtype","playerprogress","carlevel","state","carjumptimers","finalrewardamount","systemarchitecture","totalgametimesum","totaltimes","failfinishtype","rwtype","loadtime","aggregatelevelfinishtimes","required_enginelevel","gaslevel","required_gaslevel","bonuslevel","enginelevel","finalreward_diamond","aggregatediamondamount","finalreward_coin","aggregatecoinamount","partsid","tyreid","racetype","computeshadersupport" FROM ta.v_event_6 WHERE "$part_date" = '2021-04-06' 
    """
    get_data(sql)