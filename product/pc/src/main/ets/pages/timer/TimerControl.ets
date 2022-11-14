/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { TimerController, TimerState } from '@ohos/timer';
import { ImageComponent, ConfigData } from '@ohos/common';

const DEFAULT_ICON_SIZE: number = 12;

@Component
export struct TimerControl {
  private timerController: TimerController = new TimerController();
  @State state: TimerState = TimerState.IDLE;
  private timeList: Array<number> = [];

  aboutToAppear() {
    this.timerController.setStateUpdateListener((state) => {
      this.state = state;
    })
  }

  build() {
    Row() {
      Row() {
        ImageComponent({
          color: $r('app.color.white'),
          imageSrc: $r('app.media.ic_clock_refresh'),
          imgLength: DEFAULT_ICON_SIZE
        })
      }
      .opacity(this.state == TimerState.PAUSED ? $r('app.float.opacity_full') : $r('app.float.opacity_4'))
      .enabled(this.state == TimerState.PAUSED)
      .onClick(() => {
        this.timerController.reset()
      })

      Row() {
        ImageComponent({
          color: $r('app.color.selected_text_color'),
          imageSrc: this.state == TimerState.RUNNING ?
          $r('app.media.ic_clock_suspend') :
          $r('app.media.ic_clock_play'), imgLength: DEFAULT_ICON_SIZE
        })
      }.onClick(() => {
        if (this.state == TimerState.IDLE) {
          this.timerController.start();
        } else if (this.state == TimerState.RUNNING) {
          this.timerController.pause();
        } else if (this.state == TimerState.PAUSED) {
          this.timerController.start();
        }
      })

      Row() {
        ImageComponent({
          color: $r('app.color.white'),
          imageSrc: $r('app.media.ic_clock_timer2'),
          imgLength: DEFAULT_ICON_SIZE
        })
      }
      .opacity(this.state == TimerState.RUNNING ? $r('app.float.opacity_full') : $r('app.float.opacity_4'))
      .enabled(this.state == TimerState.RUNNING)
      .onClick(() => {
        this.timerController.writeTime();
      })
    }
    .height($r('app.float.wh_value_24'))
    .width(ConfigData.WH_100_100)
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: $r('app.float.distance_10'), top: $r('app.float.distance_4') })
    .padding({ left: $r('app.float.distance_84'), right: $r('app.float.distance_84') })
    .shadow({ radius: $r('app.float.wh_value_28'), offsetY: -60, color: $r('app.color.background_color') })
  }
}