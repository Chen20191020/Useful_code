[TOC]

# 文档更新情况

*更新文档后请在下方注明更新时间及更新内容概况*

1. 2021-02-09 	完成初稿内容

# 一.变现平台数据接入

## 1. Facebook

### 1.1 官方API文档

链接：https://developers.facebook.com/docs/audience-network/guides/reporting

### 1.2 数据库表信息

表 fb_ad_report: 存储精确到小时粒度的变现数据，唯一索引所设置的字段如下图中红色key所示，由于在Facebook中同一个应用的安卓、IOS都共用一个应用id，因此此处将app和platform字段均加入唯一索引中。

![image-20210114184105944](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210114184105944.png)



表fb_ad_report_aggregated: 基于fb_ad_report表进行聚合得到的表，数据精确到day级别，唯一索引设置与fb_ad_report基本一致，仅去除掉hour字段，此表一般面向产品部门、市场部门使用。

![image-20210114184122903](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210114184122903.png)



表fb_ad_revenue_imp_by_day: 存储精确到day级别的变现数据，由于是从Facebook API中直接获取day级别的数据，因此没有调整到utc+8时区，此表目前仅面向财务部门使用。

![image-20210114184137801](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210114184137801.png)



表sys_fb_monetize_info: 存储Facebook变现平台信息，包括应用信息及所属商务管理平台名称、token等，需要手动更新维护。

![image-20210209180642750](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209180642750.png)

### 1.3 API数据获取及更新

#### 1.3.1 数据获取所需权限

获取Facebook变现数据，需要获得各应用对应商务管理平台的Access_Token，并且需要在请求链接中输入对应商务管理平台的Business_ID，目前在使用的Facebook变现商务管理平台及其Access_Token、Business_ID见数据库表sys_facebook_monetize_info。

#### 1.3.2 数据获取及更新

**（1）两种请求类型**

Facebook变现数据的获取分为Sync和Async两种请求类型，两者所使用的请求链接及传参格式相同。以下是两者的区别：

| 请求类型 | 请求发送方式 |                  参数限制                   | 单次请求获取的最大数据量 |
| :------: | :----------: | :-----------------------------------------: | :----------------------: |
|   Sync   |     GET      |  只能传入一个metrics参数和至多两个分组维度  |          2,000           |
|  Async   |   POST+GET   | 可以传入多个metrics参数和两个以上的分组维度 |          20,000          |

由于Async在数据获取上灵活性更强，因此本次Facebook变现数据获取采用Async方式。后续也仅介绍Async数据获取的方式，Sync数据的更多限制可参照官方API文档。

**（3）获取动态async_result_link数据地址**

数据请求链接：https://graph.facebook.com/<API_VERSION>/<BUSINESS_ID|PROPERTY_ID>/adnetworkanalytics

请求发送方式：POST

请求参数：将<access_token>替换为对应商务管理平台的access_token

```python
"""参数实例一（获取day层级的数据）"""
data = {   	
    'access_token':<access_token>, # 输入商务管理平台的acess_token
    'metrics':'["fb_ad_network_imp", "fb_ad_network_revenue"]' , # 需要获取的数据，封装为列表，此处为impressions及revenue
    'breakdowns':'["country","platform","placement_name","property","display_format"]', # 分组维度，封装为列表
    'since': '2020-11-29',# 获取数据的起始日期，格式为yyyy-mm-dd
    'until': '2020-12-01', # 获取数据的截止日期，格式为yyyy-mm-dd，与'since'之间的时间间隔最大为30天，不设置则默认为7天
    'aggregation_period':'day', # 时间分组维度，传入'day'则返回数据会精确到day
    'limit':'20000' # 单次请求返回数据量的最大值，如不设置该参数，则默认为50，最大可设置为20000
}
```

```python
"""参数实例二（获取hour层级的数据）"""
data = {   	
    'access_token':<access_token>, # 输入商务管理平台的acess_token
    'metrics':'["fb_ad_network_imp", "fb_ad_network_revenue"]' , # 需要获取的数据，封装为列表，此处为impressions及revenue
    'breakdowns':'["country","platform","placement_name","property","display_format"]', # 分组维度，封装为列表
    'since': '1610672710',# 获取数据的起始时间，UNIX时间格式，精确到秒
    'until': '1610759110', # 获取数据的截止时间，UNIX时间格式，精确到秒，与'since'之间的时间间隔至少为1小时
    'aggregation_period':'hour', # 时间分组维度，传入'hour'则返回数据会精确到hour
    'limit':'20000' # 单次请求返回数据量的最大值，最大可设置为20000
}
```

**备注:** 更多参数设置可参考官方API文档。

请求实例: 将<BUSINESS_ID>替换为对应商务管理平台的BUSINESS_ID

```python
response = requests.post('https://graph.facebook.com/v8.0/<BUSINESS_ID>/adnetworkanalytics/',data = data)
```

响应实例：

```json
{
 "query_id":"8728d37bc84baa847fa191caa5cf8791",
 "async_result_link":"https:\/\/graph.facebook.com\/v8.0\/1197360200628027/adnetworkanalytics_results?query_ids\u00255B0\u00255D=8728d37bc84baa847fa191caa5cf8791"
}
```

**（4）获取变现数据**

将上述响应实例中的"async_result_link"值作为URL地址发送请求，请求方式为GET

请求参数：将<access_token>替换为对应商务管理平台的access_token

```python
params = {
    'access_token': <access_token>
}
```

请求实例:将<async_result_link>替换为上述响应实例中的"async_result_link"值

```python
data_response=requests.get(<async_result_link>,params=params)
```

响应实例：

```python
{
	"data": [{
		"query_id": "b30eaef5dbdd2e0d8f66ac4e1aa692cc",
		"status": "complete",
		"results": [{
			"time": "2021-01-14T08:00:00+0000",
			"metric": "fb_ad_network_revenue",
			"breakdowns": [{
				"key": "country",
				"value": "AE"
			}, {
				"key": "platform",
				"value": "android"
			}, {
				"key": "placement",
				"value": "178537773395361"
			}, {
				"key": "property",
				"value": "252945496062776"
			}, {
				"key": "display_format",
				"value": "rewarded_video"
			}, {
				"key": "placement_name",
				"value": "BH-AN-RW-$35"
			}],
			"value": "0.0935834"
		}]
}
```

**备注**：由于服务器在生成动态async_result_link链接后，数据需要一段时间才能加载完成，因此在获取async_result_link链接后，最好设置5~10秒的等待时间再发送GET请求，以免最后获取到空值。

**（4）数据更新**

① 时区情况：Facebook返回的变现数据均基于UTC-8时区，若需调整至UTC+8时区，需要获取hour层级的数据，并将返回数据的时间加16小时。

② 更新频次：由于单词请求最多返回20000行数据，为避免获取的数据量超过此限制，在获取hour层级的数据时，需要视对应商务管理平台中的资产个数来调整'until'与'to'之间的时间间隔，若资产个数较多，则需要缩小时间间隔，可设为6小时，并设置为2小时更新一次；若资产个数较少，则时间间隔可以适当扩大，更新频次也可适当降低。

③ hour层级数据限制：Facebook只提供过去48小时内的hour层级变现数据。

④day层级数据限制：暂无。

⑤ 需要根据获取的变现数据中的'property'字段与sys_facebook_monetize_info映射得到app_name存储至数据表中。

## 2. Admob

### 2.1 官方API文档

链接：https://developers.google.com/admob/api/v1/reference/rest/v1/accounts.networkReport/generate

### 2.2 数据库表信息

表admob_ad_report: 存储精确到day级别的admob变现平台数据，唯一索引字段图中红色key所示。

![image-20210121112547626](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210121112547626.png)



### 2.3 广告账户信息

目前admob投放平台有两个账号，账号邮箱分别为[polarispolep@gmail.com](mailto:polarispolep@gmail.com)ji和[mpmfgame@gmail.com](mailto:mpmfgame@gmail.com)，两个账号分别管理不同应用的变现数据，将两个账号下的变现数据均保存至admob_ad_report即可。

### 2.4 API数据获取及更新

#### 2.4.1 数据获取所需权限

获取Admob API数据的Access Token需要获取对应账号的OAuth Client ID文件，再根据此文件获取对应的Token，以下为基本步骤，其中获取Admob变现数据所需要指定的Scope为https://www.googleapis.com/auth/admob.report。

![image-20210125102111661](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210125102111661.png)



在网页端获取OAuth Client ID.json文件的网址为https://console.cloud.google.com/apis，下图为获取该文件的详细步骤。

![image-20210125104234082](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210125104234082.png)



获取的JSON文件包含有以下内容：

```json
{
    "installed":{
        "client_id":"{client_id值}",
        "project_id":"{project_id值}",
        "auth_uri":"https://accounts.google.com/o/oauth2/auth",
        "token_uri":"https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
        "client_secret":"{client_secret值}",
        "redirect_uris":[
            "urn:ietf:wg:oauth:2.0:oob",
            "http://localhost"
        ]
    }
}
```



#### 2.4.2 数据获取及更新

Admob数据是利用google-api-python-client来获取，其github地址为https://github.com/googleapis/google-api-python-client，可进入查看详细其详细信息。

以下为数据获取所需的关键点

1. 所需第三方库

   ```python
   from __future__ import print_function
   import pickle
   import os.path
   from googleapiclient.discovery import build
   from google_auth_oauthlib.flow import InstalledAppFlow
   from google.auth.transport.requests import Request
   ```

2. 获取token

   ```python
   def get_token(self):
       """
       token.pickle文件用来存储access token及refresh token，初次获取时，或根据OAuth Client ID.json文件生成授权链接，
       在链接中手动手动授权后即可永久生成token.pickle文件，保存后即可使用
       """
       if os.path.exists('token.pickle'):
           with open('token.pickle', 'rb') as token:
               self.creds = pickle.load(token)
       # 判断token.pickle文件中的access token是否有效，或者access token是否存在
       if not self.creds or not self.creds.valid:
           if self.creds and self.creds.expired and self.creds.refresh_token:
               self.creds.refresh(Request()) # access token无效，但存在refresh token，则生成新的access token
           else: # 不存在refresh token，则根据OAuth Client ID.json文件生成授权链接
               flow = InstalledAppFlow.from_client_secrets_file(
                   'OAuth_Client_ID.json', SCOPES)
               creds = flow.run_local_server(port=0)
               print(creds)
           # 存储生成的access token和refresh token文件
           with open('token.pickle', 'wb') as token:
               pickle.dump(self.creds,token)
   ```

