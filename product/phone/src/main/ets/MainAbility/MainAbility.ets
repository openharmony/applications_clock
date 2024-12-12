// import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
// import { hilog } from '@kit.PerformanceAnalysisKit';
// import { window } from '@kit.ArkUI';
//
// export default class EntryAbility extends UIAbility {
//   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
//   }
//
//   onDestroy(): void {
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
//   }
//
//   onWindowStageCreate(windowStage: window.WindowStage): void {
//     // Main window is created, set main page for this ability
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
//
//     windowStage.loadContent('pages/index', (err) => {
//       if (err.code) {
//         hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
//         return;
//       }
//       hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
//     });
//   }
//
//   onWindowStageDestroy(): void {
//     // Main window is destroyed, release UI related resources
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
//   }
//
//   onForeground(): void {
//     // Ability has brought to foreground
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
//   }
//
//   onBackground(): void {
//     // Ability has back to background
//     hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
//   }
// }

//-------------------------以上仅打开index--------------------------------------------------------------


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

import Ability from '@ohos.app.ability.UIAbility';
import contextConstant from '@ohos.app.ability.contextConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import Window from '@ohos.window';
import router from '@ohos.router';
import {
  BreakpointManager,
  GlobalContext,
  LogUtil,
  TsUtilManager,
  PageStateManager,
  CommonUtil,
  SoundPool,
  TIMER_NOTICE_ID,
  TOTAL_TIME_TIMER_PREFERENCES_CLOCK,
  LEFT_TIME_TIMER_PREFERENCES_CLOCK,
  PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK,
  START_DATE_TIMER_PREFERENCES_CLOCK,
  TimerSystemTimer,
} from '@hmos/common';
import { NotificationUtil } from '@hmos/alarmclock';
import { BusinessError } from '@ohos.base';
import EnvironmentCallback from '@ohos.app.ability.EnvironmentCallback';
import { TimerNotificationUtil } from '@hmos/timer';
import { timerPreferencesManagerUtil } from '@hmos/timer/src/main/ets/common/preferencesUtil';
import TimerAudioPlayer from '@hmos/timer/src/main/ets/manager/timerAudioPlayer';

const TAG = 'MainAbility';
const ALARM_CLOCK_TAB = 'ALARM_CLOCK_TAB';
const TIMER_TAB = 'TIMER_TAB';
const CALLER_BUNDLE_NAME = 'ohos.aafwk.param.callerBundleName';
const TIMER_BEEP: string = 'Timer_Beep.ogg';

export interface initializingProperties {
  externalWindowStage?: window.WindowStage;
  windowStage?: window.WindowStage;
}

export default class MainAbility extends Ability {
  public environmentCallbackId: number = -1;

  onBackPressed() {
    LogUtil.info(TAG, 'onBackPressed');
    return true;
  }

