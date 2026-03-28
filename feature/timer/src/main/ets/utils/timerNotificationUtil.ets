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

import screenLock from '@ohos.screenLock';
import Want from '@ohos.app.ability.Want';
import notificationManager from '@ohos.notificationManager'
import notification from '@ohos.notification'
import {
  GlobalContext,
  LEFT_TIME_TIMER_PREFERENCES_CLOCK,
  LogUtil,
  ResourceManager,
  TimerServiceType,
  TIMEOUT_FULL_SCREEN_CLOSE_ID,
  TimerStateManager,
  TIMER_NOTICE_ID,
  TIME_PAUSE_OR_CONTINUE_ID,
  WantAgentUtil
} from '@hmos/common';
import { NotificationContentUtil } from '@hmos/common/src/main/ets/utils/NotificationContentUtil'
import image from '@ohos.multimedia.image';
import deviceInfo from '@ohos.deviceInfo'
import resmgr from '@ohos.resourceManager';
import emitter from '@ohos.events.emitter';

const TAG = 'TimerNotificationUtil';
const deviceType: string = deviceInfo.deviceType;
const UPDATE_INTERVAL: number = 150;

type NotificationRequest = notificationManager.NotificationRequest;
type ActionButtons = Array<notificationManager.NotificationActionButton>;

interface ButtonInfo {
  title: string,
  wantAgent: object,
}

LogUtil.info(TAG, `deviceType-----${deviceType}`)

export class TimerNotificationUtil {
  static async notificationSubscribeSystemSubscriber(): Promise<void> {
    LogUtil.info(TAG, `subscriber_id : JSON.stringify(id)`)
    LogUtil.info(TAG, `subscriber_optionBtn : JSON.stringify(option.buttonName)`)
    // notificationManager.subscribeSystemLiveView({
    //   onResponse: async (id: number, option: notificationManager.ButtonOptions) => {
    //     if (id == Number(TIMER_NOTICE_ID)) {
    //       LogUtil.info(TAG, `subscriber_id : ${JSON.stringify(id)}`)
    //       LogUtil.info(TAG, `subscriber_optionBtn : ${JSON.stringify(option.buttonName)}`)
    //       if (option.buttonName == 'timer_begin') {
    //         emitter.emit({ eventId: TIME_PAUSE_OR_CONTINUE_ID, priority: emitter.EventPriority.IMMEDIATE })
    //       } else if (option.buttonName == 'timer_pause') {
    //         emitter.emit({ eventId: TIME_PAUSE_OR_CONTINUE_ID, priority: emitter.EventPriority.IMMEDIATE })
    //       } else if (option.buttonName == 'timer_stop') {
    //         TimerNotificationUtil.cancel(TIMER_NOTICE_ID)
    //         emitter.emit({ eventId: TIMEOUT_FULL_SCREEN_CLOSE_ID, priority: emitter.EventPriority.IMMEDIATE })
    //       }
    //     }
    //   }
    // })
  }

  static async cancel(timerId: number | string): Promise<void> {
    LogUtil.info(TAG, 'publish Cancel timerId:' + timerId);
    notificationManager.cancel(typeof timerId === 'string' ? Number(timerId) : timerId);
  }