3. 获取数据

   ```python
       def get_data(self):
           """
           根据上述token及账号的 publisher id来获取数据
           """
           admob = build('admob', 'v1', credentials=self.creds)
           publisher_id = 'pub-XXXXXXXXXXXXXXXX' # 此处输入publisher id值
   
           result = admob.accounts().get(
               name='accounts/{}'.format(publisher_id)).execute()
   
           # 可以打印查看对应账号的基本信息
           print('Name: ' + result['name'])
           print('Publisher ID: ' + result['publisherId'])
           print('Currency code: ' + result['currencyCode'])
           print('Reporting time zone: ' + result['reportingTimeZone'])
   
           # 以下为设置数据对应的参数
           date_range = {
               'startDate':{'year':2020,'month':11,'day':1},
               'endDate':{'year':2020,'month':11,'day':5},
           } # 设置日期范围
           metrics = [
               'IMPRESSIONS', 'IMPRESSION_CTR', 'ESTIMATED_EARNINGS', 'CLICKS',
               'MATCHED_REQUESTS','MATCH_RATE','AD_REQUESTS','IMPRESSION_RPM'
           ] # 设置metrics，即所需的数据字段
           dimensions = ['DATE', 'APP', 'COUNTRY', 'AD_UNIT', 'PLATFORM'] # 设置dimensions，即数据分组维度
           sort_conditions = {'dimension': 'APP', 'order': 'DESCENDING'} # 设置数据的排序方式
   
           # 将以上参数封装为字典
           report_spec = {
               'dateRange': date_range,
               'dimensions': dimensions,
               'metrics': metrics,
               'sortConditions': [sort_conditions],
           }
   
           # 生成 network report request.
           request = {'reportSpec': report_spec}
   
           # 利用API-client提供的接口，传入相应参数，获取数据
           self.result = admob.accounts().networkReport().generate(
               parent='accounts/{}'.format(publisher_id), body=request).execute()
   ```

4. 返回数据实例

   ```json
   [
     {
       "header": {
         "dateRange": {
           "startDate": {
             "year": 2021,
             "month": 1,
             "day": 24
           },
           "endDate": {
             "year": 2021,
             "month": 1,
             "day": 25
           }
         },
         "localizationSettings": {
           "currencyCode": "USD"
         }
       }
     },
     {
       "row": {
         "dimensionValues": {
           "DATE": {
             "value": "20210124"
           },
           "APP": {
             "value": "ca-app-pub-7226382995208205~8272488213",
             "displayLabel": "Crash Crash Crash!"
           },
           "COUNTRY": {
             "value": "AU"
           },
           "AD_UNIT": {
             "value": "ca-app-pub-7226382995208205/1664763559",
             "displayLabel": "CCC_AN_RW_$17"
           },
           "PLATFORM": {
             "value": "Android"
           }
         },
         "metricValues": {
           "IMPRESSIONS": {
             "integerValue": "0"
           },
           "ESTIMATED_EARNINGS": {
             "microsValue": "0"
           },
           "CLICKS": {
             "integerValue": "0"
           },
           "MATCHED_REQUESTS": {
             "integerValue": "0"
           },
           "MATCH_RATE": {
             "doubleValue": 0
           },
           "AD_REQUESTS": {
             "integerValue": "2"
           },
           "IMPRESSION_RPM": {
             "doubleValue": 0
           }
         }
       }
     },
   ```

5. 数据更新

   Admob只提供day层级的数据，其时区与账号实际所设置的时区一致（公司Admob变现通常设置为UTC+8时区），为防止其历史数据有变动，一般每次可更新三天的数据。可以获取较长时间段内的历史数据，暂未发现其他限制。

## 3. Applovin

### 3.1 官方API文档

链接：https://dash.applovin.com/documentation/mediation/features/api/max-reporting-api

### 3.2 数据库表信息

表applovin_ad_report: 存储精确到hour层级的变现数据，唯一索引如下表红色key所示，由于在Applovin中，同一个应用在不同应用系统下仍旧会共用一个包名，因此选择将application及channel作为识别唯一应用的字段加入索引。

![image-20210204182524467](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210204182524467.png)



表applovin_ad_report_aggregated: 基于applovin_ad_report按day进行聚合得到的表，其余情况与applovin_ad_report一致。

![image-20210204182640868](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210204182640868.png)



### 3.3 API数据获取及更新

#### 3.3.1 数据获取所需权限

获取MAX数据需要使用Report Key，由MAX账户管理者提供。

#### 3.3.2 数据获取及更新

1.  API地址：http://r.applovin.com/maxReport

2.  获取Applovin数据较为简便，给出以下参数即可：

```python
params = {
            'start':'2021-01-01', # 起始日期，格式为'yyyy-mm-dd'
            'end':'2021-01-03', # 截止日期，格式为'yyyy-mm-dd'
            'api_key':'{在此输入API Key}',# 获取数据所需的Report Key
            'format':'json', # 返回数据的格式，可设为json或者csv，默认为csv
            'filter_network':'APPLOVIN_NETWORK', # 变现平台名称，为获取Applovin的数据，设置为APPLOVIN_NETWORK
           'columns':'day,hour,application,package_name,platform,ad_format,country,impressions,estimated_revenue',# 所需返回的字段，更多字段及其说明见官方API文档
        }
```

3.  加入参数，向API地址发起GET请求，则会返回以下格式的数据（以json格式数据为例）：

```json
{
	"code": 200,
	"results": [{
		"day": "2021-02-03",
		"hour": "18:00",
		"application": "Truck'em All",
		"package_name": "www.huolala.truckemall",
		"platform": "android",
		"ad_format": "BANNER",
		"country": "ro",
		"impressions": "48",
		"estimated_revenue": "0.000404"
	}, {
		"day": "2021-02-03",
		"hour": "16:00",
		"application": "Truck'em All",
		"package_name": "www.huolala.truckemall",
		"platform": "android",
		"ad_format": "BANNER",
		"country": "in",
		"impressions": "9794",
		"estimated_revenue": "0.072604"
	}]
}
```

4. 数据更新

   ① Applovin提供的数据为UTC+0时区，因此需要给date加上8小时从而调整到UTC+8时区再存储至applovin_ad_report表中。

   ② 每次最好获取3天的数据，以更新历史数据。

   ③ 每次更新时均将获取的数据按day聚合到applovin_ad_report_aggregated表中，保证与applovin_ad_report表同步更新数据。

## 4. IronSource

### 4.1 官方API文档

文档链接：https://developers.ironsrc.com/ironsource-mobile/air/reporting/

### 4.2 数据库表信息

表iron_ad_report: 存储精确到day层级的数据，其唯一索引设置如图中红色key所示，由于历史数据中出现过同一app_key对应着同一个应用的不同应用系统，因此此处将app_key及channel同时加入一般索引，但一般情况下，IronSource的app_key会对应着唯一应用下的唯一应用系统。鉴于此表数据量较小，索引所占空间也较小，因此暂不针对此进行改动。

![image-20210205105635949](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205105635949.png)



### 4.3 API数据获取及更新

#### 4.3.1 数据获取所需权限

1. IronSource权限获取官方说明：https://developers.ironsrc.com/ironsource-mobile/air/authentication/

2. 需要在公司IronSource账户中获取以下Secret Key及Refresh Token，从而获取Authentication Token，每次生成后在60分钟内有效，因此一般情况下，每次获取数据都需要生成一次Authentication Token。

![image-20210205110856920](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205110856920.png)



3. 获取到Secret Key及Refresh Token后，将其封装为请求头(headers)，向token获取API：https://platform.ironsrc.com/partners/publisher/auth发起GET请求。

   ```python
   au_headers = {
               'secretkey':'{在此输入Secret Key}',
               'refreshToken':'{在此输入Refresh Token}',
           }
   ```

   请求成功后，会返回一个token字符串，如下所示，记住要将字符串里的""去掉，即为所需的Authentication Token。

   ```python
   '"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzZWNyZXRLZXkiOiIzYTM3NzcxYmRmNGQxNDA0OGNmODc1ODZkOTMwMDE1MiIsInJlZnJlc2hUb2tlbiI6IjhmY2QzYWY4NWUwMGQ4ZGI2NjFiZTZhODgyYzY0NDJiIiwiZXhwaXJhdGlvblRpbWUiOjE2MTI0OTg2MTl9.I4dVoKGWVr4PZh3cVT7gEwKWb2X8m0tmetLr-55LxQc"'
   ```

   

#### 4.3.2 数据获取及更新

1. 传入请求头：

   ```python
   headers = {
               'Authorization':'Bearer {在此输入Authentication Token}',
           }
   ```

2. 传入请求参数：

   ```python
   params = {
               'startDate': "2020-02-04", # 起始日期，格式为'yyyy-mm-dd'
               'endDate': "2020-02-05", # 截止日期，格式为'yyyy-mm-dd'
               'metrics':'revenue,eCPM,impressions', # 所需的数据字段
               'breakdowns':'date,app,platform,adUnits,country,adSource', # 分组维度，同时会返回这些字段
           }
   ```

3. 根据以上参数向API链接https://platform.ironsrc.com/partners/publisher/mediation/applications/v6/stats发起GET请求，服务器会直接返回所需数据。

   ```python
   response = requests.get('https://platform.ironsrc.com/partners/publisher/mediation/applications/v6/stats',
                           headers = headers,params=params)
   ```

