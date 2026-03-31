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
  AlarmInfo,
  AlarmManager,
  AlarmServiceType,
  FIRST_PARAM,
  GlobalContext,
  LogUtil,
  ResourceManager,
  SECOND_PARAM,
  STR_PLACE_HOLDER,
  TIMER_NOTICE_ID,
  TimeUtil,
  WantAgentUtil,
  EventName,
  EventReportUtil
} from '@hmos/common';
import { NotificationContentUtil } from '@hmos/common/src/main/ets/utils/NotificationContentUtil'
import image from '@ohos.multimedia.image';
import { AlarmServiceManager } from '../manager';
import deviceInfo from '@ohos.deviceInfo'
// import hiSysEvent from '@ohos.hiSysEvent';

const deviceType: string = deviceInfo.deviceType;

interface BundleInfo {
  bundle: string
}

interface ButtonInfo {
  title: string,
  wantAgent: object,
}

const TAG = 'NotificationUtil';

LogUtil.info(TAG, `deviceType-----${deviceType}`)
const SEPARATOR = ' ';
const BUNDLE_INFO: BundleInfo = {
  bundle: 'ohos.samples.clock',
};

type NotificationRequest = notificationManager.NotificationRequest;
type ActionButtons = Array<notificationManager.NotificationActionButton>;

/**
 * Notification Tool Class
 *
 * @since 2022-07-27
 */
export class NotificationUtil {
  /**
   * Send a notification after the alarm starts
   */
  static async publishAlarmReminder(alarmId: number | string, alarmTime: number, alarmTitle: string): Promise<void> {
    if (!alarmTime) {
      LogUtil.info(TAG, `alarmTime is diabled value is:  ${alarmTime}`);
      return;
    }
    const content = TimeUtil.getFormattedTime(alarmTime);
    LogUtil.info(TAG, 'publishAlarmReminder alarmId:' + alarmId)
    LogUtil.info(TAG, 'publishAlarmReminder content:' + content)
    if (deviceType === '2in1') {
      await NotificationUtil.publishNotificationPC(alarmId, alarmTitle, content);
    } else {
      await NotificationUtil.publishNotification(alarmId, content, alarmTitle);
      ;
    }
  }

