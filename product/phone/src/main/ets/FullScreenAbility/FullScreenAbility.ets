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

import contextConstant from '@ohos.app.ability.contextConstant';
import emitter from '@ohos.events.emitter';
import { LogUtil, FullScreenType, GlobalContext, AlarmStateManager, AlarmManager, TIMER_NOTICE_ID } from '@hmos/common';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import UIAbility from '@ohos.app.ability.UIAbility';
import { FULL_SCREEN_ALARM_PAGE } from '@hmos/alarmclock/src/main/ets/manager/types';
import { EVENT_ID_FULL_SCREEN_ALARM, EVENT_ID_TIMER_FULL_SCREEN_CLOSE } from '@hmos/common/src/main/ets/manager/types';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const TAG = 'FullScreenAbility';

export const FULL_SCREEN_TIMER_PAGE = 'pages/FullScreenTimer';

export default class FullScreenAbility extends UIAbility {
  private fullScreenPage: string = FULL_SCREEN_ALARM_PAGE;

  onCreate(want: Want): void {
    LogUtil.info(TAG, 'onCreate:' + JSON.stringify(want));
    this.context.area = contextConstant.AreaMode.EL1;
    GlobalContext.getContext().setObject('FullScreenAbilityContext', this.context);
    GlobalContext.getContext().setObject('terminateFullScreenAbilityContext', false);
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    GlobalContext.getContext().setObject('abilityWant', want);
    if (want.parameters && want.parameters.fullScreenType == FullScreenType.Timer) {
      this.fullScreenPage = FULL_SCREEN_TIMER_PAGE;
    } else {
      this.fullScreenPage = FULL_SCREEN_ALARM_PAGE;
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    LogUtil.info(TAG, 'onNewWant:' + JSON.stringify(want) + JSON.stringify(launchParam));
  }

  onDestroy(): void {
    LogUtil.info(TAG, 'onDestroy');
    GlobalContext.getContext().setObject('FullScreenAbilityContext', undefined);
    GlobalContext.getContext().setObject('terminateFullScreenAbilityContext', true);
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    LogUtil.info(TAG, 'onWindowStageCreate ' + this.fullScreenPage);
    const mainWindow = await windowStage.getMainWindow();
    mainWindow.setUIContent(this.fullScreenPage, () => {
    });
    mainWindow.setWindowLayoutFullScreen(true);
    mainWindow.setWindowKeepScreenOn(true);
    // windowStage.setShowOnLockScreen(true);
  }

  onWindowStageDestroy(): void {
    LogUtil.info(TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    LogUtil.info(TAG, 'onForeground');
  }

  onBackground(): void {
    this.processTerminate();
  }

  processTerminate(): void {
    const isTerminated: boolean = GlobalContext.getContext().getObject('terminateFullScreenAbilityContext') as boolean;
    LogUtil.info(TAG, 'onBackground isTerminated:' + isTerminated);
    if (isTerminated) {
      LogUtil.info(TAG, 'onBackground return');
      return;
    }
    GlobalContext.getContext().setObject('FullScreenAbilityContext', undefined);
    GlobalContext.getContext().setObject('terminateFullScreenAbilityContext', true);
    if (this.fullScreenPage === FULL_SCREEN_ALARM_PAGE) {
      emitter.emit({
        eventId: EVENT_ID_FULL_SCREEN_ALARM, priority: emitter.EventPriority.IMMEDIATE
      });
    } else {
      emitter.emit({
        eventId: EVENT_ID_TIMER_FULL_SCREEN_CLOSE, priority: emitter.EventPriority.IMMEDIATE
      });
    }
    this.context.terminateSelf(error => {
      LogUtil.info(TAG, `terminateSelf finish error: ${JSON.stringify(error)}`);
    });
  }
}
