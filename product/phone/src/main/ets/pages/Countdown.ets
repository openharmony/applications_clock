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

import { CountdownView, CountdownController, CountdownState, TimeSelectView } from '@ohos/countdown';
import { ImageComponent, ConfigData } from '@ohos/common';

@Component
export struct CountDown {
  private headName: ResourceStr = $r('app.string.timer_clock');
  private controller: CountdownController = new CountdownController();
  private viewSize: number = 373.5;
  @State totalTime: number = 0;
  @State currentTime: number = 0;
  @State state: CountdownState = CountdownState.IDLE;
  @State hour: string = '00';
  @State minute: string = '00';
  @State second: string = '00';

  build() {
    Column() {
      Row() {
        Text(this.headName)
          .fontSize($r('app.float.font_48'))
          .fontColor($r('app.color.text_color'))
          .lineHeight($r('app.float.wh_value_44'))
          .fontWeight(FontWeight.Regular)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .margin({ top: $r('app.float.distance_18_5'), bottom: $r('app.float.distance_12') });
      }
      .width(ConfigData.WH_100_100);

      Scroll() {
        Column() {
          Column() {
            CountdownView({
              viewSize: this.viewSize,
              totalTime: this.totalTime,
              currentTime: this.currentTime,
              state: this.state
            });
          }
          .margin({ bottom: $r('app.float.distance_16'), top: $r('app.float.distance_16') });

          Text(this.hour + ':' + this.minute + ':' + this.second)
            .fontSize($r('app.float.font_40'))
            .fontColor($r('app.color.text_color'))
            .lineHeight($r('app.float.wh_value_32'))
            .fontWeight(FontWeight.Regular);

          Column() {
            TimeSelectView({
              hour: $hour,
              minute: $minute,
              second: $second,
              callBack: this.timeSelectCallBack
            });
          }
          .margin({ top: $r('app.float.distance_42'), bottom: $r('app.float.distance_24') })
          .visibility((this.state == CountdownState.IDLE || this.state == CountdownState.PREPARED) ? Visibility.Visible : Visibility.None);
        }
      }
      .height($r('app.float.wh_value_516'))
      .width(ConfigData.WH_100_100)
      .scrollBar(BarState.Off);

      Row() {
        Row() {
          ImageComponent({ color: $r('app.color.white'), imageSrc: $r('app.media.ic_clock_refresh') });
        }
        .opacity((this.state == CountdownState.IDLE || this.state == CountdownState.STOPPED) ? $r('app.float.opacity_4') : $r('app.float.opacity_full'))
        .enabled((this.state == CountdownState.PREPARED || this.state == CountdownState.PAUSED || this.state == CountdownState.RUNNING))
        .onClick(() => {
          this.controller.reset();
        });

        Row() {
          ImageComponent({
            color: $r('app.color.selected_text_color'),
            imageSrc: this.state == CountdownState.RUNNING ? $r('app.media.ic_clock_suspend') : $r('app.media.ic_clock_play')
          });
        }
        .margin({ left: $r('app.float.distance_48'), right: $r('app.float.distance_48') })
        .opacity((this.state == CountdownState.IDLE || this.state == CountdownState.STOPPED) ? $r('app.float.opacity_4') : $r('app.float.opacity_full'))
        .enabled((this.state == CountdownState.PREPARED || this.state == CountdownState.PAUSED || this.state == CountdownState.RUNNING))
        .onClick(() => {
          if (this.state == CountdownState.PREPARED) {
            this.controller.setTime(this.totalTime);
            this.controller.start();
          } else if (this.state == CountdownState.PAUSED) {
            this.controller.start();
          } else if (this.state == CountdownState.RUNNING) {
            this.controller.pause();
          }
        })

        Row() {
          ImageComponent({ color: $r('app.color.white'), imageSrc: $r('app.media.ic_clock_sound') });
        }
        .onClick(() => {
        });
      }.margin({ top: $r('app.float.distance_16'), bottom: $r('app.float.distance_16') });
    }
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
    .padding({ left: $r('app.float.distance_32'), right: $r('app.float.distance_32') });
  }

  /**
   * CallBack for TimeSelectView.
   */
  private timeSelectCallBack: () => void = () => {
    this.totalTime = (parseInt(this.hour) * 60 * 60 + parseInt(this.minute) * 60 + parseInt(this.second)) * 1000;

    this.controller.setTime(this.totalTime);
  }

  aboutToAppear() {
    this.controller.setStateUpdateListener((state) => {
      this.state = state;
      if (state == CountdownState.STOPPED) {
        this.hour = this.fill(Math.floor(this.totalTime / ConfigData.ONE_HOUR_TIME).toString());
        this.minute = this.fill(Math.floor(this.totalTime % ConfigData.ONE_HOUR_TIME / ConfigData.ONE_MINUTE_TIME).toString());
        this.second = this.fill(Math.floor(this.totalTime % ConfigData.ONE_MINUTE_TIME / ConfigData.ONE_SECOND_TIME).toString());

        this.controller.reStart();
      }
    })
    this.controller.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
      this.currentTime = currentTimeMs;
      this.totalTime = totalTimeMs;

      this.hour = this.fill(Math.floor(this.currentTime / ConfigData.ONE_HOUR_TIME).toString());
      this.minute = this.fill(Math.floor(this.currentTime % ConfigData.ONE_HOUR_TIME / ConfigData.ONE_MINUTE_TIME).toString());
      this.second = this.fill(Math.floor(this.currentTime % ConfigData.ONE_MINUTE_TIME / ConfigData.ONE_SECOND_TIME).toString());
    })
    this.controller.getData();
  }

  /**
   * Make up 0 if less than 10.
   */
  fill(value) {
    return (value > 9 ? '' : '0') + value;
  }
}