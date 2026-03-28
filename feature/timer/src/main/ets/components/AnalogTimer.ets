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

import { CLOCK_SCALE_VALUE, HALF, LogUtil, SCALE_DIAMETER_RATIO, SECOND_IN_MINUTE } from '@hmos/common';
import {
  FULL_CIRCLE_ANGLE,
  SCALE_UNIT_HEIGHT,
  SCALE_UNIT_WIDTH,
  SECOND_ANGLE_STEP,
} from '@hmos/common/src/main/ets/components/Clock/types';
import { DialData } from '../types'
import deviceInfo from '@ohos.deviceInfo'

const TAG: string = 'AnalogTimer';
const FOLD_SCREEN_WIDTH = 2496;
const COLREMAIN_HEIGHT = 33;
const FOLD_REMAIN_HEIGHT = 22;
const ROW_REMAIN_HEIGHT = 18;
const DIAL_DIAMETER_RATIO = 1.66; //表盘直径比率
const LINE_HEIGHT = 11;

enum GradientColor {
  BLUE = '6239ff',
  CYAN = '03b6ee'
}

/**
 * Used to display the analog timer component.
 *
 * @since 2023-09-10
 */
@Component
export struct AnalogTimer {
  @State remainHeight: number = COLREMAIN_HEIGHT;
  @Prop @Watch('setRemainHeight') isPortraitOrientation: boolean;
  @Prop scaleDiameterRatio: number = SCALE_DIAMETER_RATIO;
  @Prop getOrientaion: number;
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @Prop private diameter: number = 0;
  @Prop @Watch('updateStep') totalTime: number = 0;
  @Prop timeLeft: number;
  @Link @Watch('resetAngle') reset: boolean;
  @State timerId: number = -1;
  @State @Watch('updateCurrentAngle') currentAngle: number = 360;
  @Prop @Watch('watchPassedTime') passedTime: number = 0;
  private angleStep: number = 0;
  private range: number[] = [];
  private angleList: DialData[] = [];
  @State colorList: string[] = [];
  @State deviceType: string = deviceInfo.deviceType; // 设备类型
  private isTablePad: string = 'tablet'

  aboutToAppear() {
    this.getAngle();
    LogUtil.info(TAG, 'range:' + JSON.stringify(this.range));
    this.setGradientColor(GradientColor.BLUE, GradientColor.CYAN, this.range.length);
    this.getStrokeColorList();
  }

  getAngle() {
    for (let n: number = FULL_CIRCLE_ANGLE; this.range.length < (SECOND_IN_MINUTE * SCALE_UNIT_WIDTH);
         n -= SECOND_ANGLE_STEP * HALF) {
      this.range.push(n);
    }
  }

  getStrokeColorList() {
    for (let i = 0; i < this.range.length; i++) {
      this.angleList.push({
        num: this.range[i],
        color: this.colorList[i - 1]
      });
    }
    LogUtil.info(TAG, 'angleList:' + JSON.stringify(this.angleList));
  }

  setGradientColor(startColor: string, endColor: string, step: number) {
    let startN = this.rgbToArr(startColor);
    let bR: number = startN[0];
    let bG: number = startN[1];
    let bB: number = startN[2];
    let endN = this.rgbToArr(endColor);
    let eR: number = endN[0];
    let eG: number = endN[1];
    let eB: number = endN[2];
    const rR: number = (eR - bR) / step;
    const rG: number = (eG - bG) / step;
    const rB: number = (eB - bB) / step;
    for (let i = 0; i < step; i++) {
      this.colorList.push(`rgb(${Number.parseInt(String(rR * i + bR))},${Number.parseInt(String(rG * i + bG))},${Number.parseInt(String(rB * i + bB))})`);
    }
    LogUtil.info(TAG, `colorList: ${this.colorList}`);
    this.colorList.pop();
    return this.colorList;
  }

  rgbToArr(rgb: string) {
    let newRgb = this.colorRgb(rgb);
    let rgbArr = newRgb.replace('rgb(', '').replace(')', '').split(',');
    LogUtil.info(TAG, `rgbArr: ${rgbArr}`);
    let rgbNewArr = rgbArr.map(item => {
      return Number.parseInt(item);
    })
    return rgbNewArr;
  }

