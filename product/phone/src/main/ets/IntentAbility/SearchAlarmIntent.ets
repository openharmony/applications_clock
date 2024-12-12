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

import { LogUtil, TimeUtil } from '@hmos/common';
import IntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'
import { AlarmInfo } from '@hmos/common/src/main/ets/manager/types'

// 查询闹钟
const TEST_ABILITY: string = 'testTag-IntentExecutor-SearchAlarm';

interface objExecute {
  entityName: string,
  entityId: string,
  alarmTime: number,
  alarmTitle: string,
  alarmState: number,
  alarmSnoozeDuration: number,
  alarmSnoozeTotal: number,
  alarmRingDuration: number,
}

export default class SearchAlarmIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string, param: Record<string, Object>):
    Promise<insightIntent.ExecuteResult> {

    LogUtil.info(TEST_ABILITY, 'onExecuteInUIAbilityBackgroundMode start , name is ', name, 'param is ', JSON.stringify(param));

    let result: insightIntent.ExecuteResult;
    if (name !== 'SearchAlarm') {
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, 'SearchAlarm failed,Not Support intent', JSON.stringify(result));
      return result;
    }

    // 开始查询
    // 判断参数是否满足要求: 至少得有一个参数  且若有timeInterval timeInterval的长度不能超过2
    // 至少得有一个参数
    if (Object.keys(param).length < 1) {
      result = {
        code: 10030006,
        result: {
          message: 'no params',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, ' SearchAlarm failed , at least need one param', JSON.stringify(result));
      return result
    }
    //    传的没timeInterval
    if (!param.timeInterval) {
      result = await searchAlarm(param)
      return result
    } else if (param.timeInterval && (param.timeInterval as number[]).length < 2) {
      // 如果传的有timeInterval 但是数组不符合条件  暂不处理
      LogUtil.info(TEST_ABILITY, ' SearchAlarm failed,timeInterval length error' + JSON.stringify(param.timeInterval));
      result = {
        code: 10030007,
        result: {
          message: 'SearchAlarm failed,timeInterval length error',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, ' SearchAlarm failed,timeInterval length error', JSON.stringify(result));
      return result
    }
    //  传的有timeInterval 数组符合条件 放行
    LogUtil.info(TEST_ABILITY, ' SearchAlarm , has timeInterval');
    result = await searchAlarm(param)
    return result
  }
}

// 查询闹钟
// rangeType 单独查  alarmTimeIntent单独查  // 其他几个条件并列查

async function searchAlarm(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
  let result: insightIntent.ExecuteResult
  LogUtil.info(TEST_ABILITY, ' SearchAlarm start')
  if (param.rangeType) {
    result = await searchRangeType(param.rangeType as string)
    return result
  } else if (param.alarmTime) {
    result = await searchAlarmTime(param.alarmTime as number)
    return result
  } else {
    result = await searchUnion(param)
    return result
  }
}

async function searchRangeType(rangeType: string) {
  let result: insightIntent.ExecuteResult
  switch (rangeType) {
    case 'all': {
      LogUtil.info(TEST_ABILITY, ' searchAlarm rangeType is all')
      let resultAlarmList = await AlarmManager.getAllAlarmsToShow();
      let stringifyArr: string[] = []
      resultAlarmList.forEach((alarm) => {
        stringifyArr.push(stringifyObject(alarm))
      })
      result = { code: 0, result: { items: stringifyArr, } }
      LogUtil.info(TEST_ABILITY, ' searchAlarm rangeType:all  success , list length is  ' + resultAlarmList.length + ' result is' + JSON.stringify(result));
      return result
    }
    case 'next': {
      LogUtil.info(TEST_ABILITY, ' searchAlarm rangeType is next')
      let resultAlarm = await AlarmManager.getNearestAlarm();
      if (resultAlarm) {
        let stringifyArr: string[] = []
        stringifyArr.push(stringifyObject(resultAlarm))
        result = { code: 0, result: { items: stringifyArr, } }
        LogUtil.info(TEST_ABILITY, ' SearchAlarm rangeType:next  success ', JSON.stringify(result));
        return result
      }
      result = { code: 0, result: {} }
      LogUtil.info(TEST_ABILITY, ' SearchAlarm rangeType:next  success,no next alarm will ring');
      return result
    }
    case 'current': {
      LogUtil.info(TEST_ABILITY, ' searchAlarm rangeType is current')
      let sortAlarmList = await AlarmManager.sortAlarmListById()
      let resultAlarm = await AlarmManager.getNearestAlarm();
      if (sortAlarmList) {
        resultAlarm = sortAlarmList[sortAlarmList.length - 1]
        let stringifyArr: string[] = []
        stringifyArr.push(stringifyObject(resultAlarm))
        result = { code: 0, result: { items: stringifyArr } }
        LogUtil.info(TEST_ABILITY, ' SearchAlarm rangeType:current  success ', JSON.stringify(result));
        return result
      }
    }
    default: {
      result = { code: -1, result: {} }
      return result
    }
  }
}


async function searchAlarmTime(alarmTime: number) {
  let result: insightIntent.ExecuteResult
  LogUtil.info(TEST_ABILITY + ' search by alarmTimeIntent now ');
  let resultAlarmList = await AlarmManager.getAlarmByAlarmTimeIntent(alarmTime as number)
  LogUtil.info(TEST_ABILITY + ' result alarm list is ' + JSON.stringify(resultAlarmList));
  let stringifyArr: string[] = []
  if (resultAlarmList && resultAlarmList.length != 0) {
    resultAlarmList.forEach((alarm) => {
      stringifyArr.push(stringifyObject(alarm))
    })
    result = { code: 0, result: { items: stringifyArr } }
    LogUtil.info(TEST_ABILITY, ' SearchAlarm success by alarmTime success , list length is ' + JSON.stringify(resultAlarmList.length) + ', result is ' + JSON.stringify(result));
    return result
  }
  result = { code: 0, result: {} }
  LogUtil.info(TEST_ABILITY, 'search success , no such clock', JSON.stringify(resultAlarmList));
  return result
}


async function searchUnion(param: Record<string, Object>) {
  let result: insightIntent.ExecuteResult
  let resultAlarmList: AlarmInfo[] | undefined = []
  resultAlarmList = await AlarmManager.searchAlarmInfo(param.entityId as string, param.alarmTitle as
  string, param.alarmState as boolean,
    param.timeInterval as string[]);
  let stringifyArr: string[] = []
  if (resultAlarmList && resultAlarmList.length != 0) {
    resultAlarmList.forEach((alarm) => {
      stringifyArr.push(stringifyObject(alarm))
    })
    result = { code: 0, result: { items: stringifyArr } }
    LogUtil.info(TEST_ABILITY, ' SearchAlarm success , list length is ' + JSON.stringify(resultAlarmList.length) + ', result is ' + JSON.stringify(result));
    return result
  }
  result = { code: 0, result: {} }
  LogUtil.info(TEST_ABILITY, 'search success , no such clock', JSON.stringify(resultAlarmList));
  return result
}

function stringifyObject(alarm: AlarmInfo) {
  let addObject: objExecute = {
    entityName: 'Alarm',
    entityId: alarm.id as string,
    alarmTime: TimeUtil.getAlarmTime(alarm),
    alarmTitle: alarm.title,
    alarmState: alarm.enabled ? 1 : 0,
    alarmSnoozeDuration: alarm.snoozeDuration,
    alarmSnoozeTotal: alarm.snoozeTimes,
    alarmRingDuration: alarm.ringDuration
  }
  return JSON.stringify(addObject)
}