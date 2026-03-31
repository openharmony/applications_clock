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
import display from '@ohos.display';
import windowManager from '@ohos.window';
import common from '@ohos.app.ability.common';
import notificationManager from '@ohos.notificationManager'
import { LogUtil } from '@hmos/common';
import emitter from '@ohos.events.emitter';
import image from '@ohos.multimedia.image';
import { NotificationContentUtil } from '@hmos/common/src/main/ets/utils/NotificationContentUtil'
import { WantAgentUtil, TIMEOUT_FULL_SCREEN_CLOSE_ID, } from '@hmos/common';

const TAG = 'TimerManager';

type NotificationRequest = notificationManager.NotificationRequest;

/**
 * Window-related management class
 *
 * @since 2022-08-20
 */
class TimerManager {
  async cancel(alarmId: number | string): Promise<void> {
    LogUtil.info(TAG, 'publish Cancel alarmId:' + alarmId);
    notificationManager.cancel(typeof alarmId === 'string' ? Number(alarmId) : alarmId);
  }

  async timeoutPublishAlarmMissed(alarmId: number | string, alarmAlertTime: number, alarmTitle: string): Promise<void> {
    const title = alarmAlertTime.toString();
    const content = alarmTitle;
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
}

export default new TimerManager();