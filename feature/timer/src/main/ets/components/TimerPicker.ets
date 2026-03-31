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
  EventName,
  EventReportUtil,
  MILLIS_IN_SECOND,
  MINUTE_IN_HOUR,
  SECOND_IN_MINUTE,
  EVENT_ID_SWITCH_PAGE,
  LogUtil,
  SoundPool
} from '@hmos/common';
import { prevInsertZero } from '../common/Utils';
import { ITextPickerConfig } from '../types'
// import hiSysEvent from '@ohos.hiSysEvent';
import emitter from '@ohos.events.emitter';
import common from '@ohos.app.ability.common';
import audio from '@ohos.multimedia.audio';
import vibrator from '@ohos.vibrator';

const SECOND_IN_HOUR = SECOND_IN_MINUTE * MINUTE_IN_HOUR;

// 横屏默认数据
const hTextPickerConfig: ITextPickerConfig = {
  pickerItemFontSize: $r('app.float.timer_picker_text_size_h'),
  pickerSelectedFontSize: $r('app.float.timer_picker_selected_text_size_h'),
  pickerItemHeight: '52vp',
  pickerHeight: '180vp'
}
// 竖屏默认数据
const defaultTextPickerConfig: ITextPickerConfig = {
  pickerItemFontSize: $r('app.float.timer_picker_text_size'),
  pickerSelectedFontSize: $r('app.float.timer_picker_selected_text_size'),
  pickerItemHeight: '70vp',
  pickerHeight: '210vp'
}


interface ReportParams {
  PACKAGE_NAME: string;
  PROCESS_NAME: string;
  RESULT: string;
  VALUE?: string;
  STATUS?: string
}

/**
 * Timer Picker component
 *
 * Since 2023-09-22
 */
