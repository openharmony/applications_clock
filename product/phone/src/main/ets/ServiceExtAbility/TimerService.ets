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

import contextConstant from '@ohos.app.ability.contextConstant';
// import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import { TimerNotificationUtil } from '@hmos/timer';
import {
  LogUtil,
  TimerServiceType,
  TimerStateManager,
  TIMER_NOTICE_ID,
  WantAgentUtil,
  TIMEOUT_FULL_SCREEN_ID,
  TIMEOUT_FULL_SCREEN_CLOSE_ID,
  TIMEOUT_FLAG_ID,
  CommonUtil,
  FullScreenType,
  GlobalContext,
} from '@hmos/common';
import Want from '@ohos.app.ability.Want';
import screenLock from '@ohos.screenLock';
import power from '@ohos.power';
import TimerAudioPlayer from '@hmos/timer/src/main/ets/manager/timerAudioPlayer';
import { AlarmServiceManager } from '@hmos/alarmclock';
import emitter from '@ohos.events.emitter';
import deviceInfo from '@ohos.deviceInfo';

const TAG = 'TimerService';
const TIMER_BEEP: string = 'Timer_Beep.ogg';
const UPDATE_INTERVAL: number = 150;
let timeoutDuration: number = 0;
let timeOutFlag = false

/**
 * Service ability for alarm notification
 *
 * @since 2022-08-18
 */
export default class TimerService {
  private static instance: TimerService;
  private static isNotificationSubscribe = false;

  public static getContext(): TimerService {
    if (!TimerService.instance) {
      TimerService.instance = new TimerService();
    }
    return TimerService.instance;
  }

  async onCreate(want: Want): Promise<void> {
    LogUtil.info(TAG, 'onCreate');
    // GlobalContext.getContext().setObject('clockContext', this.context);
    // GlobalContext.getContext().setObject('clockContextType', 'TimerService');
    if (!TimerService.isNotificationSubscribe) {
      await TimerNotificationUtil.notificationSubscribeSystemSubscriber();
      TimerService.isNotificationSubscribe = true;
    }
    CommonUtil.requestCPUResources();
    await CommonUtil.getWallpaper();
  }

  forwardTiming(localTime: number) {
    const now = new Date().getTime(); // 获取当前本地时间
    const timeGap = now - localTime; // 计算时间差
    //下一次计时器应该触发的时间
    const nextTickTime = UPDATE_INTERVAL - (timeGap % UPDATE_INTERVAL);
    let timerTimeout = setTimeout(() => {
      if (timeOutFlag) {
        timeoutDuration += UPDATE_INTERVAL;
        emitter.emit({
          eventId: TIMEOUT_FULL_SCREEN_ID,
          priority: emitter.EventPriority.IMMEDIATE
        }, {
          data: {
            timeoutDuration: timeoutDuration
          }
        });
        this.forwardTiming(localTime);
      } else {
        clearTimeout(timerTimeout);
      }
    }, nextTickTime);
  }

  async onRequestTimeOutFiring(timerId: string, alarmAlertTime: number): Promise<void> {
    if (deviceInfo.deviceType !== '2in1') {
      timeoutDuration = 0;
      timeOutFlag = true;
      const isScreenLocked: boolean = await screenLock.isScreenLocked();
      LogUtil.info(TAG, 'isScreenLocked is ' + isScreenLocked);
      await AlarmServiceManager.delayFiringAlarm(true);
      await TimerStateManager.setStateFiring(TIMER_NOTICE_ID);
      TimerAudioPlayer.playTick(TIMER_BEEP);
      this.forwardTiming(new Date().getTime());
      if (!isScreenLocked) {
        TimerNotificationUtil.timeoutPublishAlarmMissed(timerId, alarmAlertTime);
      } else {
        // power.wakeup('timer_alarm');
        TimerNotificationUtil.cancel(timerId);
        await WantAgentUtil.triggerFullScreenAbility(FullScreenType.Timer);
      }
      emitter.emit({
        eventId: TIMEOUT_FLAG_ID, priority: emitter.EventPriority.IMMEDIATE
      });
    } else {
      timeoutDuration = 0
      timeOutFlag = true
      const isScreenLocked: boolean = await screenLock.isScreenLocked();
      LogUtil.info(TAG, 'isScreenLockedpc is ' + isScreenLocked);
      await AlarmServiceManager.delayFiringAlarm(true);
      await TimerStateManager.setStateFiring(TIMER_NOTICE_ID);
      if (!isScreenLocked) {
        LogUtil.info('startPublishAlarmMissedPC0 notification success');
        await TimerNotificationUtil.timeoutPublishAlarmMissedPC(timerId, alarmAlertTime)
      }
      TimerAudioPlayer.playTick(TIMER_BEEP)
      this.forwardTiming(new Date().getTime())
    }
  }

  private onRequestTimeOut(info: string): void {
    LogUtil.info(TAG, info);
    timeoutDuration = 0;
    timeOutFlag = false;
  }

  private async terminateTimerService(): Promise<void> {
    LogUtil.info(TAG, `terminateTimerService begin`);
    // try {
    //   LogUtil.info(TAG, `terminateTimerService begin`);
    //   // await this.context.terminateSelf();
    // } catch (error) {
    //   LogUtil.error(TAG, 'terminateTimerService failed: ', JSON.stringify(error));
    // }
  }

  async onRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, `onRequest, want is: ${JSON.stringify(want)}`);
    const serviceType = want?.parameters?.serviceType;
    const timerId = want?.parameters?.timerId as string;
    const alarmAlertTime = want?.parameters?.alarmAlertTime as number;

    if (serviceType && serviceType === TimerServiceType.Start) {
      this.onRequestTimeOut(`timeOut_Start`);
      TimerNotificationUtil.startPublishAlarmMissed(timerId, alarmAlertTime)
      return;
    } else if (serviceType && serviceType === TimerServiceType.Pause) {
      this.onRequestTimeOut(`timeOut_Pause`);
      TimerNotificationUtil.pausePublishAlarmMissed(timerId, alarmAlertTime)
      return;
    } else if (serviceType && serviceType === TimerServiceType.Close) {
      await TimerStateManager.setStateStop(timerId.toString());
      this.onRequestTimeOut(`timeOut_Close`);
      TimerAudioPlayer.stopTick(TIMER_BEEP);
      if (deviceInfo.deviceType === '2in1') {
        emitter.emit({ eventId: TIMEOUT_FULL_SCREEN_CLOSE_ID, priority: emitter.EventPriority.IMMEDIATE });
      }
      TimerNotificationUtil.cancel(timerId);
      CommonUtil.terminateFullScreenAbility();
      await this.terminateTimerService();
      return;
    } else if (serviceType && serviceType === TimerServiceType.Firing) {
      LogUtil.info(TAG, `timeOut_Firing`);
      await this.onRequestTimeOutFiring(timerId, alarmAlertTime);
      return;
    } else if (serviceType && serviceType === TimerServiceType.ToggleFullScreen) {
      LogUtil.info(TAG, `timeOut_ToggleFullScreen`);
      await WantAgentUtil.triggerFullScreenAbility(FullScreenType.Timer);
    } else {
      LogUtil.info(TAG, 'onRequest  else');
    }
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'onDestroy');
    try {
      CommonUtil.terminateFullScreenAbility();
      CommonUtil.releaseCPUResources();
    } catch (error) {
      LogUtil.error(TAG, 'onDestroy failed: ', JSON.stringify(error));
    }
  }
}