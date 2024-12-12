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

import dataPreferences from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base'
import { LogUtil, GlobalContext, TIMER_PREFERENCES_CLOCK } from '@hmos/common';

const TAG: string = 'PreferencesManager';

interface IPreferencesManagerOptions {
  context: Context;
  name: string;
}

interface IPreferencesManager {
  create: (options: IPreferencesManagerOptions) => Promise<dataPreferences.Preferences>;
  getKey: (key: string, defVal: dataPreferences.ValueType) => Promise<dataPreferences.ValueType>;
  setKey: (key: string, value: dataPreferences.ValueType, flush?: boolean) => Promise<boolean>;
  deleteKey: (key: string, flush?: boolean) => Promise<boolean>;
}

class PreferencesManager implements IPreferencesManager {
  constructor(options: IPreferencesManagerOptions) {
    this.options = options
  }

  private preferencesInstance = {} as dataPreferences.Preferences;
  private options = {} as IPreferencesManagerOptions;

  async create() {
    try {
      const options = this.options;
      let preferencesInstance = await dataPreferences.getPreferences(options.context, options.name);
      this.preferencesInstance = preferencesInstance;
      LogUtil.info(TAG, `create preferences success.`);
    } catch (error) {
      LogUtil.info(TAG, `create preferences fail. ${JSON.stringify(error)}`)
    }
    return this.preferencesInstance;
  }

  async getKey(key: string, defVal: dataPreferences.ValueType) {
    let value = defVal;
    try {
      value = await this.preferencesInstance.get(key, defVal);
      LogUtil.info(TAG, `getKey success. ${key}, ${value}`);

    } catch (error) {
      LogUtil.info(TAG, `getKey fail. ${JSON.stringify(error)}`)
    }
    return value;
  }

  async setKey(key: string, value: dataPreferences.ValueType, flush?: boolean) {
    let success = false;
    try {
      success = await this.preferencesInstance.put(key, value).then(() => true);
      LogUtil.info(TAG, `setKey success. ${key}, ${value}`);
      if (flush) {
        await this.preferencesInstance.flush();
        LogUtil.info(TAG, `setKey flush success. ${key}, ${value}`);
      }
    } catch (error) {
      LogUtil.info(TAG, `setKey fail. ${JSON.stringify(error)}`)
    }
    return success;
  }

  async deleteKey(key: string, flush?: boolean) {
    let success = false;
    try {
      success = await this.preferencesInstance.delete(key).then(() => true);
      LogUtil.info(TAG, `deleteKey success. ${key}`);
      if (flush) {
        await this.preferencesInstance.flush();
        LogUtil.info(TAG, `deleteKey flush success. ${key}`);
      }
    } catch (error) {
      LogUtil.info(TAG, `deleteKey fail. ${JSON.stringify(error)}`)
    }
    return success;
  }
}

// TIMER_PREFERENCES_CLOCK
interface ITimerPreferencesManagerUtil {
  manager?: PreferencesManager;
  create: () => Promise<PreferencesManager>;
  save: (key: string, value: dataPreferences.ValueType) => Promise<boolean>;
  del: (key: string) => Promise<boolean>;
  getKey: (key: string) => Promise<dataPreferences.ValueType>;
}

function getContext(): Context {
  return GlobalContext.getContext().getObject('clockContext') as Context;
}

export const timerPreferencesManagerUtil: ITimerPreferencesManagerUtil = {
  async create() {
    if (this.manager) {
      return this.manager;
    }
    const options: IPreferencesManagerOptions = {
      context: getContext(),
      name: TIMER_PREFERENCES_CLOCK
    }
    const preferencesManager = new PreferencesManager(options);
    await preferencesManager.create();
    this.manager = preferencesManager;
    return this.manager;
  },
  async save(key, value) {
    const manager: PreferencesManager = await this.create();
    const success = await manager.setKey(key, value, true);
    return success;
  },
  async del(key) {
    const manager: PreferencesManager = await this.create();
    const success = await manager.deleteKey(key, true);
    return success;
  },
  async getKey(key) {
    const manager: PreferencesManager = await this.create();
    const value = await manager.getKey(key, 0);
    return value;
  }
}

export default PreferencesManager;