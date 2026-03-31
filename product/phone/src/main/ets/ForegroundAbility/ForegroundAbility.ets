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

import Ability from '@ohos.app.ability.UIAbility';
import contextConstant from '@ohos.app.ability.contextConstant';
import emitter from '@ohos.events.emitter';
import { LogUtil, EVENT_ID_FINISH_ABILITY } from '@hmos/common';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

const TAG = 'ForegroundAbility';

export default class ForegroundAbility extends Ability {
  onCreate(want: Want): void {
    LogUtil.info(TAG, 'ForegroundAbility onCreate');
    this.context.area = contextConstant.AreaMode.EL1
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'ForegroundAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    LogUtil.info(TAG, 'ForegroundAbility onWindowStageCreate');
    const mainWindow = await windowStage.getMainWindow()
    mainWindow.setUIContent('pages/ForegroundPage', () => {
    });
    emitter.on({
      eventId: EVENT_ID_FINISH_ABILITY
    }, () => {
      this.context.terminateSelf(error => {
        LogUtil.info(TAG, `terminateSelf finish error: ${JSON.stringify(error)}`);
      });
    });
  }

  onWindowStageDestroy(): void {
    LogUtil.info(TAG, 'ForegroundAbility onWindowStageDestroy');
    emitter.off(EVENT_ID_FINISH_ABILITY);
  }

  onForeground(): void {
    LogUtil.info(TAG, 'ForegroundAbility onForeground');
  }

  onBackground(): void {
    LogUtil.info(TAG, 'ForegroundAbility onBackground');
  }
}
