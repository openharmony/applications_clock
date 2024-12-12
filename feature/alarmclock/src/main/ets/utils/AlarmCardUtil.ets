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

import resmgr from '@ohos.resourceManager';
import {
  FormUtil,
  GlobalContext,
  LogUtil,
  ResourceManager,
  TIME_TAG_ID_LIST_IN_ZH,
  TimeUtil,
  AlarmStateManager,
  AlarmManager,
  AlarmInfo
} from '@hmos/common';


const TAG: string = 'AlarmCardUtil';
const TRIGGER_TIME_NEVER: number = -1;
const HOUR_OF_DAY: number = 24;
const MINUTES_OF_THIRTY: number = 30;
const MINUTES_OF_TEN: number = 10;
const ONE_DAY: number = 1;
const ZERO_DAY: number = 0;
const ZERO_HOUR: number = 0;
const ZERO_MINUTE: number = 0;
const ZERO_SECOND: number = 0;
const ALARM_CARD: string = 'ALARM_CARD';

/**
 * Alarm Clock Card Util
 *
 * @since 2023-06-08
 */
export class AlarmCardUtil {
  /**
   * notify AlarmCard show Ring when alarmClock is ringing
   *
   * @returns
   */
  public static async notifyAlarmCardRingUpdate(): Promise<void> {
    const ringingTips = await ResourceManager.getStringByIdAsync($r('app.string.fa_ringing').id);
    const firingAlarmId = await AlarmStateManager.getAlarmId();
    const firingAlarm = await AlarmManager.getLatestAlarmFromDb(firingAlarmId) as AlarmInfo;
    let timeStemp = TimeUtil.getAlarmTime(firingAlarm)
    LogUtil.info(TAG, `firingAlarm: ${JSON.stringify(firingAlarm)}, timeStemp=${timeStemp}`);
    const formData: Record<string, Object> = {
      'nextAlarmTime': ringingTips,
      'noAlarms': false,
      'isRinging': true,
      'remainingTime': '',
      'ringingTimestamp': timeStemp
    };
    FormUtil.notifyClockCardChanged(formData, ALARM_CARD);
  }

  /**
   * notify AlarmCard Time Update when clock modify
   *-大于等于24小时:“n天后响铃”
   *-大于等于30分钟,小于24小时:“n小时内响铃” (向上取整,例:4h32min显示5小时内响铃)
   *- 大于等于10分钟,小于30分钟:“30分钟内响铃”
   *-小于10分钟:“即将响铃”
   * @returns
   */
  public static async notifyAlarmCardTimeUpdate(): Promise<void> {
    let ringTimeInMs: number = await TimeUtil.getNextAlarmTime();
    const isFiring = await AlarmStateManager.isFiring();
    LogUtil.info(TAG, `notifyAlarmCardTimeUpdate ringTimeInMs:${ringTimeInMs}, isFiring=${isFiring}`);
    if (isFiring) {
      return AlarmCardUtil.notifyAlarmCardRingUpdate();
    }
    if (ringTimeInMs === TRIGGER_TIME_NEVER) {
      const nextAlarmTime: ResourceStr = $r('app.string.fa_no_alarms');
      let formData: Record<string, Object> = {
        'nextAlarmTime': nextAlarmTime,
        'noAlarms': true,
        'isRinging': false,
        'remainingTime': '',
        'ringingTimestamp': 0
      };
      LogUtil.info(TAG, 'notifyAlarmCardTimeUpdate formData:' + JSON.stringify(formData));
      FormUtil.notifyClockCardChanged(formData, ALARM_CARD);
    } else {
      await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
      const nextAlarmTime = TimeUtil.getFormattedTime(ringTimeInMs);
      const currentDate = new Date();
      const leftTimeInMs = ringTimeInMs - currentDate.getTime();
      if (leftTimeInMs < 0) {
        return;
      }
      const leftTime = new Date(leftTimeInMs);
      const leftMinutes = leftTime.getUTCMinutes();
      const leftSeconds = leftTime.getUTCSeconds();
      const leftHours = leftTime.getUTCHours();
      const leftDays = leftTime.getUTCDate() - ONE_DAY;
      LogUtil.info(TAG, `notifyAlarmCardTimeUpdate leftDays=${leftDays}, leftHours=${leftHours}, leftMinutes=${leftMinutes},ringTimeInMs =${ringTimeInMs}, currentDate=${currentDate.getTime()}, leftTimeInMs=${leftTimeInMs}`);
      let remainTime: Object;
      if (leftDays !== ZERO_DAY) {
        let dayNum = leftDays;
        remainTime = dayNum > ONE_DAY ? $r('app.string.ring_within_other_days', dayNum) : $r('app.string.ring_within_one_days', dayNum);
      } else {
        if (leftHours !== ZERO_HOUR) {
          let hoursNum = leftHours;
          if (leftMinutes !== ZERO_MINUTE) {
            hoursNum++
          } else {
            if (leftSeconds !== ZERO_SECOND) {
              hoursNum++
            }
          }
          remainTime = hoursNum > ONE_DAY ? $r('app.string.ring_within_other_hours', hoursNum) : $r('app.string.ring_within_one_hours', hoursNum);

        } else {
          if (leftMinutes >= MINUTES_OF_THIRTY) {
            remainTime = $r('app.string.ring_within_one_hours', 1);
          } else if (leftMinutes < MINUTES_OF_TEN) {
            remainTime = $r('app.string.ringing_soon');
          } else {
            remainTime = $r('app.string.ring_within_minutes', MINUTES_OF_THIRTY);
          }
        }
      }
      let formData: Record<string, Object> = {
        'nextAlarmTime': nextAlarmTime,
        'noAlarms': false,
        'isRinging': false,
        'remainingTime': remainTime,
        'ringingTimestamp': ringTimeInMs
      };
      LogUtil.info(TAG, 'notifyAlarmCardTimeUpdate formData:' + JSON.stringify(formData));
      FormUtil.notifyClockCardChanged(formData, ALARM_CARD);
    }
  }
}