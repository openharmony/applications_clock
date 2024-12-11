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

import {
  BreakPoint,
  CLOCK_RATIO_FOR_LG,
  CLOCK_RATIO_FOR_NORMAL,
  CLOCK_SCALE_VALUE,
  HALF,
  LogUtil,
  SCALE_DIAMETER_RATIO,
  SizeInfo,
  UPDATE_WIDTH_DELAY,
  GlobalContext,
  CLOCK_RATIO_FOR_NORMAL_CUSTOM,
  CLOCK_RATIO_FOR_LG_CUSTOM
} from '@hmos/common';

import window from '@ohos.window';
import { StopwatchDialScale } from './StopwatchDialScale';

const TAG = 'Stopwatch(Component)';

/**
 * An entrance to a stopwatch assembly
 *
 * @since 2023-09-08
 */
@Component
export struct StopwatchDial {
  @Link passedTime: number;
  @StorageLink('mainWindow') mainWindow: window.Window | undefined = undefined;
  @StorageProp('windowStandardHeight') windowStandardHeight: number = 0;
  @StorageProp('currentBreakpoint') @Watch('updateClockRatio') currentBreakpoint: string = '';
  @State diameter: number = 0; // Dial diameter (in vp)
  @State clockRatio: number = CLOCK_RATIO_FOR_NORMAL_CUSTOM;
  @Prop scaleDiameterRatio: number = SCALE_DIAMETER_RATIO;
  @Prop isPortraitOrientation: Boolean = true;

  async aboutToAppear(): Promise<void> {
    const windowSize: SizeInfo | window.Rect = (this.mainWindow?.getWindowProperties())?.windowRect ||
      { width: 0, height: 0 };
    this.updateStopwatchDiameter(windowSize as ESObject);
    this.mainWindow?.on('windowSizeChange', (sizeInfo: SizeInfo) => this.updateStopwatchDiameter(sizeInfo));
  }

  aboutToDisappear(): void {
    try {
      if (this.mainWindow && this.mainWindow.isWindowShowing()) {
        this.mainWindow.off('windowSizeChange');
      }
    } catch (error) {
      LogUtil.info(TAG, `${JSON.stringify(error)}`)
    }
  }

  @Builder
  buildStopwatchDial() {
    Column() {
      Stack() {
        StopwatchDialScale({
          isPortraitOrientation: false,
          diameter: this.diameter * this.scaleDiameterRatio,
          passedTime: $passedTime,
        });
      }
      .id('id_stopwatch')
      .width('100%')
      .height('100%')
      .transition({ type: TransitionType.All, opacity: 0, scale: { x: CLOCK_SCALE_VALUE, y: CLOCK_SCALE_VALUE } })
    }
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.diameter) {
      Row() {
        this.buildStopwatchDial();
      }
      .width('100%')
      .height(this.diameter)
      .justifyContent(FlexAlign.Center)
    }
  }

  private updateClockRatio(): void {
    this.clockRatio = this.currentBreakpoint === BreakPoint.LG ? CLOCK_RATIO_FOR_LG_CUSTOM :
      CLOCK_RATIO_FOR_NORMAL_CUSTOM;
  }

  private async onWindowSizeChange(sizeInfo: SizeInfo): Promise<void> {
    if (GlobalContext.getContext().getObject('updateDiameterId')) {
      clearTimeout(GlobalContext.getContext().getObject('updateDiameterId') as number);
    }
    GlobalContext.getContext()
      .setObject('updateDiameterId', setTimeout(() => this.updateStopwatchDiameter(sizeInfo), UPDATE_WIDTH_DELAY));
  }

  private updateStopwatchDiameter(sizeInfo: SizeInfo): void {
    LogUtil.info(TAG, 'updateDiameter, currentBreakpoint:', this.currentBreakpoint);
    if (!sizeInfo || !sizeInfo.height || !sizeInfo.width) {
      return;
    }
    const height: number = sizeInfo.height || this.windowStandardHeight;
    const longEdge = Math.max(height, sizeInfo.width);
    const shortEdge = Math.min(height, sizeInfo.width);
    this.diameter = px2vp(Math.min(longEdge * HALF, shortEdge) * this.clockRatio);
    LogUtil.info(TAG, 'updateDiameter, diameter:' + this.diameter);
  }
}