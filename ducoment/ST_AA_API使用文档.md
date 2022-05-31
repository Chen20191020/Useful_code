[TOC]

# API使用文档

## 1. Sensor Tower

### 1.1 官方API文档

*由于 Sensor Tower 已暂停使用，该链接内的官方API文档并不完全*

链接：

### 1.2 数据库表信息

#### 1.2.1 st_app_info

st_app_info表： 储存Sensor Tower网站上的游戏app及其基本信息，唯一索引是product_id，本表所有录入游戏均曾进入过单平台(iOS或Android)周下载量排行前1000。

![image-20210330092442087](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330092442087.png)



#### 1.2.2 st_app_rank_daily, st_app_rank_weekly, st_app_rank_monthly

st_app_rank_daily表：储存每日下载量排行前1000的游戏，date字段精确到day级别，字段date, product_id, country 组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一日为base。  

![image-20210330092547933](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330092547933.png)



st_app_rank_weekly表：储存每周下载量排行前1000的游戏，date字段精确到week级别，字段date, product_id, country 组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一周为base。 为周报方便，country字段预设值为‘US’。

![image-20210330093005827](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330093005827.png)



st_app_rank_monthly表：储存每月下载量排行前1000的游戏，date字段精确到month级别，字段date, product_id, country 组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一月为base。  

![image-20210330092815333](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330092815333.png)



#### 1.2.3 st_publisher_info

st_publisher_info表： 储存Sensor Tower网站上的游戏公司，厂商和发行商及其基本信息，唯一索引是publisher_id，本表所有录入厂商存在其发行游戏曾进入过单平台(iOS或Android)周下载量排行前1000。

![image-20210330093207386](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330093207386.png)



#### 1.2.4 st_publihser_rank_daily,  st_publihser_rank_weekly,  st_publihser_rank_monthly

st_publisher_rank_daily表：储存每日下载量排行前1000的厂商，date字段精确到day级别，字段date, publisher_id组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一日为base。

![image-20210330095736896](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330095736896.png)

st_publisher_rank_weekly表：储存每周下载量排行前1000的厂商，date字段精确到week级别，字段date, publisher_id组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一周为base。

![image-20210330095941170](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330095941170.png)



st_publisher_rank_monthly表：储存每月下载量排行前1000的厂商，date字段精确到month级别，字段date, publisher_id组成唯一复合索引，change_value, change_percent, revenue_change_value, revenue_change_percent 字段均以前一月为base。

![image-20210330095832648](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330095832648.png)



### 1.3 API数据获取及更新

#### 1.3.1 数据获取所需权限

需要Sensor Tower 专业版账号。

#### 1.3.2 数据获取及更新

Daily精度数据每日选取当日，前一日，前两日三天数据在10：00，13：00，15：00拉取三次并录入进数据库，weekly精度数据每周四10：00使用API调用函数获取并录入进数据库。

### 1.4 API调用函数说明

1. 通过Sensor Tower平台账号进入API使用模块。

   *因Sensor Tower账户暂时停用，目前无法演示该模块*

   

2. 获取永久Sensor Tower平台的账号token，并将此Token赋值给**auth_token**。此token在不退出账号和不重新刷新token的情况下可以永久使用。 

   ```python
   auth_token = 'r7cTTJq5nBSqxMU_WmJo'
   ```



3. 使用python根据不同需求撰写API调用函数，需提前在python中引入 **requests** 和 **pandas** 包。 

   ```python
   import requests
   import pandas as pd
   ```

   

#### 1.4.1 应用排行榜及下载量

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com:443/v1/{Platform}/sales_report_estimates_comparison_attributes'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android/unified
"""
```

**(4)** **TopApps_periodic** 函数结构：

```python
def TopApps_periodic(Platform, Comparison_attribute, Time_range, Measure, Device_type, Category, Date, Country, Limit):
    """
    :param  Platform: ios/android/unified
    :param  Comparision_attribute: absolute/delta/transformed_delta
    :param  Time_range: day/week/month/quarter
    :param  Measure: units/revenue
    :param  Device_type: iphone/ipad/total for ios, leave None for android, use 'total' for 'unified'
    :param  Category: Checking CountryCodes_CategoryIDs to select category.(use 6014 for game applications)
    :param  Date: yyyy-mm-dd.Auto-changes to the beginning of time_range.Ex: Mondays for weeks, 1st of the month, 1st day of the quarter, 1st day of the year.
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :param  Limit: Limit how many apps per call. (Default: 25, Max: 2000)
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'comparison_attribute': Comparison_attribute,
        'time_range': Time_range,
        'measure': Measure,
        'device_type': Device_type,
        'category': Category,
        'date': Date,
        'country': Country,
        'limit': Limit
    }
    r = requests.get(f'https://api.sensortower-china.com:443/v1/{Platform}/sales_report_estimates_comparison_attributes', params=params)
    
    ## print(r.status_code) # Get response messages
    df_TopApps = pd.DataFrame(r.json())
    
    return df_TopApps
```

**(5)** 返回数据结构实例：

```json
[{'app_id': 1539388451,
  'current_revenue_value': 0,
  'current_units_value': 121785,
  'comparison_revenue_value': 0,
  'comparison_units_value': 104005,
  'country': 'US',
  'date': '2021-03-01T00:00:00Z',
  'absolute': 121785,
  'delta': 17780,
  'transformed_delta': 0.1709533195519446,
  'units_absolute': 121785,
  'units_delta': 17780,
  'units_transformed_delta': 0.1709533195519446,
  'revenue_absolute': 0,
  'revenue_delta': 0,
  'revenue_transformed_delta': 0,
  'custom_tags': {'Is a Game': 'true',
   'Free': 'true',
   'In App Purchases': 'true',
   "Editors' Choice": 'false',
   'Recent App Update': '2021/03',
   'Latest Update Days Ago': '~ 1 week',
   'Changed Price': 'false',
   'Is Unified': 'true',
   'Overall US Rating': '4.6',
   'Global Rating Count': '59635',
   'Current US Rating': '4.6',
   'US Rating Count': '23880',
   'All Time Downloads (WW)': '5002683',
   'All Time Revenue (WW)': '$3110',
   'Last 30 Days Downloads (WW)': '1379578',
   'Last 30 Days Revenue (WW)': '$0',
   'Last 180 Days Downloads (WW)': '5200577',
   'Last 180 Days Revenue (WW)': '$3372',
   'Downloads First 30 Days (WW)': '4676394',
   'Revenue First 30 Days (WW)': '$2617',
   'All Time Publisher Downloads (WW)': '8854731',
   'All Time Publisher Revenue (WW)': '$4437991',
   'Release Days Ago': '~ 1 month',
   'App Release Date': '2021/02',
   'Category': 'Games',
   'Content Rating': '12+',
   'Soft Launched Currently': 'false',
   'Has Video Trailer': 'false',
   'Inactive App': 'false',
   'iOS App File Size': '103MB',
   'ARKit': 'false',
   'iOS Offerwalls: ironSource': 'false',
   'iOS Offerwalls: Tapjoy': 'false',
   'Horror/Fear Themes': 'Infrequent/Mild',
   'Mature/Suggestive Themes': 'Infrequent/Mild',
   'Sexual Content or Nudity': 'Infrequent/Mild',
   'Realistic Violence': 'Infrequent/Mild',
   'Alcohol, Tobacco, or Drug Use or References': 'Infrequent/Mild',
   'Cartoon or Fantasy Violence': 'Infrequent/Mild',
   'Most Popular Country by Downloads': 'US',
   'Most Popular Region by Downloads': 'Europe',
   'RPD (All Time, WW)': '$0',
   'Stock Ticker': 'OTCMKTS: TAPM',
   'Publisher Country': 'US',
   'Game Sub-genre': 'Hypercasual - Racing',
   'Game Genre': 'Hypercasual',
   'Game Category': 'Casual',
   'Game Art Style': 'Hypercasual',
   'Game Camera POV': 'Isometric',
   'Game Setting': 'N/A',
   'Game Theme': 'Hypercasual',
   'Most Popular Country by Revenue': 'US',
   'Most Popular Region by Revenue': 'North America',
   'Storefront Game Subcategory': 'Puzzle',
   'Storefront Game Subcategory (Secondary)': 'Trivia',
   'SDK: AdColony': 'false',
   'SDK: Adjust': 'false',
   'SDK: AdMob': 'true',
   'SDK: Airship': 'false',
   'SDK: Amazon Mobile Ads': 'false',
   'SDK: Amplitude': 'false',
   'SDK: Applovin': 'true',
   'SDK: Appsflyer': 'false',
   'SDK: AWS': 'false',
   'SDK: Braintree': 'false',
   'SDK: Branch': 'false',
   'SDK: Braze': 'false',
   'SDK: Chartboost': 'false',
   'SDK: CleverTap': 'false',
   'SDK: Crashlytics': 'false',
   'SDK: Facebook': 'true',
   'SDK: Facebook Ads': 'true',
   'SDK: Facebook Analytics': 'true',
   'SDK: Facebook Login': 'true',
   'SDK: Firebase': 'true',
   'SDK: Flurry': 'false',
   'SDK: Fyber': 'false',
   'SDK: GameAnalytics': 'true',
   'SDK: Inmobi': 'false',
   'SDK: Intercom': 'false',
   'SDK: ironSource': 'true',
   'SDK: Kochava': 'false',
   'SDK: Mintegral': 'false',
   'SDK: MoPub': 'false',
   'SDK: Optimizely': 'false',
   'SDK: PayPal': 'false',
   'SDK: Plaid': 'false',
   'SDK: PlayFab': 'false',
   'SDK: React Native': 'false',
   'SDK: Shopify': 'false',
   'SDK: Singular': 'false',
   'SDK: Square': 'false',
   'SDK: Stripe': 'false',
   'SDK: Swrve': 'false',
   'SDK: Tenjin': 'false',
   'SDK: Tune': 'false',
   'SDK: Twilio': 'false',
   'SDK: Unity': 'true',
   'SDK: Unity Ads': 'true',
   'SDK: Verizon': 'false',
   'SDK: Visa Checkout': 'false',
   'SDK: Vungle': 'true',
   'SDK: ZenDesk': 'false',
   'target_id (Limited)': '500066924'}}]
