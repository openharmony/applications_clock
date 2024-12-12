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

import AbilityStage from '@ohos.app.ability.AbilityStage';
import { Configuration } from '@ohos.app.ability.Configuration';
import { LogUtil } from '@hmos/common';
import { AlarmCardUtil } from '@hmos/alarmclock';

let systemLanguage: string | undefined; // 系统当前语言
const TAG: string = 'ClockAbilityStage';

export default class ClockAbilityStage extends AbilityStage {
  onCreate(): void {
    systemLanguage = this.context.config.language; // Module首次加载时，获取系统当前语言
    LogUtil.info('ClockAbilityStage onCreate');
  }

  onConfigurationUpdate(newConfig: Configuration) {
    LogUtil.info(TAG, `onConfigurationUpdated systemLanguage is ${systemLanguage}, newConfig: ${JSON.stringify(newConfig)}`);

    if (systemLanguage !== newConfig.language) {
      LogUtil.info(TAG, `systemLanguage from ${systemLanguage} changed to ${newConfig.language}`);
      systemLanguage = newConfig.language; // 将变化之后的系统语言保存，作为下一次变化前的系统语言
      AlarmCardUtil.notifyAlarmCardTimeUpdate();
    }
  }
}