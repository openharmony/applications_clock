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

import {
  HALF,
  SECOND_IN_MINUTE,
  SCALE_DIAMETER_RATIO,
  MINUTE_IN_HOUR,
  MILLIS_IN_SECOND,
  LogUtil,
  EVENT_ID_TIMEPICK_FORPC
} from '@hmos/common';
import {
  FULL_CIRCLE_ANGLE,
  SCALE_UNIT_WIDTH,
  SECOND_ANGLE_STEP,
  SCALE_UNIT_HEIGHT,
} from '@hmos/common/src/main/ets/components/Clock/types';
import { prevInsertZero } from '../common/Utils';
import emitter from '@ohos.events.emitter';

import resmgr from '@ohos.resourceManager';
import { GlobalContext } from '@hmos/common';

const SECOND_IN_HOUR = SECOND_IN_MINUTE * MINUTE_IN_HOUR;

const TAG = 'TimerPC';

interface b {
  one: string,
}

@Component
struct InputText {
  @Prop text: Resource = $r('app.string.timer_picker_hours')
  @Prop @Watch('resetChange') reset: boolean;
  @Prop indexFlag: String;
  @State textValue: string = '';
  @State isHover: boolean = false;
  @State isFocus: Boolean = false;
  @State isCaret: number = 0;
  onCallBack?: (val: string) => void;
  controller: TextInputController = new TextInputController()

  resetChange() {
    if (this.reset) {
      this.textValue = '00';
    }

  }

  build() {
    Row() {
      Flex({ direction: FlexDirection.Column }) {
        Text(this.text)
          .fontSize($r('app.float.timer_PC_label_size'))
          .lineHeight($r('app.float.line_height_27'))
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.font_secondary'))
          .width($r('app.float.timer_PC_label_width'))
          .margin({ bottom: $r('app.float.timer_PC_label_margin') })
        TextInput({
          text: !this.isFocus ? prevInsertZero(Number(this.textValue)) : this.textValue
        })
          .fontSize($r('app.float.timer_PC_size'))
          .fontColor(this.isFocus ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .maxLength(2)
          .copyOption(CopyOptions.None)
          .width($r('app.float.timer_PC_label_width'))
          .height($r('app.float.timer_PC_input_height'))
          .textAlign(TextAlign.Center)
          .border({ width: 0 })
          .caretColor(this.isCaret > 1 ? $r('app.color.dialog_background_color') : $r('app.color.dialog_background_caret_color') )
          .backgroundColor(
            this.isFocus
              ? $r('sys.color.brand')
              : $r('sys.color.comp_background_tertiary')
          )
          .type(InputType.Number)
          .borderRadius($r('sys.float.corner_radius_level4'))
          .onChange((val: string) => {
            this.textValue = val === '00' ? '00' : val;
            if (this.indexFlag === 'minutes' && Number(val) > 59 || this.indexFlag === 'seconds' && Number(val) > 59) {
              this.textValue = '00';
            }
            this.onCallBack && this.onCallBack(this.textValue);
          })
          .onClick(() => {
            this.isCaret++;
            this.controller.caretPosition(2)
          })
          .onFocus(() => {
            this.isFocus = true;
          })
          .onBlur(() => {
            this.isFocus = false;
            this.isCaret = 0;
          })
      }
    }
  }
}


@Component
export struct TimerPickerForPC {
  @Prop scaleDiameterRatio: number = SCALE_DIAMETER_RATIO
  @Prop private diameter: number = 0;
  @Link @Watch('updateSelectedValues') time: number;
  @State hours: string | number = '00';
  @State minutes: string | number = '00';
  @State seconds: string | number = '00';
  @Link @Watch('resetChange') totalTime: Number;
  @State isCleared: boolean = false
  private range: number[] = [];
  private minList: number[] = [1, 5, 10, 15, 20, 30]

  private updateSelectedTime() {
    this.time = (Number(this.hours) * SECOND_IN_HOUR + Number(this.minutes) * SECOND_IN_MINUTE +
    Number(this.seconds)) * MILLIS_IN_SECOND;
  }

