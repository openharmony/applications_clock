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

import CommonEventManager from '@ohos.commonEventManager';
import emitter from '@ohos.events.emitter';
import Want from '@ohos.app.ability.Want';
import image from '@ohos.multimedia.image';
// import hiSysEvent from '@ohos.hiSysEvent';
import deviceInfo from '@ohos.deviceInfo'
import {
  AlarmInfo,
  EventName,
  EventReportUtil,
  GlobalContext,
  LogUtil,
  ResourceManager,
  TIME_TAG_ID_LIST_IN_ZH,
  TimeUtil,
  TIMEOUT_FULL_SCREEN_ID,
  TIMEOUT_FULL_SCREEN_REPATE_ID,
  EVENT_ID_TIMER_FULL_SCREEN_CLOSE,
  CommonUtil,
  TIMER_NOTICE_ID,
  FULLSCREEN_SLIPUP_ID,
} from '@hmos/common';
import SlideCloseButton from '../../components/SlideCloseButton';
import { TimerNotificationUtil } from '../../utils';

const TAG = 'FullScreenTimerClock';
const ALARM_BACKGROUND_BLUR = 30;
const SLIDE_BTN_SPACE = 14;
const FLEX_GROW_DEUCE = 1;

interface Time {
  hours: string,
  minute: string,
  second: string
}

/**
 * Full Screen Alarm Page
 *
 * @since 2022-08-18
 */
@Component
export struct FullScreenTimer {
  @Link isBackImageShown: boolean;
  @State currentDateWithWeek: string = '';
  @State private timeText: string = '';
  @State wallpaperImage: image.PixelMap | undefined = undefined;
  private alarmInfo = {} as AlarmInfo;
  private minute: number = -1;
  // Tag of time , Exp: am pm
  private leftTag: string = '';
  private rightTag: string = '';
  private maxLine: number = 2;
  @Link timeoutDuration: number;
  @State timeoutDurationText: string = '00:00:00'
  @State deviceType: string = deviceInfo.deviceType; // 设备类型

