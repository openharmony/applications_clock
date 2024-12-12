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

import { MINUTES_ANGLE_STEP, SECONDS_ANGLE_STEP, CONST_STOPWATCH_POINTER } from './types';
import { FULL_CIRCLE_ANGLE, HALF_CIRCLE_ANGLE } from '@hmos/common/src/main/ets/components/Clock/types';
import { DIAL_DIAMETER_RATIO, LogUtil } from '@hmos/common';

const MINUTEHAND_SCALE_RATIO = 0.32;
const MINUTEHAND_OFFSET_RATIO = 0.18;

/**
 * Stopwatch Dial, scale and hands
 *
 * @since 2023-09-08
 */
@Component
export struct StopwatchDialScale {
  @Prop isPortraitOrientation: boolean = true;
  @Prop private diameter: number = 0;
  @Link @Watch('updateAngle') passedTime: number;
  @State secondsAngle: number = 0;
  @State minutesAngle: number = 0;

  private updateAngle(): void {
    if (this.passedTime == 0) {
      if (this.secondsAngle > 0) {
        animateTo({
          duration: 350,
          curve: Curve.Friction,
        }, () => {
          this.secondsAngle = this.secondsAngle > HALF_CIRCLE_ANGLE ? FULL_CIRCLE_ANGLE : 0;
          this.minutesAngle = this.minutesAngle > HALF_CIRCLE_ANGLE ? FULL_CIRCLE_ANGLE : 0;
        })
      }
    } else {
      this.secondsAngle = (this.passedTime * SECONDS_ANGLE_STEP) % FULL_CIRCLE_ANGLE;
      this.minutesAngle = (this.passedTime * MINUTES_ANGLE_STEP) % FULL_CIRCLE_ANGLE;
    }
  }

  @Builder
  buildMinutesDial() {
    Stack() {
      Image($r('app.media.img_stopwatch_minutes_dial_scale'))
        .height(this.diameter * MINUTEHAND_SCALE_RATIO)
        .width(this.diameter * MINUTEHAND_SCALE_RATIO)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .interpolation(ImageInterpolation.Low)
      Image($r('app.media.img_stopwatch_minutehand'))
        .height(this.diameter * MINUTEHAND_SCALE_RATIO)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .interpolation(ImageInterpolation.Low)
        .rotate({ angle: this.minutesAngle })
      Image($r('app.media.img_stopwatch_minutehand_shadow'))
        .height(this.diameter * MINUTEHAND_SCALE_RATIO)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .interpolation(ImageInterpolation.Low)
        .rotate({ angle: this.minutesAngle })
    }
    .offset({ y: -this.diameter * MINUTEHAND_OFFSET_RATIO })
    .width('100%')
  }

  build() {
    Stack() {
      Image($r('app.media.img_stopwatch_dial_scale'))
        .height(this.diameter * DIAL_DIAMETER_RATIO)
        .width(this.diameter * DIAL_DIAMETER_RATIO)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .interpolation(ImageInterpolation.Low)
      this.buildMinutesDial()
    }
  }
}