@Component
export struct TimerPicker {
  @Link @Watch('computedPickerConfigHandle') isPortraitOrientation: boolean; //纵向 true 横向 false
  @Link @Watch('updateSelectedValues') time: number;
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @Link planHours: string;
  @Link planMinutes: string;
  @Link planSeconds: string;
  @Prop isMdView: boolean = false;
  @Prop isTabIndexChange: boolean;
  private hoursRange: string[] = [];
  private minutesRange: string[] = [];
  private secondsRange: string[] = [];
  private uri: string = '';
  private soundID: number = 0;
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
    rendererFlags: 1
  };
  @State context: Context = getContext(this) as common.UIAbilityContext;
  @State hours: string | number = this.planHours || '00';
  @State minutes: string | number = this.planMinutes || '00';
  @State seconds: string | number = this.planSeconds || '00';
  @State textPickerConfig: ITextPickerConfig = defaultTextPickerConfig;
  @State isPageShow: boolean = true;

  aboutToAppear() {
    for (let h: number = 0; h < 100; ++h) {
      let formatNumber: string = prevInsertZero(h);
      this.hoursRange.push(formatNumber);
      if (h < MINUTE_IN_HOUR) {
        this.minutesRange.push(formatNumber);
        this.secondsRange.push(formatNumber);
      }
    }
    // 监听应用切换后台，刷新timePicker
    emitter.on({
      eventId: EVENT_ID_SWITCH_PAGE
    }, (target) => {
      this.isPageShow = target.data?.isPageShow;
    });
  }

  // 拨盘声振
  private textPickerChanged(index: number | number[]) {
    try {
      vibrator.startVibration(
        {
          type: 'preset',
          effectId: 'haptic.clock.timer',
          count: 1,
        },
        {
          id: 0,
          usage: 'simulateReality'
        }, (error) => {
        if (error) {
          LogUtil.error('vibrate fail, error.code: ' + error.code + 'error.message: ' + error.message);
          return;
        }
        LogUtil.info('Callback returned to indicate a successful vibration.');
      });
    } catch (err) {
      LogUtil.error('errCode: ' + err.code + ' ,msg: ' + err.message);
    }
    SoundPool.playSoundPool('timePick')

  }

  private updateSelectedValues(): void {
    let date = new Date(this.time);
    this.hours = prevInsertZero(Number(date.getUTCDate() - 1) * 24 + date.getUTCHours());
    this.minutes = prevInsertZero(date.getUTCMinutes());
    this.seconds = prevInsertZero(date.getUTCSeconds());
    this.planHours = this.hours;
    this.planMinutes = this.minutes;
    this.planSeconds = this.seconds;
  }

  private updateSelectedTime() {
    this.time = (Number(this.hours) * SECOND_IN_HOUR + Number(this.minutes) * SECOND_IN_MINUTE +
    Number(this.seconds)) * MILLIS_IN_SECOND;
  }

  private computedPickerConfigHandle(): void {
    if (this.isPortraitOrientation) {
      this.textPickerConfig = defaultTextPickerConfig;
    } else {
      this.textPickerConfig = hTextPickerConfig;
    }
  }

  private getFoldAbleScreen(): boolean {
    return this.foldAbleScreen === 1 || this.isPortraitOrientation ? true : false
  }

  private getFoldAbleScreenTextStyle(): Resource {
    return this.getFoldAbleScreen() ? $r('app.float.size36') : $r('app.float.size28')
  }

  private getFoldAbleScreenSelectedTextStyle(): Resource {
    return this.getFoldAbleScreen() ? $r('app.float.size42') : $r('app.float.size38')
  }

  build() {
    Row() {
      if (this.isPageShow && this.isTabIndexChange) {
        TextPicker({ range: this.hoursRange, value: this.hours.toString() })
          .canLoop(true)
          .width('52vp')
          .defaultPickerItemHeight(this.getFoldAbleScreen() ? '56vp' : '52vp')
          .backgroundColor(Color.Transparent)
          .textStyle({
            color: $r('app.color.text_picker_color'),
            font: {
              size: this.getFoldAbleScreenTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .selectedTextStyle({
            color: $r('sys.color.font_primary'),
            font: {
              size: this.getFoldAbleScreenSelectedTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .onChange((value: string | string[], index: number | number[]) => {
            this.planHours = prevInsertZero(Number(value));
            if (prevInsertZero(Number(value)) === this.hours) {
              return;
            }
            this.hours = prevInsertZero(Number(value));
            this.textPickerChanged(index);
            this.updateSelectedTime();
          })
          .height($r('app.float.timer_picker_height'))
        Text(':')
          .width($r('app.float.timer_price_width'))
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.font_primary'))
          .fontSize(this.textPickerConfig.pickerSelectedFontSize)
          .fontWeight(FontWeight.Medium)
          .lineHeight(this.getFoldAbleScreen() ? $r('app.float.line_height_36') : 0)
          .margin({
            left: $r('app.float.timer_hint_row_height'),
            right: $r('app.float.timer_hint_row_height'),
            bottom: this.getFoldAbleScreen() ? 0 : $r('app.float.timer_hint_row_height')
          })

        TextPicker({ range: this.minutesRange, value: this.minutes.toString() })
          .canLoop(true)
          .width('52vp')
          .defaultPickerItemHeight(this.getFoldAbleScreen() ? '56vp' : '52vp')
          .backgroundColor(Color.Transparent)
          .textStyle({
            color: $r('app.color.text_picker_color'),
            font: {
              size: this.getFoldAbleScreenTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .selectedTextStyle({
            color: $r('sys.color.font_primary'),
            font: {
              size: this.getFoldAbleScreenSelectedTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .onChange((value: string | string[], index: number | number[]) => {
            this.planMinutes = prevInsertZero(Number(value));
            if (prevInsertZero(Number(value)) === this.minutes) {
              return;
            }
            this.minutes = prevInsertZero(Number(value));
            this.textPickerChanged(index);
            this.updateSelectedTime();
          })
          .height($r('app.float.timer_picker_height'))
        Text(':')
          .width($r('app.float.timer_price_width'))
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
          .lineHeight(this.getFoldAbleScreen() ? $r('app.float.line_height_36') : '')
          .fontSize(this.textPickerConfig.pickerSelectedFontSize)
          .fontWeight(FontWeight.Medium)
          .margin({
            left: $r('app.float.timer_hint_row_height'),
            right: $r('app.float.timer_hint_row_height'),
            bottom: this.getFoldAbleScreen() ? 0 : $r('app.float.timer_hint_row_height')
          })

        TextPicker({ range: this.secondsRange, value: this.seconds.toString() })
          .canLoop(true)
          .width('52vp')
          .defaultPickerItemHeight(this.getFoldAbleScreen() ? '56vp' : '52vp')
          .backgroundColor(Color.Transparent)
          .textStyle({
            color: $r('app.color.text_picker_color'),
            font: {
              size: this.getFoldAbleScreenTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .selectedTextStyle({
            color: $r('sys.color.font_primary'),
            font: {
              size: this.getFoldAbleScreenSelectedTextStyle(),
              weight: FontWeight.Medium
            }
          })
          .onChange((value: string | string[], index: number | number[]) => {
            this.planSeconds = prevInsertZero(Number(value));
            if (prevInsertZero(Number(value)) === this.seconds) {
              return;
            }
            this.seconds = prevInsertZero(Number(value));
            this.textPickerChanged(index);
            this.updateSelectedTime();
          })
          .height($r('app.float.timer_picker_height'))
      }
    }
    .offset({ x: -6 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .width(this.isMdView ? '252vp' : $r('app.float.timer_picker_width_picker'))
    .height(this.isPortraitOrientation ? '210vp' : '')
  }
}
