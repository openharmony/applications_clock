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

import preferencesUtil from '@ohos.data.preferences';
import { FormInfo, FROM_DATA_STORE } from './types';
import { GlobalContext, LogUtil } from '../utils';
import { TsUtilManager } from './TsUtilManager';

type Preferences = preferencesUtil.Preferences;
const TAG: string = 'FormManager';

/**
 * FormManager
 *
 * @since 2023-06-08
 */
class FormManager {
  private preferences: Preferences | undefined = undefined;

  /**
   * Get FormManager Preferences instance.
   *
   * @return Preferences instance
   */
  private async getPreferences(): Promise<Preferences> {
    preferencesUtil.removePreferencesFromCache(GlobalContext.getContext()
      .getObject('clockContext') as Context, FROM_DATA_STORE);
    this.preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, FROM_DATA_STORE);
    return this.preferences as Preferences;
  }

  /**
   * 从 sp 中获取所有卡片信息
   *
   * @return 卡片信息数组
   */
  public async fetchAllFormsFromSp(): Promise<FormInfo[]> {
    const preferences = await this.getPreferences();
    let formList: FormInfo[] = [];
    let obj: Object = await preferences.getAll();
    formList = TsUtilManager.transferObjectToFormInfo(obj);
    return formList;
  }

  /**
   * get FromInfo from Sp ById
   *
   * @return FromInfo
   */
  public async getFromInfoSpById(fromId: string): Promise<FormInfo | undefined> {
    try {
      const preferences = await this.getPreferences();
      let formInfoString = await preferences.get(fromId, '');
      if (String(formInfoString) !== '') {
        const formInfo: FormInfo = JSON.parse(String(formInfoString));
        return formInfo;
      } else {
        return undefined;
      }
    } catch (error) {
      LogUtil.error(TAG, 'getFromNameSpById error:' + JSON.stringify(error));
    }
    return undefined;
  }

  /**
   * save formInfo to preferences
   *
   * @param formInfo 被保存的卡片信息
   */
  public async saveFormToSp(formInfo: FormInfo): Promise<void> {
    const preferences = await this.getPreferences();
    LogUtil.info(TAG, 'saveFormToSp formInfo:' + JSON.stringify(formInfo));
    await preferences.put(formInfo.formId, JSON.stringify(formInfo));
    await preferences.flush();
  }

  /**
   * delete formInfo to preferences
   *
   * @param formId 删除的卡片信息ID
   */
  public async deleteFormToSp(formId: string): Promise<void> {
    const preferences = await this.getPreferences();
    LogUtil.info(TAG, 'deleteFormToSp formId:' + formId);
    await preferences.delete(formId);
    await preferences.flush();
  }
}

export default new FormManager();