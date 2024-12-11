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

const KEY_TIMER_STATE = 'timerOut_state';

const KEY_TIMER_STATE_ID = 'timerOut_state_id';

const TAG = 'timerStateManager';

type Preferences = preferencesUtil.Preferences;

class TimerStateManager {
  private preferences: Preferences | undefined = undefined;

  private async getPreferences(): Promise<Preferences> {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    return this.preferences as Preferences;
  }

  private async setState(currentState: number, alarmId: string): Promise<void> {
    const preferences = await this.getPreferences();
    await preferences.put(KEY_TIMER_STATE, currentState);
    if (currentState === STATE_FIRING) {
      await preferences.put(KEY_TIMER_STATE_ID, alarmId);
    }
    await preferences.flush();
  }

  async getState(): Promise<number> {
    const preferences = await this.getPreferences();
    const alarmState = await preferences.get(KEY_TIMER_STATE, STATE_IDLE);
    return Number(alarmState);
  }

  async getAlarmId(): Promise<number> {
    const preferences = await this.getPreferences();
    const alarmState = await preferences.get(KEY_TIMER_STATE_ID, DEFAULT_ALARM_ID);
    return Number(alarmState);
  }

  async setStateFiring(alarmId: string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method setStateFiring failed, params is incorrect.');
      return;
    }
    await this.setState(STATE_FIRING, alarmId);
  }

  async setStateStop(alarmId: string): Promise<void> {
    if (!alarmId) {
      LogUtil.error(TAG, 'Execute method setStateStop failed, params is incorrect.');
      return;
    }
    await this.setState(STATE_STOP, alarmId);
  }

  async isFiring(): Promise<boolean> {
    const currentState = await this.getState();
    return currentState === STATE_FIRING;
  }
}

export default new TimerStateManager();