/**
 * Copyright (c) 2022 HiHope Open Source Organization.
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

import { TimerController } from '@ohos/timer';
import { ConfigData } from '@ohos/common';
import { TimerClock } from './TimerClock';
import { CurrentTimeDisplay } from './CurrentTimeDisplay';
import { TimeOfRecord } from './TimeOfRecord';
import { TimerControl } from './TimerControl';

@Component
export struct Timer {
  private timerController: TimerController = new TimerController();
  private timeList: Array<number> = [];
  @State lastTimeMs: number = 0;

  aboutToAppear() {
    this.timerController.setTimeListUpdateListener((timeList: Array<number>, lastTimeMs: number) => {
      this.timeList = timeList;
      this.lastTimeMs = lastTimeMs;
    })
    setTimeout(() => {
      this.timerController.reload();
    }, 100)
  }

  build() {
    Row() {
      Column() {
        Row() {
          Text($r('app.string.stopwatch'))
            .fontSize($r('app.float.font_30'))
            .fontWeight(500)
            .fontColor($r('app.color.text_color'))
            .lineHeight($r('app.float.wh_value_21'))
        }.width(ConfigData.WH_100_100)
        .padding({ left: $r('app.float.wh_value_24') })
        .height($r('app.float.wh_value_28'))

        Column() {
          TimerClock({ timerController: this.timerController })
        }.margin({ top: $r('app.float.wh_value_38'), bottom: $r('app.float.wh_value_38') })

        CurrentTimeDisplay({ timerController: this.timerController, lastTimeMs: this.lastTimeMs })
      }
      .height(ConfigData.WH_100_100)
      .width($r('app.float.wh_value_304'))

      Divider().vertical(true).width($r('app.float.wh_value_0_5')).opacity($r('app.float.opacity_1'))
      Column() {
        TimeOfRecord({ timeList: this.timeList, lastTimeMs: this.lastTimeMs })
        TimerControl({ timerController: this.timerController, timeList: this.timeList })
      }
      .height(ConfigData.WH_100_100)
      .width($r('app.float.wh_value_275_5'))
    }
  }
}