```



#### 1.4.2 发行商排行榜及下载量

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/top_and_trending/publishers'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android/unified
"""
```

**(4)** **TopPublishers_periodic** 函数结构：

```python
def TopPublishers_periodic(Platform, Comparison_attribute, Time_range, Measure, Device_type, Category, Date, Country, Limit):  
    """
    :param  Platform: ios/android/unified
    :param  Comparision_attribute: absolute/delta/transformed_delta
    :param  Time_range: day/week/month/quarter
    :param  Measure: units/revenue
    :param  Device_type: iphone/ipad/total for ios, leave None for android, use 'total' for 'unified'
    :param  Category: Checking CountryCodes_CategoryIDs to select category.(use 6014 for game applications)
    :param  Date: yyyy-mm-dd.Auto-changes to the beginning of time_range.Ex: Mondays for weeks, 1st of the month, 1st day of the quarter, 1st day of the year.
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :param  Limit: Limit how many apps per call. (Default: 25, Max: 2000)
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'comparison_attribute': Comparison_attribute,
        'time_range': Time_range,
        'measure': Measure,
        'device_type': Device_type,
        'category': Category,
        'date': Date,
        'country': Country,
        'limit': Limit
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/top_and_trending/publishers', params=params)
    
    ## print(r.status_code) # Get response messages
    df_TopPublishers = pd.DataFrame(r.json())
    
    return df_TopPublishers
```

**(5)** 返回数据结构：

```json
 [{'app_id': 1538758103,
    'canonical_country': 'US',
    'name': 'Lumbercraft',
    'publisher_name': 'Voodoo',
    'publisher_id': 714804730,
    'humanized_name': 'Lumbercraft',
    'icon_url': 'https://is5-ssl.mzstatic.com/image/thumb/Purple124/v4/f7/17/f4/f717f4cf-a7b4-e92a-7f02-783f6349bd9f/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
    'os': 'ios',
    'units_absolute': 40468,
    'units_delta': -7046,
    'units_transformed_delta': -0.148293134655049,
    'revenue_absolute': 63423,
    'revenue_delta': -5405,
    'revenue_transformed_delta': -0.07852908699947696,
    'custom_tags': {'Is a Game': 'true',
     'Free': 'true',
     'In App Purchases': 'true',
     "Editors' Choice": 'false',
     'Recent App Update': '2021/03',
     'Latest Update Days Ago': '~ 1 week',
     'Changed Price': 'false',
     'Is Unified': 'true',
     'Overall US Rating': '4.6',
     'Global Rating Count': '73194',
     'Current US Rating': '4.6',
     'US Rating Count': '29315',
     'All Time Downloads (WW)': '3857827',
     'All Time Revenue (WW)': '$27971',
     'Last 30 Days Downloads (WW)': '2010101',
     'Last 30 Days Revenue (WW)': '$11251',
     'Last 180 Days Downloads (WW)': '3973823',
     'Last 180 Days Revenue (WW)': '$29371',
     'Downloads First 30 Days (WW)': '41182',
     'Revenue First 30 Days (WW)': '$5',
     'All Time Publisher Downloads (WW)': '1708303483',
     'All Time Publisher Revenue (WW)': '$20609600',
     'Release Days Ago': '~ 3 months',
     'App Release Date': '2021/01',
     'Category': 'Games',
     'Content Rating': '12+',
     'Soft Launched Currently': 'false',
     'Has Video Trailer': 'false',
     'Inactive App': 'false',
     'iOS App File Size': '369MB',
     'ARKit': 'false',
     'iOS Offerwalls: ironSource': 'false',
     'iOS Offerwalls: Tapjoy': 'false',
     'Most Popular Country by Downloads': 'US',
     'Most Popular Region by Downloads': 'North America',
     'Publisher Country': 'France',
     'RPD (All Time, WW)': '$0.01',
     'Most Popular Country by Revenue': 'US',
     'Most Popular Region by Revenue': 'North America',
     'Sexual Content or Nudity': 'Infrequent/Mild',
     'Horror/Fear Themes': 'Infrequent/Mild',
     'Realistic Violence': 'Infrequent/Mild',
     'Alcohol, Tobacco, or Drug Use or References': 'Infrequent/Mild',
     'Cartoon or Fantasy Violence': 'Infrequent/Mild',
     'Medical/Treatment Information': 'Infrequent/Mild',
     'Simulated Gambling': 'Infrequent/Mild',
     'Mature/Suggestive Themes': 'Infrequent/Mild',
     'Storefront Game Subcategory': 'Action',
     'Storefront Game Subcategory (Secondary)': 'Strategy',
     'ARPDAU (Last Month, WW)': '$0.00',
     'ARPDAU (Last Month, US)': '$0.00',
     'Game Sub-genre': 'Hypercasual - Action',
     'Game Genre': 'Hypercasual',
     'Game Category': 'Casual',
     'Game Art Style': 'Hypercasual',
     'Game Camera POV': 'Isometric',
     'Game Setting': 'N/A',
     'Game Theme': 'Combat Arena',
     'SDK: AdColony': 'true',
     'SDK: Adjust': 'true',
     'SDK: AdMob': 'true',
     'SDK: Airship': 'false',
     'SDK: Amazon Mobile Ads': 'false',
     'SDK: Amplitude': 'false',
     'SDK: Applovin': 'true',
     'SDK: Appsflyer': 'false',
     'SDK: AWS': 'false',
     'SDK: Braintree': 'false',
     'SDK: Branch': 'false',
     'SDK: Braze': 'false',
     'SDK: Chartboost': 'false',
     'SDK: CleverTap': 'false',
     'SDK: Crashlytics': 'true',
     'SDK: Facebook': 'true',
     'SDK: Facebook Ads': 'true',
     'SDK: Facebook Analytics': 'false',
     'SDK: Facebook Login': 'false',
     'SDK: Firebase': 'true',
     'SDK: Flurry': 'false',
     'SDK: Fyber': 'false',
     'SDK: GameAnalytics': 'true',
     'SDK: Inmobi': 'false',
     'SDK: Intercom': 'false',
     'SDK: ironSource': 'true',
     'SDK: Kochava': 'false',
     'SDK: Mintegral': 'true',
     'SDK: MoPub': 'true',
     'SDK: Optimizely': 'false',
     'SDK: PayPal': 'false',
     'SDK: Plaid': 'false',
     'SDK: PlayFab': 'false',
     'SDK: React Native': 'false',
     'SDK: Shopify': 'false',
     'SDK: Singular': 'false',
     'SDK: Square': 'false',
     'SDK: Stripe': 'false',
     'SDK: Swrve': 'false',
     'SDK: Tenjin': 'false',
     'SDK: Tune': 'false',
     'SDK: Twilio': 'false',
     'SDK: Unity': 'true',
     'SDK: Unity Ads': 'true',
     'SDK: Verizon': 'false',
     'SDK: Visa Checkout': 'false',
     'SDK: Vungle': 'true',
     'SDK: ZenDesk': 'false',
     'target_id (Limited)': '500067338'}}]
```



