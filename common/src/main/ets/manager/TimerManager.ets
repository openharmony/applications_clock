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

// import systemTimer from '@ohos.systemTimer';
import preferencesUtil from '@ohos.data.preferences';
import { AlarmServiceType, GlobalContext, LogUtil, WantAgentUtil } from '../utils';
import {
  ALARM_CLOCK_TIMER_ID,
  ALARM_CLOCK_TIMER_STORE,
  ALARM_CLOCK_TRIGGER_TIME,
  ALARM_CLOCK_TRIGGER_TIME_ID,
  AlarmInfo,
  NO_TIMER,
  TRIGGER_TIME_NEVER,
} from './types';
import { BusinessError } from '@ohos.base';
import { ValueType } from '@ohos.data.ValuesBucket';

const TAG = 'TimerManager';

type Preferences = preferencesUtil.Preferences;

/**
 * 定时器管理工具类
 *
 * @since 2022-07-06
 */
class TimerManager {
  private preferences: Preferences | undefined = undefined; // 用于持久化计时器数据的轻量级存储对象

  /**
   * 获取操作内部存储的对象
   *
   * @return 操作内部存储的对象
   */
  async getPreferences(): Promise<Preferences> {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = await preferencesUtil.getPreferences((GlobalContext.getContext()
      .getObject('clockContext') as Context), ALARM_CLOCK_TIMER_STORE);
    return this.preferences as Preferences;
  }

  /**
   * 获取当前生效的定时器的 ID
   *
   * @return 当前生效的定时器的 ID
   */
  async getTimerId(): Promise<number> {
    const preferences = await this.getPreferences();
    const timerIdFromStorage = await preferences.get(ALARM_CLOCK_TIMER_ID, NO_TIMER);
    return Number(timerIdFromStorage);
  }

  /**
   * 获取当前生效的定时器的触发时间
   *
   * @return 当前生效的定时器的触发时间
   */
  async getTriggerTime(): Promise<number> {
    const preferences = await this.getPreferences();
    const triggerTimeFromStorage = await preferences.get(ALARM_CLOCK_TRIGGER_TIME, TRIGGER_TIME_NEVER);
    return Number(triggerTimeFromStorage);
  }

  /**
   * 获取当前生效的定时器的触发时间
   *
   * @return 当前生效的定时器的触发时间
   */
  async getTriggerTimeID(): Promise<number> {
    const preferences = await this.getPreferences();
    const triggerTimeIdFromStorage = await preferences.get(ALARM_CLOCK_TRIGGER_TIME_ID, TRIGGER_TIME_NEVER);
    return Number(triggerTimeIdFromStorage);
  }

  /**
   * 发起闹钟计时
   */
  async startAlarm(alarmInfo: AlarmInfo): Promise<void> {
    try {
      await this.stopAlarm(); // 拉起 timer 前，先停止之前的 timer（如果有）
      const timerId: number = 0;
      LogUtil.info(TAG, 'timerId:' + timerId + ' alarmId:' + alarmInfo.id);
      // LogUtil.info(TAG, 'systemTimer alarmTime:' + alarmInfo.alarmTime);
      // await systemTimer.startTimer(timerId, alarmInfo.alarmTime as number);


      // 将 timerId 和 triggerTime 放入内部存储中，持久化相关字段
      const preferences = await this.getPreferences();
      await preferences.put(ALARM_CLOCK_TIMER_ID, timerId);
      await preferences.put(ALARM_CLOCK_TRIGGER_TIME, alarmInfo.alarmTime as ValueType);
      await preferences.put(ALARM_CLOCK_TRIGGER_TIME_ID, alarmInfo.id);
      await preferences.flush();
    } catch (error) {
      LogUtil.error(TAG, 'Start timer failed: ', (error as BusinessError).message);
    }
  }

  /**
   * 发起闹钟计时
   */
  async startRepeatAlarm(alarmInfo: AlarmInfo): Promise<void> {
    try {
      await this.stopAlarm(); // 拉起 timer 前，先停止之前的 timer（如果有）
      const timerId: number = 0;
      const alarmTime = new Date();
      alarmTime.setHours(alarmInfo.hour);
      alarmTime.setMinutes(alarmInfo.minute);
      alarmTime.setSeconds(0);
      alarmTime.setMilliseconds(0);
      alarmInfo.alarmTime = alarmTime.getTime();
      LogUtil.info(TAG, 'repeatTimerId:' + timerId + ' alarmId:' + alarmInfo.id +
        'repeatSystemTimer alarmTime:' + alarmInfo.alarmTime);
      // await systemTimer.startTimer(timerId, alarmInfo.alarmTime as number);

      // 将 timerId 和 triggerTime 放入内部存储中，持久化相关字段
      const preferences = await this.getPreferences();
      await preferences.put(ALARM_CLOCK_TIMER_ID, timerId);
      await preferences.put(ALARM_CLOCK_TRIGGER_TIME, alarmInfo.alarmTime as ValueType);
      await preferences.put(ALARM_CLOCK_TRIGGER_TIME_ID, alarmInfo.id);
      await preferences.flush();
    } catch (error) {
      LogUtil.error(TAG, 'Start timer failed: ', (error as BusinessError).message);
    }
  }

  /**
   * 停止闹钟计时
   */
  async stopAlarm(): Promise<void> {
    const timerId = await this.getTimerId();
    if (!timerId || timerId === NO_TIMER) {
      return;
    }
    try {
      const preferences = await this.getPreferences();
      await preferences.delete(ALARM_CLOCK_TRIGGER_TIME);
      await preferences.delete(ALARM_CLOCK_TRIGGER_TIME_ID);
      await preferences.delete(ALARM_CLOCK_TIMER_ID);
      await preferences.flush();
      // await systemTimer.stopTimer(timerId);
      LogUtil.info(TAG, 'Stop timerId: ' + timerId);
    } catch (error) {
      LogUtil.error(TAG, 'Stop timer failed: ', (error as BusinessError).message);
    }
  }
}

export default new TimerManager();