  /**
   * Send notification after delay
   */
  static async publishAlarmSnooze(alarmId: number | string, nextAlertTime: number, snoozeDuration: number,
                                  alarmTitle: string): Promise<void> {
    if (!alarmId || !nextAlertTime || !alarmTitle) {
      LogUtil.error(TAG, 'Execute method publishAlarmSnooze failed, params is incorrect.');
      return;
    }
    const alarmLabel = await ResourceManager.getStringByIdAsync($r('app.string.alarm_clock').id);
    const title = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_snooze_title').id)).replace(STR_PLACE_HOLDER, alarmLabel);
    const alarmTimeStr = TimeUtil.getFormattedTime(nextAlertTime);
    const snoozeTimeInfo = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_snooze_context').id
    )).replace(STR_PLACE_HOLDER, alarmTimeStr);
    const content = (await ResourceManager.getStringByIdAsync(
      $r('app.string.format_notify_text').id
    ))
      .replace(FIRST_PARAM, snoozeTimeInfo)
      .replace(SECOND_PARAM, alarmTitle);
    LogUtil.info(TAG, 'publishAlarmSnooze alarmId:' + alarmId)
    LogUtil.info(TAG, 'publishAlarmSnooze content:' + content)
    await NotificationUtil.publishAlarmManual(alarmId, nextAlertTime, snoozeDuration, content);
  }

  /**
   * Send a notification that the alarm is missed
   *
   * @param alarmId Alarm id
   * @param alarmAlertTime Time when the alarm clock last started
   * @param alarmAlertTime Alarm title
   */
  static async publishAlarmManual(alarmId: number | string, alarmAlertTime: number, snoozeDuration: number,
                                  alarmTitle: string): Promise<void> {
    if (!alarmId || !alarmAlertTime || !alarmTitle) {
      LogUtil.error(TAG, 'Execute method publishAlarmManual failed, params is incorrect.');
      return;
    }
    const title = alarmAlertTime.toString();
    const content = alarmTitle;
    const initialTime = snoozeDuration * 60 * 1000;
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('alarm')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('alarm_capsule')
      const iconsPixelMap: image.PixelMap[] = [await NotificationContentUtil.createPixelMap('alarm_stop')]
      const iconsPixelMapNames: string[] = ['alarm_stop']
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
            typeCode: 5,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: content,
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
        extraInfo: { isMute: true },
        wantAgent: await WantAgentUtil.getMainPageWantAgent()
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `publishAlarmManual success: ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `publishAlarmManual failed : ${JSON.stringify(error)}`);
    }
  }

  static async publishAlarmMissed(alarmId: number | string, alarmAlertTime: number,
                                  alarmTitle: string): Promise<void> {
    if (!alarmId || !alarmAlertTime || !alarmTitle) {
      LogUtil.error(TAG, 'Execute method publishAlarmMissedPC failed, params is incorrect.');
      return;
    }
    const alarmLabel = await ResourceManager.getStringByIdAsync($r('app.string.alarm_clock').id);
    const title = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_miss_label').id)).replace(STR_PLACE_HOLDER, alarmLabel);
    const dayOfWeek = TimeUtil.getDayOfWeekByDate(new Date(alarmAlertTime));
    const alarmTimeStr = `${dayOfWeek}${SEPARATOR}${TimeUtil.getFormattedTime(alarmAlertTime)}`;
    const content = (await ResourceManager.getStringByIdAsync(
      $r('app.string.format_notify_text').id
    ))
      .replace(FIRST_PARAM, alarmTimeStr)
      .replace(SECOND_PARAM, alarmTitle);
    LogUtil.info(TAG, 'publishAlarmMissed alarmId:' + alarmId)
    LogUtil.info(TAG, 'publishAlarmMissed content:' + content)
    try {
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('alarm')
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
            typeCode: 5,
          }
        },
        extraInfo: { isMute: true },
        wantAgent: await WantAgentUtil.getMainPageWantAgent(alarmId, true)
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `publishAlarmMissed success: ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `publishAlarmMissed failed : ${JSON.stringify(error)}`);
    }
  }

  private static async publishNotification(alarmId: number | string, title: string, content: string,
                                           isSnooze?: boolean): Promise<void> {
    try {
      let alarmInfo: AlarmInfo = ((GlobalContext.getContext()
        .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
      const largeIcon: image.PixelMap = await NotificationContentUtil.createPixelMap('alarm')
      const iconPixelMap: image.PixelMap = await NotificationContentUtil.createPixelMap('alarm_capsule')
      const iconsPixelMap: image.PixelMap[] = [
        await NotificationContentUtil.createPixelMap('alarm_sleep'),
        await NotificationContentUtil.createPixelMap('alarm_stop')
      ]
      const iconsPixelMapNames: string[] = ['alarm_sleep', 'alarm_stop']
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
            typeCode: 5,
            button: {
              icons: iconsPixelMap,
              names: iconsPixelMapNames
            },
            capsule: {
              title: content,
              icon: iconPixelMap,
              backgroundColor: '#3778EF',
            }
          }
        },
        extraInfo: { isMute: true, hw_heads_up_enable: true, hw_keep_headsup_sticky: true },
        wantAgent: isSnooze ? await WantAgentUtil.getMainPageWantAgent() :
          await WantAgentUtil.getToggleFullScreenWantAgent(alarmInfo),
        tapDismissed: !isSnooze,
        isUnremovable: true,
      };
      if (isSnooze && isSnooze === true) {
        LogUtil.info(TAG, 'isSnooze:' + isSnooze);
        notificationRequest.extraInfo!.hw_keep_headsup_sticky = false
      }
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `publishNotification success: ${JSON.stringify(notificationRequest)}`);
    } catch (error) {
      LogUtil.error(TAG, `publishNotification failed: ${JSON.stringify(error)}`);
    }
  }

  static async notificationSubscribeSystemSubscriber(): Promise<void> {
    LogUtil.info(TAG, `subscriber_id : JSON.stringify(id)`)
    LogUtil.info(TAG, `subscriber_optionBtn : JSON.stringify(option.buttonName)`)
    // notificationManager.subscribeSystemLiveView({
    //   onResponse: async (id: number, option: notificationManager.ButtonOptions) => {
    //     if (id != Number(TIMER_NOTICE_ID)) {
    //       LogUtil.info(TAG, `subscriber_id : ${JSON.stringify(id)}`)
    //       LogUtil.info(TAG, `subscriber_optionBtn : ${JSON.stringify(option.buttonName)}`)
    //       const alarmFromList = await AlarmManager.getIDAlarmFrom(id.toString() as string);
    //       if (alarmFromList.length > 0) {
    //         if (option.buttonName == 'alarm_sleep') {
    //           // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.NOTIFICATION_BAR_REMIND_LATER)
    //           WantAgentUtil.triggerDelayAlarm(alarmFromList[0]!)
    //         } else if (option.buttonName == 'alarm_stop') {
    //           // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.NOTIFICATION_BANNER_CLOSE_ALARM)
    //           WantAgentUtil.triggerCloseAlarm(alarmFromList[0]!);
    //         }
    //       } else {
    //         return
    //       }
    //     }
    //   }
    // })
  }

  /**
   * Cancel notification by alarmId
   *
   * @param alarmId Alarm id
   */
  static async cancel(alarmId: number | string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method cancel failed, alarmId is incorrect.');
    }
    try {
      await notificationManager.cancel(typeof alarmId === 'string' ? Number(alarmId) : alarmId);
      LogUtil.info(TAG, 'publish Cancel alarmId:' + alarmId);
    } catch (error) {
      LogUtil.info(TAG, `cancel failed=>${error}`)
    }
  }

  private static async publishNotificationPC(alarmId: number | string, title: string, content: string,
                                             isSnooze?: boolean): Promise<void> {
    try {
      let alarmInfo: AlarmInfo = ((GlobalContext.getContext()
        .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
      const actionButtons = await NotificationUtil.getActionButtons(isSnooze, alarmId);
      const notificationRequest: NotificationRequest = {
        id: typeof alarmId === 'string' ? Number(alarmId) : alarmId,
        content: {
          contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content,
          },
        },
        slotType: notification.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: await WantAgentUtil.getMainPageWantAgent(),
        tapDismissed: !isSnooze,
        actionButtons,
        extraInfo: {
          isMute: true,
          hw_keep_headsup_sticky: true,
          hw_heads_up_enable: true
        },
        isUnremovable: true,
      };
      if (isSnooze && isSnooze === true) {
        LogUtil.info(TAG, 'isSnooze:' + isSnooze);
        notificationRequest.extraInfo!.hw_keep_headsup_sticky = false
      }
      LogUtil.info(TAG, 'publishNotificationPC notification:', `${JSON.stringify(notificationRequest)}`);
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, 'publishNotificationPC notification success');
    } catch (error) {
      LogUtil.error(TAG, 'publishNotificationPC notification failed : ', `${JSON.stringify(error)}`);
    }
  }

  static async publishAlarmSnoozePC(alarmId: number | string, nextAlertTime: number,
                                    alarmTitle: string): Promise<void> {
    if (!alarmId || !nextAlertTime || !alarmTitle) {
      LogUtil.error(TAG, 'Execute method publishAlarmSnooze failed, params is incorrect.');
      return;
    }
    const alarmLabel = await ResourceManager.getStringByIdAsync($r('app.string.alarm_clock').id);
    const title = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_snooze_title').id)).replace(STR_PLACE_HOLDER, alarmLabel);
    const alarmTimeStr = TimeUtil.getFormattedTime(nextAlertTime);
    const snoozeTimeInfo = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_snooze_context').id
    )).replace(STR_PLACE_HOLDER, alarmTimeStr);
    const content = (await ResourceManager.getStringByIdAsync(
      $r('app.string.format_notify_text').id
    ))
      .replace(FIRST_PARAM, snoozeTimeInfo)
      .replace(SECOND_PARAM, alarmTitle);
    LogUtil.info(TAG, 'publishAlarmSnoozePC alarmId:' + alarmId)
    LogUtil.info(TAG, 'publishAlarmSnoozePC content:' + content)
    await NotificationUtil.publishNotificationPC(alarmId, title, content, true);
  }

  static async publishAlarmMissedPC(alarmId: number | string, alarmAlertTime: number,
                                    alarmTitle: string): Promise<void> {
    if (!alarmId || !alarmAlertTime || !alarmTitle) {
      LogUtil.error(TAG, 'Execute method publishAlarmMissedPC failed, params is incorrect.');
      return;
    }
    const alarmLabel = await ResourceManager.getStringByIdAsync($r('app.string.alarm_clock').id);
    const title = (await ResourceManager.getStringByIdAsync(
      $r('app.string.alarm_notify_miss_label').id)).replace(STR_PLACE_HOLDER, alarmLabel);
    const dayOfWeek = TimeUtil.getDayOfWeekByDate(new Date(alarmAlertTime));
    const alarmTimeStr = `${dayOfWeek}${SEPARATOR}${TimeUtil.getFormattedTime(alarmAlertTime)}`;
    const content = (await ResourceManager.getStringByIdAsync(
      $r('app.string.format_notify_text').id
    ))
      .replace(FIRST_PARAM, alarmTimeStr)
      .replace(SECOND_PARAM, alarmTitle);
    LogUtil.info(TAG, 'publishAlarmMissedPC alarmId:' + alarmId)
    LogUtil.info(TAG, 'publishAlarmMissedPC content:' + content)
    try {
      const notificationRequest: NotificationRequest = {
        id: typeof alarmId === 'string' ? Number(alarmId) : alarmId,
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: content,
          }
        },
        extraInfo: { isMute: true },
        wantAgent: await WantAgentUtil.getMainPageWantAgent(alarmId, true)
      };
      await notificationManager.publish(notificationRequest);
      LogUtil.info(TAG, `publishAlarmMissedPC success : ${JSON.stringify(notificationRequest)}`)
    } catch (error) {
      LogUtil.error(TAG, `publishAlarmMissedPC failed : ${JSON.stringify(error)}`);
    }
  }

  private static async getActionButtons(isSnooze?: boolean, alarmId?: number | string): Promise<ActionButtons> {
    let alarmInfo: AlarmInfo = ((GlobalContext.getContext()
      .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
    if (alarmInfo?.id !== alarmId) {
      LogUtil.info(TAG, 'abilityWant not contain alarmId')
      alarmInfo = await AlarmManager.getLatestAlarmFromDb(alarmId!) as AlarmInfo;
      LogUtil.info(TAG, 'firingAlarm:' + JSON.stringify(alarmInfo))
    } else {
      LogUtil.info(TAG, 'abilityWant contain alarmId')
    }
    if (!alarmInfo) {
      return [];
    }
    const buttons: ButtonInfo[] = [
      {
        title: await ResourceManager.getStringByIdAsync($r('app.string.close').id),
        wantAgent: await WantAgentUtil.getAlarmWantAgent(alarmInfo, AlarmServiceType.Close, true, isSnooze) as object,
      }
    ];
    if (!isSnooze) {
      buttons.push({
        title: await ResourceManager.getStringByIdAsync($r('app.string.sleep').id),
        wantAgent: await WantAgentUtil.getAlarmWantAgent(alarmInfo, AlarmServiceType.Delay) as object,
      });
    }
    return buttons;
  }
}