#### 1.4.3 应用详细信息

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/apps'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android
"""
```

**(4)** **requests_Apps** 函数结构：

```python
def requests_Apps(Platform, App_ids, Country):
    """
    :param  Platform: ios/android
    :param  App_ids: A string / Strings seperated by commas.Product ID for iOS. Package name for Android.
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :return  Json data cotains app infomation
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'app_ids': App_ids,
        'country': Country
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/apps', params=params)
    
    ## df_info_Apps = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    
    return r.json()
```

**(5)** 返回数据结构：

```json
{'apps': [{'app_id': 1538758103,
   'canonical_country': 'US',
   'name': 'Lumbercraft',
   'publisher_name': 'Voodoo',
   'publisher_id': 714804730,
   'humanized_name': 'Lumbercraft',
   'icon_url': 'https://is5-ssl.mzstatic.com/image/thumb/Purple124/v4/f7/17/f4/f717f4cf-a7b4-e92a-7f02-783f6349bd9f/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
   'os': 'ios',
   'url': 'https://apps.apple.com/US/app/id1538758103?l=en',
   'categories': [6014, 7001, 7017],
   'valid_countries': ['US',
    'AU',
    'CA',
    'FR',
    'DE',
    'GB',
    'IT',
    'JP',
    'KR',
    'RU',
    'DZ',
    'AO',
    'AR',
    'AT',
    'AZ',
    'BH',
    'BB',
    'BY',
    'BE',
    'BM',
    'BR',
    'BG',
    'CL',
    'CO',
    'CR',
    'HR',
    'CY',
    'CZ',
    'DK',
    'DO',
    'EC',
    'EG',
    'SV',
    'FI',
    'GH',
    'GR',
    'GT',
    'HK',
    'HU',
    'IN',
    'ID',
    'IE',
    'IL',
    'KZ',
    'KE',
    'KW',
    'LB',
    'LT',
    'LU',
    'MO',
    'MG',
    'MY',
    'MT',
    'MX',
    'NL',
    'NZ',
    'NG',
    'NO',
    'OM',
    'PK',
    'PA',
    'PE',
    'PH',
    'PL',
    'PT',
    'QA',
    'RO',
    'SA',
    'RS',
    'SG',
    'SK',
    'SI',
    'ZA',
    'ES',
    'LK',
    'SE',
    'CH',
    'TW',
    'TH',
    'TN',
    'TR',
    'UA',
    'AE',
    'UY',
    'UZ',
    'VE',
    'VN',
    'BO',
    'KH',
    'EE',
    'LV',
    'NI',
    'PY',
    'GE',
    'IQ',
    'LY',
    'MA',
    'MZ',
    'MM',
    'YE'],
   'app_view_url': '/ios/us/voodoo/app/lumbercraft/1538758103/',
   'publisher_profile_url': '/ios/publisher/voodoo/714804730',
   'release_date': '2020-11-09T08:00:00Z',
   'updated_date': '2021-03-30T00:00:00Z',
   'in_app_purchases': True,
   'rating': 4.61706,
   'price': 0.0,
   'global_rating_count': 73194,
   'rating_count': 29315,
   'rating_count_for_current_version': 29315,
   'rating_for_current_version': 4.61706,
   'version': '1.5.1',
   'apple_watch_enabled': None,
   'imessage_enabled': None,
   'imessage_icon': None,
   'humanized_worldwide_last_month_downloads': {'downloads': 2000000,
    'downloads_rounded': 2,
    'prefix': None,
    'string': '2m',
    'units': 'm'},
   'humanized_worldwide_last_month_revenue': {'prefix': '$',
    'revenue': 10000,
    'revenue_rounded': 10,
    'string': '$10k',
    'units': 'k'},
   'bundle_id': 'com.noorgames.timbercraft',
   'support_url': 'https://www.voodoo.io',
   'website_url': 'https://www.voodoo.io',
   'privacy_policy_url': 'https://www.voodoo.io/privacy',
   'eula_url': None,
   'publisher_email': None,
   'publisher_address': None,
   'publisher_country': 'France',
   'feature_graphic': None,
   'short_description': None,
   'advisories': ['Infrequent/Mild Medical/Treatment Information',
    'Infrequent/Mild Simulated Gambling',
    'Infrequent/Mild Alcohol, Tobacco, or Drug Use or References',
    'Infrequent/Mild Horror/Fear Themes',
    'Infrequent/Mild Realistic Violence',
    'Infrequent/Mild Sexual Content and Nudity',
    'Infrequent/Mild Cartoon or Fantasy Violence',
    'Infrequent/Mild Mature/Suggestive Themes'],
   'content_rating': '12+',
   'unified_app_id': '5fab6de4ec1eca492600e74e',
   'screenshot_urls': ['https://is1-ssl.mzstatic.com/image/thumb/Purple114/v4/68/45/44/684544be-3dde-7315-11d1-891b8069ab5e/86825bbd-7008-418e-91f6-687a54979ccf_4_1242x2688.png/462x1000bb.png',
    'https://is4-ssl.mzstatic.com/image/thumb/Purple124/v4/cb/bc/59/cbbc5903-595a-ffd3-f5de-6d6ecb9b8fda/1987cb03-51a9-4f65-ae1d-1bb59286c2c4_1_1242x2688.png/462x1000bb.png',
    'https://is4-ssl.mzstatic.com/image/thumb/PurpleSource124/v4/c5/3e/fc/c53efc2e-c5b7-35e4-e839-78878f1400c4/e564a34f-c0e1-499a-afe2-72a2c9e5306f_5_1242x2688_new.png/462x1000bb.png',
    'https://is4-ssl.mzstatic.com/image/thumb/Purple114/v4/77/5d/c7/775dc7fa-e913-3721-c7f4-b7d31ba05817/b84ac059-ae36-46f4-9ae6-f212c16fbb37_3_1242x2688.png/462x1000bb.png',
    'https://is5-ssl.mzstatic.com/image/thumb/Purple124/v4/85/c0/03/85c003df-c691-b2dd-3cd6-25635ff10f8c/69fbe08b-d7b8-41a6-8cca-ced31be01b58_6_1242x2688.png/462x1000bb.png',
    'https://is1-ssl.mzstatic.com/image/thumb/Purple114/v4/5f/fe/ee/5ffeeef2-e135-47d1-b57b-194237735fcd/ae3c3fb3-0c27-4572-b87f-da1b87318eb1_2_1242x2688.png/462x1000bb.png'],
   'tablet_screenshot_urls': ['https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/68/3e/28/683e289e-0ce2-6392-79f1-7e3215e9fa17/26619806-07e4-415f-bd31-412ce9ee03b7_4_2048x2732.png/576x768bb.png',
    'https://is2-ssl.mzstatic.com/image/thumb/PurpleSource124/v4/82/4b/d1/824bd17b-f8a7-c3e8-4576-aab7915578c3/8a38b1a3-0ef9-4725-ae9f-f49e74ae80cb_5_2048x2732_new.png/576x768bb.png',
    'https://is3-ssl.mzstatic.com/image/thumb/Purple124/v4/3e/a4/ad/3ea4ada9-377f-258d-34f5-8128ac7f9e57/8d76eee0-47a2-48d5-8a29-3803d837ce9e_1_2048x2732.png/576x768bb.png',
    'https://is1-ssl.mzstatic.com/image/thumb/Purple124/v4/da/b6/05/dab60588-d44c-82f8-d5da-7b43020500cf/353fd31b-40be-4b6e-9986-a891d5473070_6_2048x2732.png/576x768bb.png',
    'https://is1-ssl.mzstatic.com/image/thumb/Purple124/v4/e6/8d/4d/e68d4d03-048f-77b9-858b-fc7e2ac44ae7/5ce1aafd-9921-4387-8f9a-b98a54c0968a_3_2048x2732.png/576x768bb.png'],
   'description': 'Cut the wood.\nBuild your town.\nBuild towers.\nKill the enemies.\nEnjoy!',
   'subtitle': 'Craft Tower &amp; Survive!',
   'promo_text': '',
   'permissions': None}]}
