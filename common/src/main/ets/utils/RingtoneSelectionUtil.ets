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

import { DEFAULT_RINGTONE_ID, noneRingtone, ringtones } from '../components/RingtoneSelection/types';
import preferencesUtil from '@ohos.data.preferences';
import { ALARM_LAST_SELECTED_RING, APP_CONFIG, TIMER_SELECTED_RING } from '../manager/types';
import { GlobalContext } from './index';

interface RingtoneItem {
  id: number,
  name: string,
  path: string
}

export class RingtoneSelectionUtil {
  static getRingtoneById(id: number) {
    return ringtones.find(r => r.id == id) ?? RingtoneSelectionUtil.getDefaultRingtone()
  }

  static getRingtoneByPath(path: string) {
    return ringtones.find(r => r.path === path) ?? RingtoneSelectionUtil.getDefaultRingtone()
  }

  static getDefaultRingtone() {
    return ringtones.find(r => r.id == DEFAULT_RINGTONE_ID) ?? noneRingtone
  }

  static async getAlarmRingtone(): Promise<RingtoneItem> {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    let ringPath = String(await preferences.get(ALARM_LAST_SELECTED_RING, ''));
    return RingtoneSelectionUtil.getRingtoneByPath(ringPath);
  }

  static async getTimerRingtone(): Promise<RingtoneItem> {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    let ringPath = String(await preferences.get(TIMER_SELECTED_RING, ''));
    return RingtoneSelectionUtil.getRingtoneByPath(ringPath);
  }
}