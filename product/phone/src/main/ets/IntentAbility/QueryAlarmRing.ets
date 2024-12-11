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
import { LogUtil, AlarmStateManager } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'

const LOG_TAG: string = 'testTag-QueryAlarmRing';


export default class QueryAlarmRingIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string, param: Record<string, Object>):
    Promise<insightIntent.ExecuteResult> {

    LogUtil.info(LOG_TAG, 'onExecuteInUIAbilityBackgroundMode start , name is ', name);

    let result: insightIntent.ExecuteResult;
    if (name !== 'QueryAlarmRing') {
      LogUtil.warn(LOG_TAG, 'Unsupported intentName %{public}s', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
        }
      };
      LogUtil.info(LOG_TAG, 'QueryAlarmRing failed,Not Support intent', JSON.stringify(result));
      return result;
    }

    result = await QueryAlarmRing();
    LogUtil.info(LOG_TAG, 'CreateAlarmResult Execute UIAbility in foreground mode finished, result %{public}s', JSON.stringify(result));
    return result;
  }
}


//查询当前是否有正在响铃的闹钟
export async function QueryAlarmRing(): Promise<insightIntent.ExecuteResult> {
  let res: insightIntent.ExecuteResult
  const isFiring = await AlarmStateManager.isFiring(); //boolean
  //需要询问是何时调用的此方法来确定是否是调用时机影响
  LogUtil.info(LOG_TAG, ' isFiring:  ' + isFiring)
  try {
    if (isFiring) {
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      LogUtil.info(LOG_TAG, `current is firing: firing alarm id is: ${firingAlarmId}`);

      const alarmClock = await AlarmManager.getLatestAlarmFromDb(firingAlarmId);
      LogUtil.info(LOG_TAG, 'alarmClockList:  ', JSON.stringify(alarmClock));

      if (alarmClock) {
        LogUtil.info(LOG_TAG, 'QueryAlarmRing  success ');
        return new Promise((resolve, reject) => {
          let result: insightIntent.ExecuteResult = {
            code: 0,
            result: {
              entityName: 'Alarm',
              entityId: alarmClock?.id ? alarmClock.id : -1,
              alarmTime: alarmClock?.alarmTimeIntent ? alarmClock.alarmTimeIntent : -1,
              alarmTitle: alarmClock?.title ? alarmClock.title : -1,
              alarmState: alarmClock?.enabled ? 1 : 0,
              alarmSnoozeDuration: alarmClock?.snoozeDuration ? alarmClock.snoozeDuration : -1,
              alarmSnoozeTotal: alarmClock?.snoozeTimes ? alarmClock.snoozeTimes : -1,
              alarmRingDuration: alarmClock?.ringDuration ? alarmClock.ringDuration : -1
            }
          }
          LogUtil.info(LOG_TAG, 'QueryAlarmRing success , the ringing alarm result: ' + JSON.stringify(result));
          resolve(result)
        })
      }

    }

    res = {
      code: 0,
      result: {}
    }
    LogUtil.info(LOG_TAG, ' QueryAlarmRing success,no ringing alarm', JSON.stringify(res));
    return res
  } catch (error) {
    LogUtil.error(LOG_TAG, `QueryAlarmRing error: ${error}`);
    res = {
      code: 10030010,
      result: {}
    }
    return res
  }
}