```



#### 1.4.4 发行商详细信息

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/publisher/publisher_apps'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android
"""
```

**(4)** **requests_Publishers** 函数结构：

```python
def requests_Publishers(Platform, Publisher_id, Limit, include_count = 'false'):
    """
    :param  Platform: ios/android
    :param  Publisher_id: A String.
    :param  Limit: Limits number of apps returned per call. Max 100 apps per call.
    :param  include_count: Includes count of publisher apps in response payload. Note: setting this to true changes the output structure of the API response.
    :return  Json data contains publisher information
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'publisher_id': Publisher_id,
        'limit': Limit,
        'include_count': include_count
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/publisher/publisher_apps', params=params)
    
    ## df_info_publisher = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    
    return r.json()
```

**(5)** 返回数据结构：

```json
[{'app_id': 1533397036,
  'canonical_country': 'US',
  'name': 'Shortcut Run',
  'publisher_name': 'Voodoo',
  'publisher_id': 714804730,
  'humanized_name': 'Shortcut Run',
  'icon_url': 'https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/41/df/37/41df3753-32c1-c0c7-3ba7-8f084102ad96/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
  'os': 'ios',
  'id': 1533397036,
  'appId': 1533397036,
  'icon': 'https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/41/df/37/41df3753-32c1-c0c7-3ba7-8f084102ad96/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
  'iconUrl': 'https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/41/df/37/41df3753-32c1-c0c7-3ba7-8f084102ad96/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
  'url': 'https://apps.apple.com/US/app/id1533397036?l=en',
  'categories': [6014, 7003, 7013],
  'valid_countries': ['US',
   'AU',
   'CA',
   'FR',
   'DE',
   'GB',
   'IT',
   'JP',
   'KR',
   'RU',
   'DZ',
   'AO',
   'AR',
   'AT',
   'AZ',
   'BH',
   'BB',
   'BY',
   'BE',
   'BM',
   'BR',
   'BG',
   'CL',
   'CO',
   'CR',
   'HR',
   'CY',
   'CZ',
   'DK',
   'DO',
   'EC',
   'EG',
   'SV',
   'FI',
   'GH',
   'GR',
   'GT',
   'HK',
   'HU',
   'IN',
   'ID',
   'IE',
   'IL',
   'KZ',
   'KE',
   'KW',
   'LB',
   'LT',
   'LU',
   'MO',
   'MG',
   'MY',
   'MT',
   'MX',
   'NL',
   'NZ',
   'NG',
   'NO',
   'OM',
   'PK',
   'PA',
   'PE',
   'PH',
   'PL',
   'PT',
   'QA',
   'RO',
   'SA',
   'RS',
   'SG',
   'SK',
   'SI',
   'ZA',
   'ES',
   'LK',
   'SE',
   'CH',
   'TW',
   'TH',
   'TN',
   'TR',
   'UA',
   'AE',
   'UY',
   'UZ',
   'VE',
   'VN',
   'BO',
   'KH',
   'EE',
   'LV',
   'NI',
   'PY',
   'GE',
   'IQ',
   'LY',
   'MA',
   'MZ',
   'MM',
   'YE'],
  'app_view_url': '/ios/us/voodoo/app/shortcut-run/1533397036/',
  'publisher_profile_url': '/ios/publisher/voodoo/714804730',
  'release_date': '2020-09-26T07:00:00Z',
  'updated_date': '2021-03-15T00:00:00Z',
  'in_app_purchases': True,
  'shows_ads': None,
  'buys_ads': None,
  'rating': 4.57118,
  'price': 0.0,
  'global_rating_count': 546848,
  'rating_count': 195068,
  'rating_count_for_current_version': 195068,
  'rating_for_current_version': 4.57118,
  'version': '1.16',
  'apple_watch_enabled': None,
  'apple_watch_icon': None,
  'imessage_enabled': None,
  'imessage_icon': None,
  'humanized_worldwide_last_month_downloads': {'downloads': 2000000,
   'downloads_rounded': 2,
   'prefix': None,
   'string': '2m',
   'units': 'm'},
  'humanized_worldwide_last_month_revenue': {'prefix': '$',
   'revenue': 8000,
   'revenue_rounded': 8,
   'string': '$8k',
   'units': 'k'},
  'bundle_id': 'com.ohmgames.cheatandrun',
  'support_url': 'https://www.voodoo.io',
  'website_url': 'https://www.voodoo.io',
  'privacy_policy_url': 'https://www.voodoo.io/privacy',
  'eula_url': None,
  'publisher_email': None,
  'publisher_address': None,
  'publisher_country': 'France',
  'feature_graphic': None,
  'short_description': None,
  'advisories': ['Infrequent/Mild Mature/Suggestive Themes',
   'Infrequent/Mild Sexual Content and Nudity',
   'Infrequent/Mild Alcohol, Tobacco, or Drug Use or References',
   'Infrequent/Mild Simulated Gambling',
   'Infrequent/Mild Medical/Treatment Information',
   'Infrequent/Mild Cartoon or Fantasy Violence',
   'Infrequent/Mild Realistic Violence',
   'Infrequent/Mild Horror/Fear Themes'],
  'content_rating': '12+'}]
```



#### 1.4.5 应用/发行商总下载量及收入

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/sales_report_estimates'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android/unified
"""
```

**(4)** **Download_RevenueEstimates** 函数结构：

```python
def Download_RevenueEstimates(Platform, Country, Date_granularity, Start_date, End_date, App_ids = None, Publisher_ids = None):
    """
    :param  Platform: ios/android/unified
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :param  Date_granularity: daily/weekly/monthly/quarterly, defaults to "daily"
    :param  Start_date: yyyy-mm-dd
    :param  End_date: yyyy-mm-dd
    :param  App_ids: A String/Strings seperated by commas
    :param  Publisher_ids: A String/Strings seperated by commas. If used publisher_ids, all applications made by this publisher will return. 
    :return  A dataframe which contains: 
         {
          "sales_report_estimates_key": {
            "ios": {
              "aid": "App ID",
              "cc": "Country Code",
              "d": "Date",
              "iu": "iPhone Downloads",
              "ir": "iPhone Revenue",
              "au": "iPad Downloads",
              "ar": "iPad Revenue"
            },
            "android": {
              "aid": "App ID",
              "c": "Country Code",
              "d": "Date",
              "u": "Android Downloads",
              "r": "Android Revenue"
            },
            "unified": {
              "app_id": "App ID",
              "country": "Country Code",
              "date": "Date",
              "android_units": "Android Downloads",
              "android_revenue": "Android Revenue",
              "ipad_units": "iPad Downloads",
              "ipad_revenue": "iPad Revenue",
              "iphone_units": "iPhone Downloads",
              "iphone_revenue": "iPhone Revenue"
            }
          }
        }
        
    :note  App_ids和Publisher_ids选择其一即可
    
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    if App_ids is None and publisher_ids is None:
        raise ValueError('at least one app ID, or one publisher ID is required.')
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'app_ids': App_ids,
        'publisher_ids': Publisher_ids if App_ids is None else None,
        'countries': Country,
        'date_granularity': Date_granularity,
        'start_date': Start_date,
        'end_date': End_date
    }
        
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/sales_report_estimates', params=params)
    
    df_DRE = pd.DataFrame(r.json())
    ## print(r.status_code)
    
    return df_DRE
```

**(5)** 返回数据结构：

```json
### ios
[{'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-01T00:00:00Z',
  'au': 2127,
  'ar': 346,
  'iu': 9999,
  'ir': 5910},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-02T00:00:00Z',
  'au': 2289,
  'ar': 601,
  'iu': 11815,
  'ir': 5359},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-03T00:00:00Z',
  'au': 2511,
  'ar': 928,
  'iu': 11642,
  'ir': 4813},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-04T00:00:00Z',
  'au': 2958,
  'ar': 1476,
  'iu': 12132,
  'ir': 5970},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-05T00:00:00Z',
  'au': 2395,
  'ar': 1052,
  'iu': 9027,
  'ir': 4671},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-06T00:00:00Z',
  'au': 3414,
  'ar': 1373,
  'iu': 13717,
  'ir': 4396},
 {'aid': 1533397036,
  'cc': 'US',
  'd': '2021-03-07T00:00:00Z',
  'au': 3213,
  'ar': 855,
  'iu': 14402,
  'ir': 6773}]

