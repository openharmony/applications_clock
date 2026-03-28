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

import emitter from '@ohos.events.emitter';
import i18n from '@ohos.i18n';
import resmgr from '@ohos.resourceManager';
import deviceInfo from '@ohos.deviceInfo';
import { BusinessError } from '@ohos.base';
import {
  AlarmInfo,
  AlarmInfoProperty,
  AlarmManager,
  AlarmStateManager,
  CommonGrid,
  CommonUtil,
  ConfirmDialog,
  EVENT_ID_CHANGE_ALARM,
  EVENT_ID_DELETE_ALARM,
  EventName,
  EventReportUtil,
  EventResult,
  FIRST_PARAM,
  GlobalContext,
  LogUtil,
  ResourceManager,
  SECOND_PARAM,
  TIME_DESC_STRING_ID_LIST,
  TimeUtil,
  TitleBar,
  WantAgentUtil,
  Card
} from '@hmos/common';
import {
  ArraySlider,
  Form,
  FormDiyCallbackInfo,
  FormField,
  FormValue,
  FormOption,
  InputType,
  ObservedAlarmInfo,
  WeekListField
} from '../../components';
import { NotificationUtil } from '../../utils/NotificationUtil';
import {
  DELETE_BUTTON_WIDTH,
  DFT_RING_DURATION,
  DFT_SNOOZE_DURATION,
  DFT_SNOOZE_INFO,
  DFT_SNOOZE_TIMES,
  RING_DURATION_OPTIONS,
  SNOOZE_DURATION_OPTIONS,
  SNOOZE_TIMES_OPTIONS,
  SnoozeInfo,
  TIME_PICKER_WIDTH,
  HTTP_TIMEOUT_TIMER,
} from './types';
import { FLEX_GROW_FILL_FULL } from '../../components/Form/types';
import connection from '@ohos.net.connection';
import promptAction from '@ohos.promptAction'
import { CACHE_HOLIDAYS_LIST, HolidaysType } from '@hmos/common/src/main/ets/utils/types';
// import hiSysEvent from '@ohos.hiSysEvent';

const TAG = 'ManageAlarmClock';
/**
 *   状态值 ：
 *    4 ： 法定工作日
 *    3 ： 自定义
 *    0 ： 单次
 */
enum StateType {
  WAKE_DAYS = 4, //
  USER_DEFINED = 3, //
  ONES = 0
}


@Extend(Image)
function appBarIconBtn(isPC: boolean) {
  .width($r('app.float.appbar_icon_size'))
  .height($r('app.float.appbar_icon_size'))
  .responseRegion({
    width: $r('app.float.response_region_size'),
    height: $r('app.float.response_region_size'),
  })
}

function getItemBackgroundColor(item: string, active: IRepeatDropMenuActive) {
  if (item !== active.key) {
    return Color.Transparent;
  }
  if (active.status === 'hover') {
    return $r('sys.color.ohos_id_color_hover');
  } else if (active.status === 'press') {
    return $r('sys.color.ohos_id_color_click_effect');
  }
  return Color.Transparent;
}

type TOnConfirmCallback = () => void;
type TOnCancelCallback = () => void;

interface IRepeatDropMenuActive {
  key: string;
  status: string;
}

/**
 * Alarm management page
 *
 * @since 2022-07-18
 */
@Component
export struct ManageAlarmClock {
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @Prop isPCView: boolean = false;
  @State alarmInfo?: AlarmInfoProperty = undefined;
  @State isMilitaryTime: boolean = false
  @State isChanged: boolean = false;
  @State alarmInfoParam?: ObservedAlarmInfo = undefined;
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State repeatType: number = 0;
  @State hoverBackgroundInfo: Resource = $r('sys.color.ohos_id_color_titlebar_sub_bg');
  @State confirmButtonBg: ResourceColor = this.isPCView ? $r('sys.color.ohos_id_color_button_normal') :
  $r('sys.color.ohos_id_color_button_normal');
  @State daysOfWakeType: number = 0;
  @State selectList: string[] = [];
  @State selectIndex: number = 0;
  @State selectVal: ResourceStr = '';
  @StorageLink('EditBindSheet') isEditShow: boolean = false;
  @StorageLink('NewBindSheet') isNewShow: boolean = false;
  @StorageLink('ShouldDismiss') @Watch('Dismiss') isDismiss: boolean = false;
  @State itemBackgroundColor: ResourceColor = $r('sys.color.ohos_id_color_card_bg');
  @State @Watch('updateWeekMapList') weekListMap: string = '{}';
  @State isPcShowMenu: boolean = false;
  @StorageProp('pcAlarmFormPopupVisible') isPcNewAlarmShow: boolean = false;
  @State repeatDropMenuActive: IRepeatDropMenuActive = { key: '', status: '' };
  @State isModelEdit: boolean = true;