  async aboutToAppear() {
    LogUtil.info(TAG, 'aboutToAppear');
    if (GlobalContext.getContext().getObject('wallpaperImage')) {
      this.wallpaperImage = GlobalContext.getContext().getObject('wallpaperImage') as image.PixelMap;
    }
    LogUtil.info(TAG, 'wallpaperImage:' + JSON.stringify(this.wallpaperImage));
    this.alarmInfo = ((GlobalContext.getContext()
      .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
    await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
    this.updateTime();
    emitter.on({ eventId: TIMEOUT_FULL_SCREEN_ID }, (eventData) => {
      this.timeoutDuration = eventData.data?.timeoutDuration
      LogUtil.info(TAG, `${this.timeoutDuration}`);
      this.timeoutDurationText = this.changeShowTime()
    });
    emitter.on({ eventId: EVENT_ID_TIMER_FULL_SCREEN_CLOSE }, async (eventData) => {
      LogUtil.info(TAG, `EVENT_ID_TIMER_FULL_SCREEN_CLOSE`)
      CommonUtil.terminateFullScreenAbility();
      await TimerNotificationUtil.timeoutSlipUpPublish(TIMER_NOTICE_ID, this.timeoutDuration);
      emitter.emit({ eventId: FULLSCREEN_SLIPUP_ID, priority: emitter.EventPriority.IMMEDIATE });
    });

  }

  aboutToDisappear() {
    LogUtil.info(TAG, 'aboutToDisappear');
    emitter.off(TIMEOUT_FULL_SCREEN_ID);
    emitter.off(EVENT_ID_TIMER_FULL_SCREEN_CLOSE);
  }

  private async updateTime(): Promise<void> {
    const currentMinute = new Date().getMinutes();
    if (currentMinute === this.minute) {
      return;
    }
    const nowDate = new Date();
    const timeObj = TimeUtil.getFormattedTimeObj(nowDate.getHours(), nowDate.getMinutes());
    if (timeObj.isTagLeft) {
      this.leftTag = timeObj.tag as string;
      this.rightTag = '';
    } else {
      this.rightTag = timeObj.tag as string;
      this.leftTag = '';
    }
    this.timeText = timeObj.time!;
    this.currentDateWithWeek = TimeUtil.getCurrentFormattedDateWithWeek();
    this.minute = currentMinute;
  }

  private changeShowTime() {
    let fillHours = parseInt(String(this.timeoutDuration / 3600000));
    let fillMinute = parseInt(String((this.timeoutDuration % 3600000) / 60000));
    let fillSecond = parseInt(String((this.timeoutDuration % 60000) / 1000));
    let timeoutDisplay: Time = {
      hours: (fillHours >= 10) ? fillHours.toString() : ('0' + fillHours.toString()),
      minute: (fillMinute >= 10) ? fillMinute.toString() : ('0' + fillMinute.toString()),
      second: (fillSecond >= 10) ? fillSecond.toString() : ('0' + fillSecond.toString())
    }
    LogUtil.info(TAG, `changeShowTime: ${timeoutDisplay.hours + ':' + timeoutDisplay.minute + ':' + timeoutDisplay.second}`)
    return timeoutDisplay.hours + ':' + timeoutDisplay.minute + ':' + timeoutDisplay.second
  }

  private async timerRepeat() {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_TIMER_AGAIN);
    emitter.emit({ eventId: TIMEOUT_FULL_SCREEN_REPATE_ID, priority: emitter.EventPriority.IMMEDIATE, }, {
      data: {
        isFullScreen: true
      }
    });
  }

  @Builder
  buildTimeArea() {
    Column() {
      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Baseline }) {
        Text(this.leftTag)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontSize($r('app.float.ohos_id_text_size_sub_title1'))
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
        Text(this.timeText)
          .fontSize($r('app.float.ohos_id_text_size_headline2'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
        Text(this.rightTag)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .fontSize($r('app.float.ohos_id_text_size_sub_title1'))
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
      }.margin({ top: $r('app.float.current_time_margin_top') })

      Text(this.currentDateWithWeek)
        .fontSize($r('app.float.ohos_id_text_size_sub_title1'))
        .fontWeight(FontWeight.Regular)
        .fontColor(Color.White)
        .margin({
          top: $r('app.float.current_date_margin_top'),
          left: $r('app.float.ohos_id_max_padding_start'),
          right: $r('app.float.ohos_id_max_padding_end'),
        })
    }
    .flexGrow(FLEX_GROW_DEUCE)
    .width('100%')
  }

  @Builder
  async buildLabelAndSnoozeArea() {
    Row() {
      Column() {
        Text($r('app.string.time_to'))
          .fontSize($r('sys.float.Title_L'))
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
          .maxLines(this.maxLine)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({
            left: $r('app.float.ohos_id_max_padding_start'),
            right: $r('app.float.ohos_id_max_padding_end'),
          })
          .alignSelf(ItemAlign.Center)
        Text(this.timeoutDurationText)
          .fontSize($r('app.float.ohos_id_text_size_headline6'))
          .fontWeight(FontWeight.Regular)
          .fontColor(Color.White)
          .maxLines(this.maxLine)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({
            left: $r('app.float.ohos_id_max_padding_start'),
            right: $r('app.float.ohos_id_max_padding_end'),
          })
          .alignSelf(ItemAlign.Center)
        Button($r('app.string.repeat_button_text'), { type: ButtonType.Normal })
          .margin({ top: $r('app.float.snooze_btn_margin_top') })
          .backgroundColor($r('app.color.snooze_button_background_color'))
          .padding({
            left: $r('app.float.snooze_button_padding_horizontal'),
            right: $r('app.float.snooze_button_padding_horizontal'),
            top: $r('app.float.snooze_button_padding_vertical'),
            bottom: $r('app.float.snooze_button_padding_vertical'),
          })
          .border({
            width: $r('app.float.snooze_button_border_width'),
            color: $r('app.color.snooze_button_border_color'),
          })
          .borderRadius($r('sys.float.corner_radius_level10'))
          .fontColor($r('sys.color.warning'))
          .onClick(() => {
            this.timerRepeat()
          })
      }
      .width('100%')
    }
    .width('100%')
    .flexGrow(FLEX_GROW_DEUCE)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildSlideButton() {
    Row() {
      Column({ space: SLIDE_BTN_SPACE }) {
        SlideCloseButton({ alarmInfo: this.alarmInfo })
        Text($r('app.string.slide_to_off_timer'))
          .align(Alignment.Bottom)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.Body_L'))
          .margin({
            bottom: $r('app.float.slide_to_turn_off_margin_bottom'),
            top: $r('app.float.slide_to_turn_off_margin_top')
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .flexGrow(FLEX_GROW_DEUCE)
    .width('100%')
    .alignItems(VerticalAlign.Bottom)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.wallpaperImage) {
        Image(this.wallpaperImage)
          .width('100%')
          .height('100%')
          .objectRepeat(ImageRepeat.NoRepeat)
          .backgroundImageSize(ImageSize.Cover)
          .backdropBlur(ALARM_BACKGROUND_BLUR)
          .onComplete((event) => {
            LogUtil.info(TAG, 'Image onComplete:' + JSON.stringify(event));
            if (event && event.loadingStatus === 1) {
              this.isBackImageShown = true;
            }
          })
      }
      Flex({ direction: FlexDirection.Column }) {
        this.buildTimeArea()
        this.buildLabelAndSnoozeArea()
        this.buildSlideButton()
      }
      .height('100%')
      .width('100%')
    }
    .visibility(this.isBackImageShown ? Visibility.Visible : Visibility.Hidden)
    .height('100%')
    .width('100%')
  }
}