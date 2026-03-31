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

import { Card, CardSize, TimeUtil, ResourceManager, TIME_TAG_ID_LIST_IN_ZH, LogUtil } from '@hmos/common';
import { WorldClockInfo } from '../../manager/types';
import { WorldClockManager } from '../../manager';

/**
 * World Clock Card
 *
 * @since 2022-09-26
 */
@Component
export struct WorldClockCard {
  @Prop @Watch('updateCityInfo') isChanged: boolean = false;
  @Prop @Watch('updateCityInfoByHourSystem') isHourSystemChanged: boolean = false;
  @Prop cancelDoubleCardMargin: boolean = false;
  @State cityTimeZoneInfo?: string = '';
  @Prop isLarge: boolean = false
  private cityInfo: WorldClockInfo = {} as WorldClockInfo;
  private cityName: string = '';
  @State timeText: string = '';
  // Tag of time , Exp: am pm
  @State private leftTag?: string = '';
  @State private rightTag?: string = '';
  private minute: number = -1;

  aboutToAppear() {
    this.updateCityInfo();
  }

  onPageShow() {
    this.updateCityInfo();
  }

  private async updateCityInfo(): Promise<void> {
    this.cityName = WorldClockManager.getDisplayCityName(this.cityInfo.cityIndex);
    const currentMinute = new Date().getMinutes();
    if (currentMinute === this.minute) {
      return;
    }
    await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
    const timeObj = TimeUtil.getFormattedTimeZoneTimeObjByTimeZone(this.cityInfo.timezone);
    if (timeObj.isTagLeft) {
      this.leftTag = timeObj.tag;
      this.rightTag = '';
    } else {
      this.rightTag = timeObj.tag;
      this.leftTag = '';
    }
    this.timeText = timeObj.time as string;
    this.minute = currentMinute;
    this.cityTimeZoneInfo = this.cityInfo.tag;
  }

  private async updateCityInfoByHourSystem(): Promise<void> {
    const timeObj = TimeUtil.getFormattedTimeZoneTimeObjByTimeZone(this.cityInfo.timezone);
    if (timeObj.isTagLeft) {
      this.leftTag = timeObj.tag;
      this.rightTag = '';
    } else {
      this.rightTag = timeObj.tag;
      this.leftTag = '';
    }
    this.timeText = timeObj.time as string;
    this.cityTimeZoneInfo = this.cityInfo.tag;
  }

  @Builder
  buildCardLeftPart() {
    Column() {
      Row() {
        Text(this.cityName)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
          .lineHeight($r('app.float.card_title_line_height'))
          .focusable(true)
      }
      .alignSelf(ItemAlign.Start)

      Row() {
        Text(this.cityTimeZoneInfo)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)
          .margin({ top: $r('app.float.card_title_line_margin') })
          .lineHeight($r('app.float.card_content_line_height'))
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('165%')
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildCardRightPart() {
    Column() {
      Flex({ justifyContent: FlexAlign.End, alignItems: ItemAlign.Baseline }) {
        Text(this.leftTag)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)
          .margin({
            right: $r('app.float.text_margin_right'),
          })
        Text(this.timeText)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
        Text(this.rightTag)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)
          .margin({
            right: $r('app.float.text_margin_right'),
          })
      }
    }
    .margin({ top: this.cancelDoubleCardMargin ? $r('app.float.card_content_text_margin_top_11') : 0 })
    .alignSelf(this.cancelDoubleCardMargin ? ItemAlign.Start : ItemAlign.Center)
  }

  @Styles
  largeStyles() {
    .padding({
      right: this.isLarge ? $r('app.float.card_padding_horizontal') : 0,
      top: this.isLarge ? $r('app.float.card_inner_padding_10') : 0,
      bottom: this.isLarge ? $r('app.float.card_inner_padding_11') : 0,
    })
    .borderRadius(this.isLarge ? $r('sys.float.corner_radius_level10') : 0)
  }

  @Builder
  buildCardFoldsLeftPartPrivate() {
    Column() {
      Row() {
        Text(this.cityName)
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Subtitle_S'))
          .fontWeight(FontWeight.Medium)
      }
      .alignSelf(ItemAlign.Start)

      Row() {
        Text(this.cityTimeZoneInfo ? this.cityTimeZoneInfo.split('，')[0].toString() : '')
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)

      }
      .margin({ top: 4 })
      .alignSelf(ItemAlign.Start)
    }
    .margin({ top: $r('app.float.card_content_text_margin_top_11') })
    .width('100%')
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildCardFoldsLeftEndPrivate() {
    Column() {
      Text(this.cityTimeZoneInfo ? this.cityTimeZoneInfo.slice(3, this.cityTimeZoneInfo.length).toString() : '')
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .alignSelf(ItemAlign.Start)
        .margin(this.cityName.length > 6 ? { bottom: 12 } : {
          top: $r('app.float.card_content_text_margin_top_24'),
          bottom: 12
        })
    }
    .width('100%')
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildContent() {
    Column() {
      Card({
        openHoverStatus: this.isLarge,
        openPressStatus: this.isLarge,
        cancelDoubleCardMargin: this.cancelDoubleCardMargin,
        restrictAlarmCardMargin: true,
        focusRemoveLRMargin: this.isLarge && true,
        cardSize: this.isLarge ? CardSize.LARGER : CardSize.NORMAL
      }) {
        if (this.cancelDoubleCardMargin) {
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
              this.buildCardFoldsLeftPartPrivate()
              this.buildCardRightPart()
            }

            this.buildCardFoldsLeftEndPrivate()
          }
          .constraintSize({
            minHeight: this.cancelDoubleCardMargin ? $r('app.float.card_double_height') : $r('app.float.card_content_height')
          })
          .largeStyles()
        } else {    //这里
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween }) {
              this.buildCardLeftPart()
              this.buildCardRightPart()
            }
            .constraintSize({
              minHeight: this.cancelDoubleCardMargin ? $r('app.float.card_double_height') : $r('app.float.card_content_height')
            })
            .largeStyles()
          }
        }
      }

    }
  }

  build() {
    Column() {
      this.buildContent()
    }
  }
}