  async onCreate(want: Want): Promise<void> {
    LogUtil.info(TAG, 'MainAbility onCreate');
    this.context.area = contextConstant.AreaMode.EL1;
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    GlobalContext.getContext().setObject('abilityWant', want);
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'MainAbility');
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    LogUtil.info(TAG, 'MainAbility onCreate' + JSON.stringify(want));
    CommonUtil.requestTimerResources();
    this.registerEnvironmentChanged();
    //处理卡片跳转时钟默认显示闹钟列表
    if (want.parameters && want.parameters.tab_active == ALARM_CLOCK_TAB) {
      AppStorage.setOrCreate<Boolean>('ALARM_CLOCK_TAB', true);
      await PageStateManager.changeTabsToIndex(0);
    } else if (want.parameters && want.parameters?.tab_active == TIMER_TAB) {
      LogUtil.info(TAG, `changeTabsToIndex=>onForeground${want.parameters?.tab_active}}`)
      await PageStateManager.changeTabsToIndex(3);
    } else if (TsUtilManager.hasItsProperty(want.parameters, CALLER_BUNDLE_NAME) &&
      TsUtilManager.getItsProperty(want.parameters, CALLER_BUNDLE_NAME) === '') {
      await PageStateManager.changeTabsToIndex(0);
    }
  }

  private registerEnvironmentChanged(): void {
    let envCallback: EnvironmentCallback = {
      onConfigurationUpdated(config): void {
        let mainWindow = AppStorage.Get<window.Window>('mainWindow')
        AppStorage.setOrCreate('currentColorMode', config.colorMode);
        if (config.colorMode === 0) {
          try {
            let mainWindow = AppStorage.Get<window.Window>('mainWindow')
            LogUtil.info(TAG, 'setting window backGroundColor');
            mainWindow?.setWindowBackgroundColor('#000000');
          } catch (error) {
            LogUtil.error(TAG, 'set windowBGColor error:' + JSON.stringify(error));
          }

          let sysBarProps: window.SystemBarProperties = {
            // 以下两个属性从API Version 8开始支持
            statusBarContentColor: '#ffffff',
            navigationBarContentColor: '#ffffff'
          };
          mainWindow?.setWindowSystemBarProperties(sysBarProps, (err: BusinessError) => {
            let errCode: number = err.code;
            if (errCode) {
              LogUtil.error(TAG, 'Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
              return;
            }
            LogUtil.info(TAG, 'Succeeded in setting the system bar properties.');
          });
        } else if (config.colorMode === 1) {
          try {
            let context = GlobalContext.getContext().getObject('clockContext') as Context
            let backgroundColor: number =
            context.resourceManager.getColorSync($r('sys.color.ohos_id_background_secondary').id)
            let mainWindow = AppStorage.Get<window.Window>('mainWindow')
            mainWindow?.setWindowBackgroundColor('#' + backgroundColor.toString(16));
          } catch (err) {
            LogUtil.error(TAG, `onConfigurationUpdated Failed: ${JSON.stringify(err)}`)
          }

          let isLayoutFullScreen = true;
          mainWindow?.setWindowLayoutFullScreen(isLayoutFullScreen, (err: BusinessError) => {
            let errCode: number = err.code;
            if (errCode) {
              LogUtil.error(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
              return;
            }
            LogUtil.info(TAG, 'Succeeded in setting the window layout to full-screen mode.');
          });
          let sysBarProps: window.SystemBarProperties = {
            // 以下两个属性从API Version 8开始支持
            statusBarContentColor: '#000000',
            navigationBarContentColor: '#000000'
          };
          mainWindow?.setWindowSystemBarProperties(sysBarProps, (err: BusinessError) => {
            let errCode: number = err.code;
            if (errCode) {
              LogUtil.error(TAG, 'Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
              return;
            }
            LogUtil.info(TAG, 'Succeeded in setting the system bar properties.');
          });
        } else {
          try {
            let context = GlobalContext.getContext().getObject('clockContext') as Context;
            let backgroundColor: number =
            context.resourceManager.getColorSync($r('sys.color.ohos_id_background_secondary').id);
            let mainWindow = AppStorage.Get<window.Window>('mainWindow');
            mainWindow?.setWindowBackgroundColor('#' + backgroundColor.toString(16));
          } catch (err) {
            LogUtil.error(TAG, `onConfigurationUpdated Failed: ${JSON.stringify(err)}`);
          }
        }
      },
      onMemoryLevel(level): void {
        LogUtil.info(TAG, `onMemoryLevel success: ${level}`);
      }
    };
    try {
      this.environmentCallbackId = this.context.getApplicationContext().on('environment', envCallback);
      LogUtil.info(TAG, `callbackId: ${this.environmentCallbackId}`);
    } catch (paramError) {
      LogUtil.info(TAG, `error on environment ${(paramError as BusinessError).code}`);
    }
  }

  async onDestroy(): Promise<void> {
    await SoundPool.releaseAll()
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
    LogUtil.info(TAG, 'MainAbility onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    windowStage?.loadContent('pages/index')
    // Main window is created, set main page for this ability
    let windowClass: window.Window | null = null;
    LogUtil.info(TAG, 'MainAbility onWindowStageCreate');
    const mainWindow = await windowStage.getMainWindow();
    AppStorage.setOrCreate<Window.Window>('mainWindow', mainWindow);
    const windowSize = (await mainWindow?.getProperties())?.windowRect || {
      width: 0, height: 0
    };
    AppStorage.setOrCreate<number>('windowStandardHeight', windowSize.height);
    await BreakpointManager.initBreakpointFromWidth(windowSize.width);
    const curColorMode = AppStorage.get<number>('currentColorMode');
    let localStorage: LocalStorage = new LocalStorage({
      windowStage: windowStage,
    } as initializingProperties);
    windowStage?.loadContent('pages/index', localStorage).then(() => {
      windowStage.getMainWindow().then((data) => {
        windowClass = data;
        AppStorage.setOrCreate<boolean>('isMainPageReport', true);
        const isMainPageReport = AppStorage.get<boolean>('isMainPageReport');
        LogUtil.info(TAG, 'onMainStageCreate...' + isMainPageReport);

        if (curColorMode === 0) {
          let isLayoutFullScreen = true;
          windowClass?.setWindowLayoutFullScreen(isLayoutFullScreen, (err: BusinessError) => {
            let errCode: number = err.code;
            if (errCode) {
              LogUtil.error(TAG, 'Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
              return;
            }
            LogUtil.info(TAG, 'Succeeded in setting the window layout to full-screen mode.');
          });
          let sysBarProps: window.SystemBarProperties = {
            // 以下两个属性从API Version 8开始支持
            statusBarContentColor: '#ffffff',
            navigationBarContentColor: '#ffffff'
          };
          windowClass.setWindowSystemBarProperties(sysBarProps, (err: BusinessError) => {
            let errCode: number = err.code;
            if (errCode) {
              LogUtil.error(TAG, 'Failed to set the system bar properties. Cause: ' + JSON.stringify(err));
              return;
            }
            LogUtil.info(TAG, 'Succeeded in setting the system bar properties.');
          });
        } else {
          let backgroundColor: number =
          this.context.resourceManager.getColorSync($r('sys.color.ohos_id_background_secondary').id)
          data.setWindowBackgroundColor('#' + backgroundColor.toString(16));
          AppStorage.SetOrCreate<window.Window>('mainWindow', data);
        }
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG, `GetMainWindow Failed: ${JSON.stringify(err)}`);
      });
    });
  }

  async onWindowStageDestroy(): Promise<void> {
    // Main window is destroyed, release UI related resources
    const curColorMode = AppStorage.get<number>('currentColorMode');
    AppStorage.setOrCreate('currentColorMode', curColorMode);
    LogUtil.info(TAG, 'MainAbility onWindowStageDestroy');
    //删除闹钟卡片进入标识
    AppStorage.setOrCreate<Boolean>('ALARM_CLOCK_TAB', false);
    await TimerNotificationUtil.cancel(TIMER_NOTICE_ID)
    timerPreferencesManagerUtil.del(TOTAL_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(LEFT_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(START_DATE_TIMER_PREFERENCES_CLOCK);
    TimerAudioPlayer.stopTick(TIMER_BEEP)
    await TimerSystemTimer.destory();
  }

  async onForeground(): Promise<void> {
    // Ability has brought to foreground
    GlobalContext.getContext().setObject('isBackground', false);
    LogUtil.info(TAG, 'MainAbility onForeground');
  }

  async onBackground(): Promise<void> {
    // Ability has back to background
    GlobalContext.getContext().setObject('isBackground', true);
    LogUtil.info(TAG, 'MainAbility onBackground');
  }

  async onNewWant(want: Want): Promise<void> {
    LogUtil.info(TAG, 'onNewWant Want:' + JSON.stringify(want));
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'MainAbility');
    if (!GlobalContext.getContext().getObject('isBackground')) {
      if (TsUtilManager.hasItsProperty(want?.parameters, 'cityId')) {
        try {
          LogUtil.info(TAG, 'cityId Property exist');
          const cityId = want?.parameters?.cityId;
          LogUtil.info(TAG, 'cityId is: ', cityId as string);
          AppStorage.setOrCreate<string>('cityId', cityId as string);
          router.back();
        } catch (error) {
          LogUtil.error(TAG, 'onNewWant error:' + JSON.stringify(error));
        }
      } else {
        LogUtil.info(TAG, 'cityId Property not exist');
      }
    }
    //处理卡片跳转时钟默认显示闹钟列表
    if (want.parameters && want.parameters.tab_active == ALARM_CLOCK_TAB) {
      AppStorage.setOrCreate<Boolean>('ALARM_CLOCK_TAB', true);
      await PageStateManager.changeTabsToIndex(0);
    } else if (want.parameters && want.parameters?.tab_active == TIMER_TAB) {
      LogUtil.info(TAG, `changeTabsToIndex=>onBackground${want.parameters?.tab_active}}`)
      await PageStateManager.changeTabsToIndex(3);
    } else if (TsUtilManager.hasItsProperty(want.parameters, CALLER_BUNDLE_NAME) &&
      TsUtilManager.getItsProperty(want.parameters, CALLER_BUNDLE_NAME) === '') {
      await PageStateManager.changeTabsToIndex(0);
    }

    if (want.parameters && want.parameters.alarmId && want.parameters.isMissed) {
      const alarmId = want?.parameters?.alarmId
      NotificationUtil.cancel(alarmId as string)
    }
  }
}
