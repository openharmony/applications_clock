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

import IntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import { LogUtil, AlarmStateManager, TimeUtil } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import { AlarmServiceManager } from '@hmos/alarmclock';

const TEST_ABILITY: string = 'testTag-IntentExecutor-DelayRing';


export default class DelayRingIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string): Promise<insightIntent.ExecuteResult> {
    LogUtil.info(TEST_ABILITY, 'onExecuteInUIAbilityBackgroundMode start , name is ', name);
    let result: insightIntent.ExecuteResult;
    if (name !== 'DelayAlarmRing') {
      LogUtil.warn(TEST_ABILITY, 'Unsupported intentName ', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
          entityName: 'Alarm'
        }
      };
      return result;
    }
    result = await delayRing()
    LogUtil.info(TEST_ABILITY, 'ExecuteInUIAbilityBackgroundMode  finished, result is', JSON.stringify(result));
    return result
  }
}


async function delayRing(): Promise<insightIntent.ExecuteResult> {
  LogUtil.info(TEST_ABILITY, ' delayRing start')
  const isFiring = await AlarmStateManager.isFiring(); //boolean
  if (isFiring) {
    let ringingAlarm = await AlarmServiceManager.delayAlarmAndReturn()
    if (ringingAlarm) {
      LogUtil.info(TEST_ABILITY, 'delayRing success , delay alarm is ' + JSON.stringify(ringingAlarm));
      return new Promise((resolve, reject) => {
        let result: insightIntent.ExecuteResult = {
          code: 0,
          result: {
            entityName: 'Alarm',
            entityId: ringingAlarm?.id ? ringingAlarm.id : -1,
            alarmTime: ringingAlarm?.alarmTimeIntent ? ringingAlarm.alarmTimeIntent : -1,
            alarmTitle: ringingAlarm?.title ? ringingAlarm.title : -1,
            alarmState: ringingAlarm?.enabled ? 1 : 0,
            alarmSnoozeDuration: ringingAlarm?.snoozeDuration ? ringingAlarm.snoozeDuration : -1,
            alarmSnoozeTotal: ringingAlarm?.snoozeTimes ? ringingAlarm.snoozeTimes : -1,
            alarmRingDuration: ringingAlarm?.ringDuration ? ringingAlarm.ringDuration : -1
          }
        }
        resolve(result)
      })
    }
  }
  let result: insightIntent.ExecuteResult = {
    code: 10030005,
    result: {}
  }
  LogUtil.info(TEST_ABILITY, ' delayRing failed,no ringing alarm');
  return result

}