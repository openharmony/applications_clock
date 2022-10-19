/**
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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

import { CountdownView, CountdownController, CountdownState, TimeSelectView } from '@ohos/countdown'
import { ImageComponent, ConfigData } from '@ohos/common'

@Component
export struct CountDown {
  private headName: ResourceStr = $r("app.string.timer_clock")
  @State totalTime: number = 0;
  @State currentTime: number = 0;
  @State state: CountdownState = CountdownState.IDLE;
  private controller: CountdownController = new CountdownController();
  @State hour: string = "00";
  @State minute: string = "00";
  @State second: string = "00";

  build() {
    Column() {
      Row() {
        Text(this.headName)
          .fontSize($r("app.float.font_48"))
          .fontColor($r("app.color.text_color"))
          .lineHeight($r("app.float.wh_value_44"))
          .fontWeight(500)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ top: $r("app.float.distance_18_5"), bottom: $r("app.float.distance_12") })
      }
      .width(ConfigData.WH_100_100)

      Scroll() {
        Column() {
          Column() {
            CountdownView({
              viewSize: 373.5,
              totalTime: this.totalTime,
              currentTime: this.currentTime,
              state: this.state
            })
          }
          .margin({ bottom: $r("app.float.distance_16"), top: $r("app.float.distance_16") })

          Text(this.hour + ":" + this.minute + ":" + this.second)
            .fontSize($r("app.float.font_40"))
            .fontColor($r("app.color.text_color"))
            .lineHeight($r("app.float.wh_value_32"))
            .fontWeight(500)

          Column() {
            TimeSelectView({
              hour: $hour,
              minute: $minute,
              second: $second,
              callBack: this.timeSelectCallBack
            })
          }
          .margin({ top: $r("app.float.distance_42"), bottom: $r("app.float.distance_24") })
          .visibility((this.state == CountdownState.IDLE || this.state == CountdownState.PREPARED) ? Visibility.Visible : Visibility.None)
        }
      }
      .height($r("app.float.wh_value_516"))
      .width(ConfigData.WH_100_100)
      .scrollBar(BarState.Off)

      Row() {
        Row() {
          ImageComponent({ color: $r("app.color.white"), imageSrc: $r('app.media.ic_clock_refresh') })
        }
        .opacity((this.state == CountdownState.IDLE || this.state == CountdownState.STOPPED) ? $r("app.float.opacity_4") : $r("app.float.opacity_full"))
        .enabled((this.state == CountdownState.PREPARED || this.state == CountdownState.PAUSED || this.state == CountdownState.RUNNING))
        .onClick(() => {
          this.controller.reset()
        })

        Row() {
          ImageComponent({
            color: $r("app.color.selected_text_color"),
            imageSrc: this.state == CountdownState.RUNNING ? $r('app.media.ic_clock_suspend') : $r('app.media.ic_clock_play')
          })
        }
        .margin({ left: $r("app.float.distance_48"), right: $r("app.float.distance_48") })
        .opacity((this.state == CountdownState.IDLE || this.state == CountdownState.STOPPED) ? $r("app.float.opacity_4") : $r("app.float.opacity_full"))
        .enabled((this.state == CountdownState.PREPARED || this.state == CountdownState.PAUSED || this.state == CountdownState.RUNNING))
        .onClick(() => {
          if (this.state == CountdownState.PREPARED) {
            this.controller.setTime(this.totalTime)
            this.controller.start()
          } else if (this.state == CountdownState.PAUSED) {
            this.controller.start()
          } else if (this.state == CountdownState.RUNNING) {
            this.controller.pause()
          }
        })

        Row() {
          ImageComponent({ color: $r("app.color.white"), imageSrc: $r('app.media.ic_clock_sound') })
        }
        .onClick(() => {
        })
      }.margin({ top: $r("app.float.distance_16"), bottom: $r("app.float.distance_16") })
    }
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
    .padding({ left: $r("app.float.distance_32"), right: $r("app.float.distance_32") })
  }

  /**
   * CallBack for TimeSelectView.
   */
  private timeSelectCallBack: () => void = () => {
    this.totalTime = (parseInt(this.hour) * 3600 + parseInt(this.minute) * 60 + parseInt(this.second)) * 1000

    this.controller.setTime(this.totalTime)
  }

  aboutToAppear() {
    this.controller.setStateUpdateListener((state) => {
      this.state = state
      if (state == CountdownState.STOPPED) {
        let date = new Date(this.totalTime)
        this.hour = this.fill(date.getHours())
        this.minute = this.fill(date.getMinutes())
        this.second = this.fill(date.getSeconds())
        this.controller.reStart()
      }
    })
    this.controller.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
      this.currentTime = currentTimeMs
      this.totalTime = totalTimeMs
      let date = new Date(this.currentTime)
      this.hour = this.fill(date.getHours())
      this.minute = this.fill(date.getMinutes())
      this.second = this.fill(date.getSeconds())
    })
    this.controller.getData();
  }

  /**
   * Make up 0 if less than 10.
   */
  fill(value) {
    return (value > 9 ? "" : "0") + value;
  }
}