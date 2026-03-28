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

import { LogUtil, TimeUtil, TIME_TAG_ID_LIST_IN_ZH } from '../../utils';
import { MILLIS_IN_SECOND } from '../../types';
import { ResourceManager } from '../../manager';

const TAG: string = 'DigitalClock';

/**
 * Digital clock for time change every second, morning, afternoon, etc.
 *
 * @since 2022-09-29
 */
@Component
export struct DigitalClock {
  @State private timeText: string = '';
  private timerId: number = -1;
  @State private leftTag: string = '';
  @State private rightTag: string = '';
  private isResourceInit: boolean = false;
  @Consume('currentIndex') @Watch('refreshTime') currentIndexProvider: number;

  aboutToAppear() {
    this.refreshTime();
    this.timerId = setInterval(() => this.refreshTime(), MILLIS_IN_SECOND);
  }

  aboutToDisappear() {
    this.cancelTimer();
  }

  private cancelTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async refreshTime(): Promise<void> {
    if (!this.isResourceInit) {
      ResourceManager.preloadStringResourcesSync(TIME_TAG_ID_LIST_IN_ZH);
      this.isResourceInit = !this.isResourceInit;
    }
    let timeObj = TimeUtil.getFullFormattedTimeObj();
    if (timeObj.isTagLeft) {
      this.leftTag = timeObj.tag ? timeObj.tag : '';
      this.rightTag = '';
    } else {
      this.rightTag = timeObj.tag ? timeObj.tag : '';
      this.leftTag = '';
    }
    this.timeText = timeObj.time ? timeObj.time : '';
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Text(this.leftTag)
          .fontSize($r('app.float.digital_clock_text_size_normal_18'))
          .fontColor($r('app.color.digital_clock_text_color'))
          .fontWeight(FontWeight.Regular)
          .margin({ bottom: 8 })
      }
      .justifyContent(FlexAlign.End)
      .height($r('sys.float.Display_L'))

      Text(this.timeText)
        .fontSize($r('app.float.digital_clock_text_size_normal_56'))
        .fontColor($r('app.color.digital_clock_text_color'))
        .fontWeight(FontWeight.Medium)
        .margin({
          left: $r('app.float.digital_clock_text_margin'),
          right: $r('app.float.digital_clock_text_margin')
        })
      Column() {
        Text(this.rightTag)
          .fontSize($r('app.float.digital_clock_text_size_normal_18'))
          .fontColor($r('app.color.digital_clock_text_color'))
          .fontWeight(FontWeight.Bold)
      }
      .justifyContent(FlexAlign.End)
      .height($r('sys.float.Title_L'))
    }
    .width('100%')
    .height('100%')
  }
}
