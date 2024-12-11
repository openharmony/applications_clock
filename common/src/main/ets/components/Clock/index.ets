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

import window from '@ohos.window';
// import hiSysEvent from '@ohos.hiSysEvent';
import { BreakPoint, PageStateManager } from '../../manager';
import { EventName, EventReportUtil, EventResult, GlobalContext, LogUtil } from '../../utils';
import ClockHands from './ClockHands';
import { DigitalClock } from './DigitalClock';
import {
  CLOCK_RATIO_FOR_LG,
  CLOCK_RATIO_FOR_NORMAL,
  CLOCK_SCALE_DURATION_INCOMING,
  CLOCK_SCALE_DURATION_OUTGOING,
  CLOCK_SCALE_DELAY,
  HALF,
  SCALE_DIAMETER_RATIO,
  SizeInfo,
  UPDATE_WIDTH_DELAY
} from './types';
import deviceInfo from '@ohos.deviceInfo'

const TAG = 'Clock(Component)';
const CLOCK_RATIO_FOR_NORMAL_CUSTOM = 0.65;
const FOLD_SCREEN_DIAMETER_RATIO = 0.767;


/**
 * An entrance to a clock assembly for stacking dials, scales, and hands to form a clock
 *
 * Switching between clocks and digital clocks by clicking
 *
 * @since 2022-07-05
 */
@Component
export struct Clock {
  @Prop getOrientaion: number;
  @StorageProp('currentBreakpoint') @Watch('updateClockRatio') currentBreakpoint: string = '';
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @StorageProp('windowStandardHeight') windowStandardHeight: number = 0;
  @StorageLink('mainWindow') mainWindow: window.Window | undefined = undefined;
  @StorageLink('showTextClock') showTextClock: boolean = PageStateManager.getClockShowStateSync();
  @StorageLink('showHandsClock') showHandsClock: boolean = PageStateManager.getClockHandsStateSync();
  @State diameter: number = 0; // Dial diameter (in vp)
  @State clockRatio: number = CLOCK_RATIO_FOR_NORMAL;
  @State deviceType: string = deviceInfo.deviceType;
  @Prop isPortraitOrientation: boolean = true; //纵向 true 横向 false
  @State isClicked: boolean = false;
  @Prop showBoth: boolean = false
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  private minuteCallback?: () => Promise<void>;

  async checkTextAndHands(): Promise<void> {
    if (this.showHandsClock === this.showTextClock) {
      this.showHandsClock = !this.showTextClock;
      await PageStateManager.saveHandsShowToSp(this.showHandsClock);
    }
    LogUtil.info(TAG, 'checkTextAndHands:', `${this.showHandsClock} ${this.showTextClock}`)
  }

