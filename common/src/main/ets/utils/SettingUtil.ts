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

import settings from '@ohos.settings';
import type common from '@ohos.app.ability.common';
import { GlobalContext } from './GlobalContext';
import { LogUtil } from './LogUtil';

const TAG: string = 'SettingUtil';

/**
 * Settings工具类
 */
export class SettingUtil {
  /**
   * 设置settings数据（同步方法）
   * @param name 名称
   * @param value 值
   * @return true：设置成功；false：设置失败
   */
  public static setValueSync(name: string, value: string): boolean {
    let clockContext: common.Context = GlobalContext.getContext().getObject('clockContext') as common.Context;
    if (clockContext) {
      let resultGlobal = settings.setValueSync(clockContext, name, value);
      LogUtil.info(TAG, `setValueSync global name:${name} value:${value} result:${resultGlobal}`);
      return resultGlobal;
    }
    LogUtil.error(TAG, 'setValueSync context is null');
    return false;
  }

  /**
   * 获取settings数据（同步方法）
   * @param name 名称
   * @param defValue 默认值
   * @return 值
   */
  public static getValueSync(name: string, defValue: string): string {
    let clockContext: common.Context = GlobalContext.getContext().getObject('clockContext') as common.Context;
    if (clockContext) {
      let resultGlobal = settings.getValueSync(clockContext, name, defValue);
      LogUtil.info(TAG, `getValueSync global name:${name} value:${resultGlobal}`);
      return resultGlobal;
    }
    LogUtil.error(TAG, 'getValueSync context is null');
    return '';
  }
}
