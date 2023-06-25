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
    Column() {
      Row() {
        Text($r('app.string.stopwatch'))
          .fontSize($r('app.float.font_48'))
          .fontColor($r('app.color.text_color'))
          .lineHeight($r('app.float.wh_value_44'))
          .fontWeight(500)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ top: $r('app.float.distance_18_5'), bottom: $r('app.float.distance_12') })
      }
      .padding({ left: $r('app.float.wh_value_32') })
      .width(ConfigData.WH_100_100)

      List() {
        ListItem() {
          TimerClock({ timerController: this.timerController })
        }.margin({ bottom: $r('app.float.distance_16'), top: $r('app.float.distance_16') })

        ListItem() {
          CurrentTimeDisplay({ timerController: this.timerController, lastTimeMs: this.lastTimeMs })
        }
        .sticky(Sticky.Normal)
        .backgroundColor($r('app.color.background_color'))
        .shadow({ radius: $r('app.float.wh_value_20'), offsetY: 30, color: $r('app.color.background_color') })
        .margin({ bottom: $r('app.float.distance_8') })

        ListItem() {
          TimeOfRecord({ timeList: this.timeList, lastTimeMs: this.lastTimeMs })
        }
      }
      .width(ConfigData.WH_100_100)
      .height($r('app.float.wh_value_526'))
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)

      TimerControl({ timerController: this.timerController, timeList: this.timeList })
    }
  }
}