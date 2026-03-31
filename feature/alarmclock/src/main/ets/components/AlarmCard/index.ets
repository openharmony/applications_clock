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
  Card,
  CardSize,
  CommonGrid,
  LogUtil,
  GlobalContext,
  ResourceManager,
  EventName,
  EventReportUtil
} from '@hmos/common';
import { ObservedAlarmInfo, AlarmCardType } from './types';
import resmgr from '@ohos.resourceManager';
import i18n from '@ohos.i18n';
// import hiSysEvent from '@ohos.hiSysEvent';

const TAG = 'AlarmCard';

/**
 * 双框架迁移数据 dayOfWeekType 值
 * 状态值 ：
 * 4: 法定工作日
 * 3: 用户自定义
 * 2: 每天
 * 1: 周一到周五
 * 0: 单次
 *
 * 单框架逻辑 处理合并 1、2、3 都为用户自定义 3
 */
enum StateType {
  WAKE_DAYS = 4, // 法定工作日
  USER_DEFINED = 3, // 自定义响铃
  ONES = 0 // 只响一次
}


/**
 * Font in the first line of the card
 * Time and period labels (morning, afternoon, etc.)
 * Rendering in two styles
 *
 * @param isTag Indicates whether the label is a time segment.
 */
@Extend(Text)
function formatTimeText(isTag: boolean) {
  .fontSize(isTag ? $r('sys.float.Body_L') : $r('sys.float.Title_M'))
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.font_primary'))
}

@Extend(Text)
function formatTimeTextPrivate(isTag: boolean) {
  .fontSize(isTag ? $r('sys.float.Subtitle_M') : $r('sys.float.Title_M'))
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.font_primary'))
}

/**
 * Font in the second line of the card
 */
@Extend(Text)
function secondaryText() {
  .fontSize($r('sys.float.Body_M'))
  .fontColor($r('sys.color.font_secondary'))
  .fontWeight(FontWeight.Regular)
}

/**
 * Card Font Transparency
 */

/**
 * Alarm clock card
 *
 * @author XiaHan
 * @since 2022-07-16
 */
