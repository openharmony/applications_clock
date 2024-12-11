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
import { PAGE_STATE_STORE } from './types';
import { GlobalContext, LogUtil } from '../utils';

type Preferences = preferencesUtil.Preferences;
const tabIndexKey: string = 'tabIndex';
const showTextClockKey: string = 'showTextClock';
const showHandsClockKey: string = 'showHandsClock';
const TAG: string = 'PageStateManager';

class PageStateManager {
  private preferences: Preferences | undefined = undefined;

  /**
   * Get PageStateManager Preferences instance.
   *
   * @return Preferences instance
   */
  private async getPreferences(): Promise<Preferences> {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = await preferencesUtil.getPreferences((GlobalContext.getContext()
      .getObject('clockContext') as Context), PAGE_STATE_STORE);
    return this.preferences as Preferences;
  }

  private getPreferencesSync(): Preferences {
    if (this.preferences) {
      return this.preferences;
    }
    this.preferences = preferencesUtil.getPreferencesSync((GlobalContext.getContext()
      .getObject('clockContext') as Context), { name: PAGE_STATE_STORE });
    return this.preferences as Preferences;
  }

  /**
   * Obtains tab index.
   *
   * @return tabIndex
   */
  async getTabIndex(): Promise<number> {
    const preferences = await this.getPreferences();
    const tabIndex = await preferences.get(tabIndexKey, 0);
    LogUtil.info(TAG, 'get tabIndex from Sp:' + tabIndex);
    return Number(tabIndex);
  }

  /**
   * save tab Index to preferences
   *
   * @param tabIndex current tabIndex
   */
  public async saveTabIndexToSp(tabIndex: number): Promise<void> {
    const preferences = await this.getPreferences();
    LogUtil.info(TAG, 'save tabIndex toSp:' + tabIndex);
    await preferences.put(tabIndexKey, tabIndex);
    await preferences.flush();
  }

  /**
   * Obtains showTextClock value.
   *
   * @return showTextClock
   */
  async getClockShowState(): Promise<boolean> {
    const preferences = await this.getPreferences();
    const showTextClock = await preferences.get(showTextClockKey, false);
    LogUtil.info(TAG, 'get showTextClock from Sp:' + showTextClock);
    return Boolean(showTextClock);
  }

  getClockShowStateSync(): boolean {
    const preferences = this.getPreferencesSync();
    const showTextClock = preferences.getSync(showTextClockKey, false);
    LogUtil.info(TAG, 'get showTextClock from Sp:' + showTextClock);
    return Boolean(showTextClock);
  }

  /**
   * Obtains showHandsClock value.
   *
   * @return showHandsClock
   */
  async getClockHandsState(): Promise<boolean> {
    const preferences = await this.getPreferences();
    const showHandsClock = await preferences.get(showHandsClockKey, true);
    LogUtil.info(TAG, 'get showHandsClock from Sp:' + showHandsClock);
    return Boolean(showHandsClock);
  }

  getClockHandsStateSync(): boolean {
    // const preferences = this.getPreferencesSync();
    // const showHandsClock = preferences.getSync(showHandsClockKey, true);
    // LogUtil.info(TAG, 'get showHandsClock from Sp:' + showHandsClock);
    return true;
  }

  /**
   * save showTextClock to preferences
   *
   * @param showTextClock showTextClock value
   */
  public async saveClockShowToSp(showTextClock: boolean): Promise<void> {
    const preferences = await this.getPreferences();
    LogUtil.info(TAG, 'save showTextClock toSp:' + showTextClock);
    await preferences.put(showTextClockKey, showTextClock);
    await preferences.flush();
  }

  /**
   * save saveHandsShowToSp to preferences
   *
   * @param showHandsClock  value
   */
  public async saveHandsShowToSp(showHandsClock: boolean): Promise<void> {
    const preferences = await this.getPreferences();
    LogUtil.info(TAG, 'save showHandsClock toSp:' + showHandsClock);
    await preferences.put(showHandsClockKey, showHandsClock);
    await preferences.flush();
  }

  public async changeTabsToIndex(tabIndex: number): Promise<void> {
    await this.saveTabIndexToSp(tabIndex);
    const isTabChange = AppStorage.get<boolean>('isTabChange');
    AppStorage.setOrCreate<boolean>('isTabChange', isTabChange ? false : true);
    LogUtil.info(TAG, 'changeTabsToIndex tabIndex:' + tabIndex);
  }
}

export default new PageStateManager();
