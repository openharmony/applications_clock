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

import { LogUtil } from '@hmos/common';
import IntentExecutor from '@ohos.app.ability.InsightIntentExecutor';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'

const TEST_ABILITY: string = 'testTag-IntentExecutor-DeleteAlarm';

export default class DeleteAlarmIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityBackgroundMode(name: string, param: Record<string, Object>):
    Promise<insightIntent.ExecuteResult> {

    LogUtil.info(TEST_ABILITY, 'onExecuteInUIAbilityBackgroundMode start , name is ', name, 'param is ', JSON.stringify(param));

    let result: insightIntent.ExecuteResult;
    if (name !== 'DeleteAlarm') {
      LogUtil.warn(TEST_ABILITY, 'Unsupported intentName ', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
          entityName: 'Alarm'
        }
      };
      LogUtil.info(TEST_ABILITY, 'DeleteAlarm failed,Not Support intent', JSON.stringify(result));
      return result;
    }
    result = await deleteAlarm(param)
    LogUtil.info(TEST_ABILITY, 'ExecuteInUIAbilityBackgroundMode  finished, result is', JSON.stringify(result));
    return result
  }
}


// 删除闹钟
// id:string
async function deleteAlarm(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {

  LogUtil.info(TEST_ABILITY, 'DeleteAlarm start', JSON.stringify(param))

  if (!param.entityId) {
    let result: insightIntent.ExecuteResult = {
      code: 10030003,
      result: {
        message: 'DeleteAlarm failed,No alarmId',
        entityName: 'Alarm'
      }
    }
    LogUtil.info(TEST_ABILITY, 'DeleteAlarm failed ,No alarmId')
    return result
  }
  let stringResult = await AlarmManager.removeAlarmById(param.entityId as string);
  LogUtil.info(TEST_ABILITY, 'DeleteAlarm ending ' + JSON.stringify(stringResult))
  if (stringResult == 'success') {
    return new Promise((resolve, reject) => {
      let result: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          message: 'DeleteAlarm success,id is ' + param.entityId,
          entityName: 'Alarm'
        }
      }
      resolve(result)
    })
  } else {
    let result: insightIntent.ExecuteResult = {
      code: 10030004,
      result: {
        message: 'DeleteAlarm failed,No this alarmId,id is ' + param.entityId,
        entityName: 'Alarm'
      }
    }
    return result
  }

}
