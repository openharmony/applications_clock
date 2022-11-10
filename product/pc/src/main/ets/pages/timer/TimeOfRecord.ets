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

import { TimerUtil, ConfigData } from '@ohos/common'

@Component
export struct TimeOfRecord {
  @State timeList: Array<number> = []
  @Prop lastTimeMs: number

  build() {
    Column() {
      List() {
        ForEach(this.timeList.map((value, index) => {
          return { i: index, data: this.timeList[this.timeList.length - index-1] }
        }), (item) => {
          ListItem() {
            Row() {
              Row() {
                Text(TimerUtil.addZero(this.timeList.length - item.i))
                  .fontColor($r("app.color.text_color"))
                  .fontSize($r("app.float.font_14"))
                  .fontWeight(500)
                Text("+" + TimerUtil.timeFormat(item.data - (item.i < this.timeList.length - 1 ? this.timeList[this.timeList.length - item.i - 2] : 0)))
                  .width($r("app.float.wh_value_60"))
                  .textAlign(TextAlign.Center)
                  .fontSize($r("app.float.font_14"))
                  .fontColor($r("app.color.text_color"))
                  .opacity($r("app.float.opacity_6"))
              }
              .width($r("app.float.wh_value_151"))
              .justifyContent(FlexAlign.SpaceBetween)

              Text(TimerUtil.timeFormat(item.data))
                .fontSize($r("app.float.font_14"))
                .fontColor($r("app.color.text_color"))
                .fontWeight(500)
            }.width(ConfigData.WH_100_100)
            .height(ConfigData.WH_100_100)
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: $r("app.float.distance_12"), right: $r("app.float.distance_12") })
          }
          .height($r("app.float.wh_value_28"))
          .width(ConfigData.WH_100_100)
          .clip(true)
        }, item => item.i)
      }
      .backgroundColor($r("app.color.background_color_white"))

      .borderRadius($r("app.float.distance_12"))
      .margin({ top: $r("app.float.distance_40") })

    }.padding($r("app.float.distance_12"))
    .height($r("app.float.wh_value_324"))
    .flexShrink(1)
  }
}