4. 返回数据实例

   ```json
   [
       {
           "date":"2021-02-04",
           "appKey":"c705fd5d",
           "platform":"iOS",
           "adUnits":"Rewarded Video",
           "bundleId":"com.mpmf.banghero",
           "appName":"Bang Hero (iOS)",
           "providerName":"ironSource",
           "data":[
               {
                   "revenue":0.01,
                   "eCPM":10,
                   "impressions":1,
                   "countryCode":"AE"
               },
               {
                   "revenue":0.04,
                   "eCPM":5.71,
                   "impressions":7,
                   "countryCode":"AL"
               }
           ]
       }
    ]
   ```

5. 数据更新
   1. IronSource只提供精确到day层级的数据，且为UTC+0时区，无法调整至UTC+8时区。
   2. 每次可获取三天左右的数据，以更新历史数据。

## 5. Unity

### 5.1 官方API文档

API文档链接：http://unityads.unity3d.com/help/resources/statistics#using-the-monetization-stats-api

### 5.2 数据库表信息

表unity_ad_report: 存储精确到hour层级的数据，其唯一索引设置如图中红色Key所示，unity中source_game_id较为规范，可以唯一识别唯一应用系统下的唯一应用，因此将其加入唯一索引中。

![image-20210205155626998](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205155626998.png)



表unity_ad_report_by_day: 存储精确到day层级的数据，其唯一索引设置与unity_ad_report基本一致。

![image-20210205160310312](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205160310312.png)



### 5.3 API数据获取及更新

#### 5.3.1 数据获取所需权限

需要账户管理员提供API KEY及Organization ID。

#### 5.3.2 数据获取及更新

1. 请求头: 设置返回数据的格式，此处设置为json格式。

   ```python
    headers = {
               'Accept':'application/json',
           }
   ```

2. 请求参数：

   ```python
   params = {
               'apikey':'{在此输入API KEY}',
               'fields':'adrequest_count,available_sum,revenue_sum,start_count,view_count', # 所需数据字段
               'scale':'hour', # 数据的时间粒度，选择精确到hour层级
               'start': '2020-11-23T00:00:00', # 起始时间，ISO时间格式，即'yyyy-mm-ddTHH:MM:SS'
               'end': '2020-11-24T00:00:00', # 截止时间，ISO时间格式，即'yyyy-mm-ddTHH:MM:SS'
               'groupBy':'country,placement,platform,game', # 分组维度
           }
   ```

3. 向服务器发送GET请求，API地址为https://monetization.api.unity.com/stats/v1/operate/organizations/{在此输入organization_id}

   ```python
   resonse = requests.get('https://monetization.api.unity.com/stats/v1/operate/organizations/{organization_id}',
                       headers = headers,params=params)
   ```

4. 返回数据实例(以json格式为例)：

   ```json
   [
       {
           "country":"AE",
           "source_game_id":"3543738",
           "adrequest_count":4,
           "placement":null,
           "revenue_sum":0,
           "start_count":0,
           "available_sum":4,
           "platform":"android",
           "view_count":0,
           "source_name":"Shooting Balls 3D",
           "timestamp":"2021-02-04T17:00:00.000Z"
       },
       {
           "country":"AE",
           "source_game_id":"3598388",
           "adrequest_count":66,
           "placement":null,
           "revenue_sum":0,
           "start_count":0,
           "available_sum":66,
           "platform":"android",
           "view_count":0,
           "source_name":"Bang Hero",
           "timestamp":"2021-02-04T17:00:00.000Z"
       }
   ]
   ```

5. 数据更新

   ① 通过API获取的数据存储至unity_ad_report表中，同时将聚合到day层级的数据同步存储至unity_ad_report_by_day中。

   ② unity提供的数据为UTC+0时区，可加上8小时后调整到UTC+8时区。

   ③ 每次可获取三天的数据，以更新历史数据。

## 6. Mintegral

### 6.1 官方API文档

API文档链接：https://cdn-adn-https.rayjump.com/cdn-adn/reporting_api/MintegralRA.html?v=2.0#examples

### 6.2 数据库表信息

表mintegral_ad_report: 存储精确到day层级的数据，其唯一索引如图中的红色KEY所示，app_id可以标识唯一应用系统下的唯一应用，因此可直接加入唯一索引。

![image-20210205172641359](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205172641359.png)



### 6.3 API数据获取及更新

#### 6.3.1 数据获取所需权限

在账户管理中获取Skey及密钥。

![image-20210205173431342](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210205173431342.png)



#### 6.3.2 数据获取及更新

1. Mintegral每一批数据会分页返回，单次请求只返回一页数据，每页最多返回1000行数据，因此需要针对页码来循环获取每一批的数据，以下为返回数据的实例，以json格式为例：

   ```json
   {
       "code":"ok",
       "data":{
           "total":8589,
           "start":"20210204",
           "end":"20210207",
           "timezone":8,
           "ad_format":"",
           "page":1, # 当前页码
           "limit":1000,
           "total_page":9, # 总页数
           "lists":[
               {
                   "date":20210204,
                   "app_id":119909,
                   "unit_id":157401,
                   "platform":"android",
                   "filled":0,
                   "request":5,
                   "impression":0,
                   "click":0,
                   "est_revenue":0,
                   "fill_rate":0,
                   "country":"AU",
                   "ecpm":0,
                   "ctr":0,
                   "app_name":"Robot Clash",
                   "unit_name":"MAX-AN-RW-R2",
                   "ad_format":"rewarded_video"
               }
           ]
       }
   }
   ```

2. 由于需要循环获取数据，因此在请求参数中需要加入页码。**另外需要特别注意的是，传入的参数有严格的顺序要求，需要按照key降序排列**，如下所示：

   ```python
   param = {
                   'end': '20210207', # 截止时间，格式为'yyyymmdd'
                   'group_by': 'date,app_id,country,platform,unit_id,', # 分组维度
                   'limit': 1000, # 每页返回的数据量，最多可设置1000行
                   'page': 1, # 获取数据的页码，根据返回数据的总页数而定，循环获取。
                   'skey': '1cf3dc10976d1849f644553c7546b980', # 权限中的Skey值
                   'start': '20210204', # 起始时间，格式为'yyyymmdd'
                   'time': '1612750568', # 获取数据时的时间，unix格式，精确到秒，需要在发起请求时间的前后300s内，否则无效
                   'timezone':8, # 时区，默认为8，即UTC+8时区
               } # 以上参数严格按照参数的key降序排列，即end,group_by,limit,page,skey,start,time,timezone
   ```

3. 获取了SKey、密钥，按规范格式生成了请求参数(param)后，需要进行md5编码，编码步骤如下：

   ```python
   string = parse.urlencode(param) # 将请求参数(param)进行URL编码
   secret= '{在此输入密钥}'
   m = hashlib.md5(string.encode()).hexdigest() # 将URL编码后的请求参数(param)进行MD5编码
   h=m+secret # 将密钥与MD5编码后的请求参数(param)直接拼接起来
   sign = hashlib.md5(h.encode()).hexdigest()# 对拼接后的字符串进行MD5编码，生成最终的sign
   ```

4. 向API发起GET请求，API地址为：https://api.mintegral.com/reporting/data。在链接后直接加入URL编码后的请求参数以及生成的sign即可，如下所示：

   ```python
   response = requests.get('https://api.mintegral.com/reporting/data?'+string+'&sign='+sign)
   ```

   根据返回数据的页码及总页数，循环发起GET请求直至获取完所有页的数据即可。

5. 数据更新

   ① Mintegral提供的数据可以直接设置为UTC+8时区，仅精确到day层级，因此不需要调整时区即可存储。

   ② 每次可以更新三天的数据

## 7. Vungle

### 7.1 官方API文档

API文档链接: https://support.vungle.com/hc/en-us/articles/211365828-Reporting-API-2-0-for-Publishers-#filter-parameters-0-4

### 7.2 数据库表信息

表vungle_ad_report: 数据精确到day层级，唯一索引如红色Key所示，application_id可以标识唯一操作系统下的唯一应用，因此加入唯一索引中。

![image-20210208114539084](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208114539084.png)



### 7.3 API数据获取及更新

#### 7.3.1 数据获取所需权限

管理员登录变现平台后，在首页即可点击获取Reporting API Key。

![image-20210208115054131](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208115054131.png)



#### 7.3.2 数据获取及更新

1. 请求头设置：

   ```python
   headers = {
               'Authorization': 'Bearer {在此输入API Key}',
               'Vungle-Version': '1', # API版本，目前为1.0
               'Accept': 'application/json', # 返回数据格式，可设置为text/csv或者application/json，此处设置为返回json格式数据
           }
   ```

2. 请求参数：

   ```python
   params = {
               'dimensions': 'date,application,placement,country,platform', # 分组维度
               'aggregates': 'views,revenue', # 所需数据
               'start': '2021-02-05', # 起始日期，格式为'yyyy-mm-dd'
               'end': '2021-02-08', # 截止日期，格式为'yyyy-mm-dd'
           }
   ```

3. 添加请求头及请求参数，发起GET请求，API地址为：https://report.api.vungle.com/ext/pub/reports/performance

   ```python
   response = requests.get('https://report.api.vungle.com/ext/pub/reports/performance', headers=headers, params=params)
   ```

4. 返回数据实例：

   ```json
   [
       {
           "application id":"5ee6d75f3cea9800014c7f53",
           "application name":"Bang Hero",
           "country":"FR",
           "date":"2021-02-07",
           "placement id":"5ee6d75f3cea9800014c7f55",
           "placement name":"VG_BH_AN_IN_13",
           "placement reference id":"VG_BH_AN_IN_13-7809994",
           "platform":"android",
           "revenue":0,
           "views":0
       }
   ]
   ```

5. 数据更新

   ① Vungle只提供精确到day层级的数据，且数据时区为UTC+0，无法调整至UTC+8时区。

   ② 每次更新可以获取三天的数据。

## 8. Adcolony

### 8.1 官方API文档

API文档链接(PDF格式):

 https://support.adcolony.com/wp-content/uploads/2019/07/AdColony-Publisher-Reporting-API-v2.3_Nov222016.pdf

### 8.2 数据库表信息

表adcolony_ad_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示，app_id可以标识唯一应用系统的唯一应用，因此加入唯一索引中。

![image-20210208141656025](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208141656025.png)



