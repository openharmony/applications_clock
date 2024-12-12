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

import preferencesUtil from '@ohos.data.preferences';
import { GlobalContext } from '../utils';
import {
  ALARM_CLOCK_SNOOZE_STORE,
  ALERT_TIME_DEFAULT_DATA,
  SNOOZE_COUNT_STEP,
  SNOOZE_ID,
  SNOOZE_SEPARATOR,
} from './types';

type Preferences = preferencesUtil.Preferences;

/**
 * Nap Management Tool Class
 *
 * @since 2022-10-27
 */
class SnoozeManager {
  private preferences: Preferences | undefined = undefined;

  /**
   * Get SnoozeManager Preferences instance.
   *
   * @return Preferences instance
   */
  private async getPreferences(): Promise<Preferences> {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = await preferencesUtil.getPreferences((GlobalContext.getContext()
      .getObject('clockContext') as Context), ALARM_CLOCK_SNOOZE_STORE);
    return this.preferences as Preferences;
  }

  /**
   * Obtains the number of naps.
   *
   * @param alarmId alarm id
   * @return number of naps
   */
  async getSnoozedTimes(alarmId: string): Promise<number> {
    const preferences = await this.getPreferences();
    const snoozedTimes = await preferences.get(alarmId, 0);
    return Number(snoozedTimes);
  }

  /**
   * The number of naps increases once.
   *
   * @param alarmId alarm id
   */
  async increaseSnoozedTimes(alarmId: string): Promise<void> {
    const snoozedTimes = await this.getSnoozedTimes(alarmId);
    const preferences = await this.getPreferences();
    await preferences.put(alarmId, snoozedTimes + SNOOZE_COUNT_STEP);
    await preferences.flush();
  }

  /**
   * Clear the number of naps
   *
   * @param alarmId alarm id
   */
  async clearSnoozeTimes(alarmId: string): Promise<void> {
    const preferences = await this.getPreferences();
    await preferences.delete(alarmId);
    await preferences.flush();
  }

  /**
   * Save Next Nap Timestamp
   *
   * @param alarmId alarm id
   * @param nextAlertTime next Nap Timestamp
   */
  async saveSnoozedAlarmData(alarmId: string, nextAlertTime: number): Promise<void> {
    const preferences = await this.getPreferences();
    const snoozeIds = await preferences.get(SNOOZE_ID, '');
    let snoozeArray: string[] = [];
    if (snoozeIds) {
      snoozeArray = snoozeIds.toString().split(SNOOZE_SEPARATOR);
      if (!snoozeArray.includes(alarmId)) {
        snoozeArray.push(alarmId);
      }
    } else {
      snoozeArray.push(alarmId);
    }
    await preferences.put(SNOOZE_ID, snoozeArray.join(SNOOZE_SEPARATOR));
    await preferences.put(`${SNOOZE_ID}${alarmId}`, nextAlertTime);
    await preferences.flush();
  }

  /**
   * Obtains the ids of all snooze alarms.
   *
   * @param snooze alarms ids
   * @return all snoozed alarm ids
   */
  async getSnoozedAlarmId(): Promise<string[]> {
    const preferences = await this.getPreferences();
    const snoozeIds = await preferences.get(SNOOZE_ID, '');
    return snoozeIds ? snoozeIds.toString().split(SNOOZE_SEPARATOR) : [];
  }

  /**
   * Delete the nap data
   *
   * @param alarmId alarm id
   */
  async deleteSnoozedAlarmId(alarmId: string): Promise<void> {
    const snoozeIdsArray = await this.getSnoozedAlarmId();
    const newSnoozeIdsArray = snoozeIdsArray.filter(id => alarmId !== id);
    const preferences = await this.getPreferences();
    await preferences.put(SNOOZE_ID, newSnoozeIdsArray.join(SNOOZE_SEPARATOR));
    await preferences.delete(SNOOZE_ID + alarmId);
    await preferences.flush();
  }

  /**
   * Obtains the next start time.
   *
   * @param alarmId alarm id
   * @return next alert time
   */
  async getNextAlertTime(alarmId: string): Promise<number> {
    const preferences = await this.getPreferences();
    const nextAlertTime = await preferences.get(SNOOZE_ID + alarmId, ALERT_TIME_DEFAULT_DATA);
    return Number(nextAlertTime);
  }
}

export default new SnoozeManager();