### Android 
[{'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-01T00:00:00Z',
  'u': 8541,
  'r': 5840},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-02T00:00:00Z',
  'u': 8204,
  'r': 5404},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-03T00:00:00Z',
  'u': 8012,
  'r': 6010},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-04T00:00:00Z',
  'u': 8020,
  'r': 6601},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-05T00:00:00Z',
  'u': 9154,
  'r': 6198},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-06T00:00:00Z',
  'u': 11703,
  'r': 5849},
 {'aid': 'air.com.hypah.io.slither',
  'c': 'US',
  'd': '2021-03-07T00:00:00Z',
  'u': 10898,
  'r': 5527}]

### unified
[{'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-01T00:00:00Z',
  'android_units': 8541,
  'android_revenue': 5840,
  'ipad_units': 2069,
  'ipad_revenue': 197,
  'iphone_units': 6294,
  'iphone_revenue': 796,
  'unified_units': 16904,
  'unified_revenue': 6833},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-02T00:00:00Z',
  'android_units': 8204,
  'android_revenue': 5404,
  'ipad_units': 1593,
  'ipad_revenue': 346,
  'iphone_units': 5523,
  'iphone_revenue': 954,
  'unified_units': 15320,
  'unified_revenue': 6704},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-03T00:00:00Z',
  'android_units': 8012,
  'android_revenue': 6010,
  'ipad_units': 2614,
  'ipad_revenue': 904,
  'iphone_units': 7895,
  'iphone_revenue': 737,
  'unified_units': 18521,
  'unified_revenue': 7651},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-04T00:00:00Z',
  'android_units': 8020,
  'android_revenue': 6601,
  'ipad_units': 2820,
  'ipad_revenue': 582,
  'iphone_units': 7144,
  'iphone_revenue': 521,
  'unified_units': 17984,
  'unified_revenue': 7704},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-05T00:00:00Z',
  'android_units': 9154,
  'android_revenue': 6198,
  'ipad_units': 3114,
  'ipad_revenue': 370,
  'iphone_units': 10031,
  'iphone_revenue': 661,
  'unified_units': 22299,
  'unified_revenue': 7229},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-06T00:00:00Z',
  'android_units': 11703,
  'android_revenue': 5849,
  'ipad_units': 3741,
  'ipad_revenue': 457,
  'iphone_units': 12280,
  'iphone_revenue': 1340,
  'unified_units': 27724,
  'unified_revenue': 7646},
 {'app_id': '56fbc26202ac64f6cd000036',
  'country': 'US',
  'date': '2021-03-07T00:00:00Z',
  'android_units': 10898,
  'android_revenue': 5527,
  'ipad_units': 2742,
  'ipad_revenue': 850,
  'iphone_units': 10286,
  'iphone_revenue': 1235,
  'unified_units': 23926,
  'unified_revenue': 7612}]
```



#### 1.4.6 平台下载量及收入

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/store_summary'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android/unified
"""
```

**(4)** **store_summary** 函数结构：

```python
def store_summary(Platform, Category, Country, Granularity, Start_date, End_date):  
    """
    :param  Platform: ios/android/unified
    :param  Category: Checking CountryCodes_CategoryIDs to select category.(use 6014 for game applications)
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :param  Granularity: daily/weekly/monthly/quarterly, defaults to "daily"
    :param  Start_date: yyyy-mm-dd
    :param  End_date: yyyy-mm-dd
    :return  aggregated download/revenue estimates of store categories by country and date
        { 'ca': category,
          'cc': country code,
          'd': date,
          'au': ipad units,
          'ar': ipad revenue,
          'iu': iphone units,
          'ir': iphone revenue
        }
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'categories': Category,
        'countries': Country,
        'date_granularity': Granularity,
        'start_date': Start_date,
        'end_date': End_date
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/store_summary', params=params)
    
    ## print(r.status_code) # Get response messages
    df_SS = pd.DataFrame(r.json())

    return df_SS
```

**(5)** 返回数据结构：

```json
[{'ca': 6014,
  'cc': 'US',
  'd': '2021-03-01T00:00:00Z',
  'au': 1306954,
  'ar': 629387394,
  'iu': 5025349,
  'ir': 1862533112},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-02T00:00:00Z',
  'au': 1257327,
  'ar': 592383111,
  'iu': 4964932,
  'ir': 1718797344},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-03T00:00:00Z',
  'au': 1306145,
  'ar': 630955068,
  'iu': 4915347,
  'ir': 1744347217},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-04T00:00:00Z',
  'au': 1532576,
  'ar': 583596329,
  'iu': 5060078,
  'ir': 1904792951},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-05T00:00:00Z',
  'au': 1472673,
  'ar': 670236045,
  'iu': 5307958,
  'ir': 2054913789},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-06T00:00:00Z',
  'au': 1938025,
  'ar': 649916701,
  'iu': 6208195,
  'ir': 1785432912},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-07T00:00:00Z',
  'au': 1737251,
  'ar': 651566781,
  'iu': 6196068,
  'ir': 1806699698}]
```



#### 1.4.7 应用类别下载量及收入

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/games_breakdown'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android/unified
"""
```

**(4)** **games_breakdown** 函数结构：

```python
def games_breakdown(Platform, Category, Country, Granularity, Start_date, End_date): 
    """
    :param  Platform: ios/android/unified
    :param  Category: Checking CountryCodes_CategoryIDs to select category.(use 6014 for game applications)
    :param  Country: Checking CountryCodes_CategoryIDs to select country (use"WW" for worldwide, "US"  for United States)
    :param  Granularity: daily/weekly/monthly/quarterly, defaults to "daily"
    :param  Start_date: yyyy-mm-dd
    :param  End_date: yyyy-mm-dd
    :return  aggregated download/revenue estimates of store categories by country and date
    	{ 'ca': category,
          'cc': country code,
          'd': date,
          'au': ipad units,
          'ar': ipad revenue,
          'iu': iphone units,
          'ir': iphone revenue
        }
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'categories': Category,
        'countries': Country,
        'date_granularity': Granularity,
        'start_date': Start_date,
        'end_date': End_date
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/games_breakdown', params=params)
    
    df_GB = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    
    return df_GB
```

**(5)** 返回数据结构：

```json
[{'ca': 6014,
  'cc': 'US',
  'd': '2021-03-01T00:00:00Z',
  'au': 1306954,
  'ar': 629387394,
  'iu': 5025349,
  'ir': 1862533112},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-02T00:00:00Z',
  'au': 1257327,
  'ar': 592383111,
  'iu': 4964932,
  'ir': 1718797344},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-03T00:00:00Z',
  'au': 1306145,
  'ar': 630955068,
  'iu': 4915347,
  'ir': 1744347217},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-04T00:00:00Z',
  'au': 1532576,
  'ar': 583596329,
  'iu': 5060078,
  'ir': 1904792951},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-05T00:00:00Z',
  'au': 1472673,
  'ar': 670236045,
  'iu': 5307958,
  'ir': 2054913789},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-06T00:00:00Z',
  'au': 1938025,
  'ar': 649916701,
  'iu': 6208195,
  'ir': 1785432912},
 {'ca': 6014,
  'cc': 'US',
  'd': '2021-03-07T00:00:00Z',
  'au': 1737251,
  'ar': 651566781,
  'iu': 6196068,
  'ir': 1806699698}]
```



#### 1.4.8 检索应用/发行商

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/search_entities'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android
"""
```

**(4)** **search_apps_publishers** 函数结构：

```python
def search_apps_publishers(Platform, Entity, Term, Limit):
    """
    :param  Platform: ios/android
    :param  Entity: app/publihser
    :param  term: key word.Match an app name or publisher name(Minimum Characters: 2 non-Latin or 3 Latin) 
    :param  limit: Limit how many apps returned per call (Max: 250)
    
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'entity_type': Entity,
        'term': Term,
        'limit': Limit,
    }
    r = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/search_entities', params=params)
    
    df_info_AppPub = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    
    return df_info_AppPub
```

**(5)** 返回数据结构：