### 8.3 API数据获取及更新

#### 8.3.1 数据权限获取

管理员登录Adcolony变现平台后，在Account Settings中可以直接获取API Key。

![image-20210208143544225](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208143544225.png)



#### 8.3.2 数据获取及更新

1. 请求参数：

   ```python
    params = {
               'date':'02052021', # 起始日期，格式为'mmddyyyy'
               'end_date': '02052021', # 截止日期，格式为'mmddyyyy'
               'user_credentials': '{在此输入API Key}', 
               'format': 'json', # 返回数据格式，可设置为json，csv，xml，默认为json
               'date_group': 'day', # 日期分组维度，可设置为day，aggregate，默认为aggregate，即不再有时间维度
               'group_by': 'app,country,zone', # 分组维度，默认为app，zone即是广告版位
           }
   ```
   

**需要注意的是**，理论上adcolony可以一次获取多天的数据，但在实际获取时发现数据存在错误的情况，主要是country字段会出现null值，难以处理，并且该类下的数据也有问题，总计数据也与实际有出入，如下所示：

   ```json
   {
         "internal_app_id": 384104,
         "app_name": "Wheel Offroad",
         "app_id": "appb55c83949d1b4b8e8a",
         "store_id": "www.wheelroad.wheeloffroad",
         "platform": "android",
         "internal_zone_id": 1384126,
         "zone_id": "vzdc7d3109837f46f1ac",
         "zone_name": "WOR_AN_ADC_INTER",
         "date": "2021-02-05",
         "earnings": 0,
         "ecpm": 0,
         "fill_rate": 0,
         "requests": 12706, # 该项值极大，但其他值均为0
         "impressions": 0,
         "house_impressions": 0,
         "cvvs": 0,
         "house_cvvs": 0,
         "completion_rate": 0,
         "clicks": 0,
         "ctr": 0,
         "country": null # country字段出现null
       }
   ```

   当一次只获取一天的数据时，不再出现上述问题，并且数据未出现差错，因此如果需要获取多天的数据，则必须循环获取单日的数据，即将date参数和end_date参数设置成一致的日期。

2. 添加请求参数，发起GET请求，API地址为：http://clients-api.adcolony.com/api/v2/publisher_summary

   ```python
   response = requests.get('http://clients-api.adcolony.com/api/v2/publisher_summary', params=params)
   ```

3. 数据返回实例(以json格式为例)：

   ```json
   {
       "status":"success",
       "results":[
           {
               "internal_app_id":384104,
               "app_name":"Wheel Offroad",
               "app_id":"appb55c83949d1b4b8e8a",
               "store_id":"www.wheelroad.wheeloffroad",
               "platform":"android",
               "internal_zone_id":1384126,
               "zone_id":"vzdc7d3109837f46f1ac",
               "zone_name":"WOR_AN_ADC_INTER",
               "date":"2021-02-05",
               "earnings":27.06124,
               "ecpm":13.75063,
               "fill_rate":0.95,
               "requests":206523,
               "impressions":1968,
               "house_impressions":0,
               "cvvs":1286,
               "house_cvvs":0,
               "completion_rate":65.35,
               "clicks":382,
               "ctr":19.41,
               "country":"US"
           }
       ]
   }
   ```

4. 数据更新

   ① Adcolony返回的数据精确到day层级，时区为UTC+0，无法调整至UTC+8时区。

   ② 每次可以更新三天的数据，但单次请求需要获取一天的数据，然后循环发送请求即可

## 9. Tapjoy

### 9.1 官方API文档

API文档链接：https://dev.tapjoy.com/cn/reporting-api/Quickstart

### 9.2 数据库表信息

表tapjoy_ad_report: 存储精确到hour层级的数据，唯一索引如图中红色Key所示，app_key可以标识唯一操作系统的唯一应用名，因此加入唯一索引中，其中hour对应的是date_utc8的小时。

![image-20210208175839683](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208175839683.png)



表tapjoy_ad_report_aggregated: 存储精确到day层级的数据，其结构与tapjoy_ad_report表基本一致。

![image-20210208180252923](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208180252923.png)



### 9.3 API数据获取及更新

#### 9.3.1 数据权限获取

1. 管理员登录tapjoy变现平台后，进入 设置>应用设置>API密钥 可以获取到API Key，如图中所示。

![image-20210208180605199](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210208180605199.png)



2. 根据API Key获取Access Token。生成后的Access Token有效期一般为一小时，因此理论上每次更新数据都需要重新获取Access Token：

   (1). 请求头为：

   ```python
    headers = {
                   'Host': 'api.tapjoy.com',
                   'Authorization': 'Basic {在此输入API Key}',
                   'Accept': 'application/json',
               }
   ```

   (2). 发起POST请求，API地址为：http://api.tapjoy.com/v1/oauth2/token

   ```python
   res = requests.post('http://api.tapjoy.com/v1/oauth2/token',headers=headers)
   ```

   (3). Token返回实例：

   ```json
   {
       "access_token":"1THTTc6AOlhoAfM1KJSAmrirUdYnY3XO49Gud5fOXl7lv0xL4NPntjzLHzQyqbLrIfkfabCy96nYgPFWhKKHww==", # 所生成的Token
       "token_type":"bearer",
       "expires_in":3599.989673405, # 有效时间，一般为一小时
       "refresh_token":null
   }
   ```

   获取以上返回数据中的Token，进行下一步变现数据的获取

#### 9.3.2 数据获取及更新

1.  请求头为：

```python
headers = {
            'Host':'api.tapjoy.com',
            'Authorization':'Bearer {在此输入生成的Token}',
            'Accept':'application/json',
            'time_increment':'hourly',
        }
```

2. 请求参数

```python
params = {
            'date':'2021-02-06', # 所需数据的日期，格式为'yyyy-mm-dd'
            'page_size':10, # 每一页数据返回的app的数目，默认为1
    		'page':1, # 返回数据的页码，默认为1
            'group_by':'placements', # 分组维度，可选择的有placements,content_types,content_cards，默认为placement是，即广告类型
            'time_increment':'hourly', # 时间粒度，可选择的有hourly, daily，默认为daily，设置为hourly则为hour层级的数据
        }
```

3. 添加请求头的请求参数，发起GET请求，API地址为：http://api.tapjoy.com//v2/publisher/reports

```python
response = requests.get('http://api.tapjoy.com//v2/publisher/reports',headers = headers,params=params)
```

4. 数据返回实例（以json格式为例）:

```json
{
	"Date": "2021-02-05",
	"TotalApps": 5,
	"PageSize": 10,
	"TotalPages": 1,
	"CurrentPage": 1,
	"Apps": [{
		"Name": "Wheel Offroad",
		"Platform": "android",
		"AppKey": "30d9770c-f4a2-409f-983c-9fda2ed97e75",
		"Placements": [{
			"Name": "WOR-AN-Reward",
			"Global": {
				"Revenue": [4.01548, 2.37442, 1.80387, 1.84659, 0.7449, 0.42997, 0.46971, 1.08099, 0.33593, 0.27378, 0.45894, 0.49493, 0.81393, 0.80054, 0.75871, 0.82179, 1.43442, 0.66982, 0.78235, 1.04252, 1.55727, 1.03893, 0.82169, 0.6266],
				"Impressions": [293.0, 245.0, 184.0, 178.0, 75.0, 69.0, 77.0, 94.0, 39.0, 52.0, 75.0, 74.0, 94.0, 79.0, 81.0, 103.0, 97.0, 124.0, 103.0, 119.0, 120.0, 125.0, 123.0, 91.0],
				"Clicks": [290.0, 248.0, 184.0, 178.0, 76.0, 71.0, 78.0, 94.0, 39.0, 52.0, 76.0, 74.0, 95.0, 80.0, 81.0, 104.0, 99.0, 126.0, 104.0, 124.0, 121.0, 125.0, 124.0, 92.0],
				"Conversions": [281.0, 240.0, 179.0, 176.0, 76.0, 66.0, 76.0, 90.0, 40.0, 50.0, 73.0, 70.0, 92.0, 79.0, 78.0, 99.0, 99.0, 124.0, 103.0, 119.0, 119.0, 125.0, 122.0, 91.0]
			},
			"Countries": [{
				"Country": "au",
				"Revenue": [0.12323, 0.02499, 0.02414, 0.03223, 0.02789, 0.04427, 0.07765, 0.0568, 0.02715, 0.01856, 0.09679, 0.00688, 0.0, 0.02439, 0.0102, 0.0, 0.0, 0.0, 0.0, 0.01205, 0.01124, 0.00497, 0.01069, 0.01229],
				"Impressions": [10.0, 4.0, 5.0, 5.0, 3.0, 7.0, 12.0, 9.0, 6.0, 3.0, 6.0, 2.0, 0.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0, 2.0, 3.0],
				"Clicks": [10.0, 4.0, 5.0, 5.0, 3.0, 8.0, 12.0, 9.0, 6.0, 3.0, 6.0, 2.0, 0.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0, 2.0, 3.0],
				"Conversions": [9.0, 4.0, 4.0, 4.0, 3.0, 8.0, 11.0, 9.0, 6.0, 2.0, 6.0, 1.0, 1.0, 2.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 1.0, 2.0, 3.0]
			
		}]
	}]
}]}
```

5. 数据更新

①. tapjoy返回的数据为UTC+0时区，可以根据小时调整至UTC+8时区进行保存，并将UTC+8的小时提取出来，保存至tapjoy_ad_report的hour字段中。

②. 由于参数设置的原因，每次请求只能返回一天的数据，因此获取多天的数据需要循环发起请求。

③. 每次可以更新三天的数据。

## 10. Fyber

### 10.1 官方API文档

官方API文档链接：https://developer.fyber.com/hc/en-us/articles/360010079438-FairBid-Reporting-API

### 10.2 数据库表信息

表fyber_ad_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示，fyber_app_id可以标识唯一操作系统下的唯一应用，因此加入唯一索引中。

![image-20210209092559877](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209092559877.png)

### 10.3 API数据获取及更新

#### 10.3.1 数据权限获取

