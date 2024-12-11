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

import commonEventManager from '@ohos.commonEventManager';
import contextConstant from '@ohos.app.ability.contextConstant';
// import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import { AlarmServiceManager, AlarmCardUtil, NotificationUtil } from '@hmos/alarmclock';
import {
  AlarmInfo,
  CommonUtil,
  EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE,
  FullScreenType,
  WantAgentUtil
} from '@hmos/common';
import {
  LogUtil,
  ResourceManager,
  AlarmStateManager,
  TIME_TAG_ID_LIST_IN_ZH,
  AlarmServiceType,
  MILLIS_IN_SECOND,
  SECOND_IN_MINUTE,
  GlobalContext,
} from '@hmos/common';
import Want from '@ohos.app.ability.Want';
import deviceInfo from '@ohos.deviceInfo'
import SnoozeManager from '@hmos/common/src/main/ets/manager/SnoozeManager';
import notificationManager from '@ohos.notificationManager';
import emitter from '@ohos.events.emitter';

const deviceType: string = deviceInfo.deviceType;
const TIME_SUBSCRIBE_INFO: CommonEventSubscribeInfo = {
  events: [
    commonEventManager.Support.COMMON_EVENT_SCREEN_OFF,
  ],
};

const TAG = 'AlarmService';

type CommonEventSubscriber = commonEventManager.CommonEventSubscriber;
type CommonEventSubscribeInfo = commonEventManager.CommonEventSubscribeInfo;

/**
 * Service ability for alarm notification
 *
 * @since 2022-08-18
 */
export default class AlarmService {
  private killAlarmMessageId: number = 0;
  private commonEventSubscriber: CommonEventSubscriber = {} as CommonEventSubscriber;
  private static instance: AlarmService;
  private static isNotificationSubscribe = false;

  public static getContext(): AlarmService {
    if (!AlarmService.instance) {
      AlarmService.instance = new AlarmService();
    }
    return AlarmService.instance;
  }

  private setInitInfo(want: Want): void {
    // this.context.area = contextConstant.AreaMode.EL1;
    // GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'AlarmService');
    // GlobalContext.getContext().setObject('AlarmServiceContext', this.context);
    // GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    GlobalContext.getContext().setObject('abilityWant', want);
  }

  async onCreate(want: Want): Promise<void> {
    LogUtil.info(TAG, 'onCreate');
    this.setInitInfo(want);
    await AlarmServiceManager.createAudioWorker(true);
    await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
    this.subscribeCommentEvent();
    if (!AlarmService.isNotificationSubscribe) {
      await NotificationUtil.notificationSubscribeSystemSubscriber();
      AlarmService.isNotificationSubscribe = true;
    }
    CommonUtil.requestCPUResources();
    await CommonUtil.getWallpaper();
  }

  private serviceType(want?: Want) {
    return want?.parameters?.serviceType
  }

  private isSnooze(want?: Want) {
    return want?.parameters?.isSnooze
  }

  async onRequest(want: Want): Promise<void> {
    LogUtil.info(TAG, `onRequest, want is: ${JSON.stringify(want)}`);
    const serviceType = this.serviceType(want);
    const alarmInfo: AlarmInfo = want?.parameters?.alarmInfo as AlarmInfo;
    const isNotificationCloseButton = want?.parameters?.isNotificationCloseButton;
    const isSnooze = this.isSnooze(want);
    this.setInitInfo(want);
    if (serviceType && serviceType === AlarmServiceType.ReStart) {
      await AlarmServiceManager.dealAlarmWithServiceType(alarmInfo, serviceType as AlarmServiceType);
      return;
    }
    if (serviceType && serviceType === AlarmServiceType.ToggleFullScreen) {
      if (deviceType !== '2in1') {
        await WantAgentUtil.triggerFullScreenAbility(FullScreenType.Alarm);
      }
      return;
    }
    if (serviceType && serviceType === AlarmServiceType.Update) {
      await AlarmServiceManager.refreshNextAlertTime(want?.parameters?.forceRefreshTimer as boolean);
      return;
    }
    if (!serviceType || !alarmInfo) {
      LogUtil.info(TAG, 'Some parameter is not passed:' + serviceType + ',alarmInfo:' + JSON.stringify(alarmInfo));
      return;
    }
    const isFiring = await AlarmStateManager.isFiring();
    if (isFiring && serviceType === AlarmServiceType.Start) {
      LogUtil.info(TAG, 'one alarm has Firing, so need to clearKillAlarmMessage:' + this.killAlarmMessageId);
      this.clearKillAlarmMessage(this.killAlarmMessageId);
    }
    await AlarmServiceManager.dealAlarmWithServiceType(alarmInfo, serviceType as AlarmServiceType,
      isNotificationCloseButton as boolean, isSnooze as boolean);
    await this.dealKillAlarmMessage(alarmInfo, serviceType as AlarmServiceType);
  }