@Component
export struct AlarmCard {
  @ObjectLink @Watch('refreshAlarmCard') alarmInfo: ObservedAlarmInfo;
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @Prop alarmInfoList: ObservedAlarmInfo[] = [];
  @Prop @Watch('refreshAlarmCardInfo') refreshAlarmClockInfo: boolean = false;
  @Prop cancelDoubleCardMargin: boolean = false;
  @Prop isPCView: boolean = false;
  @State refreshTrigger: boolean = false;
  @Prop isDateTypeClock: boolean = i18n.System.is24HourClock();
  @State isRepeatMenu: boolean = true;
  @StorageLink('isRepeat') isRepeat: boolean = false;
  public cardType?: AlarmCardType;
  // Type of the alarm card. Whether the card is used in main page or delete-alarm-clock page.
  public onRightBtnChange?: (isOn?: boolean) => void; // Callback of the click event of the button on the right.
  public isChecked?: boolean; // Whether the card is checked. Valid only in the card of the delete-alarm-clock page.
  public selectList = [(GlobalContext.getContext()
    .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('once_alarm'),
    (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('customize'),
    (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('days_of_wake_type')
  ];

  private refreshAlarmCardInfo() {
    LogUtil.info(TAG, 'alarmInfoList:' + JSON.stringify(this.alarmInfoList));
    for (let i = 0; i < this.alarmInfoList.length - 1; i++) {
      if (this.alarmInfoList[i].id == this.alarmInfo.id) {
        this.alarmInfo.title = this.alarmInfoList[i].title!;
        this.alarmInfo.time = this.alarmInfoList[i].time!;
        this.alarmInfo.tag = this.alarmInfoList[i].tag;
        this.alarmInfo.isTagLeft = this.alarmInfoList[i].isTagLeft;
        this.alarmInfo.daysOfWeekDesc = this.alarmInfoList[i].daysOfWeekDesc!;
        this.alarmInfo.daysOfWakeType = this.alarmInfoList[i].daysOfWakeType!;
        this.alarmInfo.hour = this.alarmInfoList[i].hour!;
        this.alarmInfo.minute = this.alarmInfoList[i].minute!;
        if (this.alarmInfoList[i].daysOfWeek.toString() !== this.alarmInfo.daysOfWeek.toString()) {
          this.alarmInfo.daysOfWeek = this.alarmInfoList[i].daysOfWeek!;
        }
        // alarmTime no need to update,because it will be recalculate
        this.alarmInfo.ringDuration = this.alarmInfoList[i].ringDuration!;
        this.alarmInfo.snoozeDuration = this.alarmInfoList[i].snoozeDuration!;
        this.alarmInfo.snoozeTimes = this.alarmInfoList[i].snoozeTimes!;
        this.alarmInfo.snoozeCount = this.alarmInfoList[i].snoozeCount;
        this.alarmInfo.enabled = this.alarmInfoList[i].enabled!;
        this.alarmInfo.reStart = this.alarmInfoList[i].reStart;
      }
    }
  }

  private refreshAlarmCard() {
    this.refreshTrigger = !this.refreshTrigger; // To trigger the refresh of the component and its subcomponents.
  }

  private getAlarm(alarmInfo?: ObservedAlarmInfo) {
    LogUtil.info(TAG, `daysOfWakeType, ${alarmInfo?.daysOfWakeType}`)
    if (alarmInfo?.daysOfWakeType === StateType.WAKE_DAYS) { // 法定工作日
      return `${alarmInfo?.title}，${this.selectList[2]}`
    } else if (alarmInfo?.daysOfWakeType === StateType.ONES) { // 只响一次
      return `${alarmInfo?.title}，${this.selectList[0]}`
    } else { // 1 2 3 用户自定义
      return `${alarmInfo?.title}，${alarmInfo?.daysOfWeekDesc}`
    }
  }

  /**
   * Do not modify the folding method
   */
  private getAlarmPrivate(alarmInfo?: ObservedAlarmInfo) {
    if (alarmInfo?.daysOfWakeType === StateType.WAKE_DAYS) { // 法定工作日
      return `${this.selectList[2]}`;
    } else if (alarmInfo?.daysOfWakeType === StateType.ONES) { // 只响一次
      return `${this.selectList[0]}`;
    } else { // 1 2 3 用户自定义
      return `${alarmInfo?.daysOfWeekDesc}`;
    }
  }

  @Builder
  buildAlarmBasicInfoPrivate() {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
      Text(this.alarmInfo.tag)
        .formatTimeTextPrivate(this.alarmInfo.isTagLeft as boolean)
        .fontSize($r('sys.float.Subtitle_M'))
        .margin({
          top: $r('app.float.fold_first_top'),
          right: $r('app.float.fold_first_right')
        })
      Text(this.alarmInfo.time)
        .fontSize($r('sys.float.Title_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin(this.isDateTypeClock ? { left: $r('app.float.fold_cancel_right') } : {})
    }
    .margin({ bottom: $r('app.float.fold_first_bottom') })

    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Text(this.alarmInfo.title)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_secondary'))
    }
    .margin({ bottom: $r('app.float.fold_second_bottom') })

    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Text(this.getAlarmPrivate(this.alarmInfo))
        .fontSize($r('sys.float.Subtitle_S'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_secondary'))
    }
  }

  /**
   * Basic information on the left of the alarm card
   */
  @Builder
  buildAlarmBasicInfo() {
    Column() {
      Column().height($r('app.float.card_content_padding_height'))
      if (this.foldAbleScreen === 1 && this.cancelDoubleCardMargin) {
        this.buildAlarmBasicInfoPrivate()
      } else {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
          Text(this.alarmInfo.isTagLeft ? this.alarmInfo.tag : this.alarmInfo.time)
            .margin({ right: $r('app.float.card_tag_margin_end') })
            .formatTimeText(this.alarmInfo.isTagLeft as boolean)
          Text(this.alarmInfo.isTagLeft ? this.alarmInfo.time : this.alarmInfo.tag)
            .formatTimeText(!this.alarmInfo.isTagLeft)
            .focusable(true)
        }
        .margin({ bottom: $r('app.float.card_title_line_margin') })

        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          if (this.alarmInfo.reStart === undefined || this.alarmInfo.reStart === '') {
            Text(this.getAlarm(this.alarmInfo))
              .secondaryText()
          } else {
            Text(this.getAlarm(this.alarmInfo) + this.alarmInfo.reStart)
              .secondaryText()
          }
        }
      }
    }
    .padding({
      bottom: $r('app.float.card_inner_padding_horizontal'),
    })
  }

  /**
   * Button on the right of the alarm card
   */
  @Builder
  buildRightButton() {
    Row() {
      Toggle({ type: ToggleType.Switch, isOn: this.alarmInfo.enabled })
        .onChange(async (isOn: boolean) => {

          LogUtil.info(TAG, 'AlarmCard onChange id:' + this.alarmInfo.id + ' isOn:' + isOn + ' item.enable:' + this.alarmInfo.enabled);
          if (isOn !== this.alarmInfo.enabled) {
            this.onRightBtnChange!(isOn)
          }
          let switchFlag: string = isOn ? 'on' : 'off';
          // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_SWITCH, 0, switchFlag)
        })
        .hoverEffect(HoverEffect.None)
        .id('id_switch_toggle')
        .selectedColor($r('sys.color.comp_background_emphasize'))
        .width($r('app.float.switch_width'))
        .onHover((isHover: boolean, event: HoverEvent) => {
          if (event && event.stopPropagation) {
            event.stopPropagation();
          }
        })
        .onMouse((event: MouseEvent) => {
          if (event && event.stopPropagation) {
            event.stopPropagation();
          }
        })
    }
    .bindMenu(this.repeatMenu, {
      placement: Placement.BottomRight,
    })
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  repeatMenu() {
    if (this.cardType === AlarmCardType.MainPageCard && this.isRepeatMenu === true) {
      Column() {
        Text($r('app.string.close_only_once'))
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .focusable(true)
          .tabIndex(1)
          .padding({
            left: $r('app.float.card_margin_start'),
            right: $r('app.float.card_margin_start'),
            top: $r('app.float.card_margin_start'),
            bottom: $r('app.float.card_margin_start')
          })
          .onClick(() => {
            this.isRepeat = false;
            AppStorage.setOrCreate('isRepeat', false);
            this.onRightBtnChange!(false);
          })
        Text($r('app.string.close_repeating_alarm'))
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .focusable(true)
          .tabIndex(1)
          .padding({
            left: $r('app.float.card_margin_start'),
            right: $r('app.float.card_margin_start'),
            top: $r('app.float.card_margin_start'),
            bottom: $r('app.float.card_margin_start')
          })
          .onClick(() => {
            this.isRepeat = true;
            AppStorage.setOrCreate('isRepeat', true);
            this.onRightBtnChange!(false);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width($r('app.float.repeat_menu_width'))
    }
  }

  @Builder
  buildContent() {
    Column() {
      Card({
        openHoverStatus: this.isPCView,
        openPressStatus: this.isPCView,
        cancelDoubleCardMargin: this.cancelDoubleCardMargin,
        restrictAlarmCardMargin: true,
        focusRemoveLRMargin: this.isPCView && true,
        cardSize: this.isPCView ? CardSize.LARGER : CardSize.NORMAL
      }) {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
            this.buildAlarmBasicInfo()
          }
          .constraintSize({
            minHeight: this.cancelDoubleCardMargin ? $r('app.float.card_double_height') : $r('app.float.card_content_height')
          })

          this.buildRightButton()
        }
        .constraintSize({
          minHeight: this.cancelDoubleCardMargin ? $r('app.float.card_double_height') : $r('app.float.card_content_height')
        })
      }
    }
  }

  build() {
    Column() {
      Column().backgroundColor(this.refreshTrigger ? $r('app.color.transparent') : $r('app.color.color_black'))
      Column() {
        this.buildContent()
      }
    }
  }
}
