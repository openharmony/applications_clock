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

import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { LogUtil } from '@hmos/common/src/main/ets/utils/LogUtil';
import contextConstant from '@ohos.app.ability.contextConstant';
import { GlobalContext, } from '@hmos/common';

const LOG_TAG: string = 'testTag-IntentExecutor-EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    this.context.area = contextConstant.AreaMode.EL1
    GlobalContext.getContext().setObject('abilityWant', want);
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'EntryAbility');
    LogUtil.info(LOG_TAG, 'Ability onCreate');
    LogUtil.info(LOG_TAG, JSON.stringify(this.context));
    LogUtil.info(LOG_TAG, JSON.stringify(this.context.stageMode));
  }

  async onDestroy() {
    LogUtil.info(LOG_TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    LogUtil.info(LOG_TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/TestIntentIndex', (err, data) => {
      if (err.code) {
        LogUtil.info(LOG_TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      LogUtil.info(LOG_TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    LogUtil.info(LOG_TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    LogUtil.info(LOG_TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    LogUtil.info(LOG_TAG, '%{public}s', 'Ability onBackground');
  }
}
