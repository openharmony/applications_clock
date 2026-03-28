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

import mediaQuery from '@ohos.mediaquery';
import display from '@ohos.display';
import { DisplayUtil, LogUtil } from '../utils';
import { Callback, BusinessError } from '@ohos.base';
import { BreakPointListener, MatchRule, BreakPoint, MIN_LG_WIDTH, MIN_MD_WIDTH } from './types';
import deviceInfo from '@ohos.deviceInfo';

const TAG: string = 'BreakpointManager';

/**
 * Manager Alarm state Tool Class
 *
 * @since 2023-01-10
 */
class BreakpointManager {
  private currentBreakpoint: string = '';
  private foldAbleScreen: number = 0;
  private orientaion: number = 0;
  private listenerList: BreakPointListener[] = [
    {
      listener: mediaQuery.matchMediaSync(MatchRule.SM),
      breakPoint: BreakPoint.SM,
    },
    {
      listener: mediaQuery.matchMediaSync(MatchRule.MD),
      breakPoint: BreakPoint.MD,
    },
    {
      listener: mediaQuery.matchMediaSync(MatchRule.LG),
      breakPoint: BreakPoint.LG,
    },
  ];

  /**
   * Do not modify the folding method
   */
  private getScreen() {
    let callback: Callback<display.FoldStatus> = (data: display.FoldStatus) => {
      const getfoldAbleScreen = display.getFoldStatus();
      this.foldAbleScreen = getfoldAbleScreen
      AppStorage.SetOrCreate<number>('currentAbleScreen', this.foldAbleScreen);
    };
    try {
      display.on('foldStatusChange', callback);
    } catch (exception) {
      LogUtil.error(TAG, 'get screen result' + JSON.stringify(exception));
    }
  }

  /**
   * Do not modify the folding method
   */
  private getOrientation() {
    display.getAllDisplay((err: BusinessError, data: Array<display.Display>) => {
      const errCode: number = err.code;
      if (errCode) {
        LogUtil.error(TAG, 'Failed to obtain all the display objects. Code: ' + JSON.stringify(err));
        return;
      }
      this.orientaion = data[0].width;
      AppStorage.SetOrCreate<number>('setOrientaion', this.orientaion);
    });
  }

  /**
   * Do not modify the folding method
   */
  private updateCurrentBreakpoint(breakpoint: string): void {
    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = (breakpoint === 'lg' && deviceInfo.deviceType !== '2in1') ? 'md' : breakpoint;
      AppStorage.SetOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
    }
  }

  /**
   * Initializes breakpoint based on the input window width.
   *
   * @param windowWidth Window width
   */
  public async initBreakpointFromWidth(windowWidth: number): Promise<void> {
    this.getScreen();
    this.getOrientation();
    const dftDisplay = await display.getDefaultDisplay();
    const dpi = dftDisplay.densityDPI;
    if (windowWidth > DisplayUtil.vp2pxInTs(MIN_LG_WIDTH, dpi)) {
      this.updateCurrentBreakpoint(BreakPoint.LG);
      return;
    }
    if (windowWidth > DisplayUtil.vp2pxInTs(MIN_MD_WIDTH, dpi)) {
      this.updateCurrentBreakpoint(BreakPoint.MD);
      return;
    }
    this.updateCurrentBreakpoint(BreakPoint.SM);
  }

  /**
   * Register breakpoint listening.
   */
  public register(): void {
    for (const item of this.listenerList) {
      if (item.listener.matches && this.currentBreakpoint !== item.breakPoint) {
        this.updateCurrentBreakpoint(item.breakPoint);
        break;
      }
      item.listener.on('change', data => {
        data.matches && this.updateCurrentBreakpoint(item.breakPoint);
      });
    }
  }

  /**
   * Unregister breakpoint listening.
   */
  public unregister(): void {
    for (const item of this.listenerList) {
      item.listener.off('change');
    }
  }
}

export default new BreakpointManager();