  @Styles
  itemBackgroundStyles() {
    .backgroundColor(this.itemBackgroundColor)
    .onHover((isHover) => {
      if (isHover) {
        this.itemBackgroundColor = $r('sys.color.ohos_id_color_hover');
      } else {
        this.itemBackgroundColor = $r('sys.color.ohos_id_color_card_bg');
      }
    })
    .onMouse((event) => {
      if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
        this.itemBackgroundColor = $r('sys.color.ohos_id_color_click_effect');
      } else if (event?.action === MouseAction.Release) {
        this.itemBackgroundColor = $r('sys.color.ohos_id_color_card_bg');
      }
    })
  }

  private isModified: boolean = false;
  private isEditMode: boolean = false;
  // Selected time of the time picker
  @State selectedTime: Date = new Date();
  private editingSnoozeInfo?: SnoozeInfo = DFT_SNOOZE_INFO;
  private daysOfWeekLabels: string[] = [];
  private ringDurationOptions: FormOption[] = [];
  // Form field template for repeat mode
  private repeatModeFields: FormField[] = [];
  // private weekListMap: string = '';
  // Form field template for alarm details, except for repeat mode
  // private alarmDetailFields: FormField[] = [];
  @State alarmDetailFields: FormField[] = [];
  private cancelConfirmDialog?: CustomDialogController = undefined;
  private deleteConfirmDialog?: CustomDialogController = undefined;
  private scrollerForScroll: Scroller = new Scroller();
  private httpOutTimeTimer: number = -1;

  private getBackgroundColor() {
    return this.isPCView ? Color.Transparent : $r('sys.color.ohos_id_color_panel_bg')
  }

  private onConfirmCallback: TOnConfirmCallback = () => {
  };
  private onCancelCallback: TOnCancelCallback = () => {
  };
  readonly RESTRICT: number = -999;
  // private toast: string = (GlobalContext.getContext()
  //   .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('show_toast_name');

  /**
   * handleButtonHoverEvent
   *
   * @param isHover
   */
  private handleImageHoverEvent(isHover: boolean): Resource {
    if (isHover) {
      return $r('app.color.color_hover');
    } else {
      return $r('app.color.color_hover_disabled');
    }
  };

  private updateWeekMapList() {
    LogUtil.info(TAG, `updateWeekMapList = ${this.weekListMap}`)
  }

  private Dismiss() {
    if (this.isModified) {
      this.showCancelConfirmDialog();
    } else {
      this.isNewShow = false;
      this.isEditShow = false;
      AppStorage.setOrCreate('EditBindSheet', false);
      AppStorage.setOrCreate('NewBindSheet', false);
    }
  }

  async aboutToAppear() {
    this.selectList = [(GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('once_alarm'),
      (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('customize'),
      (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('days_of_wake_type')
    ];

    LogUtil.info(TAG, 'aboutToAppear: ManageAlarmClock.');
    let appearList: number[] = [
      $r('app.string.alarm_clock').id,
      $r('app.plural.times').id,
      $r('app.string.text_with_separate').id];
    for (let i = 0; i < TIME_DESC_STRING_ID_LIST.length; ++i) {
      appearList.push(TIME_DESC_STRING_ID_LIST[i])
    }
    await ResourceManager.preloadStringResources(appearList);
    await this.initRingDurationOptions();
    await this.initAlarmInfoProperty();
    this.daysOfWeekLabels = TimeUtil.getDaysOfWeekLabels();
    this.repeatModeFields = this.getRepeatModeFields();
    this.alarmDetailFields = this.getAlarmDetailFields();
    this.isMilitaryTime = i18n.is24HourClock();
    let weekListArr: WeekListField[] = [];
    this.daysOfWeekLabels.map((label: string, index: number) => {
      weekListArr.push({
        label: label,
        value: index,
        selected: this.alarmInfo!.daysOfWeek!.some(day => day === index),
      })
      this.weekListMap = JSON.stringify(weekListArr)
    })
  }

  async aboutToDisappear(): Promise<void> {
    LogUtil.info(TAG, 'aboutToDisappear')
    this.repeatType = 0;
    this.isPcShowMenu = false;
  }

  /**
   * Get the current network status.
   *
   * @return boolean.
   */
  private async getHasNet(): Promise<boolean> {
    try {
      let isHaveNet = await connection.hasDefaultNet();

      if (isHaveNet) {
        let netHandle: connection.NetHandle = await connection.getDefaultNet();
        return netHandle.netId >= 100;
      } else {
        return false;
      }
    } catch (error) {
      LogUtil.error(TAG, ' getHasNet failed.');
      return false;
    }
  }

  /**
   * Legal workday click event.
   *
   * @param Index of legal workday in the menu.
   * @return void.
   */
  private async onClickWorkDay(index: number) {
    let cacheHolidaysList = AppStorage.get<HolidaysType>(CACHE_HOLIDAYS_LIST);
    if (!cacheHolidaysList?.year) { // Not statutory holidays data.
      let isToastShowEnd: boolean = false;
      TimeUtil.getWorkDaysNetData().then((hasNetData: boolean) => {
        clearTimeout(this.httpOutTimeTimer);
        if (hasNetData) {
          this.selectVal = this.selectList[index];
          this.selectIndex = index;
          this.daysOfWakeType = StateType.WAKE_DAYS;
        } else {
          !isToastShowEnd && promptAction.showToast({
            message: "网络服务不可用",
            duration: 2000,
            bottom: this.RESTRICT
          });
        }
      });

      // If request http not response within 1s, show not network dialog.
      clearTimeout(this.httpOutTimeTimer);
      this.httpOutTimeTimer = setTimeout(() => {
        promptAction.showToast({
          message: "网络服务不可用",
          duration: 2000,
          bottom: this.RESTRICT
        });
        isToastShowEnd = true;
        this.httpOutTimeTimer = -1;
      }, HTTP_TIMEOUT_TIMER);
    } else {
      this.selectVal = this.selectList[index];
      this.selectIndex = index;
      this.daysOfWakeType = StateType.WAKE_DAYS;
    }
  }

  private async initRingDurationOptions(): Promise<void> {
    this.ringDurationOptions = [];
    for (const ringDuration of RING_DURATION_OPTIONS) {
      this.ringDurationOptions.push({
        label: await this.getTimeWithUnitMinute(ringDuration),
        value: ringDuration,
      });
    }
  }

  private async initAlarmInfoProperty(): Promise<void> {
    // If the parameter contains the alarm to edit, the mode is Edit.
    this.isEditMode = !!this.alarmInfoParam;
    let alarmInfo: AlarmInfo = {} as AlarmInfo;
    if (this.alarmInfoParam) {
      alarmInfo = this.alarmInfoParam;
      this.daysOfWakeType = this.alarmInfoParam.daysOfWakeType!;
      this.selectIndex = this.daysOfWakeType === StateType.WAKE_DAYS ? 2 :
        this.daysOfWakeType === StateType.USER_DEFINED ? 1 : 0;
    } else {
      alarmInfo = this.getDefaultAlarmToAdd();
    }

    if (this.isEditMode) {
      this.selectedTime.setHours(alarmInfo.hour!);
      this.selectedTime.setMinutes(alarmInfo.minute!);
    }

    this.alarmInfo = {
      id: alarmInfo.id,
      title: alarmInfo.title,
      hour: alarmInfo.hour,
      minute: alarmInfo.minute,
      second: alarmInfo.second,
      daysOfWeek: alarmInfo.daysOfWeek,
      daysOfWakeType: alarmInfo.daysOfWakeType,
      alarmTime: alarmInfo.alarmTime,
      enabled: alarmInfo.enabled,
      ringDuration: alarmInfo.ringDuration,
      snoozeDuration: alarmInfo.snoozeDuration,
      snoozeTimes: alarmInfo.snoozeTimes,
      snoozeCount: alarmInfo.snoozeCount,
      ringDurationDesc: await this.getTimeWithUnitMinute(alarmInfo.ringDuration!),
      snoozeDesc: await this.getSnoozeDesc(alarmInfo.snoozeDuration!, alarmInfo.snoozeTimes!),
    };

    let selectVal = '';
    let selectIndex = 0;
    let daysOfWakeType = StateType.ONES;

    if (alarmInfo.daysOfWakeType === StateType.WAKE_DAYS) { // 法定工作日
      selectVal = this.selectList[2];
      selectIndex = 2;
      daysOfWakeType = StateType.WAKE_DAYS;
    } else if (alarmInfo.daysOfWakeType === StateType.ONES) { // 只响一次
      selectVal = this.selectList[0];
      selectIndex = 0;
      daysOfWakeType = StateType.ONES;
    } else { // 1 2 3 用户自定义
      selectVal = this.selectList[1];
      selectIndex = 1;
      daysOfWakeType = StateType.USER_DEFINED;
    }
    this.selectVal = selectVal;
    this.selectIndex = selectIndex;
    this.daysOfWakeType = daysOfWakeType;
  }

  private getDefaultAlarmToAdd(): AlarmInfo {
    return {
      title: ResourceManager.getStringById($r('app.string.alarm_clock').id),
      hour: this.selectedTime.getHours(),
      minute: this.selectedTime.getMinutes(),
      second: this.selectedTime.getSeconds(),
      ringDuration: DFT_RING_DURATION,
      snoozeDuration: DFT_SNOOZE_DURATION,
      snoozeTimes: DFT_SNOOZE_TIMES,
      daysOfWeek: [],
      daysOfWakeType: this.daysOfWakeType,
      enabled: true,
    };
  }

  private async resetToDefaultData() {
    await this.initAlarmInfoProperty();
    this.selectIndex = 0;
    this.selectedTime = new Date();
    if (this.selectList.length) {
      this.selectVal = this.selectList[this.selectIndex];
    }
    this.alarmDetailFields = this.alarmDetailFields.map<FormField>(item => {
      if (item.property === 'ringDurationDesc') {
        item.options = this.ringDurationOptions.map(option => {
          return {
            label: option.label,
            value: option.value,
            isSelected: this.alarmInfo!.ringDuration === option.value,
          } as FormOption;
        })
      }
      return item
    })
    try {
      const arr: WeekListField[] = JSON.parse(this.weekListMap);
      arr.forEach(item => {
        item.selected = false;
      });
      this.weekListMap = JSON.stringify(arr);

    } catch (error) {
      LogUtil.error(TAG, JSON.stringify(error))
    }
    this.repeatModeFields = this.getRepeatModeFields();
  }

  private async onConfirm(): Promise<void> {
    LogUtil.info(TAG, 'onConfirm Click In ManageAlarmClock');
    if (!this.alarmInfo) {
      return;
    }
    GlobalContext.getContext().setObject('dialogController', undefined);
    if (this.isPCView) {
      this.onConfirmCallback && this.onConfirmCallback();
    } else {
      this.pageInfos.pop();
    }
    const alarmTitle = await AlarmManager.getDefaultAlarmTitle(this.alarmInfo!.id as string,
      this.selectedTime.getHours());
    if (alarmTitle !== '') {
      this.alarmInfo!.title = alarmTitle;
    }
    await AlarmManager.saveDefaultAlarmTitle(this.alarmInfo!.id!, this.alarmInfo!.title!);
    this.handleDaysOfWakeType()
    let alarmInfo: AlarmInfo = this.buildAlarm()
    const clearedAlarmIds = await AlarmManager.clearSnoozedData(alarmInfo, this.isEditMode);
    if (this.isEditMode) {
      alarmInfo.alarmTime = TimeUtil.getAlarmTime(alarmInfo)
      alarmInfo.alarmTimeIntent = TimeUtil.getAlarmTime(alarmInfo)
      await AlarmManager.updateAlarm(alarmInfo);
    } else {
      alarmInfo.alarmTimeIntent = TimeUtil.getAlarmTime(alarmInfo)
      await AlarmManager.addAlarm(alarmInfo);
    }
    const alarmRingTime = await TimeUtil.calculateRingTime(TimeUtil.getAlarmTime(alarmInfo));
    LogUtil.info(TAG, `alarmRingTime=${alarmRingTime}, clearedAlarmIds=${JSON.stringify(clearedAlarmIds)}`)
    const isFiring = await AlarmStateManager.isFiring();
    const firingAlarmId = await AlarmStateManager.getAlarmId();
    LogUtil.info(TAG, `isFiring=>${JSON.stringify(isFiring)}, firingAlarmId=>${JSON.stringify(firingAlarmId)}`);
    clearedAlarmIds.forEach(alarmId => {
      if (!isFiring || Number(alarmId) !== firingAlarmId) { //编辑起闹闹钟，不清除横幅提示框和实况胶囊
        NotificationUtil.cancel(alarmId);
      }
    });
    emitter.emit({
      eventId: EVENT_ID_CHANGE_ALARM,
      priority: emitter.EventPriority.IMMEDIATE,
    }, {
      data: { KEY_ALARM_RING_TIME: alarmRingTime }
    });
    this.isPCView && this.resetToDefaultData();
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_SAVE_SETTING)
  }

  private handleDaysOfWakeType() {
    if (this.daysOfWakeType === StateType.ONES && this.alarmInfo!.daysOfWeek.length > 0) {
      this.alarmInfo!.daysOfWeek = [];
    }
    if (this.daysOfWakeType === StateType.USER_DEFINED && this.alarmInfo!.daysOfWeek.length === 0) {
      this.selectVal = this.selectList[0];
      this.selectIndex = 0;
      this.daysOfWakeType = StateType.ONES;
    }
  }
  private buildAlarm() {
    const alarmInfo: AlarmInfo = {
      id: this.alarmInfo!.id,
      title: this.alarmInfo!.title,
      daysOfWeek: this.alarmInfo!.daysOfWeek,
      daysOfWakeType: this.daysOfWakeType,
      alarmTime: this.alarmInfo!.alarmTime,
      ringDuration: this.alarmInfo!.ringDuration,
      snoozeDuration: this.alarmInfo!.snoozeDuration,
      snoozeTimes: this.alarmInfo!.snoozeTimes,
      snoozeCount: this.alarmInfo!.snoozeCount,
      hour: this.selectedTime.getHours(),
      minute: this.selectedTime.getMinutes(),
      second: this.selectedTime.getSeconds(),
      enabled: true,
      alarmTimeIntent: this.alarmInfo!.alarmTime,
    };
    LogUtil.info(TAG, `ManageAlarmClock=>${JSON.stringify(alarmInfo)}}`);
    return alarmInfo
  }

  private showDeleteConfirmDialog(): void {
    if (!this.deleteConfirmDialog) {
      let customControllerOptions: CustomDialogControllerOptions = CommonUtil.getCommonDialogConfig();
      this.deleteConfirmDialog = new CustomDialogController({
        builder: ConfirmDialog({
          confirmMessage: $r('app.string.delete_alarm_confirm'),
          cancel: () => {
          },
          confirm: () => {
            // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_EDIT_ALARM_DEL_CONFIRM)
            this.dealDeleteAction();
            this.isEditShow = false;
            AppStorage.setOrCreate('EditBindSheet', false);
          },
          cancelText: $r('app.string.cancel'),
          confirmText: $r('app.string.confirm_delete'),
          hasWarning: true,
        }),
        autoCancel: customControllerOptions.autoCancel,
        alignment: this.foldAbleScreen === 1 ? DialogAlignment.Center : customControllerOptions.alignment,
        customStyle: customControllerOptions.customStyle,
      });
    }
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_EDIT_ALARM_DEL)
    GlobalContext.getContext().setObject('dialogController', this.deleteConfirmDialog);
    this.deleteConfirmDialog.open();
  }

  private async dealDeleteAction(): Promise<void> {
    // If you want to delete an alarm that is alerting, you need to stop the alarm.
    await AlarmManager.removeAlarm(this.alarmInfo!);
    NotificationUtil.cancel(this.alarmInfo!.id!);
    const isFiring = await AlarmStateManager.isFiring();
    const alarmId = await AlarmStateManager.getAlarmId();
    LogUtil.info(TAG, `delete alarm id: ${alarmId}, isFiring${isFiring}`);
    if (isFiring && alarmId.toString() === this.alarmInfo!.id) {
      await WantAgentUtil.triggerCloseAlarm(this.alarmInfo!);
    }
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_EDIT_ALARM_DEL_CONFIRM)
    emitter.emit({
      eventId: EVENT_ID_DELETE_ALARM,
      priority: emitter.EventPriority.IMMEDIATE,
    });
    this.pageInfos.pop();
  }

  private showCancelConfirmDialog(): void {
    if (!this.cancelConfirmDialog) {
      let customControllerOptions: CustomDialogControllerOptions = CommonUtil.getCommonDialogConfig();
      this.cancelConfirmDialog = new CustomDialogController({
        builder: ConfirmDialog({
          confirmMessage: $r('app.string.save_changes_confirm'),
          cancel: () => {
            this.isNewShow = false;
            this.isEditShow = false;
            AppStorage.setOrCreate('EditBindSheet', false);
            AppStorage.setOrCreate('NewBindSheet', false);
            GlobalContext.getContext().setObject('dialogController', undefined);
            if (this.isPCView) {
              this.resetToDefaultData();
              this.onCancelCallback && this.onCancelCallback();
            } else {
              this.pageInfos.pop()
            }
          },
          confirm: () => {
            this.onConfirm();
            this.isNewShow = false;
            this.isEditShow = false;
            AppStorage.setOrCreate('EditBindSheet', false);
            AppStorage.setOrCreate('NewBindSheet', false);
          },
          cancelText: $r('app.string.quit'),
          confirmText: $r('app.string.keep'),
        }),
        autoCancel: customControllerOptions.autoCancel,
        alignment: this.foldAbleScreen === 1 ? DialogAlignment.Center : customControllerOptions.alignment,
        customStyle: customControllerOptions.customStyle,
      });
    }
    GlobalContext.getContext().setObject('dialogController', this.cancelConfirmDialog);
    this.cancelConfirmDialog.open();
  }

  private async getTimeWithUnitMinute(minute: number): Promise<string> {
    return await ResourceManager.getPluralStringAsync($r('app.plural.minute').id, minute);
  }

  private async getSnoozeDesc(duration: number, times: number): Promise<string> {
    const durationWithUnit = await this.getTimeWithUnitMinute(duration);
    const snoozeTimes = await ResourceManager.getPluralStringAsync($r('app.plural.times').id, times);
    return ResourceManager.getStringById($r('app.string.text_with_separate').id)
      .replace(FIRST_PARAM, durationWithUnit)
      .replace(SECOND_PARAM, snoozeTimes);
  }

  private getRepeatModeFields(): FormField[] {
    return [
      {
        label: $r('app.string.repeat'),
        property: 'daysOfWeekDesc',
        inputType: InputType.CHECK_BOX,
        options: this.daysOfWeekLabels.map((label: string, dayNumber: number): FormOption => {
          return {
            label,
            value: dayNumber,
            isSelected: this.alarmInfo!.daysOfWeek!.some(day => day === dayNumber),
          }
        }),
        onChange: (daysOfWeek: FormValue) => {
          this.alarmInfo!.daysOfWeek = daysOfWeek as number[];
          const tempAlarmInfo = this.alarmInfo;
          this.alarmInfo = undefined;
          this.alarmInfo = tempAlarmInfo;
          this.repeatModeFields = this.getRepeatModeFields();
          this.isChanged = !this.isChanged;
        },
        onOpenDialog: () => this.isModified = true
      },
    ];
  }

  private getAlarmDetailFields(): FormField[] {
    let formDiyCallbackInfo: FormDiyCallbackInfo = this.getCallbacksForSnoozeField();
    return [
      {
        label: $r('app.string.label'),
        property: 'title',
        inputType: InputType.TEXT,
        onChange: async (value: FormValue) => {
          this.alarmInfo!.title = value as string;
          const tempAlarmInfo = this.alarmInfo;
          this.alarmInfo = undefined;
          this.alarmInfo = tempAlarmInfo;
          await AlarmManager.saveDefaultAlarmTitle(this.alarmInfo!.id!, this.alarmInfo!.title!);
          this.isChanged = !this.isChanged;
        },
        onOpenDialog: () => this.isModified = true
      },
      {
        label: $r('app.string.ring_duration'),
        property: 'ringDurationDesc',
        inputType: InputType.RADIO,
        options: this.ringDurationOptions.map(option => {
          return {
            label: option.label,
            value: option.value,
            isSelected: this.alarmInfo!.ringDuration === option.value,
          } as FormOption;
        }),
        onChange: async (value: FormValue) => {
          this.alarmInfo!.ringDuration = value as number;
          this.alarmInfo!.ringDurationDesc = await this.getTimeWithUnitMinute(value as number);
          const tempAlarmInfo = this.alarmInfo;
          this.alarmInfo = undefined;
          this.alarmInfo = tempAlarmInfo;
          this.alarmDetailFields = this.getAlarmDetailFields();
          this.isChanged = !this.isChanged;
        },
        onOpenDialog: () => this.isModified = true
      },
      {
        label: $r('app.string.snooze_duration'),
        property: 'snoozeDesc',
        inputType: InputType.DIY,
        onOpenDialog: formDiyCallbackInfo.onOpenDialog,
        onCloseDialog: formDiyCallbackInfo.onCloseDialog,
        onConfirmDialog: formDiyCallbackInfo.onConfirmDialog,
      }
    ];
  }

  private getCallbacksForSnoozeField(): FormDiyCallbackInfo {
    return {
      onOpenDialog: () => {
        this.isModified = true;
        this.editingSnoozeInfo = {
          duration: this.alarmInfo!.snoozeDuration!,
          times: this.alarmInfo!.snoozeTimes!,
        };
      },
      onCloseDialog: () => {
        this.editingSnoozeInfo = undefined;
      },
      onConfirmDialog: async () => {

        let duration = this.editingSnoozeInfo!.duration;
        let times = this.editingSnoozeInfo!.times;

        if (!this.alarmInfo) {
          return;
        }

        this.alarmInfo = {
          id: this.alarmInfo.id,
          title: this.alarmInfo.title,
          hour: this.alarmInfo.hour,
          minute: this.alarmInfo.minute,
          second: this.alarmInfo.second,
          daysOfWeek: this.alarmInfo.daysOfWeek,
          alarmTime: this.alarmInfo.alarmTime,
          enabled: this.alarmInfo.enabled,
          ringDuration: this.alarmInfo.ringDuration,
          ringDurationDesc: this.alarmInfo.ringDurationDesc,
          snoozeCount: this.alarmInfo.snoozeCount,
          snoozeDesc: await this.getSnoozeDesc(duration, times),
          snoozeDuration: duration,
          snoozeTimes: times,
        };
        this.isChanged = !this.isChanged;
      },
    }
  }

  private isPcModelPage(): boolean {
    return deviceInfo.deviceType === '2in1';
  }

  // 编辑打点事件
  private changeTime(): void {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.EDIT_ALARM_CLOCK_TIME)
  }

  @Builder
  renderDivider(index: number | undefined) {
    if (index) {
      // Render divider above items except for the first item with index zero
      Divider().color($r('sys.color.comp_divider'))
    }
  }

  //设置闹钟的单次或者工作日
  @Builder
  MyMenu() {
    Column() {
      ForEach(this.selectList, (item: string, index: number) => {
        this.renderDivider(index)
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(item)
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_primary'))
            .focusable(true)
            .tabIndex(1)
          Image(this.selectIndex === index ? $r('app.media.ic_public_ok') : '')
            .height($r('app.float.menu_item_icon'))
            .width($r('app.float.menu_item_icon'))
            .fillColor($r('sys.color.icon_primary'))
        }
        .height($r('app.float.list_item_height'))
        .padding({
          left: $r('app.float.card_margin_start'),
          right: $r('app.float.card_margin_start'),
          top: $r('app.float.list_item_padding'),
          bottom: $r('app.float.list_item_padding')
        })
        .margin({
          left: $r('app.float.card_item_margin_horizontal__8'),
          right: $r('app.float.card_item_margin_horizontal__8'),
        })
        .onClick(() => {
          this.isModified = true
          if (index === 2) { //法定工作日
            this.alarmInfo!.daysOfWeek = [];
            this.onClickWorkDay(index)
          } else if (index === 1) { //自定义
            if (this.repeatType !== index) {
              this.selectVal = this.selectList[index];
            }
            this.selectIndex = index;
            this.daysOfWakeType = StateType.USER_DEFINED;
          } else { //单次
            this.selectVal = this.selectList[index];
            this.selectIndex = index;
            this.daysOfWakeType = StateType.ONES;
          }
          this.repeatType = index;
        })
        .borderRadius($r('sys.float.corner_radius_level10'))
        .backgroundColor(getItemBackgroundColor(item, this.repeatDropMenuActive))
        .onHover((isHover: boolean) => {
          const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: '' };
          if (isHover) {
            repeatDropMenuActive.status = 'hover';
          } else {
            repeatDropMenuActive.status = '';
          }
          this.repeatDropMenuActive = repeatDropMenuActive;
        })
        .onMouse((event: MouseEvent) => {
          if ((event.action === MouseAction.Press) && (event.button === MouseButton.Left)) {
            const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: 'press' };
            this.repeatDropMenuActive = repeatDropMenuActive;
          } else if (event.action === MouseAction.Release) {
            const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: 'hover' };
            this.repeatDropMenuActive = repeatDropMenuActive;
          }
        })
      })
    }
    .width(this.isPcModelPage() ? $r('app.float.pc_new_alarm_menu_width') : '44%')
    .padding({ left: $r('app.float.card_margin_start'), right: $r('app.float.card_margin_start') })
  }

  // PC create alarm repeating options menu.
  @Builder
  pcNewAlarmMenu() {
    Column() {
      ForEach(this.selectList, (item: string, index: number) => {
        this.renderDivider(index)
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(item)
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_primary'))
            .focusable(true)
            .tabIndex(1)
          Image(this.selectIndex === index ? $r('app.media.ic_public_ok') : '')
            .height($r('app.float.menu_item_icon'))
            .width($r('app.float.menu_item_icon'))
            .fillColor($r('sys.color.icon_primary'))
        }
        .borderRadius($r('sys.float.corner_radius_level10'))
        .height($r('app.float.list_item_height'))
        .padding({
          left: $r('app.float.card_margin_start'),
          right: $r('app.float.card_margin_start'),
          top: $r('app.float.list_item_padding'),
          bottom: $r('app.float.list_item_padding')
        })
        .margin({
          left: $r('app.float.card_item_margin_horizontal__8'),
          right: $r('app.float.card_item_margin_horizontal__8'),
        })
        .backgroundColor(getItemBackgroundColor(item, this.repeatDropMenuActive))
        .onHover((isHover: boolean) => {
          const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: '' };
          if (isHover) {
            repeatDropMenuActive.status = 'hover';
          } else {
            repeatDropMenuActive.status = '';
          }
          this.repeatDropMenuActive = repeatDropMenuActive;
        })
        .onMouse((event: MouseEvent) => {
          if ((event.action === MouseAction.Press) && (event.button === MouseButton.Left)) {
            const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: 'press' };
            this.repeatDropMenuActive = repeatDropMenuActive;
          } else if (event.action === MouseAction.Release) {
            const repeatDropMenuActive: IRepeatDropMenuActive = { key: item, status: 'hover' };
            this.repeatDropMenuActive = repeatDropMenuActive;
          }
        })
        .onClick(() => {
          if (index === 2) { // Statutory working days.
            this.alarmInfo!.daysOfWeek = [];
            this.onClickWorkDay(index)
          } else if (index === 1) { // Customization.
            if (this.repeatType !== index) {
              this.selectVal = this.selectList[index];
            }
            this.selectIndex = index;
            this.daysOfWakeType = StateType.USER_DEFINED;
          } else { // Single time.
            this.alarmInfo!.daysOfWeek = [];
            this.selectVal = this.selectList[index];
            this.selectIndex = index;
            this.daysOfWakeType = StateType.ONES;
          }
          this.isPcShowMenu = false;
          this.repeatType = index;
        })
      })
    }
    .width($r('app.float.pc_new_alarm_menu_width'))
    .padding({
      top: $r('app.float.card_padding_vertical'),
      bottom: $r('app.float.card_padding_vertical'),
      left: $r('app.float.card_margin_start'),
      right: $r('app.float.card_margin_start'),
    })
    .position({
      x: $r('app.float.pc_new_alarm_menu_position_x'), y: $r('app.float.pc_new_alarm_menu_position_y')
    })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .transition(
      TransitionEffect.OPACITY.animation({ curve: Curve.Linear, duration: 0.5 })
        .combine(TransitionEffect.translate({ x: 0, y: -56 })).animation({ curve: Curve.Linear, duration: 0.5 })
    )
    .shadow(ShadowStyle.OUTER_DEFAULT_MD)
  }

  @Builder
  repeatOptionText() {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text($r('app.string.repeat'))
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ right: $r('app.float.card_tag_margin_end') })
        .fontWeight(FontWeight.Medium)
      Column() {
        Row() {
          Text(this.selectVal)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .textAlign(TextAlign.End)
        }
      }
      .alignItems(HorizontalAlign.End)
      .flexGrow(FLEX_GROW_FILL_FULL)
    }
    .padding({
      left: $r('app.float.card_inner_padding_horizontal'),
      right: $r('app.float.card_inner_padding_horizontal'),
    })
    .constraintSize({ minHeight: $r('app.float.set_alarm_card_height') })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .itemBackgroundStyles()
  }

  // Create alarm repeating options.
  @Builder
  repeatOption($$: boolean) {
    if ($$) {
      Row() {
        this.repeatOptionText();
        if (this.isPcShowMenu) {
          this.pcNewAlarmMenu();
        }
      }
      .onClick(() => this.isPcShowMenu = !this.isPcShowMenu);
    } else {
      Row() {
        this.repeatOptionText();
      }
      .bindMenu(this.MyMenu, {
        placement: Placement.BottomRight,
      });
    }
  }

  @Builder
  buildAlarmInfoForms() {
    Column() {
      Column() {
        Row() {
          this.repeatOption(this.isPcNewAlarmShow);
        }
        .zIndex(1)

        if (this.selectIndex === 1) {
          Column() {
            Divider().color($r('sys.color.comp_divider'))
            Row({ space: 8.5 }) {
              Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                ForEach(JSON.parse(this.weekListMap), (item: WeekListField, index: number) => {
                  Button({ type: ButtonType.Circle, stateEffect: true }) {
                    Text(item.label.split('')[1])
                      .textAlign(TextAlign.Center)
                      .fontSize(13)
                      .fontWeight(item.selected ? FontWeight.Medium : FontWeight.Regular)
                      .fontColor(item.selected ? $r('sys.color.font_on_primary') : $r('sys.color.font_secondary'))
                      .focusable(true)
                  }
                  .backgroundColor(item.selected ? $r('sys.color.ohos_id_icon_color_active') : $r('sys.color.ohos_id_background_secondary'))
                  .width('40vp')
                  .height('40vp')
                  .onClick(() => {
                    this.isModified = true
                    let _weekList: WeekListField[] = JSON.parse(this.weekListMap);
                    _weekList[index].selected = !item.selected
                    this.weekListMap = JSON.stringify(_weekList)
                    let daysNumArr: number[] = [];
                    _weekList.map((item: WeekListField, index: number) => {
                      if (item.selected) {
                        daysNumArr.push(item.value)
                      }
                    })
                    this.alarmInfo!.daysOfWeek = daysNumArr
                  })
                })
              }
            }
            .width('100%')
            .height(60)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({
            left: $r('app.float.card_inner_padding_horizontal'),
            right: $r('app.float.card_inner_padding_horizontal'),
          })
        }
      }
      .zIndex(9)
      .padding({
        top: $r('app.float.card_padding_horizontal'),
        right: $r('app.float.card_padding_horizontal'),
        bottom: $r('app.float.card_padding_horizontal'),
        left: $r('app.float.card_padding_horizontal'),
      })
      .margin({
        bottom: $r('app.float.card_margin_end')
      })
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor($r('sys.color.comp_background_list_card'))

      Row() {
        // Form of alarm details
        Form({
          fields: this.alarmDetailFields,
          properties: this.alarmInfo,
          buildDiyInput: (): void => this.buildSnoozeInput(),
        })
      }
    }
  }

  @Builder
  buildDivider() {
    Column() {
      Divider().color($r('sys.color.comp_divider'))
    }
    // Make the divider fill the width of the dialog
    .margin({
      top: $r('app.float.snooze_setting_margin_vertical_max'),
      bottom: $r('app.float.snooze_setting_margin_vertical_max'),
      left: $r('app.float.divider_margin_horizontal'),
      right: $r('app.float.divider_margin_horizontal'),
    })
    .offset({ x: $r('app.float.divider_margin_offset_left') })
  }

  @Builder
  buildSnoozeInput() {
    if (this.editingSnoozeInfo) {
      Column() {
        ArraySlider({
          label: $r('app.string.snooze_duration_time'),
          value: this.editingSnoozeInfo.duration,
          scales: SNOOZE_DURATION_OPTIONS,
          onChange: (value: number) => {
            try {
              if (this.editingSnoozeInfo) {
                this.editingSnoozeInfo.duration = value;
              }
            } catch (error) {
              LogUtil.error(TAG, 'set ArraySlider1 failed: ', (error as BusinessError).message);
            }
          },
        })
        this.buildDivider()
        ArraySlider({
          label: $r('app.string.number_of_snoozes'),
          value: this.editingSnoozeInfo.times,
          scales: SNOOZE_TIMES_OPTIONS,
          onChange: (value: number) => {
            try {
              if (this.editingSnoozeInfo) {
                this.editingSnoozeInfo.times = value;
              }
            } catch (error) {
              LogUtil.error(TAG, 'set ArraySlider2 failed: ', (error as BusinessError).message);
            }
          },
        })
      }
      .padding({
        left: $r('app.float.snooze_setting_margin_vertical_min'),
        right: $r('app.float.snooze_setting_margin_vertical_min')
      })
    }
  }

  @Builder
  buildPageTitle() {
    Flex({ alignItems: ItemAlign.Start }) {
      Row() {
        TitleBar({
          modelEditFlag: this.isModelEdit,
          title: (GlobalContext.getContext()
            .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync(this.isEditMode ? 'edit_alarm' : 'add_alarm'),
          titleFontWeight: this.isPCView ? FontWeight.Bold : FontWeight.Medium,
          isPCView: this.isPCView,
          onIconClick: () => {
            if (this.isEditMode) {
              // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_SAVE_SETTING)
            } else {
              // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_SAVE_SETTING)
            }
            if (this.isModified) {
              this.showCancelConfirmDialog();
            } else if (this.isPCView) {
              this.onCancelCallback && this.onCancelCallback();
            } else {
              GlobalContext.getContext().setObject('dialogController', undefined);
              this.pageInfos.pop();
              this.isNewShow = false;
              this.isEditShow = false;
              AppStorage.setOrCreate('EditBindSheet', false);
              AppStorage.setOrCreate('NewBindSheet', false);
            }
          },
          iconResource: $r('app.media.ic_cancel'),
          isHoverInfo: true,
          isFocusAble: true,
          isModelBg: true,
          operationArea: (): void => this.buildPageOperations(),
        })
      }
      .backgroundColor(this.getBackgroundColor())
    }
    .hitTestBehavior(HitTestMode.Transparent)
    .width('100%')
    .height('100%')
    .padding({
      left: this.isPCView ? $r('sys.float.padding_level8') : 0,
      right: this.isPCView ? $r('sys.float.padding_level8') : 0
    })
  }

  @Builder
  buildPageOperations() {
    Row() {
      Image($r('app.media.ic_confirm'))
        .fillColor($r('sys.color.icon_primary'))
        .draggable(false)
        .width($r('app.float.button_icon_size'))
        .height($r('app.float.button_icon_size'))
        .appBarIconBtn(this.isPCView)
        .focusable(true)
        .id('id_confirmed_img')
    }
    .onClick(() => {
      this.onConfirm();
      this.isNewShow = false;
      this.isEditShow = false;
      AppStorage.setOrCreate('EditBindSheet', false);
      AppStorage.setOrCreate('NewBindSheet', false);
    })
    .justifyContent(FlexAlign.Center)
    .width($r('app.float.new_button_size'))
    .height($r('app.float.new_button_size'))
    .borderRadius($r('app.float.new_button_size'))
    .backgroundColor(this.confirmButtonBg)
    .onMouse((event) => {
      if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
        this.confirmButtonBg = $r('sys.color.interactive_click');
      } else if (event?.action === MouseAction.Release) {
        this.confirmButtonBg = $r('sys.color.interactive_hover');
      }
    })
  }

  @Builder
  buildTimePicker() {
    Column() {
      TimePicker({ selected: this.selectedTime })
        .selectedTextStyle({
          color: $r('sys.color.ohos_id_icon_color_active')
        })
        .useMilitaryTime(this.isMilitaryTime)
        .onChange((date) => {
          this.changeTime();
          this.isModified = true;
          this.selectedTime.setHours(date.hour!);
          this.selectedTime.setMinutes(date.minute!);
        })
        .width(this.isPCView ? '100%' : $r('app.float.timer_picker_width'))
        .height($r('app.float.timer_picker_height'))
    }
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level10'))
    .width(TIME_PICKER_WIDTH)
    .padding({
      top: $r('app.float.timer_pick_padding_vertical'),
      bottom: $r('app.float.timer_pick_padding_vertical'),
    })
    .margin({
      top: $r('app.float.card_margin_top'),
    })
  }

  @Builder
  buildDeleteButton() {
    if (this.isEditMode) {
      Flex({ justifyContent: FlexAlign.Center }) {
        Button($r('app.string.delete_alarm'))
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.warning'))
          .width(DELETE_BUTTON_WIDTH)
          .onClick(() => this.showDeleteConfirmDialog())
          .id('id_deleteAlarm_button')
      }
      .hitTestBehavior(HitTestMode.Transparent)
      .width('100%')
      .padding({
        bottom: $r('app.float.delete_button_margin_bottom'),
        top: $r('sys.float.padding_level8')
      })
      .backgroundColor(this.getBackgroundColor())
    }
  }

  @Builder
  pcContentBuilder() {
    Column() {
      Scroll(this.scrollerForScroll) {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center
        }) {
          Card({
            cancelMargin: true,
            bgColor: $r('sys.color.comp_background_list_card')
          }) {
            this.buildTimePicker();
          }

          Row() {
            this.buildAlarmInfoForms();
          }
        }
        .padding({
          left: $r('sys.float.padding_level8'),
          right: $r('sys.float.padding_level8')
        })
      }
      .height('100%')
    }
    .padding({
      top: $r('app.float.header_footer_height'),
      bottom: this.isEditMode ? $r('app.float.edit_alarm_content_padding_bottom') : 0
    })
    .height('100%')
    .backgroundColor(this.getBackgroundColor())
  }

  @Builder
  buildContent() {
    Scroll(this.scrollerForScroll) {
      Column() {
        Row() {
          CommonGrid() {
            this.buildTimePicker();
          }
        }
        .margin({
          bottom: $r('app.float.card_margin_end')
        })

        if (this.isChanged) {
          CommonGrid() {
            this.buildAlarmInfoForms();
          }
        } else {
          CommonGrid() {
            this.buildAlarmInfoForms();
          }
        }
      }
    }
    .align(Alignment.Top)
    .width('100%')
    .height('100%')
    .margin({
      top: this.isPcModelPage() ? $r('app.float.header_footer_height') : '',
      bottom: this.isPcModelPage() ? $r('app.float.edit_alarm_content_padding_bottom') : ''
    })
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      top: this.isPcModelPage() ? '' : $r('app.float.header_footer_height'),
      bottom: this.isPcModelPage() ? '' : (this.isEditMode ? $r('app.float.edit_alarm_content_padding_bottom') : 0)
    })
    .backgroundColor(this.getBackgroundColor())
  }

  build() {
    NavDestination() {
      if (this.alarmInfo) {
        Stack({ alignContent: Alignment.Bottom }) {
          if (this.isPCView) {
            this.pcContentBuilder();
          } else {
            this.buildContent();
          }
          this.buildDeleteButton();
          this.buildPageTitle();
        }
        .expandSafeArea([SafeAreaType.KEYBOARD])
        .onClick(() => {
          if (this.isPCView && this.isPcShowMenu) {
            this.isPcShowMenu = false;
          }
        })
      }
    }
    .renderGroup(true)
    .onBackPressed(() => {
      if (this.isModified) {
        this.showCancelConfirmDialog();
        return true;
      } else {
        return false;
      }
    })
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
    .height((this.isPCView && !this.isEditMode) ? '560vp' : '100%')
    .constraintSize({
      maxHeight: (this.isPCView && !this.isEditMode) ? '90%' : '100%'
    })
  }
}