```json
### app
[{'app_id': 514562699,
  'canonical_country': 'US',
  'name': 'Voodoo Friends',
  'publisher_name': 'Cego ApS',
  'publisher_id': 404756866,
  'humanized_name': 'Voodoo Friends',
  'icon_url': 'https://is4-ssl.mzstatic.com/image/thumb/Purple/v4/2a/bd/88/2abd8882-f3e9-3276-582a-526a072c0acf/mzl.yzsfwedz.png/150x150bb.png',
  'os': 'ios',
  'categories': [6014, 7002, 7012, 6016],
  'global_rating_count': 1418,
  'publisher_profile_url': '/ios/publisher/cego-aps/404756866',
  'release_date': '2012-05-21T07:00:00Z',
  'updated_date': '2013-09-24T00:00:00Z',
  'valid_countries': []}]

### publisher
[{'publisher_id': 714804730,
  'publisher_name': 'Voodoo',
  'publisher_country': 'France',
  'name': 'Voodoo',
  'entity_type': 'publisher',
  'os': 'ios',
  'is_publisher': True,
  'icon_urls': ['https://is2-ssl.mzstatic.com/image/thumb/Purple124/v4/cf/90/6d/cf906d6d-dc4a-1e00-548d-818986503833/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png',
   'https://is1-ssl.mzstatic.com/image/thumb/Purple114/v4/da/4d/b2/da4db279-1d59-d927-43ba-b878e2403c26/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png'],
  'app_count': 283,
  'url': '/ios/publisher/voodoo/714804730'}]

```



#### 1.4.9 应用unified_id查询

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/unified/apps'
```

**(3)** 请求参数：

无 

**(4)** **requests_unified_apps** 函数结构：

```python
def requests_unified_apps(App_ids, App_id_type = 'unified'):
    """
    :param  App_ids: A String/Stings seperated by commas,at most 100 app_ids for a request
    :param  App_id_type: Defualt by 'unified'
    :return  包含应用的unified_id及其发行商的unfied_id信息
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'app_ids': App_ids,
        'app_id_type': App_id_type
    }
    r = requests.get('https://api.sensortower-china.com/v1/unified/apps', params=params)
    
    ## df_aux_unified_Apps = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    return r.json()
```

**(5)** 返回数据结构：

```json
{'apps': [{'unified_app_id': '56fbc26202ac64f6cd000036',
   'name': 'slither.io',
   'itunes_apps': [{'app_id': 1091944550}],
   'android_apps': [{'app_id': 'air.com.hypah.io.slither'}],
   'unified_publisher_ids': ['572e521832377d0920001289'],
   'itunes_publisher_ids': [867992583],
   'android_publisher_ids': ['Lowtech+Studios']}]}
```



#### 1.4.10 发行商unified_id查询

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/unified/publishers'
```

**(3)** 请求参数： 

无

**(4)** **requests_unified_publishers** 函数结构：

```python
def requests_unified_publishers(Publisher_ids, Publisher_id_type = 'unified'):
    """
    :param  Publisher_ids: A String/Stings seperated by commas,at most 100 publisher_ids for a request
    :param  Publisher_id_type: Defualt by 'unified'
    :return  包含母公司的unified_id及其的各平台下发行商的unfied_id
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'publisher_ids': Publisher_ids,
        'publisher_id_type': Publisher_id_type
    }
    r = requests.get('https://api.sensortower-china.com/v1/unified/publishers', params=params)
    
    ## df_aux_unified_Publishers = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    return r.json()
```

**(5)** 返回数据结构：

```json
{'publishers': [{'unified_publisher_id': '572e521832377d0920001289',
   'unified_publisher_name': 'Lowtech Studios',
   'itunes_publishers': [{'publisher_id': 867992583}],
   'android_publishers': [{'publisher_id': 'Lowtech+Studios'},
    {'publisher_id': 'Thorntree+Studios'}]}]}
```



#### 1.4.11 发行商及应用unified_id查询

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/unified/publishers/apps'
```

**(3)** 请求参数： 

无

**(4)** **requests_unified_PubApp** 函数结构：

```python
def requests_unified_PubApp(Unified_id):
    """
    :param  Unified_id: A String of app_id/publisher_id
    :return  1.所查询unfied_id的母公司信息；2.隶属于该母公司的所有发行商id、名称及旗下所发行应用unified及app的id、名称
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    ## API所需参数
    params = {
        'auth_token': auth_token,
        'unified_id': Unified_id
    }
    r = requests.get('https://api.sensortower-china.com/v1/unified/publishers/apps', params=params)
    
    ## df_aux_unified_PubApp = pd.DataFrame(r.json())
    ## print(r.status_code) # Get response messages
    return r.json()
```

**(5)** 返回数据结构：

```json
### app 
{'unified_publisher_id': '572e521832377d0920001289',
 'unified_publisher_name': 'Lowtech Studios',
 'apps': [{'unified_app_id': '56fbc26202ac64f6cd000036',
   'unified_app_name': 'slither.io',
   'ios_apps': [{'app_id': 1091944550,
     'app_name': 'slither.io',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.io.slither',
     'app_name': 'slither.io',
     'publisher_id': 'Lowtech+Studios',
     'publisher_name': 'Lowtech Studios'}]},
  {'unified_app_id': '5570eb8ceb30420bc2000204',
   'unified_app_name': '2048 Flap',
   'ios_apps': [{'app_id': 867992580,
     'app_name': 'Flappy 2048 Extreme',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.release.A2048flap',
     'app_name': '2048 Flap',
     'publisher_id': 'Lowtech+Studios',
     'publisher_name': 'Lowtech Studios'}]},
  {'unified_app_id': '55d9407802ac645ad21666b6',
   'unified_app_name': 'Circle Push',
   'ios_apps': [{'app_id': 968402209,
     'app_name': 'Circle Push',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.release.gameofcircles',
     'app_name': 'Circle Push',
     'publisher_id': 'Thorntree+Studios',
     'publisher_name': 'Thorntree Studios'}]}]}

### publisher
{'unified_publisher_id': '572e521832377d0920001289',
 'unified_publisher_name': 'Lowtech Studios',
 'apps': [{'unified_app_id': '56fbc26202ac64f6cd000036',
   'unified_app_name': 'slither.io',
   'ios_apps': [{'app_id': 1091944550,
     'app_name': 'slither.io',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.io.slither',
     'app_name': 'slither.io',
     'publisher_id': 'Lowtech+Studios',
     'publisher_name': 'Lowtech Studios'}]},
  {'unified_app_id': '5570eb8ceb30420bc2000204',
   'unified_app_name': '2048 Flap',
   'ios_apps': [{'app_id': 867992580,
     'app_name': 'Flappy 2048 Extreme',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.release.A2048flap',
     'app_name': '2048 Flap',
     'publisher_id': 'Lowtech+Studios',
     'publisher_name': 'Lowtech Studios'}]},
  {'unified_app_id': '55d9407802ac645ad21666b6',
   'unified_app_name': 'Circle Push',
   'ios_apps': [{'app_id': 968402209,
     'app_name': 'Circle Push',
     'publisher_id': 867992583,
     'publisher_name': 'Lowtech Studios LLC'}],
   'android_apps': [{'app_id': 'air.com.hypah.release.gameofcircles',
     'app_name': 'Circle Push',
     'publisher_id': 'Thorntree+Studios',
     'publisher_name': 'Thorntree Studios'}]}]}
```



#### 1.4.12 APP商店页评分

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

```python
'https://api.sensortower-china.com/v1/{Platform}/review/get_ratings'
```

**(3)** 请求参数： 

```python
"""
{Platform}: ios/android
"""
```

**(4)** **app_rating** 函数结构：

```python
def app_rating(Platform, App_id, Start_date=None, End_date=None):
        """
        获取应用的商店页评分
        :param Platform: ios/android
        :param App_id: 应用id
        :param Start_date: yyyy-mm-dd
        :param End_date: yyyy-mm-dd
        :return: average: Rating
                 total: Total number of person who rates.
        """
        params = {
            'auth_token': auth_token,
            'app_id': App_id,
            'start_date': Start_date,
            'end_date': End_date
        }
        aux_rating = requests.get(f'https://api.sensortower-china.com/v1/{Platform}/review/get_ratings', params=params)
        df_rating = pd.DataFrame(aux_rating.json())
        # print(aux_rating.status_code)  # Get response messages
        return aux_rating.json()
```

**(5)** 返回数据结构：

