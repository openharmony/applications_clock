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

import CommonEventManager from '@ohos.commonEventManager';
import emitter from '@ohos.events.emitter';
// import hiSysEvent from '@ohos.hiSysEvent';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import {
  AlarmInfo,
  EVENT_ID_FINISH_ABILITY,
  EventName,
  EventReportUtil,
  GlobalContext,
  LogUtil,
  ResourceManager,
  TIME_TAG_ID_LIST_IN_ZH,
  TimeUtil,
  AlarmStateManager,
  EVENT_ID_FULL_SCREEN_ALARM,
  EVENT_ID_SEND_ALARM,
  AlarmManager,
  CommonUtil,
  WantAgentUtil
} from '@hmos/common';
import SlideCloseButton from '../../components/SlideCloseButton';
import { AlarmServiceManager } from '../../manager';
import wallpaper from '@ohos.wallpaper';
import image from '@ohos.multimedia.image';
import buffer from '@ohos.buffer';
import audio from '@ohos.multimedia.audio';

const TAG = 'FullScreenClock';
const ALARM_BACKGROUND_BLUR = 30;
const SLIDE_BTN_SPACE = 14;
const FLEX_GROW_DEUCE = 1;
const TIME_SUBSCRIBE_INFO: CommonEventSubscribeInfo = {
  events: [
    CommonEventManager.Support.COMMON_EVENT_TIME_TICK,
  ],
};

// This type is not exported from @ohos.commonEvent, so we get it by exported function.
type CommonEventSubscriber = CommonEventManager.CommonEventSubscriber
// type ServiceExtensionContext = common.ServiceExtensionContext;
type CommonEventSubscribeInfo = CommonEventManager.CommonEventSubscribeInfo


/**
 * Full Screen Alarm Page
 *
 * @since 2022-08-18
 */
@Component
export struct FullScreenAlarm {
  @Link isBackImageShown: boolean;
  @State currentDateWithWeek: string = '';
  @State private timeText: string = '';
  @State wallpaperImage: image.PixelMap | undefined = undefined;
  @State alarmInfo: AlarmInfo | undefined = undefined;
  private timeSubscriber?: CommonEventSubscriber;
  private minute: number = -1;
  // Tag of time , Exp: am pm
  private leftTag: string = '';
  private rightTag: string = '';
  private maxLine: number = 2;

  async getAlarmInfo() {
    let wantAlarmInfo = (GlobalContext.getContext()
      .getObject('abilityWant') as Want)?.parameters?.alarmInfo;
    LogUtil.info(TAG, `wantAlarmInfo => ${JSON.stringify(wantAlarmInfo as AlarmInfo)}`)
    if (wantAlarmInfo) {
      this.alarmInfo = wantAlarmInfo as AlarmInfo;
    } else {
      const isFiring = await AlarmStateManager.isFiring();
      if (isFiring) {
        const firingAlarmId = await AlarmStateManager.getAlarmId();
        const alarmFromList = await AlarmManager.getIDAlarmFrom(firingAlarmId.toString() as string);
        if (alarmFromList.length > 0) {
          this.alarmInfo = alarmFromList[0];
        } else {
          LogUtil.error(TAG, `firingAlarmId:${firingAlarmId}. cannot get alarmInfo.`)
        }
      } else {
        LogUtil.error(TAG, `not firing state.`)
      }
    }
    LogUtil.info(TAG, `alarmInfo => ${JSON.stringify(this.alarmInfo)}`)
  }

  async aboutToAppear() {
    LogUtil.info(TAG, 'aboutToAppear');
    this.sendAlarmListening('show')
    if (GlobalContext.getContext().getObject('wallpaperImage')) {
      this.wallpaperImage = GlobalContext.getContext().getObject('wallpaperImage') as image.PixelMap;
    }
    LogUtil.info(TAG, 'wallpaperImage:' + JSON.stringify(this.wallpaperImage));
    this.listeningSnooze();
    await this.getAlarmInfo();
    await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
    this.updateTime();
    this.subscribeTimeChangedEvent();
    AlarmServiceManager.listenSnoozeInput();
    AlarmServiceManager.startAudioWorker();
    audio.getAudioManager().getVolumeManager().on('volumeChange', (volumeEvent: audio.VolumeEvent) => {
      LogUtil.info(TAG, `VolumeType of stream =>${volumeEvent.volumeType}`)
      this.delayAlarm();
    });
  }

