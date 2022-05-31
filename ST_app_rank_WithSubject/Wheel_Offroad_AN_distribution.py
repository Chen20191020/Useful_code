# -*- coding:utf-8
import csv
import time
from datetime import datetime, timedelta, date
from retry import retry
import requests

# from email_file import Email_file


class WheelOffroad(object):
    def __init__(self, install_startTime, install_endTime, event_startTime, event_endTime):
        self.token = "bjMIEMvVgCYH3ngtjTw1hngzuKpdqSkI1GoO1A0NkJQdubjrmHmYBGCH8HRE20tU"
        self.headers = {
            "content-type": "application/json",
            "accept": "application/json",
        }
        self.dis_data = None
        self.ins_data = None
        self.install_startTime = install_startTime
        self.install_endTime = install_endTime
        self.event_startTime = event_startTime
        self.event_endTime = event_endTime

    @retry(delay=3,tries=5)
    def distribution_data(self):
        """

        :return:获取WOR分布分析下的数据
        """
        api_path = "open/distribution-analyze"  # API地址，此处对应分布分析的API

        data = {
            "eventView": {
                "endTime": self.event_endTime,
                "firstDayOfWeek": 1,
                "groupBy": [
                    {
                        "columnDesc": "app_version",
                        "columnName": "app_version",
                        "propertyRange": "",
                        "tableType": "user"
                    }
                ],
                "recentDay": "StartToNow",
                "startTime": self.event_startTime,
                "timeParticleSize": "total"
            },
            "events": [
                {
                    "analysisDesc": "",
                    "customEvent": "mpmf_Progress_Finish.TIMES",
                    "customFilters": [

                    ],
                    "eventName": "自定义指标",
                    "eventNameDisplay": "",
                    "filts": [
                        {
                            "columnDesc": "",
                            "columnName": "#vp@media_source",
                            "comparator": "notEqual",
                            "ftv": [
                                "organic"
                            ],
                            "tableType": "user",
                            "timeUnit": ""
                        },
                        {
                            "columnDesc": "",
                            "columnName": "install_time",
                            "comparator": "range",
                            "ftv": [
                                self.install_startTime,
                                self.install_endTime
                            ],
                            "tableType": "user",
                            "timeUnit": ""
                        }
                    ],
                    "formulation": {
                        "formulationDeps": [
                            {
                                "event": {
                                    "eventDesc": "mpmf_Progress_Finish",
                                    "eventName": "mpmf_Progress_Finish"
                                },
                                "property": {

                                },
                                "quota": {
                                    "quotaDesc": "次数",
                                    "quotaName": "TIMES"
                                }
                            }
                        ]
                    },
                    "intervalType": "discrete",
                    "quota": "",
                    "relation": "and",
                    "type": "customized"
                }
            ],
            "projectId": 6
        }

        url = "http://101.32.192.62:8992/{api_path}?token={token}".format(api_path=api_path, token=self.token)
        dis_response = requests.post(url, headers=self.headers, json=data)
        time.sleep(10)
        # print(dis_response.text)
        self.dis_data = dis_response.json()
        # with open('dis_data.json','w',encoding='utf8') as dis:
        #     json.dump(self.dis_data,dis,indent=2)

    @retry(delay=3, tries=5)
    def install_data(self):
        """

        :return: 获取注册用户数据
        """
        api_path = "open/event-analyze"
        data = {
            "eventView": {
                "comparedByTime": False,
                "comparedRecentDay": "",
                "endTime": self.install_endTime,
                "filts": [

                ],
                "groupBy": [
                    {
                        "columnDesc": "app_version",
                        "columnName": "app_version",
                        "propertyRange": "",
                        "tableType": "user"
                    }
                ],
                "recentDay": "",
                "relation": "and",
                "startTime": self.install_startTime,
                "timeParticleSize": "day"
            },
            "events": [
                {
                    "analysis": "TRIG_USER_NUM",
                    "eventName": "install",
                    "filts": [
                        {
                            "columnDesc": "",
                            "columnName": "#vp@media_source",
                            "comparator": "notEqual",
                            "ftv": [
                                "organic"
                            ],
                            "tableType": "event",
                            "timeUnit": ""
                        },
                        {
                            "columnDesc": "lifetime_生命周期天数",
                            "columnName": "#vp@lifetime",
                            "comparator": "equal",
                            "ftv": [
                                "0"
                            ],
                            "tableType": "event",
                            "timeUnit": ""
                        }
                    ],
                    "quota": "",
                    "relation": "and",
                    "type": "normal"
                }
            ],
            "projectId": 6
        }
        url = "http://101.32.192.62:8992/{api_path}?token={token}".format(api_path=api_path, token=self.token)
        ins_response = requests.post(url, headers=self.headers, json=data)
        # print(ins_response.text)
        time.sleep(10)
        self.ins_data = ins_response.json()
        # with open('install_data.json','w',encoding='utf8') as ins:
        #     json.dump(self.ins_data,ins,indent=2)

    def data_process(self):
        """

        :return:1. 返回处理完成的数据，格式为字典列表;2. 返回值字段的列表
        """
        dic_list = []
        dic_install = dict()

        # 计算注册总人数,并生成注册人数分布的字典
        total_install = 0
        for row in self.ins_data['data']['y'][0]['install.TRIG_USER_NUM']:
            app_version = row.get('group_cols')[0]
            dic_install[app_version] = int(row.get('values')[0])
            total_install += int(row['values'][0])
        dic_install['总体'] = total_install
        # 生成注册人数的字典

        # 计算事件发生人数分布情况
        x_value = self.dis_data['data']['x'][0]  # 获取x轴的时间值
        distribution_list = list(int(i) for i in self.dis_data['data']['distribution_interval'])

        for line in self.dis_data['data']['y'][x_value]:
            dic_num = dict()
            dic_ratio = dict()

            dic_num['事件起始时间'] = self.event_startTime
            dic_num['事件截止时间'] = self.event_endTime
            dic_ratio['事件起始时间'] = self.event_startTime
            dic_ratio['事件截止时间'] = self.event_endTime
            dic_num['指标'] = '人数'
            dic_ratio['指标'] = '比例'

            app_version = line['groupCols'][0]
            dic_num['app_version'] = app_version
            dic_ratio['app_version'] = app_version
            dic_num['首日注册用户数'] = dic_install.get(app_version)
            dic_ratio['首日注册用户数'] = dic_install.get(app_version)
            for times in distribution_list:
                lis_id = distribution_list.index(times)  # 获取该值的索引
                value_list = line['values']
                dic_num[times] = sum(value_list[lis_id:])  # 计算总人数
                dic_ratio[times] = '%.2f%%' % (
                        sum(value_list[lis_id:]) / dic_install.get(app_version, 1) * 100)  # 计算人数占比，保留两位小数且以百分数格式存储

            dic_list.append(dic_num)
            dic_list.append(dic_ratio)
        return dic_list, distribution_list