```json
[{'app_id': 1538758103,
  'country': 'US',
  'date': '2021-03-07T00:00:00Z',
  'breakdown': [861, 395, 1111, 2352, 19552],
  'current_version_breakdown': [861, 395, 1111, 2352, 19552],
  'average': 4.621,
  'total': 24271},
 {'app_id': 1538758103,
  'country': 'US',
  'date': '2021-03-06T00:00:00Z',
  'breakdown': [838, 386, 1087, 2282, 19038],
  'current_version_breakdown': [838, 386, 1087, 2282, 19038],
  'average': 4.621,
  'total': 23631},
 {'app_id': 1538758103,
  'country': 'US',
  'date': '2021-03-04T00:00:00Z',
  'breakdown': [766, 350, 1011, 2172, 18008],
  'current_version_breakdown': [766, 350, 1011, 2172, 18008],
  'average': 4.628,
  'total': 22307},
 {'app_id': 1538758103,
  'country': 'US',
  'date': '2021-03-03T00:00:00Z',
  'breakdown': [696, 323, 941, 2073, 17159],
  'current_version_breakdown': [696, 323, 941, 2073, 17159],
  'average': 4.636,
  'total': 21192},
 {'app_id': 1538758103,
  'country': 'US',
  'date': '2021-03-01T00:00:00Z',
  'breakdown': [630, 292, 853, 1931, 15862],
  'current_version_breakdown': [630, 292, 853, 1931, 15862],
  'average': 4.641,
  'total': 19568}]
```



## 2. APP Annie

### 2.1 官方API文档

链接：

### 2.2 数据库表信息

#### 2.2.1 aa_app_info

aa_app_info表：储存APP Annie网站上的游戏app及其基本信息，唯一索引是product_id，本表所有录入游戏均曾进入过单平台(iOS或Android)周下载量排行前1000。改： 关注厂商新发布也会进入

![image-20210330110910487](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330110910487.png)



#### 2.2.2 aa_demographic

aa_demographic表：储存aa_app_info录入游戏的用户画像，以年龄阶段，国家和性别分别为分类标准。字段product_id，start_date，country组成唯一的复合，其中country字段为用户属性而非游戏属性。

![image-20210330112406785](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330112406785.png)



#### 2.2.3 aa_app_rank_daily, aa_app_rank_weekly

aa_app_rank_daily表：储存每日下载量排行前1000的游戏，date字段精确到day级别，字段date, product_id, country 组成唯一复合索引，change_rank, change_value, change_percent, 字段均以前一日为base。  

![image-20210330111120302](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330111120302.png)



aa_app_rank_weekly表：储存每周下载量排行前1000的游戏，date字段精确到week级别，字段date, product_id, country 组成唯一复合索引，change_rank, change_value, change_percent, 字段均以前一周为base。  

![image-20210330111221954](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330111221954.png)



#### 2.2.4 aa_publisher_info

aa_publisher_info表： 储存APP Annie网站上的游戏公司，厂商和发行商及其基本信息，唯一索引是publisher_id，本表所有录入厂商存在其发行游戏曾进入过单平台(iOS或Android)周下载量排行前1000。

![image-20210330111409448](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330111409448.png)



#### 2.2.5 aa_publisher_rank_daily, aa_publisher_rank_weekly

aa_publisher_rank_daily表：储存每日下载量排行前1000的厂商，date字段精确到day级别，字段date, publisher_id, country组成唯一复合索引，change_rank, change_value, change_percent 字段均以前一日为base。

![image-20210330111456036](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330111456036.png)

aa_publisher_rank_weekly表：储存每周下载量排行前1000的厂商，date字段精确到week级别，字段date, publisher_id, country组成唯一复合索引，change_rank, change_value, change_percent 字段均以前一周为base。

![image-20210330111600896](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210330111600896.png)



### 2.3 API数据获取及更新

#### 2.3.1 数据获取所需权限

#### 2.3.2 数据获取及更新

### 2.4 API调用函数说明

*# 版本说明：*

*# 请求头：*

#### 2.4.1 应用排行榜及下载量

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_app_ranks** 函数结构：

```python
def AA_app_ranks(Platform, Countries, Ranks, Categories, Granularity, Device, Start_date):
     """
        This fnx is for obtaining the rank of an APP, including its package_id and downloads
        :param Platform: 应用平台名称，分为ios/google-play
        :param Countries: 国家代码（两位字符串），一次输入一个国家代码
        :param Ranks: 排行数量，设置为1000则返回前一千名的应用排行榜，设置范围为0-1000
        :param Categories: 应用类别，ios: Overall > Games；android: OVERALL > GAME
        :param Granularity: daily/weekly/monthly
        :param Device: ios/android (ios包含了ipad及iphone)
        :param Start_date: yyyy-mm-dd
        :return: 1. A dataframe of the rank that user obtained.
                 2. A list of product_id
                version of v1.3: package_id, downloads, rank
                version of v1_2: 'product_id', 'rank', 'estimate', 'change_rank', 'change_value',
                                   'change_percent', 'product_name', 'publisher_id',
                                   'product_franchise_id', 'price', 'has_iap', 'company_id',
                                   'unified_product_id', 'country', 'release_date', 'product_code',
                                   'parent_company_id', 'company_name', 'parent_company_name',
                                   'publisher_name', 'unified_product_name', 'product_franchise_name',
                                    'product_category', 'feed', 'category', 'product_device'
        """
    # --------------------------------------------以下为API正文部分------------------------------------- #

    ## API所需参数
    params ={
    'countries': Countries,
    'categories': Categories,
    'feeds': 'free',
    'ranks': Ranks,
    'granularity': Granularity,
    'device': Device,
    'start_date': Start_date
    }

    r = requests.get(f'https://api.appannie.com/{api_version}/intelligence/apps/{Platform}/ranking', params=params, headers=headers)
    ## print(r)  #查看json
    return pd.DataFrame(r.json()['list']['free'])
```

**(5)** 返回数据结构：



#### 2.4.2 发行商排行榜及下载量

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_publisher_ranks_v1_3** 函数结构：

```python
def AA_publisher_ranks_v1_3(Platform, Countries, Ranks, Categories, Granularity, Device, Start_date):
    """
    所需参数与AA_app_rank一致
    """
    # --------------------------------------------以下为API正文部分------------------------------------- #

    ## API所需参数
    params = {
        'countries': Countries,
        'categories': Categories,
        'feeds': 'free',
        'ranks': Ranks,
        'granularity': Granularity,
        'device': Device,
        'start_date': Start_date
    }
    r = requests.get(f'https://api.appannie.com/{api_version}/intelligence/apps/{Platform}/publisher-ranking', params=params, headers=headers)
    ## print(r)  #查看json
    return pd.DataFrame(r.json()['list']['free'])
```

**(5)** 返回数据结构：



#### 2.4.3 应用详细信息

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_AppInformation** 函数结构：

```python
def AA_AppInformation(Platform, Product_id):
    """
    返回应用详情，API直接返回的为json格式的字符串
    :param Platform: 应用平台名称，分为ios/google-play
    :param Product_id: APP Annie内的应用ID
    """
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    r = requests.get(f'https://api.appannie.com/{api_version}/apps/{Platform}/app/{Product_id}/details', headers=headers)
    
    ## print(r)  #查看json
    return pd.DataFrame(r.json()['list']['free'])
```

**(5)** 返回数据结构：



#### 2.4.4 获取单个应用某个连续时间段的下载量/内购收入

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **download_revenue** 函数结构：

```python
def download_revenue(Platform, Product_id, Countries, Categories, Feeds, Granularity,
                     Start_date, End_date, Device=None):
    """
    获取单个应用某个连续时间段的Downloads/Revenue
    :param Product_id: 应用id
    :param Platform: 应用平台名称，分为ios/google-play
    :param Countries: 国家代码（两位字符串），一次输入一个国家代码
    :param Categories: 应用类别，ios: Overall > Games；android: OVERALL > GAME
    :param Granularity: daily/weekly/monthly
    :param Device: ios/android (ios包含了ipad及iphone)
    :param Start_date: yyyy-mm-dd
    :param End_date: yyyy-mm-dd
    :param Feeds：
                downloads
                revenue
                paid_downloads            （# 导量）
                organic_downloads         （# 自然量）
                percent_paid_downloads    （# 导量百分比）
                percent_organic_downloads （# 自然量百分比）
    """

    # --------------------------------------------以下为API正文部分------------------------------------- #

    # API所需参数
    params = {
        'countries': Countries,
        'categories': Categories,
        'feeds': Feeds,
        'granularity': Granularity,
        'device': Device,
        'start_date': Start_date,
        'end_date': End_date
    }
    r = requests.get(
        f'https://api.appannie.com/{api_version}/intelligence/apps/{Platform}/app/{Product_id}/history',
        params=params, headers=headers)
    # print(r.status_code)  #查看json

    # 数据清洗 （将原始数据的list进行拆分）
    r = pd.DataFrame(r.json())

    r['estimate'] = r['list'].apply(lambda r: r['estimate'] if r['estimate'] != 'N/A' else 0)
    r['device'] = r['list'].apply(lambda r: r['device'])
    r['start_date'] = r['list'].apply(lambda r: r['date'])

    if Platform == 'ios':
        r = pd.merge(r[r['device'] == 'iphone'], r[r['device'] == 'ios'][['estimate', 'start_date']], how='outer',
                     on='start_date')
        r['estimate_x'] = r['estimate_x'].fillna(0)
        r['estimate_y'] = r['estimate_y'].fillna(0)
        r['estimate'] = r['estimate_x'] + r['estimate_y']
        r = r[['product_id', 'country', 'start_date', 'estimate']]
        r['platform'] = 'ios'
    else:
        r = r[['product_id', 'country', 'start_date', 'estimate']]
        r['platform'] = Platform if Platform == 'ios' else 'android'

    return r.convert_dtypes()
```