  static async startPublishAlarmMissed(timerId: number | string, alarmAlertTime: number): Promise<void> {
    const title = alarmAlertTime.toString();
    const content = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('is_counting_down');
    const initialTime = Math.ceil((alarmAlertTime - UPDATE_INTERVAL) / 1000) * 1000;
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('timer')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('timer_capsule')
      const iconsPixelMap: image.PixelMap[] = [
        await NotificationContentUtil.createPixelMap('timer_pause'),
        await NotificationContentUtil.createPixelMap('timer_stop')
      ]
      const iconsPixelMapNames: string[] = ['timer_pause', 'timer_stop']
      const notificationRequest: NotificationRequest = {
        id: typeof timerId === 'string' ? Number(timerId) : timerId,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        largeIcon: largeIcon,
        smallIcon: largeIcon,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: title,
            text: content,
            typeCode: 6,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: title,
              icon: iconPixelMap,
              backgroundColor: '#3778EF',
            },
            time: {
              initialTime: initialTime,
              isCountDown: true,
              isInTitle: true,
              isPaused: false
            }
          }
        },
        extraInfo: { isMute: true, hw_heads_up_enable: false },
        wantAgent: await WantAgentUtil.getTimerMainPageWantAgent('TIMER_TAB')
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `startPublishAlarmMissed success: ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `startPublishAlarmMissed failed: ${JSON.stringify(error)}`);
    }
  }

  static async pausePublishAlarmMissed(timerId: number | string, alarmAlertTime: number): Promise<void> {
    const alarmAlertTimeNew = alarmAlertTime - UPDATE_INTERVAL;
    const title = alarmAlertTime.toString();
    const content = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('countdown_pause');
    const initialTime = Math.ceil(alarmAlertTimeNew / 1000) * 1000;
    LogUtil.info(TAG, `alarmAlertTime=${alarmAlertTime},initialTime = ${initialTime}`)
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('timer')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('timer_capsule')
      const iconsPixelMap: image.PixelMap[] = [
        await NotificationContentUtil.createPixelMap('timer_begin'),
        await NotificationContentUtil.createPixelMap('timer_stop')
      ]
      const iconsPixelMapNames: string[] = ['timer_begin', 'timer_stop']
      const notificationRequest: NotificationRequest = {
        id: typeof timerId === 'string' ? Number(timerId) : timerId,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        largeIcon: largeIcon,
        smallIcon: largeIcon,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: title,
            text: content,
            typeCode: 6,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: title,
              icon: iconPixelMap,
              backgroundColor: '#3778EF',
            },
            time: {
              initialTime: initialTime,
              isCountDown: true,
              isInTitle: true,
              isPaused: true
            }
          }
        },
        extraInfo: { isMute: true, hw_heads_up_enable: false },
        wantAgent: await WantAgentUtil.getTimerMainPageWantAgent('TIMER_TAB')
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `pausePublishAlarmMissed success : ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `pausePublishAlarmMissed failed: ${JSON.stringify(error)}`);
    }
  }

  static async timeoutPublishAlarmMissed(timerId: number | string, alarmAlertTime: number): Promise<void> {
    const title = alarmAlertTime.toString();
    const content = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('timer_timeout');
    const initialTime = alarmAlertTime;
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('timer')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('timer_capsule')
      const iconsPixelMap: image.PixelMap[] = [await NotificationContentUtil.createPixelMap('timer_stop')]
      const iconsPixelMapNames: string[] = ['timer_stop']
      const notificationRequest: NotificationRequest = {
        id: typeof timerId === 'string' ? Number(timerId) : timerId,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        largeIcon: largeIcon,
        smallIcon: largeIcon,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: title,
            text: content,
            typeCode: 6,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: title,
              icon: iconPixelMap,
              backgroundColor: '#3778EF',
            },
            time: {
              initialTime: initialTime,
              isCountDown: false,
              isInTitle: true,
              isPaused: false
            }
          }
        },
        extraInfo: { isMute: true, hw_heads_up_enable: true, hw_keep_headsup_sticky: true },
        wantAgent: await WantAgentUtil.getTimerFullScreenWantAgent()
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `timeoutPublishAlarmMissed success: ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `timeoutPublishAlarmMissed faild: ${JSON.stringify(error)}`);
    }
  }

  static async timeoutSlipUpPublish(alarmId: number | string, alarmAlertTime: number): Promise<void> {
    const title = alarmAlertTime.toString();
    const content = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('timer_timeout');
    const initialTime = alarmAlertTime;
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('timer')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('timer_capsule')
      const iconsPixelMap: image.PixelMap[] = [await NotificationContentUtil.createPixelMap('timer_stop')]
      const iconsPixelMapNames: string[] = ['timer_stop']
      const notificationRequest: NotificationRequest = {
        id: typeof alarmId === 'string' ? Number(alarmId) : alarmId,
        notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
        largeIcon: largeIcon,
        smallIcon: largeIcon,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
          systemLiveView: {
            title: title,
            text: content,
            typeCode: 6,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: title,
              icon: iconPixelMap,
              backgroundColor: '#3778EF',
            },
            time: {
              initialTime: initialTime,
              isCountDown: false,
              isInTitle: true,
              isPaused: false
            }
          }
        },
        extraInfo: { isMute: true, hw_heads_up_enable: false, hw_keep_headsup_sticky: true },
        wantAgent: await WantAgentUtil.getTimerFullScreenWantAgent()
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `timeoutPublishAlarmMissed success: ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `timeoutPublishAlarmMissed faild: ${JSON.stringify(error)}`);
    }
  }

  static async timeoutPublishAlarmMissedPC(timerId: number | string, alarmAlertTime: number): Promise<void> {
    LogUtil.info(TAG, 'startPublishAlarmMissedPC1 notification success');
    const title = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringSync($r('app.string.timer').id);
    const content = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('timer_timeout');
    try {
      const actionButtons = await TimerNotificationUtil.getActionButtons(timerId);
      const notificationRequest: NotificationRequest = {
        id: typeof timerId === 'string' ? Number(timerId) : timerId,
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        content: {
          contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content,
          },
        },
        actionButtons,
        extraInfo: {
          isMute: true,
          hw_keep_headsup_sticky: true,
          hw_heads_up_enable: true
        },
        isUnremovable: true,
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, 'startPublishAlarmMissedPC notification success');
    } catch (error) {
      LogUtil.error(TAG, 'startPublishAlarmMissedPC notification failed : ', `${JSON.stringify(error)}`);
    }
  }

  private static async getActionButtons(timerId?: number | string): Promise<ActionButtons> {
    let timerIdNext = timerId;
    if (!timerIdNext) {
      timerIdNext = 0;
    }
    const buttons: ButtonInfo[] = [
      {
        title: await ResourceManager.getStringByIdAsync($r('app.string.close').id),
        wantAgent: await WantAgentUtil.timerWantAgent(TimerServiceType.Close, timerIdNext) as object,
      }
    ];
    return buttons;
  }
}