def main():
    install_startTime = datetime.strptime('2021-01-08 00:00:00', '%Y-%m-%d %H:%M:%S')  # 用户注册的起始时间，精确到秒
    event_endTime = datetime.now().replace(microsecond=0, hour=23, minute=59, second=59) + timedelta(
        days=-1)  # 事件的截止时间，截止到前一天的最后一秒
    i = 0
    data = []
    header = ['事件起始时间', '事件截止时间', 'app_version', '首日注册用户数', '指标']
    value_list = []  # 存储返回的值字段
    file = 'E:\\pythonProject\\ThinkingData\\Wheel_Offroad_Android_{date}.csv'.format(date=event_endTime.strftime('%Y-%m-%d'))
    with open(file, 'w', encoding='gbk', newline='') as wf:
        while install_startTime <= event_endTime:
            i += 1
            install_endTime = install_startTime + timedelta(hours=23, minutes=59, seconds=59)
            event_startTime = install_startTime
            # event_endTime = date.today().strftime('%Y-%m-%d')+' 23:59:59'
            print('安装用户起始时间为：{start}-{end}'.format(start=install_startTime, end=install_endTime),
                  '事件截止时间为：{event_start}-{event_end}'.format(event_start=event_startTime, event_end=event_endTime))
            wor = WheelOffroad(install_startTime.strftime('%Y-%m-%d %H:%M:%S'),
                               install_endTime.strftime('%Y-%m-%d %H:%M:%S'),
                               event_startTime.strftime('%Y-%m-%d %H:%M:%S'),
                               event_endTime.strftime('%Y-%m-%d %H:%M:%S'))
            wor.distribution_data()
            wor.install_data()
            dic_list, header_list = wor.data_process()
            value_list.extend(header_list)  # 接收返回的值字段
            data.extend(dic_list)  # 接收返回的字典列表数据

            install_startTime = install_startTime + timedelta(days=1)
            # 设置等待时间
            time.sleep(5)
            if i % 3 == 0:
                # break
                time.sleep(10)

        # 写入文件
        value_set = list(sorted(set(value_list)))  # 值字段去重并排序
        header.extend(value_set)  # 合并生成最终的字段
        writer = csv.DictWriter(wf, fieldnames=header)
        writer.writeheader()
        writer.writerows(data)

    # # 发送文件
    # username = 'liumenghao@mpmfgame.com'  # 腾讯企业邮箱登录名
    # password = 'Lmh854471244k'  # 腾讯企业邮箱登录密码
    # sender = 'liumenghao@mpmfgame.com'  # 发送者
    # sender_name = '刘梦豪'  # 发送者昵称，可不设置
    # receiver = '8xn-pycn3xlqa@dingtalk.com'  # 接收者
    # receiver_name = '赵灵丽'  # 接收者昵称，可不设置
    # subject = '{name}分布分析表'.format(name=file.split('\\')[-1].strip())  # 邮件主题
    # message = """
    #     附件为{name}的数据表，如有疑问，请及时联系BI数据中台相关同事。
    #
    #
    #
    # BI数据中台
    # {date}
    #     """.format(name=file.split('\\')[-1].strip(), date=date.today().strftime('%Y-%m-%d'))  # 邮件正文内容
    # email = Email_file(sender, receiver)  # 实例化邮件发送方法，并传入发送者和接收者邮箱
    # email.content(subject, message, file, sender_name, receiver_name)  # 传入邮件内容，包括主题，正文，附件，发送者及接收者昵称
    # email.send(username, password)  # 连接腾讯企业邮箱服务器，传入登录名及密码


if __name__ == '__main__':
    main()
