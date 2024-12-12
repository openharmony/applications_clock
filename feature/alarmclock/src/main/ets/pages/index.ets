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

// import hiSysEvent from '@ohos.hiSysEvent';
// import dataShare from '@ohos.data.dataShare';
import settings from '@ohos.settings';
import resmgr from '@ohos.resourceManager';
import preferencesUtil from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import CommonEventManager from '@ohos.commonEventManager';
import common from '@ohos.app.ability.common';
import i18n from '@ohos.i18n';
import promptAction from '@ohos.promptAction';
import curves from '@ohos.curves';
import deviceInfo from '@ohos.deviceInfo';
import router from '@ohos.router';
import {
  AddButton,
  AlarmInfo,
  AlarmInfoToShow,
  AlarmManager,
  AlarmStateManager,
  BreakPoint,
  ButtonSize,
  Clock,
  CommonGrid,
  EVENT_ID_ALARM_RING,
  EventName,
  EventReportUtil,
  FROM_DATA_STORE,
  GlobalContext,
  LESS_THAN_ONE_MINUTE_FLAG,
  LogUtil,
  NO_ALARM_ENABLED,
  ONE_MINUTE,
  ResourceManager,
  TIMER_Toggle_FRONT_AND_BACKEND,
  TimerManager,
  TimeUtil,
  CommonUtil,
  FIRST_PARAM,
  SECOND_PARAM
} from '@hmos/common';
import { AlarmCardUtil } from '../utils/AlarmCardUtil';
import { AlarmCard, AlarmCardType, ObservedAlarmInfo } from '../components/index';
import { NotificationUtil } from '../utils';
import { AlarmServiceManager } from '../manager';
import { PCAlarmFormPopupBuilder } from '../components/PCBuilder';
import { ManageAlarmClock } from './ManageAlarmClock';
import emitter from '@ohos.events.emitter';


interface ParamType {
  alarmList: ObservedAlarmInfo[],
  selectedAlarmId?: string
}

interface OffsetNum {
  yOffset: number
}

interface visibleType {
  isVisible: boolean
}

const MANAGE_ALARM_CLOCK_PAGE = 'pages/ManageAlarmClock';

// Threshold for long press gesture. The current value is 600 ms.
const LONG_PRESS_DURATION = 500;

const WAKE_DAYS = 4;

export const REPEAT_TAG_ID_LIST_IN_ZH = [
  $r('app.string.customize').id,
  $r('app.string.open_tomorrow').id,
  $r('app.string.will_open').id,
];

export const FLEX_GROW_FILL_FULL = 1;

const CLOCK_DIAL_AREA_OFFSET = 340;
const TAG = 'AlarmClock';
const MAX_HEAD_ANGLE: number = 17;
const BODY_HEAD_CRITICAL_ANGLE: number = 12;
const MAX_BODY_ANGLE: number = 10;
const DELETE_SWIPE_HEAD_WIDTH: number = 56;
const DELETE_SWIPE_BODY_WIDTH: number = 123;
const ANGLE_RADIO: number = 10;
const TIME_SUBSCRIBE_INFO: CommonEventSubscribeInfo = {
  events: [
    CommonEventManager.Support.COMMON_EVENT_TIME_CHANGED,
    CommonEventManager.Support.COMMON_EVENT_TIMEZONE_CHANGED,
    CommonEventManager.Support.COMMON_EVENT_TIME_TICK,
  ],
};
const TRIGGER_TIME_NEVER: number = -1;
const HOUR_OF_DAY: number = 24;
const ONE_DAY: number = 1;
const ZERO_DAY: number = 0;
const ZERO_HOUR: number = 0;
const ALARM_CARD: string = 'ALARM_CARD';
const LIST_ITEM_HEIGHT: number = 60;
const LIST_ITEM_MARGIN: number = 12;
const FOLD_SCREEN_DIAMETER_RATIO = 0.85;
// This type is not exported from @ohos.commonEventManager, so we get it by exported function.
type CommonEventSubscriber = CommonEventManager.CommonEventSubscriber
// type ServiceExtensionContext = common.ServiceExtensionContext;
type CommonEventSubscribeInfo = CommonEventManager.CommonEventSubscribeInfo;


interface ITranslateList {
  x: number,
  y: number,
  z: number
}

interface ICustomMenuItem extends MenuItemOptions {
  key: string;
}


/**
 * Alarm clock home page
 *
 * Used to display the time, list of existing alarms, and pause and resume alarms.
 * Provides entries for adding, modifying, and deleting alarms.
 *
 * @since 2022-07-05
 */
@Component
export struct AlarmClock {
  @Link @Watch('updateAlarmClockList') alarmClockListFromEntry: AlarmInfoToShow[];
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @StorageProp('setOrientaion') getOrientaion: number = 0;
  @StorageProp('ALARM_CLOCK_TAB') ALARM_CLOCK_TAB: Boolean = false;
  @Prop @Watch('isBigViewChangeHandle') isBigView: string = ''
  @State isDateTypeClock: boolean = i18n.System.is24HourClock();
  @Prop isPortraitOrientation: boolean = true; //纵向 true 横向 false
  @State translateList: ITranslateList = { x: 0, y: 0, z: 0 };
  @State alarmClockList: ObservedAlarmInfo[] = [];
  @State refreshAlarmClockInfo: boolean = false;
  @State deviceType: string = deviceInfo.deviceType; // 设备类型
  @Link leftTimeToRingTime: string;
  @State isClockHide: boolean = false;
  @State clockDiameter: number = 0;
  @State headAngle: number = 0;
  @State bodyAngle: number = 0;
  @State swipeScale: number = 1;
  @State isFiring: boolean = false;
  @StorageLink('EditBindSheet') isEditShow: boolean = false;
  @StorageLink('NewBindSheet') isNewShow: boolean = false;
  @StorageLink('ShouldDismiss') isDismiss: boolean = false;
  @StorageLink('TextInputClose') isTextInputClose: boolean = false;
  @StorageLink('isRepeat') isRepeat: boolean = false;
  @State deleteAlarmId: string = '';
  @State editShowItem: ObservedAlarmInfo | undefined = undefined;
  @Prop isAlarmClockVisible: boolean = true;
  @State isPCView: boolean = this.computedIsPCView();
  @State listIndexCache: number = 0;
  @State itemContextMenuData: Array<ICustomMenuItem> = [{ key: 'del', content: $r('app.string.alarm_tips_del') }];
  @StorageLink('pcAlarmFormPopupVisible') pcAlarmFormPopupVisible: boolean = false;
  @State isAlarm: boolean = true;

