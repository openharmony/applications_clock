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
  private viewSize: number = 232;
  private originRadius: number = 5;
  private scaleWidth: number = 2;
  private scaleHeight: number = 10;
  private scalePadding: number = 5;
  private sca: number = 0.6;
  private imgLength: number = 12;
  @State totalTime: number = 0;
  @State currentTime: number = 0;
  @State state: CountdownState = CountdownState.IDLE;
  @State hour: string = '00';
  @State minute: string = '00';
  @State second: string = '00';

  build() {
    Row() {
      Column() {
        Row() {
          Text(this.headName)
            .fontSize($r('app.float.font_30'))
            .fontWeight(FontWeight.Regular)
            .fontColor($r('app.color.text_color'))
            .lineHeight($r('app.float.wh_value_21'));
        }.width(ConfigData.WH_100_100)
        .padding({ left: $r('app.float.wh_value_24') })
        .height($r('app.float.wh_value_28'));

        Column() {
          CountdownView({
            viewSize: this.viewSize,
            totalTime: this.totalTime,
            currentTime: this.currentTime,
            state: this.state,
            originRadius: this.originRadius,
            scaleWidth: this.scaleWidth,
            scaleHeight: this.scaleHeight,
            scalePadding: this.scalePadding
          });
        }.margin({ top: $r('app.float.wh_value_38'), bottom: $r('app.float.wh_value_38') });

        Column() {
          Text(this.hour + ':' + this.minute + ':' + this.second)
            .lineHeight($r('app.float.wh_value_16'))
            .fontColor($r('app.color.text_color'))
            .fontWeight(FontWeight.Regular)
            .fontSize($r('app.float.font_20'));
        }.width(ConfigData.WH_100_100);
      }
      .height(ConfigData.WH_100_100)
      .width($r('app.float.wh_value_304'));

      Divider().vertical(true).width($r('app.float.wh_value_0_5'));
      Column() {
        Column() {
          TimeSelectView({
            marginRight: $r('app.float.distance_19'),
            dividerMargin: $r('app.float.distance_19'),
            hour: $hour,
            minute: $minute,
            second: $second,
            sca: this.sca,
            callBack: this.timeSelectCallBack
          });
        }
        .justifyContent(FlexAlign.Center)
        .visibility((this.state == CountdownState.IDLE || this.state == CountdownState.PREPARED) ? Visibility.Visible : Visibility.Hidden)
        .padding($r('app.float.distance_12'))
        .height($r('app.float.wh_value_324'))
        .flexShrink(1);

        Row() {
          Row() {
            ImageComponent({
              color: $r('app.color.white'),
              imageSrc: $r('app.media.ic_clock_refresh'),
              imgLength: this.imgLength
            });
          }
          .opacity((this.state == CountdownState.IDLE || this.state == CountdownState.STOPPED) ? $r('app.float.opacity_4') : $r('app.float.opacity_full'))
          .enabled((this.state == CountdownState.PREPARED || this.state == CountdownState.PAUSED || this.state == CountdownState.RUNNING))
          .onClick(() => {
            this.controller.reset();
          });

          Row() {
            ImageComponent({
              color: $r('app.color.selected_text_color'),
              imageSrc: this.state == CountdownState.RUNNING ? $r('app.media.ic_clock_suspend') : $r('app.media.ic_clock_play'),
              imgLength: this.imgLength
            });
          }
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
          });

          Row() {
            ImageComponent({
              color: $r('app.color.white'),
              imageSrc: $r('app.media.ic_clock_sound'),
              imgLength: this.imgLength
            });
          }
          .onClick(() => {
          });
        }
        .height($r('app.float.wh_value_24'))
        .width(ConfigData.WH_100_100)
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: $r('app.float.distance_10'), top: $r('app.float.distance_4') })
        .padding({ left: $r('app.float.distance_84'), right: $r('app.float.distance_84') });
      }
      .height(ConfigData.WH_100_100)
      .width($r('app.float.wh_value_275_5'));
    }
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
        let date = new Date(this.totalTime);
        this.hour = this.fill(date.getHours());
        this.minute = this.fill(date.getMinutes());
        this.second = this.fill(date.getSeconds());
        this.controller.reStart();
      }
    })
    this.controller.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
      this.currentTime = currentTimeMs;
      this.totalTime = totalTimeMs;
      let date = new Date(this.currentTime);
      this.hour = this.fill(date.getHours());
      this.minute = this.fill(date.getMinutes());
      this.second = this.fill(date.getSeconds());
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