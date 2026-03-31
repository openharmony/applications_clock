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

import { WantAgent } from '@ohos.wantAgent';
import wantAgent from '@ohos.app.ability.wantAgent'
import { AlarmInfo } from '../manager';
import { LogUtil } from './LogUtil';
import {
  AGENT_REQUEST_CODE_NORMAL,
  AlarmServiceType,
  TimerServiceType,
  MAIN_ABILITY,
  TIMER_ALERT_ABILITY,
  TIMER_ALERT_BUNDLE,
  TIMER_TIMER_ABILITY,
  FULL_SCREEN_ABILITY,
  FullScreenType
} from './types';
import { BusinessError } from '@ohos.base';
import { GlobalContext } from './GlobalContext';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

const TAG = 'WantAgentUtil';
// type ServiceExtensionContext = common.ServiceExtensionContext;

/**
 * WantAgent Util
 *
 * @since 2022-08-29
 */
export class WantAgentUtil {
  /**
   * Get the WantAgent used by the timer to start the alarm ringing service.
   *
   * @param alarmInfo AlarmInfo
   * @param serviceType AlarmServiceType Enum value
   * @param isNotificationCloseButton Whether is button for closing the notification bar
   * @return WantAgent used by the timer to start the alarm ringing service
   */
  static async getAlarmWantAgent(alarmInfo: AlarmInfo, serviceType: AlarmServiceType,
                                 isNotificationCloseButton?: boolean, isSnooze?: boolean):
    Promise<WantAgent | undefined> {
    LogUtil.info(TAG, 'getAlarmWantAgent with serviceType:', serviceType);
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: TIMER_ALERT_ABILITY,
            parameters: {
              alarmInfo: alarmInfo,
              serviceType: serviceType,
              isNotificationCloseButton: isNotificationCloseButton as Object,
              isSnooze: isSnooze as Object,
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, 'getAlarmWantAgent failed: ', (error as BusinessError).message);
      return;
    }
  }

  /**
   * Get the WantAgent used by the AlarmInitSubscriber to start the alarm service.
   *
   * @param forceRefreshTimer The timer needs to be reset during startup.
   * @return WantAgent used by the timer to start the alarm ringing service.
   */
  static async getCommonEventWantAgent(forceRefreshTimer?: boolean): Promise<WantAgent | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: TIMER_ALERT_ABILITY,
            parameters: {
              serviceType: AlarmServiceType.Update,
              forceRefreshTimer: forceRefreshTimer as Object
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, `getCommonEventWantAgent failed: ${JSON.stringify(error)}`);
      return;
    }
  }

  /**
   * Get the WantAgent used to start the full screen alarm page.
   *
   * @param alarmInfo AlarmInfo
   * @return WantAgent used to start the full screen alarm page.
   */
  static async getToggleFullScreenWantAgent(alarmInfo: AlarmInfo): Promise<WantAgent | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: FULL_SCREEN_ABILITY,
            parameters: {
              fullScreenType: FullScreenType.Alarm,
              alarmInfo: alarmInfo,
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, `getToggleFullScreenWantAgent failed: ${JSON.stringify(error)}`);
      return;
    }
  }

  /**
   * Obtaining the WantAgent for Encapsulating the Home Page
   *
   * @return WantAgent used to start main page
   */
  static async getMainPageWantAgent(alarmId?: number | string, isMissed?: boolean): Promise<WantAgent | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: MAIN_ABILITY,
            parameters: {
              alarmId: alarmId ? alarmId : '',
              isMissed: isMissed ? true : false
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, `getMainPageWantAgent failed: ${JSON.stringify(error)}`);
      return;
    }
  }

  /**
   * Trigger the alarm to turn off
   *
   * @param alarmInfo AlarmInfo
   */
  static async triggerCloseAlarm(alarmInfo: AlarmInfo): Promise<void> {
    if (!alarmInfo) {
      LogUtil.error(TAG, 'Trigger close alarm failed, params is incorrect.');
      return;
    }
    const triggerWantAgent = await WantAgentUtil.getAlarmWantAgent(alarmInfo, AlarmServiceType.Close);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `trigger response:  ${JSON.stringify(data)}`);
      });
    }
  }

  static async triggerDelayAlarm(alarmInfo: AlarmInfo): Promise<void> {
    if (!alarmInfo) {
      LogUtil.error(TAG, 'Trigger Delay alarm failed, params is incorrect.');
      return;
    }
    const triggerWantAgent = await WantAgentUtil.getAlarmWantAgent(alarmInfo, AlarmServiceType.Delay);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `trigger response:  ${JSON.stringify(data)}`);
      });
    }
  }

  static async getTimerMainPageWantAgent(tabActive: string): Promise<WantAgent | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: MAIN_ABILITY,
            parameters: {
              tab_active: tabActive
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, `getTimerMainPageWantAgent failed: ${JSON.stringify(error)}`);
      return;
    }
  }

  static async getTimerFullScreenWantAgent(): Promise<WantAgent | undefined> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: FULL_SCREEN_ABILITY,
            parameters: {
              fullScreenType: FullScreenType.Timer,
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, `getTimerFullScreenWantAgent failed: ${JSON.stringify(error)}`);
      return;
    }
  }

  static async timerWantAgent(serviceType: TimerServiceType, timerId: number | string,
                              alarmAlertTime?: number | string):
    Promise<WantAgent | undefined> {
    LogUtil.info(TAG, 'timerWantAgent with serviceType:', serviceType);
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: TIMER_ALERT_BUNDLE,
            abilityName: TIMER_TIMER_ABILITY,
            parameters: {
              timerId: timerId,
              alarmAlertTime: alarmAlertTime ? alarmAlertTime : 0,
              serviceType: serviceType,
            },
          }
        ],
        // operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
        requestCode: AGENT_REQUEST_CODE_NORMAL,
      }
      return await wantAgent.getWantAgent(wantAgentInfo);
    } catch (error) {
      LogUtil.error(TAG, 'timerWantAgent failed: ', (error as BusinessError).message);
      return;
    }
  }

  static async triggerTimerMainPage(tabActive: string): Promise<void> {
    LogUtil.info(TAG, `triggerTimerMainPage`);
    const triggerWantAgent = await WantAgentUtil.getTimerMainPageWantAgent(tabActive);
    if (triggerWantAgent) {
      wantAgent.trigger(
        triggerWantAgent,
        { code: AGENT_REQUEST_CODE_NORMAL },
        (data) => {
          LogUtil.info(TAG, `triggerTimerMainPage res ${JSON.stringify(data)}`);
        }
      );
    }
  }

  static async triggerStartTimer(timerId: number | string, alarmAlertTime: number | string): Promise<void> {
    LogUtil.info(TAG, `triggerStartTimer`);
    const triggerWantAgent = await WantAgentUtil.timerWantAgent(TimerServiceType.Start, timerId, alarmAlertTime);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `triggerStartTimer response:  ${JSON.stringify(data)}`);
      });
    }
  }

  static async triggerPauseTimer(timerId: number | string, alarmAlertTime: number | string): Promise<void> {
    LogUtil.info(TAG, `triggerPauseTimer`);
    const triggerWantAgent = await WantAgentUtil.timerWantAgent(TimerServiceType.Pause, timerId, alarmAlertTime);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `triggerPauseTimer response:  ${JSON.stringify(data)}`);
      });
    }
  }


  static async triggerCloseTimer(timerId: number | string, alarmAlertTime?: number | string): Promise<void> {
    LogUtil.info(TAG, `triggerCloseTimer`);
    const triggerWantAgent = await WantAgentUtil.timerWantAgent(TimerServiceType.Close, timerId);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `triggerCloseTimer response:  ${JSON.stringify(data)}`);
      });
    }
  }

  static async triggerFiringTimer(timerId: number | string, alarmAlertTime: number | string): Promise<void> {
    LogUtil.info(TAG, `triggerFiringTimer`);
    const triggerWantAgent = await WantAgentUtil.timerWantAgent(TimerServiceType.Firing, timerId, alarmAlertTime);
    if (triggerWantAgent) {
      wantAgent.trigger(triggerWantAgent, {
        code: AGENT_REQUEST_CODE_NORMAL,
      }, data => {
        LogUtil.info(TAG, `triggerFiringTimer response:  ${JSON.stringify(data)}`);
      });
    }
  }

  static async triggerFullScreenAbility(fullScreenType: FullScreenType, timerId?: number | string,
                                        alarmAlertTime?: number | string): Promise<void> {
    LogUtil.info(TAG, `triggerFullScreenAbility fullScreenType=${fullScreenType}`);
    try {
      // const context = GlobalContext.getContext().getObject('clockContext') as ServiceExtensionContext;
      // const contextType = GlobalContext.getContext().getObject('clockContextType') as string;
      // if (context && contextType) {
      //   await context.startAbility({
      //     bundleName: TIMER_ALERT_BUNDLE,
      //     abilityName: FULL_SCREEN_ABILITY,
      //     parameters: {
      //       fullScreenType: fullScreenType,
      //       timerId: timerId ? timerId : -1,
      //       alarmAlertTime: alarmAlertTime ? alarmAlertTime : 0,
      //     },
      //   });
      // }
    } catch (error) {
      LogUtil.error(TAG, 'triggerFullScreenAbility failed: ', (error as BusinessError).message);
      return;
    }
  }
}