  aboutToDisappear() {
    LogUtil.info(TAG, 'aboutToDisappear');
    this.sendAlarmListening('hide')
    this.unSubscribeTimeChangedEvent();
    AlarmServiceManager.cancelSnoozeInput();
    this.notifyAbilityDismiss();
    audio.getAudioManager().getVolumeManager().on('volumeChange', (volumeEvent: audio.VolumeEvent) => {
      LogUtil.info(TAG, ` aboutToDisappear getVolumeManager=>${volumeEvent.volumeType}`)
      return
    });
    emitter.off(EVENT_ID_FULL_SCREEN_ALARM);
  }

  private sendAlarmListening(toggle: string): void {
    emitter.emit({ eventId: EVENT_ID_SEND_ALARM }, { data: { toggle: toggle } })
  }

  private listeningSnooze(): void {
    emitter.on({ eventId: EVENT_ID_FULL_SCREEN_ALARM }, (target) => {
      if (target) {
        this.delayAlarm();
      } else {
        LogUtil.error(TAG, `listeningSnooze: + ${target}`);
        return;
      }
      LogUtil.info(TAG, `listeningSnooze target: + ${target}`);
    });
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

  private async subscribeTimeChangedEvent(): Promise<void> {
    // Create a subscriber and subscribe to time-change event.
    this.timeSubscriber = await CommonEventManager.createSubscriber(TIME_SUBSCRIBE_INFO);
    if (!this.timeSubscriber) {
      return;
    }
    CommonEventManager.subscribe(this.timeSubscriber, () => this.updateTime());
  }

  private unSubscribeTimeChangedEvent() {
    if (this.timeSubscriber) {
      CommonEventManager.unsubscribe(this.timeSubscriber, error => {
        if (error) {
          LogUtil.error(TAG, `Unsubscribe to time-change event failed: ${JSON.stringify(error)}`);
          return;
        }
        LogUtil.info(TAG, 'Unsubscribe to time-change event successfully!');
      });
    }

  }

  private notifyAbilityDismiss(): void {
    LogUtil.info(TAG, 'notifyAbilityDismiss');
    emitter.emit({
      eventId: EVENT_ID_FINISH_ABILITY,
      priority: emitter.EventPriority.IMMEDIATE,
    })
  }

  private async delayAlarm(): Promise<void> {
    LogUtil.info(TAG, 'Delay Alarm');
    if (!this.alarmInfo) {
      LogUtil.info(TAG, `No alarmInfo`)
      return;
    }
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_LOCK_SCREEN_REMIND_LATER)
    const firingAlarmId = await AlarmStateManager.getAlarmId();
    if (JSON.parse(JSON.stringify(this.alarmInfo)).id == firingAlarmId) {
      LogUtil.info(TAG, `delayAlarm=>${firingAlarmId}`);
      await WantAgentUtil.triggerDelayAlarm(this.alarmInfo);
    } else {
      LogUtil.info(TAG, `alarmInfo=>${JSON.stringify(this.alarmInfo)} `, `delayAlarm=>${firingAlarmId}`)
      return
    }
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
  buildLabelAndSnoozeArea() {
    Row() {
      Column() {
        Text(this.alarmInfo?.title ? this.alarmInfo.title : $r('app.string.alarm_clock'))
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
        this.buildSnoozeButton()
      }
      .width('100%')
    }
    .width('100%')
    .flexGrow(FLEX_GROW_DEUCE)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildSnoozeButton() {
    if (typeof this.alarmInfo?.snoozeDuration === 'number') {
      Row() {
        Button($r(
          'app.plural.alarm_alert_snooze_button_text',
          this.alarmInfo?.snoozeDuration || 0,
          this.alarmInfo?.snoozeDuration || 0,
        ), {
          type: ButtonType.Normal
        })
          .fontSize($r('sys.float.Body_L'))
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
          .onClick(() => this.delayAlarm())
      }
    }
  }

  @Builder
  buildSlideButton() {
    Row() {
      Column({ space: SLIDE_BTN_SPACE }) {
        SlideCloseButton({ alarmInfo: this.alarmInfo })
        Text($r('app.string.slide_to_turn_off'))
          .fontSize($r('sys.float.Body_L'))
          .align(Alignment.Bottom)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Regular)
          .fontSize($r('app.float.slide_to_turn_off_font_size'))
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
        this.buildTimeArea();
        this.buildLabelAndSnoozeArea();
        this.buildSlideButton();
      }
      .height('100%')
      .width('100%')
    }
    .visibility(this.isBackImageShown ? Visibility.Visible : Visibility.Hidden)
    .height('100%')
    .width('100%')
  }
}