  async dealKillAlarmMessage(alarmInfo: AlarmInfo | undefined, serviceType: AlarmServiceType): Promise<void> {
    const isFiring = await AlarmStateManager.isFiring();
    const snoozeIds = await SnoozeManager.getSnoozedAlarmId();
    const notificationCnt = await notificationManager.getActiveNotificationCount();
    LogUtil.info(TAG, `dealKillAlarmMessage isFiring:${isFiring} cnt:${notificationCnt} snoozeIds:${JSON.stringify(snoozeIds)} `);
    if (serviceType === AlarmServiceType.Start) {
      if (isFiring && alarmInfo) {
        LogUtil.info(TAG, 'alarm isFiring, so need to sendDelayedKillAlarmMessage');
        this.killAlarmMessageId = this.sendDelayedKillAlarmMessage(alarmInfo);
        AlarmCardUtil.notifyAlarmCardRingUpdate();
      } else {
        AlarmServiceManager.setScreenOff();
        LogUtil.info(TAG, 'no alarm isFiring, so not need to sendDelayedKillAlarmMessage');
      }
    } else {
      if (!isFiring) {
        AlarmServiceManager.setScreenOff();
        this.clearKillAlarmMessage(this.killAlarmMessageId);
        await CommonUtil.terminateAlarmService();
      }
    }
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'onDestroy');
    try {
      GlobalContext.getContext().setObject('AlarmServiceContext', undefined);
      this.clearKillAlarmMessage(this.killAlarmMessageId);
      CommonUtil.terminateFullScreenAbility();
      AlarmServiceManager.setScreenOff();
      AlarmServiceManager.cancelSnoozeInput();
      AlarmServiceManager.stopAudioWorker();
      CommonUtil.releaseCPUResources();
      this.unSubscribeCommentEvent();
    } catch (error) {
      LogUtil.error(TAG, 'onDestroy failed: ', JSON.stringify(error));
    }

  }

  /**
   * Send a delay message after the alarm starts to automatically snooze the alarm.
   */
  private sendDelayedKillAlarmMessage(alarmInfo: AlarmInfo): number {
    this.clearKillAlarmMessage(this.killAlarmMessageId);
    LogUtil.info(TAG, `send auto snooze message alarm id: ${JSON.stringify(alarmInfo.id)}, time:  ${alarmInfo.ringDuration! * SECOND_IN_MINUTE * MILLIS_IN_SECOND}`);
    return setTimeout(async (alarmInfo: AlarmInfo) => {
      LogUtil.info(TAG, 'start to execute delayAlarm for auto snooze');
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      LogUtil.info(TAG, `auto snooze alarmInfo id: ${JSON.stringify(alarmInfo.id)}, firingAlarmId: ${firingAlarmId}`);
      if (alarmInfo.id !== String(firingAlarmId)) {
        return;
      }
      await AlarmServiceManager.delayAlarm(alarmInfo, true);
      this.killAlarmMessageId = 0;
      const isFiring = await AlarmStateManager.isFiring();
      if (!isFiring) {
        AlarmServiceManager.setScreenOff();
        await CommonUtil.terminateAlarmService();
      }
    }, alarmInfo.ringDuration! * SECOND_IN_MINUTE * MILLIS_IN_SECOND, alarmInfo);
  }

  private clearKillAlarmMessage(messageId?: number): void {
    try {
      if (messageId) {
        LogUtil.info(TAG, `clearKillAlarmMessage: ${messageId}`);
        clearTimeout(messageId);
        this.killAlarmMessageId = 0;
      }
    } catch (error) {
      LogUtil.error(TAG, 'clearKillAlarmMessage failed: ', JSON.stringify(error));
    }
  }

  private async subscribeCommentEvent(): Promise<void> {
    this.commonEventSubscriber = await commonEventManager.createSubscriber(TIME_SUBSCRIBE_INFO);
    if (!this.commonEventSubscriber) {
      return;
    }
    commonEventManager.subscribe(this.commonEventSubscriber, async () => {
      LogUtil.info(TAG, 'receive screen off event');
      await AlarmServiceManager.delayFiringAlarm();
    });

    emitter.on({
      eventId: EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE
    }, async (eventData) => {
      LogUtil.info(TAG, `receve EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE: ${JSON.stringify(eventData)}`);
      await this.dealKillAlarmMessage(undefined, AlarmServiceType.Delay);
    })
  }

  private unSubscribeCommentEvent(): void {
    commonEventManager.unsubscribe(this.commonEventSubscriber, error => {
      if (error) {
        LogUtil.error(TAG, `Unsubscribe to common event failed because: ${JSON.stringify(error)}`);
        return;
      }
      LogUtil.info(TAG, 'Unsubscribe to common event event successfully!');
    });
    emitter.off(EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE);
  }
};