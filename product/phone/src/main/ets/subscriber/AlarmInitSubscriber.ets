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

// import StaticSubscriberExtensionAbility from '@ohos.application.StaticSubscriberExtensionAbility';
import wantAgent from '@ohos.app.ability.wantAgent';
import commonEventManager from '@ohos.commonEventManager';
import { LogUtil, WantAgentUtil, AGENT_REQUEST_CODE_NORMAL } from '@hmos/common';


const TAG = 'AlarmInitSubscriber';

const EVENT_TIME_CHANGED = 'usual.event.TIME_CHANGED';

const EVENT_TIMEZONE_CHANGED = 'usual.event.TIMEZONE_CHANGED';

const EVENT_BOOT_COMPLETED = 'usual.event.BOOT_COMPLETED';

const EVENT_LOCKED_BOOT_COMPLETED = 'usual.event.LOCKED_BOOT_COMPLETED';

type CommonEventData = commonEventManager.CommonEventData;

/**
 * Subscriber used to receive common events
 *
 * @since 2022-11-11
 */
export default class AlarmInitSubscriber {
  async onReceiveEvent(event: CommonEventData): Promise<void> {
    LogUtil.info(TAG, `receive event: ${JSON.stringify(event)}`);
    if (!event?.event) {
      LogUtil.error(TAG, 'onReceiveEvent occurs error');
      return;
    }
    if (event.event === EVENT_TIME_CHANGED) {
      const triggerWantAgent = await WantAgentUtil.getCommonEventWantAgent();
      if (triggerWantAgent) {
        wantAgent.trigger(triggerWantAgent, {
          code: AGENT_REQUEST_CODE_NORMAL,
        }, data => {
          LogUtil.info(TAG, `trigger response:  ${JSON.stringify(data)}`);
        });
      }
    } else if (event.event === EVENT_BOOT_COMPLETED || event.event === EVENT_LOCKED_BOOT_COMPLETED ||
      event.event === EVENT_TIMEZONE_CHANGED) {
      const triggerWantAgent = await WantAgentUtil.getCommonEventWantAgent(true);
      if (triggerWantAgent) {
        wantAgent.trigger(triggerWantAgent, {
          code: AGENT_REQUEST_CODE_NORMAL,
        }, data => {
          LogUtil.info(TAG, `trigger response:  ${JSON.stringify(data)}`);
        });
      }
    }
  }
};