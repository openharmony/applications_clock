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
import { LogUtil, AlarmStateManager, WantAgentUtil } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'

const TEST_ABILITY: string = 'testTag-IntentExecutor-StopRing';

export default class StopAlarmRingIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string): Promise<insightIntent.ExecuteResult> {

    LogUtil.info(TEST_ABILITY, 'onExecuteInUIAbilityBackgroundMode start , name is ', name);

    let result: insightIntent.ExecuteResult;
    if (name !== 'StopAlarmRing') {
      LogUtil.warn(TEST_ABILITY, 'Unsupported intentName ', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, 'StopAlarmRing failed,Not Support intent', JSON.stringify(result));
      return result;
    }
    result = await stopAlarmRing()
    LogUtil.info(TEST_ABILITY, 'ExecuteInUIAbilityBackgroundMode  finished, result is', JSON.stringify(result));
    return result
  }
}


async function stopAlarmRing(): Promise<insightIntent.ExecuteResult> {

  LogUtil.info(TEST_ABILITY, 'StopRing start')

  const isFiring = await AlarmStateManager.isFiring(); //boolean
  if (isFiring) {
    const firingAlarmId = await AlarmStateManager.getAlarmId();
    const firingAlarm = await AlarmManager.getLatestAlarmFromDb(firingAlarmId);
    if (firingAlarm) {
      WantAgentUtil.triggerCloseAlarm(firingAlarm);
      LogUtil.info(TEST_ABILITY, 'StopRing success , stop alarm is' + JSON.stringify(firingAlarm))
      return new Promise((resolve, reject) => {
        let result: insightIntent.ExecuteResult = {
          code: 0,
          result: {
            entityName: 'Alarm',
            entityId: firingAlarm.id!,
            alarmTitle: firingAlarm.title,
            alarmTime: firingAlarm.alarmTimeIntent ? firingAlarm.alarmTimeIntent : -1,
            alarmState: firingAlarm.enabled ? 1 : 0,
            alarmSnoozeDuration: firingAlarm.snoozeDuration,
            alarmSnoozeTotal: firingAlarm.snoozeTimes,
            alarmRingDuration: firingAlarm.ringDuration
          }
        }
        resolve(result)
      })
    }
  }

  let result: insightIntent.ExecuteResult = {
    code: 10030008,
    result: {}
  }
  LogUtil.info(TEST_ABILITY, 'StopRing failed,no ringing alarm');
  return result

}