**(5)** 返回数据结构：



#### 2.4.5 包名转 APP Annie的应用id

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **Packageid2AAid** 函数结构：

```python
def Packageid2AAid(Platform,Package_ids):
    """
    This fnx is for obatining AA_ids(product_ids), of APPs, including its package_id and AA_ids. 
    It mainly serves for the apps on google-play. (iOS package_id can be obatined by [1]).
    
    :param  Platform: ios/google-play
    :param  Package_ids: A string / Strings seperated by commas
    :return A dataframe of package_ids and AA_ids that user obatained.
    """
    
    # --------------------------------------------以下为API正文部分------------------------------------- #

    ## API所需参数
    params = {
        'package_codes': Package_ids
    }
    r = requests.get(f'https://api.appannie.com/{api_version}/apps/{Platform}/package-codes2ids', params=params, headers = headers)
    
    return pd.DataFrame(r.json()['items'])
```

**(5)** 返回数据结构：



#### 2.4.6 获取国家代码列表

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_CountriesCodes** 函数结构：

```python
def AA_CountriesCodes():
    """
    :return  A dataframe of Countries Codes.
    """
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    r = requests.get(f'https://api.appannie.com/{api_version}/meta/countries', headers = headers)
    
    # print(r)  #查看json
    return pd.DataFrame(r.json()['country_list'])
```

**(5)** 返回数据结构：



#### 2.4.7 Categorical List (总分类；不是对于游戏的详细分类)

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_CategoricalList** 函数结构：

```python
def AA_CategoricalList(Platform):
    """
    :param   platform:google-play/ios
    :return  A dataframe of Catgories
    """
    # --------------------------------------------以下为API正文部分------------------------------------- #
    
    r = requests.get(f'https://api.appannie.com/{api_version}/meta/apps/{Platform}/categories', headers = headers)
    
    # print(r)  #查看json
    return pd.DataFrame(r.json()['category_list'])
```

**(5)** 返回数据结构：



#### 2.4.8 用户特征获取（demographics）

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **AA_UserDemographic** 函数结构：

```python
def AA_UserDemographic(platform, product_id, start_date,country='US'):
    '''
    INPUTS:
        platform: 
            ios/all-android
        product_id
        country:(default = US)
        start_date:yyyy-mm-dd

    RETURNS:
        A dataframe(row_length = 1)
            cols = ['product_id','age_index_16_24', 'age_percent_16_24', 'age_index_25_44',
           'age_percent_25_44', 'age_index_45_plus', 'age_percent_45_plus',
           'gender_index_male', 'gender_percent_male', 'gender_index_female',
           'gender_percent_female','start_date','end_date','country']
    '''
     # --------------------------------------------以下为API正文部分------------------------------------- #

    ## API所需参数
    params = {
        'countries': country,
        'start_date': start_date
    }
    r_demographic = requests.get(f"https://api.appannie.com/v1.3/intelligence/apps/{platform}/app/{product_id}/demographics", params=params,headers=headers)
    print(r_demographic.text)
    df = pd.DataFrame(r_demographic.json()['list'])
    r_demographic.json()
    df['product_id'] = r_demographic.json()['product_id']
    df['start_date'] = r_demographic.json()['start_date']
    df['end_date'] = r_demographic.json()['end_date']
    df['country'] = r_demographic.json()['country']
    df = df[['product_id', 'age_index_16_24', 'age_percent_16_24', 'age_index_25_44',
             'age_percent_25_44', 'age_index_45_plus', 'age_percent_45_plus',
             'gender_index_male', 'gender_percent_male', 'gender_index_female',
             'gender_percent_female', 'start_date', 'end_date', 'country']]
    return df
```

**(5)** 返回数据结构：



#### 2.4.9 APP 商店页评分

**(1)**  请求发送方式：GET

**(2)** 数据请求链接：

**(3)** 请求参数： 

**(4)** **app_rating** 函数结构：

```python
def app_rating(product_id, platform):
	 '''
    INPUTS:
        platform: 
            ios/all-android
        product_id

    RETURNS:
        A dataframe(row_length = 1)
            
    '''
     # --------------------------------------------以下为API正文部分------------------------------------- #

    r = requests.get(f'https://api.appannie.com/v1.3/apps/{platform}/app/{product_id}/ratings', headers=headers)
    r_df = pd.DataFrame(r.json()['ratings'])

    r_df['average'] = r_df['all_ratings'].apply(lambda x: x['average'])
    r_df['star_1_count'] = r_df['all_ratings'].apply(lambda x: x['star_1_count'])
    r_df['star_2_count'] = r_df['all_ratings'].apply(lambda x: x['star_2_count'])
    r_df['star_3_count'] = r_df['all_ratings'].apply(lambda x: x['star_3_count'])
    r_df['star_4_count'] = r_df['all_ratings'].apply(lambda x: x['star_4_count'])
    r_df['star_5_count'] = r_df['all_ratings'].apply(lambda x: x['star_5_count'])
    r_df['rating_count'] = r_df['all_ratings'].apply(lambda x: x['rating_count'])
    r_df = r_df[['country', 'average', 'star_1_count', 'star_2_count',
                 'star_3_count', 'star_4_count', 'star_5_count', 'rating_count']]
    avg = ((r_df['star_1_count'] + r_df['star_2_count'] * 2 + r_df['star_3_count'] * 3 + r_df['star_4_count'] * 4 +
            r_df['star_5_count'] * 5).sum() / r_df['rating_count'].sum()).round(2)

    if platform == 'ios':
        r_df.loc[len(r_df)] = ['WW', avg, r_df['star_1_count'].sum(), r_df['star_2_count'].sum(),
                               r_df['star_3_count'].sum(), r_df['star_4_count'].sum(), r_df['star_5_count'].sum(),
                               r_df['rating_count'].sum()]

    return r_df
```

**(5)** 返回数据结构：



# 周报补充说明

## 1.数据库表

### 1.1 premium_apps

premium_apps表：以week为时间精度储存录入过aa_app_info或st_app_info表且其玩法分类标签是解谜，跑酷，解压或其题材子分类是车的游戏，字段product_id, start_date, country, source_platform组成唯一复合索引。因API次数限制，rating字段暂不每周更新。

![image-20210331111355468](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210331111355468.png)



### 1.2 premium_publishers

premium_publishers表：以week为时间精度储存录入过aa_app_info或st_app_info表且其玩法分类标签是解谜，跑酷，解压或其题材子分类是车的游戏的其发行商，字段parent_company_id, start_date, country, platform组成唯一复合索引。字段downloads储存该厂商其录入进premium_apps中的游戏在该周下载量总和。 

![image-20210331111501909](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210331111501909.png)



### 1.3 top_app_weekly

top_app_weekly表：以week时间精度储存录入过aa_app_info或st_app_info表的所有游戏，字段date, unified_id, platform, source_platform组成唯一复合索引。字段unified_id, unified_name统一platform字段，rank_diff 字段以前一周为base。

![image-20210331111630589](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210331111630589.png)



### 1.4 top_publisher_weekly

top_publisher_weekly表：以week时间精度储存存在录入过aa_app_info或st_app_info表的游戏的厂商，字段date, parent_company_id, platform, source_platform组成唯一复合索引。rank_diff 字段以前一周为base。字段last_date 储存上周一的日期。 

![image-20210331111735400](C:\Users\chenq\AppData\Roaming\Typora\typora-user-images\image-20210331111735400.png)



# 文档更新情况

*更新文档后请在下方注明更新时间及更新内容概况*

1. 2021-02-09 	完成初稿内容