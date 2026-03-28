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

import {
  ACCURACY_ASSURANCE,
  DIAL_DIAMETER_RATIO,
  HOUR_ANGLE_STEP,
  HOUR_HAND_REFRESH_FREQUENCY,
  HOUR_HAND_ROTATION_ANGEL_IN_120_SECONDS,
  HOUR_HAND_ROTATION_ANGEL_IN_TEN_MINUTES,
  MINUTE_ANGLE_STEP,
  SECOND_ANGLE_STEP,
  CONST_POINTER,
  MINUS_HOUR_ANGLE,
  ADD_MINUTE_ANGLE
} from './types';
import { MILLIS_IN_SECOND } from '../../types';
import { LogUtil } from '../../utils';

const TAG: string = 'ClockHands';
const START_HOUR: number = 6;
const END_HOUR: number = 18;

/**
 * 钟表指针，实现时针、分针、秒针样式，控制指针走动
 *
 * @author XiaHan
 * @since 2022-07-05
 */
@Component
struct ClockHands {
  @Prop private diameter: number = 0; // 刻度圆环直径
  @State private secondAngle: number = 0; // 秒针相对12点钟方向的偏移角度
  @State private minuteAngle: number = 0; // 分针相对12点钟方向的偏移角度
  @State private hourAngle: number = 0; // 时针相对12点钟方向的偏移角度
  @State isDay: boolean = false; // 白天or黑夜
  @State nowTime: number = new Date().getHours();
  private secondIntervalId: number = -1; // 每秒执行的更新指针方法的定时器实例的 ID，用于页面销毁时清空定时器
  @Consume('currentIndex') @Watch('refreshTime') currentIndexProvider: number;
  @State isClockBackShown: boolean = false;

  aboutToAppear(): void {
    this.refreshTime(); // 初始化各指针角度
    this.secondIntervalId = setInterval(() => this.refreshTime(), MILLIS_IN_SECOND);
    LogUtil.info(TAG, 'diameter:' + this.diameter + (this.diameter * DIAL_DIAMETER_RATIO));
  }

  aboutToDisappear(): void {
    if (this.secondIntervalId !== -1) {
      clearInterval(this.secondIntervalId);
      this.secondIntervalId = -1;
    }
  }

  /**
   * refresh the angle of each pointer
   */
  private refreshTime(): void {
    const time = new Date();
    this.nowTime = time.getHours();
    if (this.nowTime >= START_HOUR && this.nowTime < END_HOUR) {
      this.isDay = true;
    } else {
      this.isDay = false;
    }
    this.secondAngle = time.getSeconds() * SECOND_ANGLE_STEP;
    this.minuteAngle = (time.getMinutes() * MINUTE_ANGLE_STEP * ACCURACY_ASSURANCE +
    time.getSeconds()) / ACCURACY_ASSURANCE;
    this.hourAngle = (time.getHours() * HOUR_ANGLE_STEP * ACCURACY_ASSURANCE + time.getMinutes() *
      HOUR_HAND_ROTATION_ANGEL_IN_TEN_MINUTES + time.getSeconds() / HOUR_HAND_REFRESH_FREQUENCY *
      HOUR_HAND_ROTATION_ANGEL_IN_120_SECONDS) / ACCURACY_ASSURANCE;
  }

  private ShowsSetInterval(): Resource {
    let pictures: Resource = $r('app.media.img_clock_dial_scale_day')
    return pictures
  }

  build() {
    Stack() {
      Image(this.ShowsSetInterval())
        .height(this.diameter * DIAL_DIAMETER_RATIO)
        .width(this.diameter * DIAL_DIAMETER_RATIO)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .interpolation(ImageInterpolation.Low)
        .onComplete((event) => {
          LogUtil.info(TAG, 'Image onComplete:' + JSON.stringify(event));
          // 返回的状态值为0时，表示图片数据加载成功。返回的状态值为1时，表示图片解码成功。
          if (event && event.loadingStatus === 1) {
            this.isClockBackShown = true;
          }
        })
    }
    .visibility(this.isClockBackShown ? Visibility.Visible : Visibility.Hidden)
  }
}

export default ClockHands;