1. 管理员登录变现平台后，在User Profile中可以获取到Client ID及Client Secret

![image-20210209092850532](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209092850532.png)

2. 生成Access Token。生成后的Access Token有效期一般为一小时，因此理论上每次更新数据都需要重新获取Access Token：

   ① 请求头设置：

   ```Python
    headers = {
                   "Content-Type":"application/json",
               } 
   ```

   ② 请求参数设置：

   ```python
   data = {
                   "grant_type": "client_credentials", # 授权类型，必须为'client_credentials'
                   "client_id": "{在此输入Client ID}",
                   "client_secret":"{在此输入Client Secret}",
               }
   ```

   ③ 添加请求头和请求参数，发起POST请求，API地址为：https://reporting.fyber.com/auth/v1/token

   ```python
   response = requests.post('https://reporting.fyber.com/auth/v1/token',json=data,headers=headers)
   ```

   ④ Token返回实例：

   ```json
   {
     "accessToken":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE2MTI4MzQ1MjcsImV4cCI6MTYxMjgzODEyNywiYXVkIjoic3BlZWRiYWxsIiwic3ViIjoiMjE1NTIxIn0.fEH-DHPXps7Ile2d0R3d4bKJaRaRUkgBSfEH_IXLqYc", # 所需的Access Token
       "tokenType":"bearer", #验证类型
       "expiresIn":3600 # Token有效时间，一般为一小时
   }
   ```

#### 10.3.2 数据获取及更新

1. 请求头设置：

   ```python
   headers = {
               'Content - Type': 'application/json', # 数据返回格式
               'Authorization': 'Bearer {在此输入Access Token}'
           }
   ```