  private updateSelectedValues(): void {
    let date = new Date(this.time);
    this.hours = Number(date.getUTCDate() - 1) * 24 + date.getUTCHours();
    this.minutes = date.getUTCMinutes();
    this.seconds = date.getUTCSeconds();
    emitter.emit({
      eventId: EVENT_ID_TIMEPICK_FORPC,
      priority: emitter.EventPriority.IMMEDIATE,
    }, {
      data: {
        hours: prevInsertZero(this.hours),
        minutes: prevInsertZero(this.minutes),
        seconds: prevInsertZero(this.seconds)
      }
    })
    LogUtil.info(TAG, 'onCallBack this.hours-' + this.hours + ',this.minutes' + this.minutes + ',this.seconds' + this.seconds)
  }

  resetChange() {
    LogUtil.info(TAG, 'resetChange' + this.totalTime);
    if (this.totalTime === 0) {
      this.isCleared = true;
    } else {
      this.isCleared = false;
    }
  }

  aboutToAppear() {
    // 拿到每个刻度的角度
    for (let n: number = FULL_CIRCLE_ANGLE; this.range.length < (SECOND_IN_MINUTE * SCALE_UNIT_WIDTH);
         n -= SECOND_ANGLE_STEP * HALF) {
      this.range.push(n);
    }
    LogUtil.info(TAG, 'Line', this.range.length + '',)
  }

  // 快捷时间按钮
  @Builder
  timeList() {
    Row() {
      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        ForEach(this.minList, (item: number) => {
          Row() {
            Stack() {
              Row() {
              }
              .height($r('app.float.timer_PC_button_width'))
              .width($r('app.float.timer_PC_button_width'))
              .backgroundColor($r('app.color.start_window_background'))
              .borderRadius($r('app.float.timer_PC_button_radius'))

              ForEach(this.range, (item: number) => {
                Line()
                  .width(SCALE_UNIT_WIDTH)
                  .height($r('app.float.timer_PC_button_round_width'))
                  .startPoint([0, 0])
                  .endPoint([0, SCALE_UNIT_HEIGHT])
                  .stroke($r('app.color.timer_stroke'))
                  .strokeWidth(SCALE_UNIT_WIDTH)
                  .strokeLineCap(LineCapStyle.Round)
                  .rotate({ z: 1, angle: item })
                  .visibility(Visibility.Visible)
              })
              Column() {
                Text(item + '')
                  .fontSize($r('app.float.timer_PC_button_size1'))
                  .fontColor($r('app.color.timer_background_color'))
                Text($r('app.string.timer_picker_minutes'))
                  .fontSize($r('app.float.timer_PC_button_size2'))
                  .fontColor($r('app.color.timer_PC_label_font_color'))
              }
            }
          }
          .width('33.33%')
          .margin({ bottom: $r('app.float.timer_PC_button_margin') })
          .justifyContent(FlexAlign.Center)
          .onClick((e) => {
            this.minutes = item
          })
        })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      Row() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          InputText({
            text: $r('app.string.timer_picker_hours'),
            reset: this.isCleared,
            indexFlag: 'hours',
            onCallBack: ((val: string) => {
              LogUtil.info(TAG, 'onCallBack--hours', val)
              this.hours = val
              this.updateSelectedTime()
            })
          })
          Text(':')
            .fontSize($r('app.float.timer_PC_placeholder_size'))
            .margin({ top: $r('app.float.timer_PC_label_margin_top') })
            .fontColor($r('app.color.timer_PC_input_font_color'))
          InputText({
            text: $r('app.string.timer_picker_minutes'),
            reset: this.isCleared,
            indexFlag: 'minutes',
            onCallBack: ((val: string) => {
              LogUtil.info(TAG, 'onCallBack--minutes', val)
              this.minutes = val
              this.updateSelectedTime()
            })
          })
          Text(':')
            .fontSize($r('app.float.timer_PC_placeholder_size'))
            .margin({ top: $r('app.float.timer_PC_label_margin_top') })
            .fontColor($r('app.color.timer_PC_input_font_color'))
          InputText({
            text: $r('app.string.timer_picker_seconds'),
            reset: this.isCleared,
            indexFlag: 'seconds',
            onCallBack: ((val: string) => {
              LogUtil.info(TAG, 'onCallBack--seconds', val)
              this.seconds = val
              this.updateSelectedTime()

            })
          })
        }
        .height($r('app.float.timer_PC_input_main_height'))
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}