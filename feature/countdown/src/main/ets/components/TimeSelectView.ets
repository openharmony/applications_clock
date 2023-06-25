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

import { ConfigData, LogUtil } from '@ohos/common';

const TAG = 'TimeSelectView : ';

@Component
export struct TimeSelectView {
  private marginRight: number | Resource = $r('app.float.distance_30');
  private dividerMargin: number | Resource = $r('app.float.distance_75');
  private hourRange: number[] = Array.from(new Array(ConfigData.HOUR_SELECT).keys());
  private minuteRange: number[] = Array.from(new Array(ConfigData.MINUTE_SELECT).keys());
  private secondRange: number[] = Array.from(new Array(ConfigData.SECOND_SELECT).keys());
  private callBack?: () => void;
  private sca: number = 1;
  @Link hour: string;
  @Link minute: string;
  @Link second: string;

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignContent: FlexAlign.Start }) {
      Stack() {
        Row() {
          TimeSelectItem({
            fruits: this.convert(this.hourRange),
            text: $r('app.string.hour'),
            isVisibility: true,
            marginRight: this.marginRight,
            value: $hour,
            onChangCallBack: this.callBack
          });

          TimeSelectItem({
            fruits: this.convert(this.minuteRange),
            text: $r('app.string.minute'),
            isVisibility: true,
            marginRight: this.marginRight,
            value: $minute,
            onChangCallBack: this.callBack
          });

          TimeSelectItem({
            fruits: this.convert(this.secondRange),
            text: $r('app.string.second'),
            isVisibility: false,
            marginRight: this.marginRight,
            value: $second,
            onChangCallBack: this.callBack
          });
        }

        Divider()
          .strokeWidth(1)
          .color($r('app.color.divider_color'))
          .margin({
            left: this.dividerMargin,
            right: this.dividerMargin, top: $r('app.float.distance_35')
          });

        Divider()
          .strokeWidth(1)
          .color($r('app.color.divider_color'))
          .margin({
            left: this.dividerMargin,
            right: this.dividerMargin, bottom: $r('app.float.distance_78')
          });
      }
    }
    .scale({ x: this.sca, y: this.sca })
  }

  /**
   * Make up 0 if less than 10.
   */
  private convert(char: Array<number>) {
    let str = [];
    for (let i = 0; i < char.length; i++) {
      str.push((char[i] > 9 ? '' : '0') + char[i]);
    }
    return str;
  }
}

@Component
struct TimeSelectItem {
  private fruits: string[] = [];
  private text: ResourceStr = '';
  private isVisibility: boolean = true;
  private marginRight: number | Resource = $r('app.float.distance_30');
  private componentWidth: number | Resource = $r('app.float.wh_value_40');
  private componentHeight: number | Resource = $r('app.float.wh_value_160');
  private onChangCallBack?: () => void;
  @Link value: string;

  build() {
    Row() {
      Column() {
        TextPicker({ range: this.fruits, selected: Number(this.value) })
          .backgroundColor($r('app.color.background_color'))
          .width(this.componentWidth)
          .height(this.componentHeight)
          .onChange((value: string, index: number) => {
            this.value = value;
            this.onChangCallBack();
            LogUtil.info(`${TAG} Picker item changed, value: ${value}, index: ${index} `);
          });
        Text(this.text).fontSize($r('app.float.font_24')).fontWeight(FontWeight.Regular).height($r('app.float.wh_value_21_5'))
      }.margin({ right: this.isVisibility ? this.marginRight : $r('app.float.distance_0') });

      Column() {
        Text(':').fontSize($r('app.float.font_40')).fontWeight(FontWeight.Regular).fontColor($r('app.color.font_color'));
        Text('').fontSize($r('app.float.font_24')).fontWeight(FontWeight.Regular).height($r('app.float.wh_value_21_5'));
      }.margin({ right: this.marginRight })
      .visibility(this.isVisibility ? Visibility.Visible : Visibility.None);
    }
  }
}