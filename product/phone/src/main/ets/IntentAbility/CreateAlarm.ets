/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import IntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import { LogUtil, AlarmInfo } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'

const LOG_TAG: string = 'testTag-IntentExecutor-CreateAlarm';

export default class CreateAlarmIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string, param: Record<string, Object>):
    Promise<insightIntent.ExecuteResult> {
    LogUtil.info(LOG_TAG, 'onExecuteInUIAbilityBackgroundMode start , name is ', name, 'param is ', JSON.stringify(param));
    let result: insightIntent.ExecuteResult;
    if (name !== 'CreateAlarm') {
      LogUtil.warn(LOG_TAG, 'Unsupported intentName %{public}s', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
        }
      };
      LogUtil.info(LOG_TAG, 'CreateAlarm failed,Not Support intent', JSON.stringify(result));
      return result;
    }

    // 开始创建
    // 至少得有一个参数
    if (Object.keys(param).length < 1) {
      result = {
        code: 10030006,
        result: {
          message: 'no params',
        }
      };
      LogUtil.info(LOG_TAG, ' CreateAlarm failed , at least need one param', JSON.stringify(result));
      return result
    }

    result = await CreateAlarm(param);
    LogUtil.info(LOG_TAG, 'CreateAlarmResult Execute UIAbility in foreground mode finished, result %{public}s', JSON.stringify(result));
    return result;
  }
}

//创建闹钟
export async function CreateAlarm(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
  let result: insightIntent.ExecuteResult
  LogUtil.info(LOG_TAG, 'CreateAlarm param: ', JSON.stringify(param));

  let newDate = new Date(param.alarmTime as string)

  const alarmInfo: AlarmInfo = {
    id: '',
    title: param.alarmTitle ? param.alarmTitle as string : '闹钟',
    hour: newDate.getHours(),
    minute: newDate.getMinutes(),
    second: newDate.getSeconds(),
    daysOfWeek: [], // 设置每个星期哪一天重复提醒，范围从 1 到 7
    alarmTime: param.alarmTime as number, // 最近一次响铃时间，使用 Date 的 getTime 方法获取
    enabled: param.alarmState as boolean, // 是否打开
    ringPath: '',
    ringDuration: param.alarmRingDuration ? param.alarmRingDuration as number : 5, // 响铃时间
    snoozeDuration: param.alarmSnoozeDuration ? param.alarmSnoozeDuration as number : 10, // 再响间隔
    snoozeTimes: param.alarmSnoozeTotal ? param.alarmSnoozeTotal as number : 3, // 再响次数
    snoozeCount: 0, // 某次响铃中，已再响的次数，与 snoozeTimes 相等时，不再重新响铃
    alarmTimeIntent: param.alarmTime as number,
  }

  const currentTime = new Date().getTime();
  if (alarmInfo.alarmTime && alarmInfo.alarmTime < currentTime) {
    result = {
      code: 10030009,
      result: {
        message: 'CreateAlarm failed,the alarmTime need greater than the currentTime',
        entityName: 'Alarm',
      }
    }
    LogUtil.info(LOG_TAG, ' CreateAlarm failed, result:  ', JSON.stringify(result));
    return result
  }
  LogUtil.info(LOG_TAG, 'before addAlarm alarmInfo:  ', JSON.stringify(alarmInfo));
  await AlarmManager.addAlarm(alarmInfo, true);
  //排序
  let sortAlarmList = await AlarmManager.sortAlarmListById();
  LogUtil.info(LOG_TAG, 'addAlarm sortAlarmList:  ', JSON.stringify(sortAlarmList));
  if (sortAlarmList) {
    const resultAlarm = sortAlarmList[sortAlarmList.length - 1]
    LogUtil.info(LOG_TAG, 'addAlarm resultAlarm:  ', JSON.stringify(resultAlarm));
    result = {
      code: 0,
      result: {
        entityName: 'Alarm',
        entityId: resultAlarm.id!,
        alarmTime: resultAlarm.alarmTimeIntent ? resultAlarm.alarmTimeIntent : -1,
        alarmTitle: resultAlarm.title,
        alarmState: resultAlarm.enabled ? 1 : 0,
        alarmSnoozeDuration: resultAlarm.snoozeDuration,
        alarmSnoozeTotal: resultAlarm.snoozeTimes,
        alarmRingDuration: resultAlarm.ringDuration
      }
    }
    LogUtil.info(LOG_TAG, 'addAlarm success result:  ', JSON.stringify(result))
    return result
  }
  result = {
    code: -100,
    result: {
      message: 'CreateAlarm failed,because can not find the alarm list or the latest alarm',
      entityName: 'Alarm',
    }
  }
  LogUtil.info(LOG_TAG, ' CreateAlarm failed, result:  ', JSON.stringify(result));
  return result

}