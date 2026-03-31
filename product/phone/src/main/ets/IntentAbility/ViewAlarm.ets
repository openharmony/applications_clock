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
import { AGENT_REQUEST_CODE_NORMAL, LogUtil, WantAgentUtil } from '@hmos/common';
import insightIntent from '@ohos.app.ability.insightIntent';
import AlarmManager from '@hmos/common/src/main/ets/manager/AlarmManager'
import window from '@ohos.window';
import wantAgent from '@ohos.app.ability.wantAgent'
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';

const LOG_TAG: string = 'testTag-ViewAlarm';


export default class ViewAlarmIntentExecutorImpl extends IntentExecutor {
  async onExecuteInUIAbilityForegroundMode(name: string, param: Record<string, Object>,
                                           pageLoader?: window.WindowStage):
    Promise<insightIntent.ExecuteResult> {
    LogUtil.info(LOG_TAG, 'onExecuteInUIAbilityForegroundMode start , name is ', JSON.stringify(param));

    let result: insightIntent.ExecuteResult;
    if (name !== 'ViewAlarm') {
      LogUtil.warn(LOG_TAG, 'Unsupported intentName %{public}s', name);
      result = {
        code: 10030002,
        result: {
          message: 'Not Support intent.',
        }
      };
      LogUtil.info(LOG_TAG, 'ViewAlarm failed,Not Support intent', JSON.stringify(result));
      return result;
    }

    const triggerWantAgent = await WantAgentUtil.getMainPageWantAgent();
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(LOG_TAG, `trigger response:  ${JSON.stringify(data)}`);
      });
    }

    result = await viewAlarm(param);
    LogUtil.info(LOG_TAG, 'Execute UIAbility in foreground mode finished, result %{public}s', JSON.stringify(result));
    return result;
  }
}


//查看闹钟
async function viewAlarm(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
  let res: insightIntent.ExecuteResult
  LogUtil.info(LOG_TAG, 'ViewAlarm param :  ' + param.entityId);

  try {
    if (!param.entityId) {
      LogUtil.info(LOG_TAG, 'ViewAlarm failed ,No alarmId')
      let result: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          message: 'ViewAlarm success ,but No Id '
        }
      }
      return result

    } else {
      const alarmFromList = await AlarmManager.getIDAlarmFrom(param.entityId as string);
      LogUtil.info(LOG_TAG, ' getIDAlarmFrom success, alarmFromList: ', JSON.stringify(alarmFromList))
      let result: insightIntent.ExecuteResult = {
        code: 0,
        result: {
          message: 'ViewAlarm success'
        }
      }
      LogUtil.info(LOG_TAG, ' ViewAlarm success, result:  ', JSON.stringify(result))
      return result
    }
  } catch (error) {
    LogUtil.error(LOG_TAG, `ViewAlarm error: ${error}`);
    res = {
      code: 10030011,
      result: {
        message: 'ViewAlarm failed',
        entityName: 'Alarm',
      }
    }
    return res
  }

}
