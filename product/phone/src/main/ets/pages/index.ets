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

import { ConfigData } from '@ohos/common';
import { Timer } from './timer/Timer';
import { CountDown } from './Countdown';

@Entry
@Component
struct Index {
  private featureList: Array<any> = [
    {
      name: $r('app.string.alarm_clock'),
      icon: $r('app.media.ic_clock_clock'),
      selectedIcon: $r('app.media.ic_clock_clock_click')
    },
    {
      name: $r('app.string.stopwatch'),
      icon: $r('app.media.ic_clock_timer'),
      selectedIcon: $r('app.media.ic_clock_timer_click')
    },
    {
      name: $r('app.string.timer_clock'),
      icon: $r('app.media.ic_clock_second_chronograph'),
      selectedIcon: $r('app.media.ic_clock_second_chronograph_click')
    },
  ];
  @State featureIndex: number = 1;

  build() {
    Column() {
      Column() {
        Column() {
          Timer()
        }.visibility(this.featureIndex == 1 ? Visibility.Visible : Visibility.None)

        Column() {
          CountDown()
        }.visibility(this.featureIndex == 2 ? Visibility.Visible : Visibility.None)
      }
      .width(ConfigData.WH_100_100)
      .height(ConfigData.WH_100_100)
      .flexShrink(1)

      Row() {
        ForEach(this.featureList.map((value, index) => {
          return { i: index, data: value }
        }), item => {
          Column() {
            Image(this.featureIndex == item.i ? item.data.selectedIcon : item.data.icon)
              .width($r('app.float.wh_value_32'))
              .height($r('app.float.wh_value_32'))
            Text(item.data.name)
              .fontColor(this.featureIndex == item.i ? $r('app.color.selected_text_color') : $r('app.color.text_color'))
              .fontSize($r('app.float.font_24'))
              .margin({ top: $r('app.float.distance_3') })
          }.width(ConfigData.WH_33_100)
          .onClick(() => {
            this.featureIndex = item.i;
          })
        }, item => item.i)
      }
      .height($r('app.float.wh_value_75'))
      .width(ConfigData.WH_100_100)
      .justifyContent(FlexAlign.Center)
    }
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
    .backgroundColor($r('app.color.background_color'))
  }
}