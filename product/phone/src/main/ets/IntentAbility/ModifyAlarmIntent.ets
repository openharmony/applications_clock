/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import { LogUtil, TimeUtil } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'
import { AlarmInfo } from '@hmos/common/src/main/ets/manager/types'
import IntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import { AlarmServiceManager } from '@hmos/alarmclock';

const TEST_ABILITY: string = 'testTag-IntentExecutor-modifyAlarm';


export default class ModifyAlarmIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string, param: Record<string, Object>):
    Promise<insightIntent.ExecuteResult> {
    LogUtil.info(TEST_ABILITY, 'onExecuteInUIAbilityBackgroundMode start , name is ', name, 'param is ', JSON.stringify(param));
    let result: insightIntent.ExecuteResult;
    if (name !== 'ModifyAlarm') {
      LogUtil.warn(TEST_ABILITY, 'Unsupported intentName ', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, 'modifyAlarm failed,Not Support intent', JSON.stringify(result));
      return result;
    }
    const currentTime = new Date().getTime();
    if (param.alarmTime && param.alarmTime < currentTime) {
      result = {
        code: 10030009,
        result: {
          message: 'Create/modify Alarm  failed,the  alarmTime  need greater than the currentTime',
          entityName: 'Alarm',
        }
      }
      LogUtil.info(TEST_ABILITY, ' CreateAlarm failed, result:  ', JSON.stringify(result))
      return result
    }
    result = await modifyAlarm(param)
    LogUtil.info(TEST_ABILITY, 'ExecuteInUIAbilityBackgroundMode  finished, result is', JSON.stringify(result));
    return result

  }
}


// 修改闹钟
async function modifyAlarm(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
  LogUtil.info(TEST_ABILITY, 'modifyAlarm start , id is ' + param.entityId)
  if (!param.entityId) {
    let result: insightIntent.ExecuteResult = {
      code: 10030003,
      result: {
        message: 'modifyAlarm failed,No alarmId',
        entityName: 'Alarm'
      }
    }
    LogUtil.info(TEST_ABILITY, 'modifyAlarm failed ,No alarmId')
    return result
  }

  let alarmInfoList: AlarmInfo[] | undefined = []

  alarmInfoList = await AlarmManager.getAlarmById(param.entityId as string)

  if (alarmInfoList && alarmInfoList.length != 0) {
    LogUtil.info(TEST_ABILITY, 'this alarm will be modified: ', JSON.stringify(alarmInfoList[0]))
    alarmInfoList[0].title = param.alarmTitle ? param.alarmTitle as string : alarmInfoList[0].title
    alarmInfoList[0].alarmTime = param.alarmTime ? param.alarmTime as number : alarmInfoList[0].alarmTime
    alarmInfoList[0].alarmTimeIntent = param.alarmTime ? param.alarmTime as number : alarmInfoList[0].alarmTimeIntent
    alarmInfoList[0].enabled = param.alarmState === 1 ? true : param.alarmState === 0 ? false : true
    alarmInfoList[0].snoozeDuration = param.alarmSnoozeDuration ? param.alarmSnoozeDuration as number :
    alarmInfoList[0].snoozeDuration
    alarmInfoList[0].snoozeTimes = param.alarmSnoozeTotal ? param.alarmSnoozeTotal as number :
    alarmInfoList[0].snoozeTimes
    alarmInfoList[0].ringDuration = param.alarmRingDuration ? param.alarmRingDuration as number :
    alarmInfoList[0].ringDuration
    alarmInfoList[0].daysOfWeek = []
    alarmInfoList[0].daysOfWakeType = 1
    if (param.alarmTime || param.alarmTime === 0) {
      let newDate = new Date(param.alarmTime as string)
      alarmInfoList[0].hour = newDate.getHours()
      alarmInfoList[0].minute = newDate.getMinutes()
      alarmInfoList[0].second = newDate.getSeconds()
    }

    LogUtil.info(TEST_ABILITY, 'before update ' + JSON.stringify(alarmInfoList[0]))
    // 更新数据
    await AlarmManager.updateAlarm(alarmInfoList[0], true);
    // 存储默认名称
    await AlarmManager.saveDefaultAlarmTitle(alarmInfoList[0].id!, alarmInfoList[0].title!);
    // 更新还有xxx时间响铃
    await AlarmServiceManager.refreshNextAlertTime(false, true)

    let resultAlarmList: AlarmInfo[] | undefined = []
    resultAlarmList = await AlarmManager.getAlarmById(param.entityId as string)
    if (resultAlarmList && resultAlarmList != undefined && resultAlarmList.length != 0) {
      LogUtil.info(TEST_ABILITY, 'this alarm has be modified , the modified result is  ', JSON.stringify(resultAlarmList![0]))
      return new Promise((resolve, reject) => {
        let result: insightIntent.ExecuteResult = {
          code: 0,
          result: {
            entityType: 'Alarm',
            entityId: resultAlarmList![0].id!,
            alarmTime: resultAlarmList![0].alarmTimeIntent as number,
            alarmTitle: resultAlarmList![0]?.title,
            alarmState: resultAlarmList![0]?.enabled ? 1 : 0,
            alarmSnoozeDuration: resultAlarmList![0]?.snoozeDuration,
            alarmSnoozeTotal: resultAlarmList![0]?.snoozeTimes,
            alarmRingDuration: resultAlarmList![0]?.ringDuration,
          }
        }
        resolve(result)
      })
    }
  }
  let result: insightIntent.ExecuteResult = {
    code: 10030004,
    result: {
      message: 'modifyAlarm failed , no alarmInfo',
      entityName: 'Alarm',
    }
  }
  LogUtil.info(TEST_ABILITY, ' modifyAlarm failed,no alarmInfo', JSON.stringify(result))
  return result
}
