/*
 * Copyright (c) 2023-2024 Huawei Device Co., Ltd.
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

@Entry
@Component
struct WidgetCard {
  @LocalStorageProp('nextAlarmTime') nextAlarmTime: ResourceStr = $r('app.string.fa_alarm_alert');
  @LocalStorageProp('remainingTime') remainingTime: string = '';
  @LocalStorageProp('isRinging') isRinging: boolean = false;
  @LocalStorageProp('ringingTimestamp') ringingTimestamp: number = 0;
  @LocalStorageProp('noAlarms') noAlarms: boolean = true;
  @State time: number = -1;
  @State six: number = 6;
  @State ten: number = 10;
  @State XVIII: number = 18;
  @State twentyTwo: number = 22;
  private timeCache: number = -1;
  private pictures: Resource = $r('app.media.Stateless')
  private blackWhite: Resource = $r('app.media.icon_clock_black')
  /*
   * The title.
   */
  readonly TITLE: string = 'Hello World';
  /*
   * The action type.
   */
  readonly ACTION_TYPE: string = 'router';
  /*
   * The ability name.
   */
  readonly ABILITY_NAME: string = 'com.ohos.clock.phone';
  /*
   * The message.
   */
  readonly MESSAGE: string = 'add detail';
  /*
   * The width percentage setting.
   */
  readonly FULL_WIDTH_PERCENT: string = '100%';
  /*
   * The height percentage setting.
   */
  readonly FULL_HEIGHT_PERCENT: string = '100%';

  private ShowsSetInterval(): Resource {
    this.pictures = $r('app.media.Stateless')
    return this.pictures
  }

  private blackAndWhite(): Resource {
    if (this.noAlarms) {
      return $r('app.media.icon_clock_black');
    }
    if (this.time >= this.six && this.time < this.XVIII ||
      this.time == -1 && (this.timeCache >= this.six && this.timeCache < this.XVIII)) {
      this.blackWhite = $r('app.media.icon_clock_black')
    } else if (this.time >= this.XVIII || this.time < this.six ||
      (this.time == -1 && (this.timeCache >= this.XVIII || this.timeCache < this.six))) {
      this.blackWhite = $r('app.media.icon_clock_white')
    }
    return this.blackWhite
  }

  @Builder
  CardRipples(): void {
    Image(this.ShowsSetInterval())
      .width(this.FULL_WIDTH_PERCENT)
      .height(this.FULL_HEIGHT_PERCENT)
      .syncLoad(true)
  }

  @Builder
  buildClockDetail(): void {
    Stack() {
      this.CardRipples()
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Start }) {
          Text(this.nextAlarmTime)
            .fontSize($r('app.float.main_tab_line_height'))
            .fontColor($r('app.color.card_text_color_title'))
            .lineHeight($r('app.float.slide_to_turn_off_font_size'))
            .margin({ left: $r('app.float.divider_margin_offset_left') })
            .fontWeight(FontWeight.Medium)
          if (this.remainingTime) {
            Text(this.remainingTime)
              .fontSize($r('app.float.select_all_text_size'))
              .fontColor($r('app.color.card_text_color_Description'))
              .lineHeight($r('app.float.ohos_id_card_margin_middle'))
              .letterSpacing(0)
              .textAlign(TextAlign.Start)
              .opacity(0.6)
              .margin({ top: $r('app.float.card_title_line_margin'), left: $r('app.float.divider_margin_offset_left') })
              .fontWeight(FontWeight.Regular)
          }
        }

        Image(this.blackAndWhite())
          .width($r('app.float.appbar_icon_size'))
          .height($r('app.float.appbar_icon_size'))
          .margin({ right: $r('app.float.divider_margin_offset_left') })
      }
    }
  }

  build() {
    Row() {
      this.buildClockDetail();
    }
    .width(this.FULL_WIDTH_PERCENT)
    .height(this.FULL_HEIGHT_PERCENT)
    .onClick(() => {
      postCardAction(this, {
        'action': this.ACTION_TYPE,
        'abilityName': this.ABILITY_NAME,
        'params': {
          'tab_active': 'ALARM_CLOCK_TAB'
        }
      });
    })
  }
}