  colorRgb(sColor: string) {
    sColor = sColor.replace('#', '');
    const RR = Number.parseInt(sColor.slice(0, 2), 16);
    const BB = Number.parseInt(sColor.slice(2, 4), 16);
    const AA = Number.parseInt(sColor.slice(4), 16);
    LogUtil.info(TAG, `rgb(${RR},${BB},${AA})`);
    return `rgb(${RR},${BB},${AA})`;
  }

  updateCurrentAngle() {
  }

  aboutToDisappear() {
    this.timerId !== -1 && clearInterval(this.timerId);
  }

  watchPassedTime() {
    let angle = 0;
    const passedTime = this.passedTime;
    let totalTime = this.totalTime;
    let step = 360 / totalTime;
    angle = passedTime * step * -1;
    if (Math.abs(angle) >= 360) {
      angle = 0;
    }
    this.currentAngle = angle;
  }

  private updateStep() {
    this.angleStep = (FULL_CIRCLE_ANGLE / this.totalTime);
    LogUtil.info(TAG, `totalTime=>${this.totalTime}`);
    LogUtil.info(TAG, `angleStep=>${this.angleStep}`);
  }

  private resetAngle() {
    if (this.reset) {
      LogUtil.info(TAG, 'Resetting angle with animation');
      animateTo({
        duration: 350,
        curve: Curve.Friction,
      }, () => {
      })
    }
  }

  setRemainHeight() {
    if (this.foldAbleScreen === 1) {
      this.remainHeight = this.getOrientaion === FOLD_SCREEN_WIDTH ? FOLD_REMAIN_HEIGHT : COLREMAIN_HEIGHT;
    }
    this.remainHeight = this.isPortraitOrientation ? COLREMAIN_HEIGHT : ROW_REMAIN_HEIGHT;
  }

  @Builder
  buildTimerDial() {
    Column() {
      Stack() {
        Image($r('app.media.img_clock_timer_bg'))
          .height(this.diameter * this.scaleDiameterRatio * DIAL_DIAMETER_RATIO)
          .width(this.diameter * this.scaleDiameterRatio * DIAL_DIAMETER_RATIO)
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .interpolation(ImageInterpolation.Medium)

        ForEach(this.angleList, (item: DialData) => {
          Line()
            .width(SCALE_UNIT_WIDTH)
            .height(this.diameter * this.scaleDiameterRatio + LINE_HEIGHT)
            .startPoint([0, 0])
            .endPoint([0, SCALE_UNIT_HEIGHT])
            .stroke($r('app.color.timer_stroke'))
            .strokeWidth(SCALE_UNIT_WIDTH)
            .strokeLineCap(LineCapStyle.Round)
            .rotate({ z: 1, angle: item.num })
            .visibility(this.diameter > 0 ? Visibility.Visible : Visibility.Hidden)

          if ((this.currentAngle !== 0) && (item.num <= (FULL_CIRCLE_ANGLE - Math.abs(this.currentAngle)))) {
            Line()
              .width(SCALE_UNIT_WIDTH)
              .height(this.diameter * this.scaleDiameterRatio + LINE_HEIGHT)
              .startPoint([0, 0])
              .endPoint([0, SCALE_UNIT_HEIGHT])
              .stroke(item.color)
              .strokeWidth(SCALE_UNIT_WIDTH)
              .strokeLineCap(LineCapStyle.Round)
              .rotate({ z: 1, angle: item.num })
              .opacity(item.num / FULL_CIRCLE_ANGLE + 0.2)
          }
        })

        Image($r('app.media.img_clock_timer_dial_secondhand'))
          .height(this.diameter * this.scaleDiameterRatio + this.remainHeight)
          .objectFit(ImageFit.Contain)
          .draggable(false)
          .translate({ x: -0.52 })
          .rotate({ z: 1, angle: this.currentAngle })
          .interpolation(ImageInterpolation.Medium)
      }
      .id('id_timer')
      .width('100%')
      .height('100%')
      .transition({ type: TransitionType.All, opacity: 0, scale: { x: CLOCK_SCALE_VALUE, y: CLOCK_SCALE_VALUE } })
    }
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.diameter) {
      Row() {
        this.buildTimerDial();
      }
      .width('100%')
      .height(this.diameter)
      .justifyContent(FlexAlign.Center)
    }
  }
}