  private isPCLg() {
    return this.deviceType === '2in1'
  }

  private timeSubscriber?: CommonEventSubscriber;
  // private dataShareHelper?: dataShare.DataShareHelper;
  private scrollerForScroll: Scroller = new Scroller();
  private scrollerForList: Scroller = new Scroller();
  private uri: string = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=' + settings.date.TIME_FORMAT;
  private isReady: boolean = false
  readonly RESTRICT: number = -999;
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  // private toast: string = (GlobalContext.getContext()
  //   .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('show_toast_name');
  private timeOutId: number = -1;

  private async updateAlarmClockList(): Promise<void> {
    LogUtil.info(TAG, 'start to updateAlarmClockList');
    this.alarmClockList = this.alarmClockListFromEntry.map(item => new ObservedAlarmInfo(item));
    if (this.alarmClockList.length === this.alarmClockListFromEntry.length) {
      this.refreshAlarmClockInfo = !this.refreshAlarmClockInfo; // refresh only when modify
    }
    this.isFiring = await AlarmStateManager.isFiring();
    this.AlarmClockVisibleFn();
  }

  private async AlarmClockVisibleFn(): Promise<void> {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, FROM_DATA_STORE);
    let alarm_clock_time_id = await TimerManager.getTriggerTimeID();
    LogUtil.info(TAG, 'alarm_active ' + this.ALARM_CLOCK_TAB);
    let ringTimeInMs: number = await TimeUtil.getNextAlarmTime();
    if (this.ALARM_CLOCK_TAB && ringTimeInMs != TRIGGER_TIME_NEVER) {
      let order = this.getAlarmClockListIndex(String(alarm_clock_time_id))
      // 152为ListiItem高；12为ListItem间距
      let SCROOL_HEIGHT = order * (LIST_ITEM_HEIGHT + LIST_ITEM_MARGIN);
      LogUtil.info(TAG, 'alarm_active Order=' + order + '&& SCROOL_HEIGHT=' + (CLOCK_DIAL_AREA_OFFSET + SCROOL_HEIGHT));
      this.timeOutId = setTimeout(() => {
        this.scrollerForScroll.scrollTo({
          xOffset: 0,
          yOffset: CLOCK_DIAL_AREA_OFFSET + MAX_HEAD_ANGLE + SCROOL_HEIGHT,
          animation: { duration: 100, curve: Curve.Linear }
        })
        clearTimeout(this.timeOutId);
        this.timeOutId = -1;
      }, 50)
    }
  }

  //获取指定id闹钟列表index
  private getAlarmClockListIndex(id: string): number {
    let listIndex = 0;
    this.alarmClockList.map((item, index) => {
      if (item.id == id) {
        listIndex = index;
      }
    })
    return Number(listIndex)
  }

  // 获取时间戳
  private async calculateRingTime(ringTimeInMs: number): Promise<string> {
    const currentDate = new Date();
    const leftTimeInMs = ringTimeInMs - currentDate.getTime();
    const leftTime = new Date(leftTimeInMs);
    const leftMinutes = leftTime.getUTCMinutes();
    const leftHours = leftTime.getUTCHours();
    const leftDays = leftTime.getUTCDate() - ONE_DAY;
    if (leftDays === 0 && leftHours === 0 && leftMinutes < ONE_MINUTE) {
      return LESS_THAN_ONE_MINUTE_FLAG;
    }
    const leftTimeStrParts: string[] = [];
    if (leftDays != 0) {
      // If the number of remaining days is not 0, the description of remaining days needs to be assembled.
      const leftDayStr = await ResourceManager.getPluralStringAsync($r('app.plural.day').id, leftDays);
      leftTimeStrParts.push(leftDayStr);
    }
    if (leftHours != 0) {
      // If the number of remaining hours is not 0, the description of remaining hours needs to be assembled.
      const leftHourStr = await ResourceManager.getPluralStringAsync($r('app.plural.hour').id, leftHours);
      leftTimeStrParts.push(leftHourStr);
    }
    if (leftMinutes != 0) {
      // If the number of remaining minutes is not 0, the description of the remaining minutes needs to be assembled.
      const leftMinuteStr = await ResourceManager.getPluralStringAsync($r('app.plural.minute').id, leftMinutes);
      leftTimeStrParts.push(leftMinuteStr);
    }
    return `${leftTimeStrParts.join(' ')}`;
  }

  private async openAlarmShowToast(alarmId: string): Promise<void> {
    const alarmClockListFromDatabase: AlarmInfo[] = await AlarmManager.getAllAlarms();
    alarmClockListFromDatabase.forEach(((alarmClockInfo, alarmClockIndex) => {
      LogUtil.info(TAG, 'alarmClockInfo:', JSON.stringify(alarmClockInfo));
      if (alarmClockInfo.id === alarmId) {
        this.calculateRingTime(Number(alarmClockInfo.alarmTime)).then((data) => {
          return promptAction.showToast({
            message: data === LESS_THAN_ONE_MINUTE_FLAG
              ? $r('app.string.less_than_one_minute')
              : $r('app.string.ring_in', data), // 显示文本
            duration: 2000, // 显示时长
            bottom: this.RESTRICT // 距离底部的距离
          })
        })
      }
    }))
  }

  /**
   * Update the time since the last ring
   */
  private async refreshLeftTime(isTimeChange: boolean): Promise<void> {
    if (isTimeChange) {
      await AlarmServiceManager.refreshNextAlertTime(isTimeChange);
    }
    this.leftTimeToRingTime = await TimeUtil.getLeftTimeToRingTime(isTimeChange);
    const isFiring = await AlarmStateManager.isFiring();
    LogUtil.info(TAG, 'refreshLeftTime isFiring=' + isFiring)
    if (!isFiring) {
      AlarmCardUtil.notifyAlarmCardTimeUpdate();
    }
    if (this.leftTimeToRingTime === NO_ALARM_ENABLED && isTimeChange) {
      this.refreshAlarmData();
    }
  }

  async aboutToAppear(): Promise<void> {
    LogUtil.info(TAG, 'aboutToAppear len1:' + this.alarmClockListFromEntry.length + ' len2:' + this.alarmClockList.length);
    if (this.alarmClockList.length !== this.alarmClockListFromEntry.length) {
      this.refreshAlarmData();
    }
    await this.subscribeEvents();
    await this.subscribeDataBaseShare();
    await TimeUtil.getWorkDaysNetData();
    this.isReady = true;
    await TimeUtil.getFreeday(); // Obtaining statutory holidays data in the database.
    emitter.on({ eventId: TIMER_Toggle_FRONT_AND_BACKEND }, (eventData) => {
      LogUtil.info(TAG, `TIMER_Toggle_FRONT_AND_BACKEND pageShow=${eventData.data?.pageShow}`)
      if (eventData.data?.pageShow) {
        this.AlarmClockVisibleFn()
      }
    });
  }

  async aboutToDisappear(): Promise<void> {
    this.unSubscribeEvents();
    this.unSubscribeDataBaseShare();
    emitter.off(TIMER_Toggle_FRONT_AND_BACKEND);
  }

  private isBigViewChangeHandle() {
    this.isPCView = this.computedIsPCView();
  }

  private computedIsPCView(): boolean {
    return this.isBigView === BreakPoint.LG;
  }

  /**
   * Subscribe events, used to refresh the page
   */
  private async subscribeEvents(): Promise<void> {
    // Create a subscriber and subscribe to time-change event.
    LogUtil.info(TAG, 'createSubscriber');
    this.timeSubscriber = await CommonEventManager.createSubscriber(TIME_SUBSCRIBE_INFO);
    if (!this.timeSubscriber) {
      return;
    }
    CommonEventManager.subscribe(this.timeSubscriber, (error, data) => {
      if (error) {
        LogUtil.error(TAG, 'time changed error:' + JSON.stringify(error));
      } else {
        if (data && (data.event.indexOf('usual.event.TIME_CHANGED') !== -1 || data.event.indexOf('usual.event.TIMEZONE_CHANGED') !== -1)) {
          this.refreshLeftTime(true);
        } else {
          this.refreshLeftTime(false);
        }
        setTimeout(async () => {
          await this.checkTriggerTime();
        }, 1000);
      }
    });
  }

  async checkTriggerTime(): Promise<void> {
    try {
      let ringTimeInMs = await TimerManager.getTriggerTime();
      let ringTimeId = await TimerManager.getTriggerTimeID();
      const currentTime = new Date().getTime();
      if (ringTimeInMs === TRIGGER_TIME_NEVER || currentTime <= ringTimeInMs) {
        return;
      }
      const isFiring = await AlarmStateManager.isFiring();
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      if (isFiring && firingAlarmId === ringTimeId) {
        return;
      }
      LogUtil.info(TAG, `checkTriggerTime begin ${ringTimeId} ${ringTimeInMs}  ${currentTime}`);
      await AlarmManager.closeNoRepeatAlarmsDB(ringTimeInMs);
      emitter.emit({
        eventId: EVENT_ID_ALARM_RING,
        priority: emitter.EventPriority.IMMEDIATE,
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      let errCode = (err as BusinessError).code;
      LogUtil.error(TAG, `checkTriggerTime error: code: ${errCode}, message: ${message} `);
    }

  }

  /**
   * Subscribe DataBaseShare, used to refresh the page
   */
  private async subscribeDataBaseShare(): Promise<void> {
    LogUtil.info(TAG, 'subscribeDataBaseShare');
    // try {
    //   dataShare.createDataShareHelper((GlobalContext.getContext().getObject('clockContext') as Context), this.uri)
    //     .then((data: dataShare.DataShareHelper) => {
    //       LogUtil.info(TAG, 'createDataShareHelper succeed');
    //       this.dataShareHelper = data;
    //       this.dataShareHelper.on('dataChange', this.uri, () => {
    //         LogUtil.info(TAG, 'refreshAlarmData');
    //         this.isDateTypeClock = !this.isDateTypeClock
    //         this.refreshAlarmData();
    //       });
    //     })
    //     .catch((err: BusinessError) => {
    //       LogUtil.error(TAG, `createDataShareHelper error: code: ${err.code}, message: ${err.message} `);
    //     });
    // } catch (err) {
    //   let message = (err as BusinessError).message;
    //   let errCode = (err as BusinessError).code;
    //   LogUtil.error(TAG, `createDataShareHelper error: code: ${errCode}, message: ${message} `);
    // }
  }

  /**
   * Unsubscribe DataBaseShare
   */
  private unSubscribeDataBaseShare(): void {
    // this.dataShareHelper!.off('dataChange', this.uri, () => {
      LogUtil.info(TAG, 'unSubscribeDataBaseShare');
    // });
  }

  /**
   * Unsubscribe events
   */
  private unSubscribeEvents(): void {
    LogUtil.info(TAG, 'unSubscribeEvents');
    if (!this.timeSubscriber) {
      return;
    }
    try {
      CommonEventManager.unsubscribe(this.timeSubscriber, error => {
        if (error) {
          LogUtil.error(TAG, 'Unsubscribe to time-change event failed because: ', JSON.stringify(error));
        } else {
          LogUtil.info(TAG, 'Unsubscribe to time-change event successfully!');
        }
      });
    } catch (error) {
      LogUtil.error(TAG, 'Unsubscribe to time-change event error');
    }
  }

  async refreshAlarmData(): Promise<void> {
    this.alarmClockListFromEntry = await AlarmManager.getAllAlarmsToShow();
  }

  /**
   * Obtains the displayed string resource from the last ringing time.
   *
   * @return The string resource corresponding to the latest ringing time.
   */
  private getLeftTimesToAlarmTips(): Resource {
    if (this.leftTimeToRingTime === NO_ALARM_ENABLED) {
      return $r('app.string.no_alarms_on');
    }
    return this.leftTimeToRingTime === LESS_THAN_ONE_MINUTE_FLAG
      ? $r('app.string.less_than_one_minute')
      : $r('app.string.ring_in', this.leftTimeToRingTime);
  }

  private onScrollParent(yOffset: number): void {
    if (yOffset === 0 || yOffset > 0 && this.isClockHide || yOffset < 0 && !this.isClockHide) {
      return;
    }
    const offset = this.scrollerForScroll.currentOffset();
    LogUtil.info(TAG, `yOffset=${yOffset}  current=${offset.yOffset}`);
    if (yOffset > 0) {
      this.isClockHide = true;
    } else {
      this.isClockHide = false;
    }
  }

  private onScrollStopParent(): void {
    const offset = this.scrollerForScroll.currentOffset();
    LogUtil.info(TAG, `onScrollStop  current=${offset.yOffset} ${this.isClockHide}`);
    if (this.isClockHide) {
      this.scrollerForScroll.scrollEdge(Edge.End);
    } else {
      this.scrollerForScroll.scrollEdge(Edge.Start);
    }
  }

  private pcRightControlMenuClickHandle = (menuItem: ICustomMenuItem, alarmItem: ObservedAlarmInfo) => {
    if (menuItem.key === 'del') {
      this.deleteAlarmId = alarmItem.id as string;
      this.dealAlarmDelete(alarmItem);
    }
  }

  @Builder
  pcRightControlMenuBuilder(alarmItem: ObservedAlarmInfo) {
    Menu() {
      ForEach(this.itemContextMenuData, (item: ICustomMenuItem) => {
        MenuItem({ content: item.content })
          .onClick(() => this.pcRightControlMenuClickHandle(item, alarmItem))
      }, (item: MenuItemOptions, index: number) => String(index))
    }
    .shadow(ShadowStyle.OUTER_DEFAULT_MD)
  }

  @Builder
  buildClock(): void {
    Row() {
      Clock({
        getOrientaion: this.getOrientaion,
        isPortraitOrientation: this.isPortraitOrientation,
        showBoth: this.isPCView
      })
    }
    .transition(TransitionEffect.opacity(1))
    .width('100%')
    .margin({
      top: this.isPCLg() ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? $r('app.float.clock_shadow_above_space_32') : '10vp'),
      bottom: this.isPCLg() ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? $r('app.float.clock_margin_vertical') : $r('app.float.clock_landscape_no_height')),
    })
    .focusable(false)
  }

  @Builder
  buildNoAlarms(): void {
    Row() {
      Flex({ justifyContent: FlexAlign.Center }) {
        Text($r('app.string.no_alarms'))
          .fontSize($r('sys.float.Body_M'))
          .fontColor(this.isPCView ? $r('sys.color.font_secondary') : $r('sys.color.font_tertiary'))
          .fontWeight(FontWeight.Regular)
          .margin(this.isBigView === BreakPoint.MD ? { top: '99vp' } : {})
      }
    }
    .renderGroup(true)
    .width('100%')
    .flexGrow(FLEX_GROW_FILL_FULL)
    .margin({ bottom: this.isPCView ? $r('app.float.date_info_margin_bottom') : 0 })
    .focusable(false)
  }

  @Builder
  buildLeftTimeTips(): void {
    Flex({ justifyContent: FlexAlign.Center }) {
      Text(this.getLeftTimesToAlarmTips())
        .fontColor(this.isPCView ? $r('sys.color.font_secondary') : $r('sys.color.icon_primary'))
        .fontSize(this.isPCView ? $r('sys.float.Subtitle_S') : $r('app.float.clock_text_size'))
        .lineHeight(this.isPCView ? 0 : $r('app.float.left_time_line_height'))
        .fontWeight(this.isPCView ? FontWeight.Regular : FontWeight.Medium)
        .margin({ top: !this.isPortraitOrientation && this.foldAbleScreen === 1 ? '10vp' : 0 })
    }
    .renderGroup(true)
    .width('100%')
    .padding({
      bottom: this.isPCView ? $r('app.float.date_info_margin_bottom') : $r('app.float.left_time_tips_margin_bottom')
    })
  }

  @Builder
  ManageAlarmClockBuilder(alarmItem: ObservedAlarmInfo | undefined) {
    Stack() {
      if (alarmItem) {
        ManageAlarmClock({
          alarmInfoParam: alarmItem as ObservedAlarmInfo,
        });
      } else {
        ManageAlarmClock({});
      }
    }
    .width('100%')
  }

  private alarmRestart(item: ObservedAlarmInfo, alarmClockInfo: ObservedAlarmInfo,
                       alarmClockIndex: number, enabled?: boolean) {
    this.alarmClockList[alarmClockIndex].enabled = enabled!
    const repeatAlarmShow = TimeUtil.getAlarmTime(alarmClockInfo);
    const newDate = new Date(repeatAlarmShow);
    const repeatAlarmDate = newDate.setDate(newDate.getDate() + 1);
    const repeatAlarmDay = new Date(repeatAlarmDate);
    const todayDate = new Date();
    const tomorrowDate = todayDate.setDate(todayDate.getDate() + 1);
    const tomorrow = new Date(tomorrowDate);
    const tomorrowDay = tomorrow.getDate();
    const tomorrowMonth = tomorrow.getMonth() + 1;
    const day = repeatAlarmDay.getDate();
    let month = repeatAlarmDay.getMonth() + 1;
    if (month === 13) {
      month = 1;
    }
    if (tomorrowDay === day && tomorrowMonth === month) {
      item.reStart = ResourceManager.getStringById($r('app.string.open_tomorrow').id);
    } else {
      item.reStart = ResourceManager.getStringById($r('app.string.will_open').id)
        .replace(FIRST_PARAM, JSON.stringify(month))
        .replace(SECOND_PARAM, JSON.stringify(day));
    }
  }

  private async onRightBtn(item: ObservedAlarmInfo, enabled?: boolean) {
    await ResourceManager.preloadStringResources(REPEAT_TAG_ID_LIST_IN_ZH);
    item.enabled = enabled!;
    this.alarmClockList.forEach((alarmClockInfo, alarmClockIndex) => {
      if (alarmClockInfo.id === item.id) {
        this.alarmClockList[alarmClockIndex].enabled = enabled!
      }
    })
    !enabled && AlarmManager.clearSnoozedData(item, true);
    const alarmTitle = await AlarmManager.getDefaultAlarmTitle(item.id as string, item.hour);
    if (alarmTitle !== '') {
      item.title = alarmTitle;
    }
    LogUtil.info(TAG, 'updateAlarm', JSON.stringify(item))
    await AlarmManager.updateAlarm(item);
    item.enabled && this.openAlarmShowToast(item.id as string);
    this.refreshLeftTime(false);
    const isFiring = await AlarmStateManager.isFiring();

    if (isFiring) {
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      if (firingAlarmId.toString() !== item.id) {
        !enabled && NotificationUtil.cancel(item.id as string);
      }
    } else {
      !enabled && NotificationUtil.cancel(item.id as string);
    }
  }

  @Builder
  buildAlarmListItem(item: ObservedAlarmInfo): void {
    Stack() {
      if (this.isPCView) {
        // 子容器获焦后，父容器不可再获焦，为列表可获焦，改为兄弟组件
        Column() {
        }
        .width($r('app.float.list_item_focus_width'))
        .height($r('app.float.list_item_focus_height'))
        .onClick(() => {
          this.alarmItemClick(item)
        })
      }
      Column() {
        AlarmCard({
          alarmInfo: item,
          alarmInfoList: this.alarmClockList,
          refreshAlarmClockInfo: this.refreshAlarmClockInfo,
          cardType: AlarmCardType.MainPageCard,
          isPCView: this.isPCView,
          onRightBtnChange: async (enabled?: boolean) => {
            this.onRightBtn(item, enabled);
          },
          cancelDoubleCardMargin: this.foldAbleScreen === 1 && this.alarmClockList.length > 3,
          isDateTypeClock: this.isDateTypeClock
        })
      }
      .bindContextMenu(this.pcRightControlMenuBuilder(item), ResponseType.RightClick)
      .onClick(() => {
        this.alarmItemClick(item)
      })
      .bindSheet(this.isEditShow && this.editShowItem &&
        this.editShowItem.id === item.id, this.ManageAlarmClockBuilder(this.editShowItem), {
        height: '94.3%',
        backgroundColor: $r('sys.color.ohos_id_background_secondary'),
        maskColor: $r('sys.color.mask_fourth'),
        showClose: false,
        dragBar: true,
        preferType: SheetType.CENTER,
        onAppear: () => {
          LogUtil.info(TAG, '==== BindSheet onAppear.' + JSON.stringify(this.editShowItem));
        },
        onDisappear: () => {
          this.onDisappear();
        },
        shouldDismiss: () => {
          this.shouldDismiss();
        }
      })
    }
  }

  private onDisappear() {
    this.isEditShow = false;
    AppStorage.setOrCreate('EditBindSheet', false);
    if (this.isTextInputClose == false) {
      this.isTextInputClose = true;
      AppStorage.setOrCreate('TextInputClose', true);
    } else if (this.isTextInputClose == true) {
      this.isTextInputClose = false;
      AppStorage.setOrCreate('TextInputClose', false);
    }
    LogUtil.info(TAG, '==== BindSheet onDisappear.');
  }

  private shouldDismiss() {
    if (this.isDismiss === false) {
      this.isDismiss = true;
      AppStorage.setOrCreate('ShouldDismiss', true);
    } else if (this.isDismiss === true) {
      this.isDismiss = false;
      AppStorage.setOrCreate('ShouldDismiss', false);
    }
  }

  private alarmItemClick(item: ObservedAlarmInfo) {
    LogUtil.info(TAG, '==== edit alarm:', JSON.stringify(item));
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 328, 36)
    }, () => {
      this.isEditShow = false;
      AppStorage.setOrCreate('EditBindSheet', false);
      this.isEditShow = true;
      AppStorage.setOrCreate('EditBindSheet', true);
      this.editShowItem = item;
    })
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.ENTER_ALARM_EDIT_PAGE)
  }

  private async dealAlarmDelete(alarmInfo: ObservedAlarmInfo): Promise<void> {
    LogUtil.info(TAG, 'dealAlarmDelete alarmId: ' + alarmInfo.id);
    let delIndex = -1;
    this.alarmClockList.forEach((item: ObservedAlarmInfo, index: number) => {
      if (item.id === alarmInfo.id) {
        delIndex = index;
      }
    })
    LogUtil.info(TAG, 'dealAlarmDelete alarmId index: ' + delIndex);
    if (delIndex !== -1) {
      this.alarmClockList.splice(delIndex, 1);
    }
    alarmInfo.enabled = false;
    const isFiring = await AlarmStateManager.isFiring();
    const firingAlarmId = await AlarmStateManager.getAlarmId();
    LogUtil.info(TAG, `isFiring: ${isFiring}, firingAlarmId: ${firingAlarmId}, deleteAlarmId: ${alarmInfo.id}`);
    if (isFiring && String(firingAlarmId) === alarmInfo.id) {
      await AlarmServiceManager.stopAlarm(alarmInfo);
      await CommonUtil.terminateAlarmService();
    } else {
      await AlarmManager.clearSnoozedData(alarmInfo, true);
      NotificationUtil.cancel(alarmInfo.id as string);
    }
    let deletedAlarmSet: Set<string> = new Set();
    deletedAlarmSet.add(alarmInfo.id as string);
    await AlarmManager.removeAlarms(deletedAlarmSet);
    this.refreshLeftTime(false);
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.SINGLE_ALARM_SWIPE_LEFT_DEL)
  }

  @Styles
  buttonStyle()
  {
    .borderRadius($r('app.float.swipe_image_height_and_width'))
    .height($r('app.float.swipe_button_height_and_width'))
    .width($r('app.float.swipe_button_height_and_width'))
    .margin($r('app.float.swipe_margin_size'))
  }

  @Builder
  renderSwipeAction(alarmInfo: ObservedAlarmInfo): void {
    Row() {
      Stack() {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Image($r('app.media.ic_delete_grey'))
            .width($r('app.float.swipe_delete_head_width'))
            .rotate({
              x: 0,
              y: 0,
              z: 1,
              centerX: '100%',
              centerY: '100%',
              angle: this.headAngle,
            })
        }
        .width($r('app.float.swipe_button_height_and_width'))
        .height($r('app.float.swipe_button_height_and_width'))
      }
      .buttonStyle()
      .scale({ x: this.swipeScale, y: this.swipeScale })
      .backgroundColor($r('app.color.swipe_delete_button_color'))
      .onClick(() => {
        setTimeout(() => {
          this.deleteAlarmId = alarmInfo.id as string;
          if (this.alarmClockList.length > 3 && this.foldAbleScreen === 1) {
            this.dealAlarmDelete(alarmInfo);
          } else {
            animateTo({
              duration: 350,
              curve: Curve.Friction,
            }, () => {
              this.dealAlarmDelete(alarmInfo);
            })
          }
        }, 150)
      })
    }
    .id('id_deleteAlarm_img')
    .padding(this.foldAbleScreen === 1 && this.alarmClockList.length < 4 ? {
      left: 0,
      top: $r('app.float.swipe_margin_size'),
      right: $r('app.float.swipe_padding_size'),
      bottom: $r('app.float.swipe_margin_size')
    } : $r('app.float.swipe_margin_size'))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      let wid = newValue.width;
      this.headAngle = (Number(wid) - DELETE_SWIPE_HEAD_WIDTH) / DELETE_SWIPE_HEAD_WIDTH * ANGLE_RADIO;
      if (this.headAngle <= 0) {
        this.headAngle = 0;
      }
      if (this.headAngle >= MAX_HEAD_ANGLE) {
        this.headAngle = MAX_HEAD_ANGLE;
      }
      if (this.headAngle > BODY_HEAD_CRITICAL_ANGLE) {
        this.swipeScale = 1.05;
        this.bodyAngle = (Number(wid) - DELETE_SWIPE_BODY_WIDTH) / DELETE_SWIPE_BODY_WIDTH * ANGLE_RADIO;
      } else {
        this.bodyAngle = 0;
        this.swipeScale = 1;
      }
      if (this.bodyAngle > MAX_BODY_ANGLE) {
        this.bodyAngle = MAX_BODY_ANGLE;
        this.swipeScale = 1.05;
      }
      this.bodyAngle = (-1) * this.bodyAngle;
    })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  private swipeAction(item: ObservedAlarmInfo) {
    setTimeout(() => {
      this.deleteAlarmId = item.id as string;
      if (this.alarmClockList.length > 3 && this.foldAbleScreen === 1) {
        this.dealAlarmDelete(item);
      } else {
        animateTo({
          duration: 350,
          curve: Curve.Friction,
        }, () => {
          this.dealAlarmDelete(item);
        })
      }
    }, 350);
  }

  private keyEvent(e: KeyEvent, item: ObservedAlarmInfo) {
    if (e.keyText === 'KEYCODE_TAB' || e.keyText === 'KEYCODE_DPAD_DOWN' || e.keyText === 'KEYCODE_DPAD_UP') {
      const listIndex = this.alarmClockList.findIndex(i => item.id === i.id)
      if (listIndex !== this.listIndexCache) {
        this.listIndexCache = listIndex
        // 38 视口区最后显示一半的列表向上滚动的距离，94.2每条item滚动高度
        this.scrollerForScroll.scrollTo({
          xOffset: 0,
          yOffset: listIndex > 3 ? (listIndex - 4) * 94.2 + 38 : 0,
          animation: { duration: 100, curve: Curve.Linear }
        });
      }
    }
  }

  @Builder
  alarmListItem() {
    ForEach(this.alarmClockList, (item: ObservedAlarmInfo) => {
      ListItem() {
        Row() {
          this.buildAlarmListItem(item);
        }
      }
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY,
          TransitionEffect.scale({ x: 1, y: 1 })
            .animation({ curve: Curve.Friction, duration: 0 })
            .combine(
              TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
            )
        )
      )
      .margin(this.alarmClockList.length === 1 || this.isPCView ? 0 : { bottom: $r('app.float.card_list_margin') })
      .clip(this.isPCLg() ? false : true)
      .zIndex(this.deleteAlarmId === item.id ? 0 : 1)
      .borderRadius($r('sys.float.corner_radius_level10'))
      .swipeAction(
        {
          edgeEffect: SwipeEdgeEffect.None,
          end: {
            builder: (): void => this.renderSwipeAction(item),
            onAction: () => {
              this.swipeAction(item);
            },
            onEnterActionArea: () => {
              LogUtil.info(TAG, 'List Swipe EnterDeleteArea');
            },
            onExitActionArea: () => {
              LogUtil.info(TAG, 'List Swipe ExitDeleteArea');
            }
          },
        }
      )
      .onKeyEvent((e: KeyEvent) => {
        this.keyEvent(e, item);
      })
    }, (item: ObservedAlarmInfo) => JSON.stringify(item))
  }

  @Builder
  alarmListItemPc() {
    ForEach(this.alarmClockList, (item: ObservedAlarmInfo) => {
      ListItem() {
        Row() {
          this.buildAlarmListItem(item);
        }
      }
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY,
          TransitionEffect.scale({ x: 1, y: 1 })
            .animation({ curve: Curve.Friction, duration: 0 })
            .combine(
              TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
            )
        )
      )
      .margin(this.alarmClockList.length === 1 || this.isPCView ? 0 : { bottom: $r('app.float.card_list_margin') })
      .clip(this.isPCLg() ? false : true)
      .zIndex(this.deleteAlarmId === item.id ? 0 : 1)
      .onKeyEvent((e: KeyEvent) => {
        this.keyEvent(e, item);
      })
    }, (item: ObservedAlarmInfo) => JSON.stringify(item))
  }

  @Builder
  listAlarm(): void {
    if (this.isPCView) {
      this.alarmListItemPc()
    } else if (!this.isPCView) {
      this.alarmListItem()
    }
    if (!this.isPCView) {
      ListItem() {
      }
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY,
          TransitionEffect.scale({ x: 1, y: 1 })
            .animation({ curve: Curve.Friction, duration: 0 })
            .combine(
              TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
            )
        )
      )
      .height($r('app.float.empty_alarm_list_item'))
    }
    if (this.alarmClockList.length > 3 && this.foldAbleScreen !== 1 && !this.isPCView) {
      ListItem() {
      }
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY,
          TransitionEffect.scale({ x: 1, y: 1 })
            .animation({ curve: Curve.Friction, duration: 0 })
            .combine(
              TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
            )
        )
      )
    }
  }

  @Builder
  buildAlarmList(): void {
    List({ scroller: this.scrollerForList }) {
      this.listAlarm()
    }
    .renderGroup(true)
    .padding(this.foldAbleScreen === 1 ? {
      left: $r('app.float.flod_padding_left'),
      right: $r('app.float.flod_padding_right')
    } : {})
    .lanes(this.alarmClockList.length > 3 && this.foldAbleScreen === 1 ? 2 : 1, $r('app.float.lans_list_item_10'))
    .margin({
      left: $r('app.float.card_margin_start'),
      right: $r('app.float.card_margin_start')
    })
    .clip(false)
    .edgeEffect(EdgeEffect.Spring)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
  }

  @Builder
  buildAlarmPcList(): void {
    List({ space: 12 }) {
      this.listAlarm()
    }
    .height(this.alarmClockList.length >= 5 ? '100%' : '')
    .padding(this.isPCView ? {
      right: $r('app.float.card_margin_start')
    } : (this.isBigView === BreakPoint.MD ? this.isPortraitOrientation ? {
      left: $r('app.float.flod_padding_left'),
      right: $r('app.float.flod_padding_right')
    } : this.foldAbleScreen === 1 ?
      this.getOrientaion === this.isFoldCross ? {
        left: $r('app.float.flod_padding_left'),
        right: $r('app.float.flod_padding_right')
      } :
        {
          left: $r('app.float.fold_cross_padding'),
          right: $r('app.float.fold_cross_padding'),
        } : {} : {}))
    .margin(this.isPCView ? { left: $r('app.float.card_margin_start'), right: 0 } : {
      left: $r('app.float.card_margin_start'),
      right: $r('app.float.card_margin_start')
    })
    .clip(false)
  }

  @Builder
  buildTipsAndList() {
    if (this.alarmClockList.length === 0) {
      if (this.leftTimeToRingTime) {
        this.buildNoAlarms()
      }
    } else {
      Stack({ alignContent: Alignment.Start }) {
        Flex({ direction: FlexDirection.Column }) {
          if (this.leftTimeToRingTime) {
            CommonGrid() {
              this.buildLeftTimeTips()
            }
          }
        }

        Flex({ direction: FlexDirection.Column }) {
          CommonGrid() {
            this.buildAlarmList()
          }
        }
        .padding({ top: $r('app.float.empty_alarm_list_item') })
      }
      .width('100%')
      .height('97%')
    }
  }

  @Builder
  buildPortrait() { // 纵向
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scrollerForScroll) {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start }) {
          Row() {
            this.buildClock()
          }

          this.buildTipsAndList();
        }
      }
      .scrollBar(BarState.Off)
      .onScroll((_: number, yOffset: number) => this.onScrollParent(yOffset))
      .onScrollStop(() => this.onScrollStopParent())
      .align(Alignment.Top)
      .height('100%')
      .width('100%')

      AddButton({
        alarmFlag: this.isAlarm,
        onButtonClick: () => {
          animateTo({
            curve: curves.interpolatingSpring(0, 1, 328, 36)
          }, () => {
            this.isNewShow = false;
            AppStorage.setOrCreate('NewBindSheet', false);
            this.isNewShow = true;
            AppStorage.setOrCreate('NewBindSheet', true);
          })
        }
      })
        .bindSheet($$this.isNewShow, this.ManageAlarmClockBuilder(undefined), {
          height: '94.3%',
          backgroundColor: $r('sys.color.ohos_id_background_secondary'),
          maskColor: $r('sys.color.mask_fourth'),
          showClose: false,
          preferType: SheetType.CENTER,
          dragBar: true,
          onAppear: () => {
            LogUtil.info(TAG, 'BindSheet onAppear.');
          },
          onDisappear: () => {
            LogUtil.info(TAG, 'BindSheet onDisappear.');
          },
          shouldDismiss: () => {
            if (this.isDismiss == false) {
              this.isDismiss = true;
              AppStorage.setOrCreate('ShouldDismiss', true);
            } else if (this.isDismiss == true) {
              this.isDismiss = false;
              AppStorage.setOrCreate('ShouldDismiss', false);
            }
          }
        })
        .transition(TransitionEffect.opacity(1))
        .visibility(this.isAlarmClockVisible ? Visibility.Visible : Visibility.Hidden)
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  buildLandscape() { // 横向
    Row() {
      Column() {
        this.buildClock()
        if (this.alarmClockList.length === 0) {
          if (this.leftTimeToRingTime) {
            this.buildNoAlarms()
          }
        } else {
          if (this.leftTimeToRingTime) {
            CommonGrid() {
              this.buildLeftTimeTips()
            }
          }
        }
      }
      .width('40%')
      .padding({
        left: 0,
      })

      Rect()
        .fill($r('sys.color.comp_divider'))
        .width('1px')
        .height($r('app.float.line_height'))
        .margin({ left: $r('app.float.rect_margin_left') })
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll(this.scrollerForScroll) {
          this.buildAlarmList()
        }
        .height('100%')
        .edgeEffect(EdgeEffect.Spring)
        .align(this.isPCView ? Alignment.Center : Alignment.Top)

        AddButton({
          alarmFlag: this.isAlarm,
          onButtonClick: () => {
            animateTo({
              curve: curves.interpolatingSpring(0, 1, 328, 36)
            }, () => {
              this.isNewShow = false;
              AppStorage.setOrCreate('NewBindSheet', false);
              this.isNewShow = true;
              AppStorage.setOrCreate('NewBindSheet', true);
            })
          }
        })
          .bindSheet($$this.isNewShow, this.ManageAlarmClockBuilder(undefined), {
            height: '94.3%',
            backgroundColor: $r('sys.color.ohos_id_background_secondary'),
            maskColor: $r('sys.color.mask_fourth'),
            showClose: false,
            dragBar: true,
            preferType: SheetType.CENTER,
            onAppear: () => {
              LogUtil.info(TAG, 'BindSheet onAppear.');
            },
            onDisappear: () => {
              LogUtil.info(TAG, 'BindSheet onDisappear.');
            },
            shouldDismiss: () => {
              if (this.isDismiss == false) {
                this.isDismiss = true;
                AppStorage.setOrCreate('ShouldDismiss', true);
              } else if (this.isDismiss == true) {
                this.isDismiss = false;
                AppStorage.setOrCreate('ShouldDismiss', false);
              }
            }
          })
          .transition(TransitionEffect.opacity(1))
          .visibility(this.isAlarmClockVisible ? Visibility.Visible : Visibility.Hidden)
      }
      .width(this.deviceType === 'tablet' ? ('calc(60% - 19vp)') : '60%')
    }
    .width('100%')

    // .justifyContent(this.isPCView && (this.alarmClockList.length === 0) ? FlexAlign.Center: FlexAlign.Start)
  }

  @Builder
  pcListAndAddBuilder() {
    Flex({ alignItems: ItemAlign.Center, direction: FlexDirection.Row }) {
      if (this.alarmClockList.length) {
        Scroll(this.scrollerForScroll) {
          this.buildAlarmPcList()
        }
        .height('76%')
        .edgeEffect(EdgeEffect.Spring)
        .align(this.isPCView ? Alignment.Center : Alignment.Top)
        .flexBasis(50)
        .flexGrow(10)
      }
      Flex({ alignItems: ItemAlign.Center, direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
        AddButton({
          alarmFlag: this.isAlarm,
          buttonSize: ButtonSize.LARGER,
          onButtonClick: (): void => {
            if (this.isPCView) {
              this.pcAlarmFormPopupVisible = true;
            } else {
              this.isNewShow = true;
              AppStorage.setOrCreate('NewBindSheet', true);
            }
          },
        })
          .transition(TransitionEffect.opacity(1))
          .visibility(this.isAlarmClockVisible ? Visibility.Visible : Visibility.Hidden)
          .bindPopup(this.pcAlarmFormPopupVisible, {
            builder: PCAlarmFormPopupBuilder({
              isPCView: this.isPCView,
              visible: this.pcAlarmFormPopupVisible,
              onConfirm: () => {
                this.pcAlarmFormPopupVisible = false;
              },
              onCancel: () => {
                this.pcAlarmFormPopupVisible = false;
              },
            }),
            placement: Placement.Left,
            popupColor: $r('app.color.component_ultra_thick_panel'),
            enableArrow: true,
            onStateChange: (e) => {
              this.getStateChange(e);
            }
          })
      }
      .flexBasis(50)
      .flexGrow(1)
      .padding({
        left: $r('app.float.pc_padding'),
        right: $r('app.float.pc_padding')
      })
    }
    .renderGroup(true)
    .width(this.isPCView && (this.alarmClockList.length === 0) ? '14%' : '60%')
  }

  getStateChange(e: visibleType): void {
    if (!e.isVisible) {
      this.pcAlarmFormPopupVisible = false;
    }
    if (this.isTextInputClose === false) {
      this.isTextInputClose = true;
      AppStorage.setOrCreate('TextInputClose', true);
    } else if (this.isTextInputClose === true) {
      this.isTextInputClose = false;
      AppStorage.setOrCreate('TextInputClose', false);
    }
  }

  @Builder
  buildPC() {
    Row() {
      Column() {
        this.buildClock()
        if (this.alarmClockList.length === 0) {
          if (this.leftTimeToRingTime) {
            this.buildNoAlarms()
          }
        } else {
          if (this.leftTimeToRingTime) {
            CommonGrid() {
              this.buildLeftTimeTips()
            }
          }
        }
      }
      .width(this.alarmClockList.length === 0 ? '86%' : '40%')
      .padding({
        left: this.alarmClockList.length === 0 ? $r('app.float.tool_bar_width_1') : $r('app.float.tool_bar_width'),
      })

      this.pcListAndAddBuilder();
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.isPCView) {
      this.buildPC()
    } else {
      if (this.isPortraitOrientation || this.foldAbleScreen === 1) {
        this.buildPortrait();
      } else {
        this.buildLandscape();
      }
    }
  }
}
