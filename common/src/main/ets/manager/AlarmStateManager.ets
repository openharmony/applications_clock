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
import { LogUtil } from '../utils';
import { GlobalContext } from '../utils';
import { APP_CONFIG, STATE_FIRING, STATE_SNOOZE, STATE_IDLE, STATE_STOP, DEFAULT_ALARM_ID, } from './types';

const KEY_ALARM_STATE = 'alarm_state';

const KEY_ALARM_STATE_ID = 'alarm_state_id';

const TAG = 'AlarmStateManager';

type Preferences = preferencesUtil.Preferences;

/**
 * Manager Alarm state Tool Class
 *
 * @since 2022-11-24
 */
class AlarmStateManager {
  private preferences: Preferences | undefined = undefined;

  /**
   * Get AlarmStateManager Preferences instance.
   *
   * @return Preferences instance
   */
  private async getPreferences(): Promise<Preferences> {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    return this.preferences as Preferences;
  }

  /**
   * set alarm state
   *
   * @param currentState alarm state
   * @param alarmId alarm id
   */
  private async setState(currentState: number, alarmId: string): Promise<void> {
    const preferences = await this.getPreferences();
    await preferences.put(KEY_ALARM_STATE, currentState);
    if (currentState === STATE_FIRING) {
      await preferences.put(KEY_ALARM_STATE_ID, alarmId);
    }
    await preferences.flush();
  }

  /**
   * get current alarm state
   *
   * @return alarm state
   */
  async getState(): Promise<number> {
    const preferences = await this.getPreferences();
    const alarmState = await preferences.get(KEY_ALARM_STATE, STATE_IDLE);
    return Number(alarmState);
  }

  /**
   * get alarm id which causes a state change
   *
   * @return alarm id
   */
  async getAlarmId(): Promise<number> {
    const preferences = await this.getPreferences();
    const alarmState = await preferences.get(KEY_ALARM_STATE_ID, DEFAULT_ALARM_ID);
    return Number(alarmState);
  }

  /**
   * set alarm state firing
   *
   * @param alarmId alarm id
   */
  async setStateFiring(alarmId: string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method setStateFiring failed, params is incorrect.');
      return;
    }
    await this.setState(STATE_FIRING, alarmId);
  }

  /**
   * set alarm state firing
   *
   * @param alarmId alarm id
   */
  async setStateSnooze(alarmId: string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method setStateSnooze failed, params is incorrect.');
      return;
    }
    await this.setState(STATE_SNOOZE, alarmId);
  }

  /**
   * set alarm state stop
   *
   * @param alarmId alarm id
   */
  async setStateStop(alarmId: string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method setStateStop failed, params is incorrect.');
      return;
    }
    const isFiring = await this.isFiring();
    const isFiringId = await this.getAlarmId();
    LogUtil.info(TAG, `setStateStop isFiring:${isFiring} isFiringId:${isFiringId}  alarmId:${alarmId}`);
    if (isFiring && isFiringId === Number(alarmId)) {
      await this.setState(STATE_STOP, alarmId);
    }
  }

  /**
   * is current firing
   */
  async isFiring(): Promise<boolean> {
    const currentState = await this.getState();
    return currentState === STATE_FIRING;
  }

  /**
   * is current snoozed
   */
  async isSnoozed(): Promise<boolean> {
    const currentState = await this.getState();
    return currentState === STATE_SNOOZE;
  }

  /**
   * is current stopped
   */
  async isStopped(): Promise<boolean> {
    const currentState = await this.getState();
    return currentState === STATE_STOP;
  }
}

export default new AlarmStateManager();