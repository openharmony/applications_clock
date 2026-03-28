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

import UIAbility from '@ohos.app.ability.UIAbility';
import contextConstant from '@ohos.app.ability.contextConstant';
import { LogUtil, GlobalContext } from '@hmos/common';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const TAG: string = 'FaCityManagerAbility';

export default class FaCityManagerAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.area = contextConstant.AreaMode.EL1
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'FaCityManagerAbility');
    LogUtil.info(TAG, 'FaCityManagerAbility onCreate:' + JSON.stringify(want));
    if (want.parameters) {
      const formId = want?.parameters.formId;
      LogUtil.info(TAG, 'FaCityManagerAbility formId:' + formId);
      AppStorage.SetOrCreate<string>('requestFormId', formId);
    }
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'FaCityManagerAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    LogUtil.info(TAG, 'FaCityManagerAbility onWindowStageCreate');
    const mainWindow = await windowStage.getMainWindow();
    windowStage.loadContent('pages/FaManagerCity', (err, data) => {
      if (err.code) {
        LogUtil.error(TAG, 'Failed to load the content. Cause: ' + JSON.stringify(err));
        return;
      }
      LogUtil.info(TAG, 'Succeeded in loading the content. Data:' + JSON.stringify(data));
    });

  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    LogUtil.info(TAG, 'FaCityManagerAbility onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    LogUtil.info(TAG, 'FaCityManagerAbility onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    LogUtil.info(TAG, 'FaCityManagerAbility onBackground');
  }
}