2. 请求参数设置：

   data = {

   ```Python
               "source": "mediation",
               "dateRange": {
                   "start": '2021-02-05', # 起始日期，格式为'yyyy-mm-dd'
                   "end": '2021-02-08', # 截止日期，格式为'yyyy-mm-dd'
               },
               "metrics": [
                   "Bid Requests", 
                   "Bid Responses",
                   "Impressions",
                   "Clicks",
                   "Rewarded Completions",
                   "Revenue (USD)",
                   "Unique Impressions"
               ], # 所需数据的列表
               "splits": [
                   "Fyber App ID",
                   "App Name",
                   "Placement Name",
                   "Placement Type",
                   "Country",
                   "Device OS",
                   "Date",
               ], #分组维度的列表
               "filters":[], # 筛选条件的列表，此处设置为空，即不进行筛选
       }
   ```

3. 发起POST请求，API地址为：

   ```python
   reponse_url = requests.post('https://reporting.fyber.com/api/v1/report?format=csv',json=data,headers=headers)
   ```

4. 返回结果为一个包含URL链接的json格式数据，该链接中包含本次请求所需的数据:

   ```json
   {
       "id":"edc0807c-b64d-48d8-a53a-f96374377a6b",
       "url":"https://fyber-async-reports.s3.amazonaws.com/group%3D215521/edc0807c-b64d-48d8-a53a-f96374377a6b/edc0807c-b64d-48d8-a53a-f96374377a6b.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQBQNZ5FY5FFZ6DTR%2F20210209%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20210209T015115Z&X-Amz-Expires=10800&X-Amz-Signature=072569e26792d795d232cf74904292cadfba33400046d8995e4d022e2170a160&X-Amz-SignedHeaders=host"
   }
   ```

5. 加载URL链接，获取数据。由于链接中的数据加载完毕需要一定的时间，因此建议获取到上述URL链接后，等待一段时间后(可以设置为20s)，再进行加载：

   ```python
   re = requests.get('{在此输入获取的URL链接}')
   ```

6. 返回数据实例。返回的数据为csv格式：

   ```html
   Fyber App ID,App Name,Placement Name,Placement Type,Country,Device OS,Date,Bid Requests,Bid Responses,Impressions,Clicks,Rewarded Completions,Revenue (USD),Unique Impressions
   115929,Wreck Master 3D!,FY WM3D AN BANNER2,Banner,DE,android,2021-02-06,52580,438,12,0,0,0.0084,6
   115929,Wreck Master 3D!,FY WM3D AN BANNER5,Banner,BE,android,2021-02-04,2,2,0,0,0,0.0,""
   115929,Wreck Master 3D!,FY WM3D AN INTER2,Interstitial,SG,android,2021-02-04,0,0,0,0,0,0.0,""
   115929,Wreck Master 3D!,FY WM3D AN INTER4,Interstitial,KR,android,2021-02-04,1752,252,7,3,6,0.035,3
   115932,Truck'em All,FY TA IOS BANNER1,Banner,AO,ios,2021-02-07,40,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER1,Banner,AT,ios,2021-02-07,16585,1543,3,0,0,0.0033,2
   115932,Truck'em All,FY TA IOS BANNER1,Banner,DZ,ios,2021-02-07,300,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER1,Banner,GT,ios,2021-02-04,1640,120,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER1,Banner,PH,ios,2021-02-04,52117,95,33,0,0,0.036300000000000006,4
   115932,Truck'em All,FY TA IOS BANNER10,Banner,LY,ios,2021-02-05,0,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER11,Banner,AE,ios,2021-02-04,900,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER11,Banner,GT,ios,2021-02-07,580,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER11,Banner,PA,ios,2021-02-06,500,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER12,Banner,UA,ios,2021-02-07,440,40,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER12,Banner,US,ios,2021-02-07,8156101,695016,8849,32,0,13.289675770000008,5234
   115932,Truck'em All,FY TA IOS BANNER2,Banner,AD,ios,2021-02-05,0,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER2,Banner,AM,ios,2021-02-04,600,0,0,0,0,0.0,""
   115932,Truck'em All,FY TA IOS BANNER2,Banner,CL,ios,2021-02-06,83419,1979,17,0,0,0.013600000000000001,16
   ```

7. 数据更新

   ① Fyber返回的数据只精确到day层级，时区为UTC+0，无法调整至UTC+8时区。

   ② 每天的Fyber变现数据会在次日下午两点(北京时间)生成，因此每天下午两点后才能获取前一天的变现数据。

   ③ 每次可以更新三天的变现数据。

## 11. Inmobi

### 11.1 官方API文档

官方API文档链接为：https://support.inmobi.com/monetize/reporting-api

### 11.2 数据库表信息

表inmobi_ad_report: 存储精确到day层级的数据，唯一索引如图中红色key所示，app_id可以标识唯一操作系统下的唯一应用，因此加入唯一索引中。

![image-20210209102323319](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209102323319.png)

### 11.3 API数据获取及更新

#### 11.3.1 数据权限获取

1. 需要管理员登录变现平台后，生成API Key，并提供账户名称。

![image-20210209103213743](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209103213743.png)

2. 获取sessionID及accountID。成功生成后，有效期为24小时，在24小时内最多可以获取15次sessionID及accountID，由于每天会多次更新数据，因此建议每天获取后自动保存至本地进行重复调用：

   ① 请求头设置：

   ```python
   headers = {
               "userName":"{在此输入账户名称}",
               "secretKey":"{在此输入API Key}",
           }
   ```

   ② 发起GET请求，API地址为https://api.inmobi.com/v1.0/generatesession/generate/：

   ```python
   response = requests.get(url="https://api.inmobi.com/v1.0/generatesession/generate/",headers=headers)
   ```

   ③ 返回实例：

   ```json
   {
       "sessionId":"9e3a8b02c4d94acab365608ff76a8cb2",
       "accountId":"4f9c7e7f206041079963bea59e98902f"
   }
   ```

   根据获取的sessionID、accountID及Secret Key来获取变现数据。

#### 11.3.2 数据获取及更新

1. 请求头设置:

   ```python
   headers = {
               'Content-Type': 'application/json',
               'Accept': 'application/json',
               'accountId': '{在此输入accountId}',
               'secretKey': '{在此输入Secret Key}',
               'sessionId': '{在此输入sessionID}',
           }
   ```

2. 请求参数设置。由于inmobi单次请求最多返回5000行数据，因此在获取多天数据时可能需要循环获取。inmobi提供了'offset'参数来让我们可以选择从哪一行开始获取数据，如此一来，数据顺序的不变性就显得尤为重要。为保证每次发起请求时，固定日期范围内的数据顺序不会发生变动，必须明确设置'orderBy'及'orderType'参数。

   ```python
   data = {'reportRequest':
               {
                   'metrics': ['adRequests', 'adImpressions', 'clicks', 'earnings', 'servedImpressions',
                               'costPerMille','fillRate'], # 所需数据的列表
                   'timeFrame': '2020-02-06:2020-02-09', #日期范围，格式为'yyyy-mm-dd:yyyy-mm-dd'，前者为起始日期，后者为截止日期
                   'groupBy': ['date', 'country', 'platform', 'inmobiAppId', 'placement', 'adUnitType'], #分组维度列表
                   'offset': 5000, # 返回数据的起始行数，设为5000，则从5001行开始获取数据，设为0，则从第1行开始获取数据
                   'length': 5000, # 单次请求返回的数据量，最多为5000行
                   'orderBy': ['date', 'adRequests', 'adImpressions', 'clicks', 'earnings', 'servedImpressions',
                               'costPerMille', 'fillRate'], # 按哪些字段进行排序，以列表形式输入
                   'orderType': 'desc', # 排序方式，'desc'为降序，'asc'为升序
               }
           }
   ```

3. 发起POST请求，API地址为：https://api.inmobi.com/v3.0/reporting/publisher

   ```python
   reponse = requests.post(url='https://api.inmobi.com/v3.0/reporting/publisher', headers=headers, json=data)
   ```

4. 返回数据实例：

   ```json
   {
       "error":false,
       "respList":[
           {
               "adImpressions":1831,
               "adRequests":56048,
               "adUnitType":"Banner",
               "bundleId":"com.mpmf.truckemall",
               "clicks":1,
               "costPerMille":1.432,
               "country":"USA",
               "countryId":94,
               "date":"2021-02-09 00:00:00",
               "earnings":2.622,
               "fillRate":3.419,
               "inmobiAppId":1604888734755,
               "inmobiAppName":"Truck'em All",
               "placementId":1606809022020,
               "placementName":"IM_TA_IOS_BANNER_1.5",
               "platform":"iOS",
               "platformId":5,
               "servedImpressions":1916
           }
       ]
   }
   ```

5. 数据更新

   ①  inmobi返回的数据只精确到day层级，时区为UTC+0，无法调整至UTC+8时区

   ② 每次可以更新三天的数据。

## 12. Pangle

### 12.1 官方API文档

官方API文档链接为：https://www.pangleglobal.com/union/media/union/download/detail?id=37&osType=

### 12.2 数据库表信息

表pangle_ad_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示，app_id及package_name均可以标识唯一操作系统下的唯一应用，此处选pangle变现平台生成的app_id来加入唯一索引中。

![image-20210209112208994](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209112208994.png)

表pangle_ad_type: 根据pangle_ad_report表来自动更新表中的ad_id。由于pangle在返回数据时会出现广告类型为空的情况，根据ad_id又无法判断广告类型，因此每次更新pangle_ad_report表时，会根据ad_id来映射出pangle_ad_report中的ad_type。同时pangle_ad_report中新出现的ad_id会更新至pangle_ad_type中，再根据实际情况手动输入ad_type即可。

![image-20210209113644248](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209113644248.png)

### 12.3 API数据获取及更新

#### 12.3.1 数据权限获取

管理员登录变现平台后，可以在 接入>数据与内容接收 中获取SecurityKey及RoleId。

![image-20210209112529368](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209112529368.png)

#### 12.3.2 数据获取及更新

1. 在获取数据前，需要根据RoleId及Securitykey得到sign，pangle官方提供了sign并根据sign得到数据URL链接的生成方法，源码如下：

   ```python
   class PangleMediaUtil:
       user_id = 459 # 调用方法时用RoleId对该类属性重新赋值
       role_id = 459 # 调用方法时用RoleId对该类属性重新赋值
       secure_key = "xxxxsecure_key" #调用方法时用Securitykey对该类属性重新赋值
   
       version = "2.0" # API版本，默认为2.0
       sign_type_md5 = "MD5"
       KEY_USER_ID = "user_id" 
       KEY_ROLE_ID = "role_id" 
       KEY_VERDION = "version"
       KEY_SIGN    = "sign"
       KEY_SIGN_TYPE = "sign_type"
       PANGLE_HOST = "https://www.pangle.cn"
   
       @classmethod
       def sign_gen(self, params):
           """Fetches sign .
   
           Args:
               params: a dict need to sign
               secure_key: string
   
           Returns:
               A dict. For example:
   
               {'url': 'a=1&sign_type=MD5&t=2&z=a&sign=4d0e069c1776f665583bc0f39d9d59795aa3cdff',
               'sign': '4d0e069c1776f665583bc0f39d9d59795aa3cdff'}
           """
           result = {
               "sign": "",
               "url": "",
           }
           try:
               if not isinstance(params, dict):
                   print("invalid params: ", params)
                   return result
   
               if self.user_id != "":
                   params[self.KEY_USER_ID] = self.user_id
   
               if self.role_id != "":
                   params[self.KEY_ROLE_ID] = self.role_id
   
               params[self.KEY_VERDION] = self.version
               params[self.KEY_SIGN_TYPE] = self.sign_type_md5
   
               param_orders = sorted(params.items(), key=lambda x: x[0], reverse=False)
               raw_str = ""
               for k, v in param_orders:
                   raw_str += (str(k) + "=" + str(v) + "&")
               print ("raw sign_str: ", raw_str)
               if len(raw_str) == 0:
                   return ""
               sign_str = raw_str[0:-1] + self.secure_key
               print ("raw sign_str: ", sign_str)
   
               sign = hashlib.md5(sign_str.encode()).hexdigest()
               result[self.KEY_SIGN] = sign
               result["url"] = raw_str + "sign=" + sign
               return result
           except Exception as err:
               print ("invalid Exception", err)
           return result
   
       @classmethod
       def get_signed_url(self, params):
           return self.sign_gen(params).get("url", "")
   
       @classmethod
       def get_media_rt_income(self, params):
           result = self.get_signed_url(params)
           if result == "":
               return ""
           return self.PANGLE_HOST + "/union_pangle/open/api/rt/income?" + result
   ```

2. 请求参数设置，部分参数已经在PangleMediaUtil设置完毕，以下仅就其余部分参数进行设置：

   ```python
   params = {
               "currency": "usd", # 指定收入的货币形式，可设置为usd或者cny，默认为cny
               "date": '2021-02-09' # 数据日期，只能指定单日日期，不能指定日期范围
       		"time_zone": 8 # 数据的时区，可设置为0或者8，默认为8，即UTC+8时区
           }
   ```

3. 调用PangleMediaUtil类得到URL链接

   ```python
       PangleMediaUtil.user_id = {在此输入RoleId}  # 数值类型为int ，与role_id一致
       PangleMediaUtil.role_id = {在此输入RoleId}  # 数值类型为int
       PangleMediaUtil.secure_key = "{在此输入Securitykey}"
       url = PangleMediaUtil.get_media_rt_income(params) # 调用get_media_rt_income方法，返回sign及数据的URL链接
   ```

4. 返回实例（一个URL链接的字符串）：

   ```python
   'https://www.pangle.cn/union_pangle/open/api/rt/income?currency=usd&date=2021-02-09&role_id=46023&sign_type=MD5&user_id=46023&version=2.0&sign=661804e841f708cb7e7f1a3a6f5dbf86'
   ```

5. 直接GET上述URL即可获得数据：

   ```python
   response = requests.get(url)
   ```

6. 返回数据实例：

   ```json
   {
       "Code":"100",
       "Data":{
           "2021-02-09":[
               {
                   "ad_slot_id":945687376,
                   "ad_slot_type":5,
                   "app_id":5128071,
                   "app_name":"Stunt Car Jumping_android",
                   "click":790,
                   "click_rate":0.23,
                   "currency":"usd",
                   "date":"2021-02-09",
                   "ecpm":4.23,
                   "fill_rate":0,
                   "media_m_ssr":0,
                   "package_name":"www.stunt.stuntcarjumping",
                   "region":"za",
                   "request":0,
                   "return":0,
                   "revenue":14.33,
                   "show":3386,
                   "time_zone":8
               }
           ]
       },
       "Message":""
   }
   ```

7. 数据更新

   ① pangle只提供精确到day层级的数据，时区自由设置，一般情况下设置为UTC+8。

   ② 一次请求只能获取一天的数据，获取多天的数据需要循环发起请求。

   ③ 每次更新可以更新三天的数据。

# 二.投放平台数据接入

## 1. Facebook

### 1.1 官方API文档

官方API文档链接：https://developers.facebook.com/docs/marketing-api/insights/

### 1.2 数据库表信息

表fb_cost_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示。ad_account可以标识唯一的账户，因此加入唯一索引中。

![image-20210209144140831](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209144140831.png)

表sys_fb_market_info: 存储Facebook投放账户信息，唯一索引如红色Key所示。

![image-20210209144710564](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209144710564.png)

### 1.3 API数据获取及更新

#### 1.3.1 数据权限获取

登录Facebook商务管理平台后，需要获取对应的Access Token，可以让市场部门同事协助获取。对应的Token必须具有的权限为ads_read，进入https://developers.facebook.com/tools/debug/accesstoken/，输入对应的Access Token，可以查看Token的相关信息，如果没有对应的权限，需要重新获取，如下图所示：

![image-20210209150010673](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209150010673.png)

#### 1.3.2 数据获取及更新

1. 从sys_fb_market_info表中获取存储好的game_name, ad_account, access_token。

2.  请求参数设置：

   ```python
    data = {
                       'level': 'campaign', # 精确到campaign粒度
                       'access_token': '{在此输入access_token}', # 输入对应商务管理平台的access_token
                       'fields': "account_id,account_name,campaign_id,campaign_name,clicks,frequency,impressions,reach,spend,actions,action_values", # 所需字段
                        'time_increment':1, # 时间粒度，设为1即为按天返回数据，默认为'all_days'，即将所有天的数据进行聚合
                       'time_range': {'since': '2021-02-06', 'until': '2021-02-09'}, # 时间范围，字典格式，'since'接起始日期，'until'接截止日期，格式为'yyyy-mm-dd'
                       'breakdowns':'country', # 分组维度，此处设置为'country'
                   }
   ```

3. 发起POST请求，API地址为：https://graph.facebook.com/v9.0/act_{在此输入ad_account}/insights

   ```python
   re = requests.post(url='https://graph.facebook.com/v9.0/act_{在此输入ad_account}/insights', json=data)
   ```

4. 返回数据报告的report_run_id，需要根据该id获取最终变现数据：

   ```json
   {"report_run_id":"1139581813142561"}
   ```

5. 请求头设置：

   ```python
   params = {
       'access_token':'{在此输入access_token}', # 输入对应商务管理平台的access_token
       'limit':1000, # 官方文档未给出此参数的说明，但在测试时发现最大值为1000，默认为25，超出范围会给出下一页数据的url
                   }
   ```

6. 发起GET请求，API地址为：https://graph.facebook.com/v9.0/{在此输入report_run_id}/insights

   ```python
   response = requests.get('https://graph.facebook.com/v9.0/{在此输入report_run_id}/insights',params=params)
   ```

7. 数据返回实例，如果返回的数据超过1000行，会在末尾返回返回下一页的URL链接，获取该链接的数据即可：

   ```json
   {
       "data":[
           {
               "account_id":"3252382668140841",
               "account_name":"JC3D-IOS-01",
               "campaign_id":"23846504533610705",
               "campaign_name":"install-I945-1104-US-类似受众new-不出价",
               "clicks":"3518",
               "frequency":"1.046346",
               "impressions":"134468",
               "reach":"128512",
               "spend":"1294.89",
               "actions":[
                   {
                       "action_type":"app_custom_event.other",
                       "value":"34263"
                   },
                   {
                       "action_type":"comment",
                       "value":"17"
                   },
                   {
                       "action_type":"app_custom_event.fb_mobile_activate_app",
                       "value":"6627"
                   },
                   {
                       "action_type":"onsite_conversion.post_save",
                       "value":"2"
                   },
                   {
                       "action_type":"link_click",
                       "value":"3618"
                   },
                   {
                       "action_type":"mobile_app_install",
                       "value":"1891"
                   },
                   {
                       "action_type":"post",
                       "value":"8"
                   },
                   {
                       "action_type":"post_reaction",
                       "value":"38"
                   },
                   {
                       "action_type":"video_view",
                       "value":"49566"
                   },
                   {
                       "action_type":"omni_custom",
                       "value":"34263"
                   },
                   {
                       "action_type":"post_engagement",
                       "value":"53249"
                   },
                   {
                       "action_type":"page_engagement",
                       "value":"53249"
                   },
                   {
                       "action_type":"omni_activate_app",
                       "value":"6627"
                   },
                   {
                       "action_type":"omni_app_install",
                       "value":"1891"
                   }
               ],
               "date_start":"2021-02-08",
               "date_stop":"2021-02-08",
               "country":"US"
           }
       ]
   }
   ```

9. 数据更新

   ① Facebook的投放数据为UTC+8时区，直接存储即可。

   ② 每次可以更新三天的数据

   ③ 由于每次请求必须根据ad_account来发起，因此有多少个ad_account就需要发起多少次请求，建议在sys_fb_market_info中及时将不进行投放的ad_account账户状态设置为0，避免过多的请求。

## 2. Google

### 2.1 官方API文档

官方API文档地址： https://developers.google.cn/google-ads/api/docs/reporting/example?hl=de

### 2.2 数据库表信息

由于权限问题，暂未获取到Google投放平台的原始数据，因此未单独建立数据表，目前从af_cost_report表中获取相应的投放数据。

## 3. Applovin

### 3.1 官方API文档

官方API文档地址：https://growth-support.applovin.com/hc/zh-cn/articles/115000784688-%E5%9F%BA%E6%9C%AC%E6%8A%A5%E8%A1%A8API

### 3.2 数据库表信息

表applovin_cost_report: 存储精确到hour层级的数据，唯一索引设置如图中红色Key所示，由于applovin平台的特殊性，单个应用在不同操作系统下共用同一个包名，因此将app_id及platform都加入唯一索引中。此外，少数情况下，由于中文的特殊性，同一个campaign_id对应着不同的campaign_name，因此同时将campaign_id及campaign_name加入唯一索引。

![image-20210209154256499](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209154256499.png)

### 3.3 API数据获取及更新

#### 3.3.1 数据权限获取

获取MAX数据需要使用Report Key，由MAX账户管理者提供。

#### 3.3.2 数据获取及更新

1. 请求参数设置：

   ```python
    params = {
               'start': '2021-02-06', # 起始日期，格式为'yyyy-mm-dd'
               'end':'2021-02-09', # 截止日期，格式为'yyyy-mm-dd'
               'api_key':'{在此输入API Key}',
               'format':'json', # 接收数据的返回格式
               'report_type': 'advertiser', # 数据报告类型，此处advertiser表示为广告投放数据
    'columns':'day,hour,campaign,country,platform,campaign_id_external,campaign_package_name,impressions,clicks,conversions,cost', #返回的字段
           }
   ```

2. 发起GET请求，API地址为：

   ```python
   response = requests.get('http://r.applovin.com/report',params = params)
   ```

3. 数据返回实例

   ```json
   {
       "code":200,
       "results":[
           {
               "day":"2021-02-08",
               "hour":"17:00",
               "campaign":"BH_IOS_T0+T1+T2+T3",
               "country":"tw",
               "platform":"ios",
               "campaign_id_external":"4f23bd6690d40e7586719f10d0a1424d",
               "campaign_package_name":"com.mpmf.banghero",
               "impressions":"1",
               "clicks":"1",
               "conversions":"0",
               "cost":"0"
           },
           {
               "day":"2021-02-08",
               "hour":"13:00",
               "campaign":"BH_IOS_T0+T1+T2+T3",
               "country":"dk",
               "platform":"ios",
               "campaign_id_external":"4f23bd6690d40e7586719f10d0a1424d",
               "campaign_package_name":"com.mpmf.banghero",
               "impressions":"2",
               "clicks":"0",
               "conversions":"0",
               "cost":"0"
           }
       ]
   }
   ```

4. 数据更新

   ① applovin返回小时层级的数据，时区为UTC+0，可以据此调整为UTC+8时区进行存储。

   ② 每次可以更新三天的历史数据

## 4. IronSource

### 4.1 官方API文档

官方API文档链接：https://developers.ironsrc.com/ironsource-mobile/general/reporting-api-v2/#step-2

### 4.2 数据库表信息

表iron_cost_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示。

![image-20210209161815575](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209161815575.png)

### 4.3 API数据获取及更新

#### 4.3.1 数据权限获取

与IronSource变现平台数据权限获取一致，可以直接使用相同的Secret Key及Refresh Token，并用同样的方法生成Authentication Token。

#### 4.3.2 数据获取及更新

1. 请求头设置：

   ```Python
   headers = {
               'Authorization': 'Bearer {在此输入Authentication Token}' ,
           }
   ```

2. 请求参数设置：

   ```python
   params = {
               'startDate':'2021-02-06', # 起始日期，格式为'yyyy-mm-dd'
               'endDate':'2021-02-09', # 截止日期，格式为'yyyy-mm-dd'
               'metrics': 'impressions,clicks,completions,installs,spend', # 所需字段
               'breakdowns': 'day,campaign,country,os,title', # 分组维度
               'format':'json', # 返回数据格式，可设置为json或者csv，默认为json
           }
   ```

3. 发起GET请求，API地址为：https://api.ironsrc.com/advertisers/v2/reports

   ```Python
   response = requests.get(url='https://api.ironsrc.com/advertisers/v2/reports',headers=headers,params=params)
   ```

4. 数据更新

   ① IronSource返回的数据为UTC+0时区，不能调整至UTC+8时区。

   ② 每次可更新三天的历史数据。

## 5. Unity

### 5.1 官方API文档

官方API文档链接：http://unityads.unity3d.com/help/advertising/stats-api

### 5.2 数据库表信息

表unity_cost_report: 存储精确到hour层级的数据，其唯一索引如图中红色Key所示

![image-20210209163015097](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209163015097.png)

表unity_cost_report_by_day: 存储精确到day层级的数据，其结构与unity_cost_report基本一致。

![image-20210209164731867](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209164731867.png)

### 5.3 API数据获取及更新

#### 5.3.1 数据权限获取

需要管理员提供API Key及Orgnization_id，与变现平台不同。

#### 5.3.2 数据获取及更新

1. 请求头设置：

   ```Python
   headers = {
               'Accept': 'application/json',# 接收json格式的数据
           }
   ```

2. 请求参数设置：

   ```Python
   params = {
               'apikey': '{在此输入API Key}',
               'start':'2020-12-31T00:00:00', # 起始日期，ISO格式，即'yyyy-mm-ddTHH:MM:SS'
               'end':'2021-01-18T00:00:00', # 截止日期日期，ISO格式，即'yyyy-mm-ddTHH:MM:SS'
               'splitBy':'country,campaign,platform,target', # 分组维度
               'fields':'timestamp,campaign,country,target,platform,starts,views,clicks,installs,spend', # 所需字段
               'scale':'hour', # 时间粒度，可设置为all/year/quarter/month/week/day/hour，默认为all
           }
   ```

3. 发起GET请求，API地址为：https://stats.unityads.unity3d.com/organizations/{在此输入Organization_id}/reports/acquisitions

   ```python
   response  = requests.get('https://stats.unityads.unity3d.com/organizations/{在此输入Organization_id}/reports/acquisitions',params=params,headers=headers)
   ```

4. 返回数据实例：

   ```json
   {
   	'code': 200,
   	'results': [{
   		'day': '2021-02-08',
   		'hour': '17:00',
   		'campaign': 'BH_IOS_T0+T1+T2+T3',
   		'country': 'tw',
   		'platform': 'ios',
   		'campaign_id_external': '4f23bd6690d40e7586719f10d0a1424d',
   		'campaign_package_name': 'com.mpmf.banghero',
   		'impressions': '1',
   		'clicks': '1',
   		'conversions': '0',
   		'cost': '0'
   	}]
   }
   ```

5. 数据更新

   ① unity返回的是精确到hour层级的数据，时区为UTC+0，可以调整为UTC+8时区进行存储

   ② 每次可以更新三天的历史数据

## 6. Mintegral

### 6.1 官方API文档

官方API文档链接（PDF版本）：https://www.mintegral.com/wp-content/uploads/2018/10/1-Mintegral_Reporting-API.pdf

### 6.2 数据库表信息

表mintegral_cost_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示。

![image-20210209165308213](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209165308213.png)

### 6.3 API数据获取及更新

#### 6.3.1 数据权限获取

1. 需要管理员提供API Key以及账户名称。

2. 需要获取当前时间戳，加上API Key，进行MD5编码后生成access token:

   ```Python
   time_now = str(round(int(time.time()), 0)) # 当前时间的时间戳，精确到秒
   time_md5 = hashlib.md5(time_now.encode()).hexdigest() # 将时间戳进行MD5编码
   api_key = '{在此输入API Key}'  
   string = api_key + time_md5 # 将API Key与编码后的时间戳拼接起来
   token = hashlib.md5(string.encode()).hexdigest() # 对拼接后的字符串进行MD5编码，即为所需的access token
   ```

#### 6.3.2 数据获取及更新

1. 请求参数设置，需要根据返回数据中显示的总页数，设置'page'参数，循环获取所有页的数据：

   ```python
   params = {
                   'username': '{在此输入用户名}',
                   'token': '{在此输入access token}',
                   'timestamp': '1612861210', # 当前时间戳，与生成token时的时间戳一致
                   'start_time':1612540800, # 起始日期，需转化为时间戳，精确到秒，数值格式为整型
                   'end_time':1612800000,# 截止日期，需转化为时间戳，精确到秒，数值格式为整型
                   'page': 1, # 获取第几页数据
                   'timezone': 8, # 时区，默认为8，及UTC+8时区
                   'dimension':'location', # 分组维度，此处为国家
               }
   ```

2. 发起GET请求，API地址为：http://data.mintegral.com/v4.php?m=advertiser

   ```python
   response = requests.get('http://data.mintegral.com/v4.php?m=advertiser', params=params)
   ```

3. 数据返回实例：

   ```json
   {
       "code":200,
       "message":"success",
       "page":"1", # 当前为第几页数据
       "per_page":"5000",
       "page_count":"1",  # 数据总页数
       "total_count":"1160",
       "data":[
           {
               "click":0,
               "impression":1,
               "install":0,
               "offer_id":43818,
               "uuid":"ss_WHOR_AN_T0",
               "preview_link":"https://play.google.com/store/apps/details?id=www.wheelroad.wheeloffroad",
               "offer_name":"WHOR_AN_T0",
               "geo":[
                   "JP",
                   "KR",
                   "TW",
                   "US"
               ],
               "platform":"android",
               "package_name":"www.wheelroad.wheeloffroad",
               "spend":0,
               "location":"vn",
               "date":"2021-02-08",
               "currency":"USD",
               "utc":"+8"
           },
           {
               "click":41,
               "impression":255,
               "install":4,
               "offer_id":43818,
               "uuid":"ss_WHOR_AN_T0",
               "preview_link":"https://play.google.com/store/apps/details?id=www.wheelroad.wheeloffroad",
               "offer_name":"WHOR_AN_T0",
               "geo":[
                   "JP",
                   "KR",
                   "TW",
                   "US"
               ],
               "platform":"android",
               "package_name":"www.wheelroad.wheeloffroad",
               "spend":1.402,
               "location":"us",
               "date":"2021-02-08",
               "currency":"USD",
               "utc":"+8"
           }
       ]
   }
   ```

4. 数据更新

   ① mintegral返回的数据为精确到day层级的数据，时区为UTC+8，可直接存储。

   ② 每次可更新三天的历史数据

## 7. Vungle

### 7.1 官方API文档

官方API文档链接：https://support.vungle.com/hc/zh-cn/articles/115003842687#%E4%BD%BF%E7%94%A8%E7%BB%B4%E5%BA%A6%E5%8F%82%E6%95%B0-0-8

### 7.2 数据库表信息

表vungle_cost_report: 存储精确到day层级的数据，唯一索引如图中红色Key所示。

![image-20210209171217869](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209171217869.png)

### 7.3 API数据获取及更新

#### 7.3.1 数据权限获取

需要管理员登录投放平台后获取API Key。

#### 7.3.2 数据获取及更新

1. 请求头设置：

   ```Python
   headers = {
               'Authorization': 'Bearer {在此输入API Key}',
               'Vungle-Version': '1', #API版本，目前为1.0
               'Accept': 'application/json', #返回数据格式，可设置为text/csv或者application/json，默认为text/csv
           }
   ```

2. 请求参数设置：

   ```python
   params = {
               'dimensions': 'date,application,campaign,country,platform', # 分组维度
               'aggregates': 'views,clicks,installs,spend', # 所需数据字段
               'start': '2020-11-25', # 起始日期，格式为'yyyy-mm-dd'
               'end': '2020-12-29', # 截止日期，格式为'yyyy-mm-dd'
           }
   ```

3. 发起GET请求，API地址为：https://report.api.vungle.com/ext/adv/reports/spend

   ```Python
   response = requests.get('https://report.api.vungle.com/ext/adv/reports/spend', headers=headers, params=params)
   ```

4. 返回数据实例：

   ```json
   [
       {
           "application id":"5f681ddcbc1baa00159e2dab",
           "application name":"Crash Race.io",
           "campaign id":"5f6824dbdfa15d0015ae86bf",
           "campaign name":"CRI-IOS-US-0921-D454",
           "clicks":0,
           "country":"US",
           "date":"2021-02-07",
           "installs":0,
           "platform":"iOS",
           "spend":0,
           "views":2
       },
       {
           "application id":"5f681ddcbc1baa00159e2dab",
           "application name":"Crash Race.io",
           "campaign id":"5f6824dbdfa15d0015ae86bf",
           "campaign name":"CRI-IOS-US-0921-D454",
           "clicks":1,
           "country":"US",
           "date":"2021-02-06",
           "installs":0,
           "platform":"iOS",
           "spend":0,
           "views":1
       }
   ]
   ```

5. 数据更新

   ① vungle只返回精确到day层级的数据，时区为UTC+0，无法调整至UTC+8时区。

   ② 每次可以更新三天的历史数据。

## 8. SnapChat

### 8.1 官方API文档

官方API文档链接：https://developers.snapchat.com/api/docs/?python#create-an-audience-segment

### 8.2 数据库表信息

由于权限问题，暂未获取SnapChat投放平台的原始数据，因此未单独建立数据表，目前采用af_cost_report表中的数据。

### 8.3 API数据获取及更新

暂无

# 三. 中介平台数据接入

## 1. AppsFlyer

### 1.1 官方API文档

官方API文档链接：https://support.appsflyer.com/hc/zh-cn/categories/201132313-%E6%8A%A5%E5%91%8A

### 1.2 数据库表信息

表af_cost_report: 存储精确到day层级的投放数据，综合了各投放平台的数据。

![image-20210209173744848](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209173744848.png)

表af_dau_report: 存储精确到day层级的投放数据，存放用户活跃数据即用户留存数据。

![image-20210209174047319](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209174047319.png)

表sys_appsflyer_info: 存储AppsFlyer中接入的应用信息，包括包名、应用名称、操作系统名称，需要手动更新维护。

![image-20210209180249274](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209180249274.png)

### 1.3 API数据获取及更新

#### 1.3.1 数据权限获取

需要管理员提供Access Token。

#### 1.3.2 数据获取及更新

1. 由于所需的花费及用户活跃数据需要精确到国家、投放渠道、campaign等字段，因此只有借助AppsFlyer中的数据透视表来获取。按照指定需求生成透视表后，可以获取响应的API链接。

   ![image-20210209174710681](C:\Users\PC\AppData\Roaming\Typora\typora-user-images\image-20210209174710681.png)

2. 上述数据透视表的生成，可以直接通过参数的设置来实现，app_id需要从sys_appsflyer_info表中获取：

   ```python
   """以下为生成af_cost_report表的请求参数"""
   params = {
               "api_token":"{在此输入access token}",
               "from": "2021-02-06", # 起始日期，格式为'yyyy-mm-dd'
               "to": "2021-02-08", # 截止日期，格式为'yyyy-mm-dd'
               "timezone":"Asia/Shanghai", # 时区，设置为北京时区，即UTC+8
               'app_id':'www.wheelroad.wheeloffroad,id1519552096,www.huolala.truckemall',# 所需获取的应用数据，应用id拼接成字符串，以逗号分隔
               'groupings':'app_id,af_c_id,pid,c,geo,install_day', # 分组维度值
               'kpis':'clicks,cost,installs,impressions', #KPI关键绩效指标值
               'format':'json',
           }
   ---------------------------------------------------------------------------------------------------------------
   """以下为生成af_dau_report表的请求参数"""
   params = {
               "api_token":"4e0b3808-42ed-4244-9b53-cb3f326cfc17",
               "from": "2021-02-06", 
               "to": "2021-02-08", 
               "timezone":"preferred",
               'app_id':'www.wheelroad.wheeloffroad,id1519552096,www.huolala.truckemall',
               'groupings':'app_id,af_c_id,pid,c,geo,install_day',
            'kpis':'activity_average_dau,retention_day_1,retention_day_2,retention_day_3,retention_day_4,retention_day_5,retention_day_6',
               'format':'json',
           }
   ```

3. 发起GET请求，数据透视表对应的API地址为：https://hq1.appsflyer.com/master/v4

   ```python
   re = requests.get('https://hq1.appsflyer.com/master/v4',params=params)
   ```

4. 数据更新

   ① 由于AppsFlyer透视表提供的DAU及留存数据在次日下午三点左右才会开始更新，因此af_dau_report会在每天下午三点开始更新前一天的数据，由于历史留存数据每天都会更新，因此每次需要更新7天以上的历史数据。

   ② AppsFlyer透视表提供的投放数据会不断更新，但用户下载量数据在次日下午三点左右才会更新完全，因此af_cost_report每天上午和下午都会更新，但下午三点开始需提高更新频次，以保证更新的数据完全。每次可以更新三天的历史数据。

### 1.4 说明

由于归因逻辑的不同，AppsFlyer提供的投放数据与各投放平台存在一定的差异，花费数据基本一致，但广告展示次数、下载量等会存在较大的误差。

## 2. MAX

### 2.1说明

1. MAX整合了各变现平台的变现数据，均精确到小时层级，原始数据时区为UTC+0，可根据小时调整至UTC+8时区，但其数据与各平台提供的数据存在一定的误差。
2. 获取MAX数据的方式与获取Applovin变现数据一致，只需要更改请求参数中的'filter_network'对应的值即可，如IronSource平台对应的值为'IRONSOURCE_NETWORK'，其余平台的名称可从MAX变现平台中获取。

### 2.1 已获取的平台数据

由于部分变现平台的数据无法调整为UTC+8时区，因此为这些平台分别从MAX获取了数据，并调整至UTC+8时区，目前单独接入的平台有以下几个，其表与applovin_ad_report_aggregated表一致：

| 变现平台名称 |     MAX中名称      |       数据库表名       |
| :----------: | :----------------: | :--------------------: |
|  IronSource  | IRONSOURCE_NETWORK |   max_iron_ad_report   |
|    Vungle    |   VUNGLE_NETWORK   |  max_vungle_ad_report  |
|   Adcolony   |  ADCOLONY_NETWORK  | max_adcolony_ad_report |
|    Fyber     |   FYBER_NETWORK    |  max_fyber_ad_report   |
|    Inmobi    |   INMOBI_BIDDING   |  max_inmobi_ad_report  |
|              |                    |                        |
