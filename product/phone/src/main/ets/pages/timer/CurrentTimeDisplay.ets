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
import { TimerController } from "@ohos/timer"
import { TimerUtil, ConfigData } from '@ohos/common'

@Component
export struct CurrentTimeDisplay {
  @State currentTime: number = 0
  @Prop lastTimeMs: number
  @State timerController: TimerController = new TimerController()

  aboutToAppear() {
    this.timerController.setTimeUpdateListener((currentTimeMs: number) => {
      this.currentTime = currentTimeMs
    })
  }

  build() {
    Column() {
      Text(TimerUtil.timeFormat(this.currentTime))
        .lineHeight($r("app.float.wh_value_32"))
        .fontColor($r("app.color.text_color"))
        .fontWeight(500)
        .fontSize($r("app.float.font_40"))
      Text(TimerUtil.timeFormat(this.currentTime - this.lastTimeMs))
        .lineHeight($r("app.float.wh_value_32"))
        .fontColor($r("app.color.text_color"))
        .opacity($r("app.float.opacity_6"))
        .fontSize($r("app.float.font_28"))
        .visibility(this.lastTimeMs > 0 ? Visibility.Visible : Visibility.Hidden)
    }.width(ConfigData.WH_100_100)
  }
}