  async aboutToAppear(): Promise<void> {
    await this.checkTextAndHands();
    this.deviceType = deviceInfo.deviceType
    const windowSize: SizeInfo | window.Rect = (this.mainWindow?.getWindowProperties())?.windowRect || {
      width: 0,
      height: 0
    };
    this.updateClockDiameter(windowSize as ESObject);
    this.mainWindow?.on('windowSizeChange', sizeInfo => this.updateClockDiameter(sizeInfo));
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

  private updateClockRatio(): void {
    LogUtil.info(TAG, 'updateClockRatio', `${this.currentBreakpoint}`)
    this.clockRatio = this.currentBreakpoint === BreakPoint.LG ? CLOCK_RATIO_FOR_LG : CLOCK_RATIO_FOR_NORMAL;
  }

  private async onWindowSizeChange(sizeInfo: SizeInfo): Promise<void> {
    if (GlobalContext.getContext().getObject('updateDiameterId')) {
      clearTimeout(GlobalContext.getContext().getObject('updateDiameterId') as number);
    }
    GlobalContext.getContext()
      .setObject('updateDiameterId', setTimeout(() => this.updateClockDiameter(sizeInfo), UPDATE_WIDTH_DELAY));
  }

  private updateClockDiameter(sizeInfo: SizeInfo | window.Size): void {
    LogUtil.info(TAG, 'updateDiameter, currentBreakpoint:', this.currentBreakpoint);
    if (!sizeInfo || !sizeInfo.height || !sizeInfo.width) {
      return;
    }
    const height = sizeInfo.height || this.windowStandardHeight;
    const longEdge = Math.max(height, sizeInfo.width);
    const shortEdge = Math.min(height, sizeInfo.width);
    this.diameter = px2vp(Math.min(longEdge * HALF, shortEdge) * this.clockRatio);
    LogUtil.info(TAG, 'updateDiameter, diameter:' + this.diameter);
  }

  private getFoldHeight() {
    if (this.deviceType == '2in1') {
      return this.diameter * CLOCK_RATIO_FOR_NORMAL_CUSTOM
    }
    if (this.foldAbleScreen === 1) {
      return this.getOrientaion === this.isFoldCross ? this.diameter * SCALE_DIAMETER_RATIO :
        this.diameter * FOLD_SCREEN_DIAMETER_RATIO
    } else {
      return this.isPortraitOrientation ? this.diameter * SCALE_DIAMETER_RATIO :
        this.diameter * CLOCK_RATIO_FOR_NORMAL_CUSTOM
    }
  }

  @Builder
  buildAnalogClock(): void {
    Stack() {
      ClockHands({
        diameter: this.getFoldHeight(),
      });
    }
    .id('id_analog_clock')
    .width('100%')
    .height(this.showBoth ? '80%' : '100%')
    .transition(TransitionEffect.opacity(this.isClicked ? 0 : 1))
  }

  @Builder
  buildDigitalClock(): void {
    Stack() {
      DigitalClock();
    }
    .id('id_digital_clock')
    .width('100%')
    .height(this.deviceType == '2in1' ? '74vp' : (this.showBoth ? '70vp' : '100%'))
    .transition(TransitionEffect.opacity(this.isClicked ? 0 : 1))
  }

  @Builder
  buildClockContent(): void {
    Column() {
      // if (this.showBoth) {
        // this.buildAnalogClock();
        this.buildDigitalClock();
      // } else {
      //   Stack() {
      //     if (this.showTextClock) {
      //       this.buildDigitalClock();
      //     }
      //     if (this.showHandsClock) {
      //       // this.buildAnalogClock();
      //     }
      //   }
      // }
    }
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.diameter) {
      Row() {
        this.buildClockContent();
      }
      .focusable(false)
      .onClick(() => {
        if (!this.showBoth) {
          this.isClicked = true;
          const oldShowTextClock = this.showTextClock;
          LogUtil.info(TAG, 'onClick showTextClock:' + this.showTextClock);

          // animateTo({
          //   duration: CLOCK_SCALE_DURATION_INCOMING,
          //   delay: CLOCK_SCALE_DELAY,
          //   curve: Curve.Friction,
          //   onFinish: () => {
          //     LogUtil.info(TAG, 'Clock incoming play end');
          //   }
          // }, () => {
          //   if (oldShowTextClock) {
          //     this.showHandsClock = true;
          //     PageStateManager.saveHandsShowToSp(this.showHandsClock);
          //   } else {
          //     this.showTextClock = true;
          //     PageStateManager.saveClockShowToSp(this.showTextClock);
          //   }
          // });

          // animateTo({
          //   duration: CLOCK_SCALE_DURATION_OUTGOING,
          //   curve: Curve.Friction,
          //   onFinish: () => {
          //     LogUtil.info(TAG, 'Clock outgoing play end');
          //   }
          // }, () => {
          //   if (oldShowTextClock) {
          //     this.showTextClock = false;
          //     PageStateManager.saveClockShowToSp(this.showTextClock);
          //   } else {
          //     this.showHandsClock = false;
          //     PageStateManager.saveHandsShowToSp(this.showHandsClock);
          //   }
          // });
        }
        // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.DIGITAL_DIAL_SWITCHING)
        this.checkTextAndHands();
      })
      .width('100%')
      .height(this.diameter)
      .justifyContent(FlexAlign.Center)
    }
  }
}