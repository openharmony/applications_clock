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

// import emitter from '@ohos.events.emitter';
// import router from '@ohos.router';
// import i18n from '@ohos.i18n';
// import promptAction from '@ohos.promptAction'
// import resmgr from '@ohos.resourceManager';
// import display from '@ohos.display';
// import { Callback, BusinessError } from '@ohos.base';
import deviceInfo from '@ohos.deviceInfo'
import commonEventManager from '@ohos.commonEventManager';
import {
  ResourceManager,
  AlarmManager,
  AlarmInfoToShow,
  TimeUtil,
  TIME_DESC_STRING_ID_LIST,
  LogUtil,
  EVENT_ID_ALARM_RING,
  EVENT_ID_CHANGE_ALARM,
  EVENT_ID_DELETE_ALARM,
  EVENT_ID_WINDOW_SHADOW,
  EVENT_ID_SWITCH_PAGE,
  PROMPT_TIME,
  LESS_THAN_ONE_MINUTE_FLAG,
  TitleBar,
  FIRST_PARAM,
  BreakpointManager,
  BreakPoint,
  EventReportUtil,
  EventName,
  EVENT_ID_CHANGE_WORLD_CLOCK,
  PageStateManager,
  GlobalContext,
  AlarmInfo,
  AlarmStateManager,
  TimerManager,
  CommonUtil,
  SoundPool,
  EVENT_ID_WORLDCLOCK_FORPC,
  TIMER_Toggle_FRONT_AND_BACKEND,
} from '@hmos/common';
// import hiSysEvent from '@ohos.hiSysEvent';
import {
  AlarmClock,
  ManageAlarmClock,
  MANAGE_NEW_ALARM,
  MANAGE_EDIT_ALARM,
  ObservedAlarmInfo,
  DELETE_ALARM_CLOCK,
  AlarmCardUtil
} from '@hmos/alarmclock';
import {
  PRESET_CITY_BEIJING,
  PRESET_CITY_LONDON,
  PRESET_CITY_PARIS
} from '@hmos/common/src/main/ets/utils/types'
import {
  WorldClock,
  WorldClockInfo,
  WorldClockManager,
  WorldClockUtil,
  MANAGE_NEW_WORLD_CLOCK,
  MANAGE_EDIT_WORLD_CLOCK,
  MANAGE_EDIT_WORLD_CLOCK_PC,
  AddCity,
  EditCities,
  EditCitiesForPC
} from '@hmos/worldclock';
import device, { DeviceResponse } from '@system.device'
import { Stopwatch } from '@hmos/stopwatch';
import { Timer } from '@hmos/timer';
import mediaquery from '@ohos.mediaquery';
import Window from '@ohos.window';

const TAG = 'ClockEntry';
const MAX_CITY_NUM = 24;
const DEFAULT_SORT_ORDER = 9999;
const SMALL_SCREEN_CONTENT_SPAN = 12;
const SMALL_SCREEN_CONTENT_OFFSET = 0;
const BIG_SCREEN_CONTENT_SPAN = 10;
const BIG_SCREEN_CONTENT_OFFSET = 2;
const TABLE_PAD = 2560;
const TIME_OUT_MILLIS = 600;

enum MenuIndex {
  ALARM = 0,
  WORLD_CLOCK = 1,
  STOPWATCH = 2,
  TIMER = 3
};

interface MenuItem {
  icon: Resource,
  iconActivated: Resource,
  label: Resource,
  index: number,
  defaultBgColor: ResourceColor,
  hoverBgColor: ResourceColor,
  pressBgColor: ResourceColor,
};

const MENU_CONFIG: MenuItem[] = [
  {
    icon: $r('app.media.ic_alarm'),
    iconActivated: $r('app.media.ic_alarm_activated'),
    label: $r('app.string.alarm_clock'),
    index: MenuIndex.ALARM,
    defaultBgColor: Color.Transparent,
    hoverBgColor: $r('sys.color.ohos_id_color_hover'),
    pressBgColor: $r('sys.color.ohos_id_color_click_effect')
  },
  {
    icon: $r('app.media.ic_world_clock'),
    iconActivated: $r('app.media.ic_world_clock_activated'),
    label: $r('app.string.world_clock'),
    index: MenuIndex.WORLD_CLOCK,
    defaultBgColor: Color.Transparent,
    hoverBgColor: $r('sys.color.ohos_id_color_hover'),
    pressBgColor: $r('sys.color.ohos_id_color_click_effect')
  },
  {
    icon: $r('app.media.ic_stopwatch'),
    iconActivated: $r('app.media.ic_stopwatch_activated'),
    label: $r('app.string.stopwatch'),
    index: MenuIndex.STOPWATCH,
    defaultBgColor: Color.Transparent,
    hoverBgColor: $r('sys.color.ohos_id_color_hover'),
    pressBgColor: $r('sys.color.ohos_id_color_click_effect')
  },
  {
    icon: $r('app.media.ic_timer'),
    iconActivated: $r('app.media.ic_timer_activated'),
    label: $r('app.string.timer'),
    index: MenuIndex.TIMER,
    defaultBgColor: Color.Transparent,
    hoverBgColor: $r('sys.color.ohos_id_color_hover'),
    pressBgColor: $r('sys.color.ohos_id_color_click_effect')
  }
];
type CommonEventSubscriber = commonEventManager.CommonEventSubscriber;
type CommonEventSubscribeInfo = commonEventManager.CommonEventSubscribeInfo;
const SCREEN_LOCK_INFO: CommonEventSubscribeInfo = {
  events: [
    commonEventManager.Support.COMMON_EVENT_SCREEN_OFF,
  ],
};

interface ITabBarBackgroundEvent {
  onHover: (isHover: boolean, event: HoverEvent) => void;
  onMouse: (event: MouseEvent) => void;
}

interface ITabBarActionOptions {
  index: MenuIndex | undefined;
  status: string | undefined;
}

function computedTabBarBackground(options: MenuItem, activeOptions: ITabBarActionOptions): ResourceColor {
  if (options.index === activeOptions.index) {
    if (activeOptions.status === 'hover') {
      return options.hoverBgColor;
    } else if (activeOptions.status === 'press') {
      return options.pressBgColor;
    }
  }
  return Color.Transparent
}

@Extend(Column)
function tabBarBackground(options: MenuItem, events: ITabBarBackgroundEvent, activeOptions: ITabBarActionOptions) {
  .backgroundColor(computedTabBarBackground(options, activeOptions))
  .onHover(events.onHover)
  .onMouse(events.onMouse)
}


/**
 * 手机产品的时钟入口页面
 *
 * @since 2022-07-19
 */
@Entry
@Component
@Preview
struct Index {
  @StorageProp('currentAbleScreen') @Watch('listenFoldScreen') foldAbleScreen: number = 0;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = '';
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  @StorageProp('setOrientaion') getOrientaion: number = 0;
  @State currentIndex: number = -1; // 当前中的工具栏菜单下标
  @Provide('currentIndex') currentIndexProvider: number = -1;
  @State currentIndexCache: number = -1;
  @State alarmClockList: AlarmInfoToShow[] = []; // 闹钟列表
  @State leftTimeToRingTime: string = ''; // 到下次响铃的间隔时间
  @StorageLink('count') count: number = 0;
  @State isClockHide: boolean = false;
  @State worldClockList: WorldClockInfo[] = [];
  @State @Watch('changeNavbarStatus') isPortraitOrientation: boolean = true;
  @State isPortrait: boolean = true
  @StorageProp('isTabChange') @Watch('tabChangeProcess') isTabChange: boolean = false;
  @State isForeground: boolean = false;
  @StorageLink('EditBindSheet') isEditShow: boolean = false;
  @StorageLink('NewBindSheet') isNewShow: boolean = false;
  @State isPageHide: boolean = true;
  @State isScreenLock: boolean = false;
  @State isScreenEntry: boolean = false
  @State currentActiveTab: ITabBarActionOptions = { index: undefined, status: undefined };
  @State isStopInit: boolean = false;
  @State isTimerInit: boolean = false;
  @State isAlarmInit: boolean = false;
  @State isWorldClockInit: boolean = false;
  @State isAlarmShown: boolean = false;
  @State isWorldClockShown: boolean = false;
  @State isWorldClockVisible: boolean = false;
  @State isAlarmClockVisible: boolean = true;
  @State isStopWatchVisible: boolean = true;
  @State isTimerVisible: boolean = true;
  private cityList: Set<string> = new Set();
  private alarmRingTime: string = ''; // Next ringing time of a new or edited alarm
  private tabController: TabsController = new TabsController();
  private orientationListener: mediaquery.MediaQueryListener | undefined = undefined;
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  private isTablePad: string = 'tablet'
  private commonEventSubscriberAsLock: CommonEventSubscriber = {} as CommonEventSubscriber;
  private deviceType: string = deviceInfo.deviceType;

  private async subscribeCommentAsLockEvent(): Promise<void> {
    this.commonEventSubscriberAsLock = await commonEventManager.createSubscriber(SCREEN_LOCK_INFO);
    if (!this.commonEventSubscriberAsLock) {
      return;
    }
    commonEventManager.subscribe(this.commonEventSubscriberAsLock, async () => {
      this.isScreenLock = true
      // SoundPool.releaseAll();

    });
  }

  private listenFoldScreen() {
    // this.getScreen()
  }

  private unSubscribeCommentAsLockEvent(): void {
    // commonEventManager.unsubscribe(this.commonEventSubscriberAsLock, error => {
    //   if (error) {
    //     LogUtil.error(TAG, `Unsubscribe to common event failed because: ${JSON.stringify(error)}`);
    //     return;
    //   }
    //   LogUtil.info(TAG, 'Unsubscribe to Lock event successfully!');
    // });
  }

  private isPCLg() {
    return this.deviceType === '2in1'
  }

  async tabChangeProcess(): Promise<void> {
    // if (GlobalContext.getContext().getObject('dialogController')) {
    //   LogUtil.info(TAG, 'tabChangeProcess  dialogController close');
    //   (GlobalContext.getContext().getObject('dialogController') as CustomDialogController).close()
    // }
    // GlobalContext.getContext().setObject('textInput', undefined);
    //
    // if (this.pageInfos.size() > 0) {
    //   LogUtil.info(TAG, 'tabChangeProcess  pageInfos' + JSON.stringify(this.pageInfos));
    //   this.pageInfos.pop();
    // } else {
    //   this.isEditShow = false;
    //   this.isNewShow = false;
    //   AppStorage.setOrCreate('EditShowItem', false);
    //   AppStorage.setOrCreate('NewShowItem', false);
    //   const routerState = router.getState();
    //   LogUtil.info(TAG, 'tabChangeProcess  routerState:' + JSON.stringify(routerState));
    //   if (routerState && routerState.name !== 'index') {
    //     router.back();
    //   }
    // }
    // await this.initContent();
  }

  async aboutToAppear(): Promise<void> {
    // LogUtil.info(TAG, 'about to appear');
    // if (this.deviceType === this.isTablePad) {
    //   this.isPortraitOrientation = false;
    // }
    // LogUtil.info(TAG, 'about to appear1');
    //
    // await this.initContent();
    // LogUtil.info(TAG, 'about to appear2');
    //
    // ResourceManager.preloadStringResources(TIME_DESC_STRING_ID_LIST);
    // LogUtil.info(TAG, 'about to appear3');
    // if (this.currentIndex === MenuIndex.ALARM) {
    //   await this.refreshAlarmData();
    // } else {
    //   this.refreshAlarmData();
    // }
    // if (this.currentIndex === MenuIndex.WORLD_CLOCK) {
    //   await this.refreshWorldClockData();
    // } else {
    //   this.refreshWorldClockData();
    // }
    // LogUtil.info(TAG, 'about to appear4');
    //
    // // await SoundPool.create('aboutToAppear');
    // // SoundPool.loadResource(0, this.currentIndex);
    // LogUtil.info(TAG, 'about to appear5');
    //
    // // let lastWindow = await Window.getLastWindow(GlobalContext.getContext().getObject('clockContext') as Context);
    // LogUtil.info(TAG, 'about to appear5.1');
    //
    // if (this.deviceType === this.isTablePad) {
    //   LogUtil.info(TAG, 'about to appear5.2');
    //
    //   // device.getInfo({
    //   //   success: (ret: DeviceResponse) => {
    //   //     lastWindow.setPreferredOrientation(Window.Orientation.AUTO_ROTATION_RESTRICTED);
    //   //     if (ret.windowWidth === TABLE_PAD) {
    //   //       this.isPortraitOrientation = false;
    //   //     } else {
    //   //       this.isPortraitOrientation = true;
    //   //     }
    //   //   }
    //   // })
    // } else {
    //   LogUtil.info(TAG, 'about to appear5.3');
    //
    //   // lastWindow.setPreferredOrientation(Window.Orientation.PORTRAIT);
    // }
    // LogUtil.info(TAG, 'about to appear6');
    //
    // this.getScreen()
    // this.getOrientationOnce()
    // this.getOrientation(true)
    // LogUtil.info(TAG, 'about to appear7');
    //
    // this.orientationListener = mediaquery.matchMediaSync('(orientation: landscape)');
    // this.orientationListener.on('change', (result) => {
    //   emitter.emit({
    //     eventId: EVENT_ID_WINDOW_SHADOW,
    //     priority: emitter.EventPriority.IMMEDIATE,
    //   }, {
    //     data: {
    //       isPortraitOrientation: result.matches ? true : false,
    //     }
    //   })
    //   LogUtil.info(TAG, 'Orientation change, result: ' + result + result.matches)
    //   if (result.matches) {
    //     this.isPortraitOrientation = false;
    //     LogUtil.info(TAG, 'Screen orientation changed to landscape');
    //   } else {
    //     this.isPortraitOrientation = true;
    //     LogUtil.info(TAG, 'Screen orientation changed to portrait');
    //   }
    // })
    // LogUtil.info(TAG, 'about to appear8');
    //
    // this.subscribeCommentAsLockEvent();
    // await this.getDefaultCity();
    // this.subscribeEvents();
    // BreakpointManager.register();
    // LogUtil.info(TAG, 'about to appear9');
    //
    // setTimeout(() => {
    //   if (!this.isAlarmInit || !this.isWorldClockInit || !this.isStopInit || this.isTimerInit) {
    //     this.isAlarmInit = true;
    //     this.isWorldClockInit = true;
    //     this.isStopInit = true;
    //     this.isTimerInit = true;
    //   }
    // }, TIME_OUT_MILLIS);
    // LogUtil.info(TAG, 'about to appear10');

  }

  private async getDefaultCity() {
    // let worldClockList = await WorldClockManager.getAllWorldClock();
    // const result = await AlarmManager.getFirstEnterApp(worldClockList?.length);
    // if (result) {
    //   await this.initPresetCity(PRESET_CITY_BEIJING);
    //   await this.initPresetCity(PRESET_CITY_LONDON);
    //   await this.initPresetCity(PRESET_CITY_PARIS);
    // }
  }

  async aboutToDisappear(): Promise<void> {
    // this.unSubscribeCommentAsLockEvent();
    // this.unSubscribeEvents();
    // BreakpointManager.unregister();
  }

  private getScreen() {
    // LogUtil.info(TAG, 'Get screen start');
    // let callback: Callback<display.FoldStatus> = (data: display.FoldStatus) => {
    //   AppStorage.SetOrCreate<number>('currentAbleScreen', data === 3 ? 1 : data);
    // };
    // try {
    //   const getfoldAbleScreen = display.getFoldStatus();
    //   AppStorage.SetOrCreate<number>('currentAbleScreen', getfoldAbleScreen === 3 ? 1 : getfoldAbleScreen);
    //   display.on('foldStatusChange', callback);
    //   LogUtil.info(TAG, 'get screen success' + JSON.stringify(getfoldAbleScreen));
    // } catch (exception) {
    //   LogUtil.error('get screen result' + JSON.stringify(exception));
    // }
  }

  // reslove  Orientation problem
  private getOrientationOnce() {
    // LogUtil.info(TAG, 'Get orientation once start');
    // display.getAllDisplay((err: BusinessError, data: Array<display.Display>) => {
    //   const errCode: number = err.code;
    //   if (errCode) {
    //     LogUtil.error(TAG, 'Failed to obtain all the display objects. Code: ' + JSON.stringify(err));
    //     return;
    //   }
    //   if (this.deviceType === this.isTablePad) {
    //     LogUtil.info(TAG, 'Now device is tablet');
    //     if (data[0].rotation === 0 || data[0].rotation === 2) {
    //       this.isPortraitOrientation = false
    //     } else if (data[0].rotation === 1 || data[0].rotation === 3) {
    //       this.isPortraitOrientation = true
    //     }
    //   } else {
    //     LogUtil.info(TAG, 'Now device is default');
    //     if (data[0].rotation === 0 || data[0].rotation === 2) {
    //       this.isPortraitOrientation = true
    //     } else if (data[0].rotation === 1 || data[0].rotation === 3) {
    //       this.isPortraitOrientation = true
    //     }
    //   }
    // });
  }

  async onPageShow(): Promise<void> {
    // LogUtil.info(TAG, 'on page show');
    // await this.getScreen()
    // LogUtil.info(TAG, 'on page show');
    // const cityId = AppStorage.Get<string>('cityId');
    // AppStorage.Delete('cityId');
    // this.UpdateCityList()
    // cityId && await this.addNewWorldClock(cityId)
    // this.refreshAlarmData()
    // this.refreshWorldClockData();
    // this.emitSwitchPageHandle(true);
    // if (this.isScreenLock) {
    //   // await SoundPool.loadResource(1, this.currentIndex)
    //   // SoundPool.soundPool.on('loadComplete', (soundId_: number) => {
    //   //   this.isPageHide = false
    //   // })
    //   this.isScreenLock = false
    //   this.isScreenEntry = true
    // } else {
    //   this.isPageHide = false
    //   this.isScreenEntry = false
    // }

  }

  async onPageHide(): Promise<void> {
    // this.isPageHide = true
    // this.emitSwitchPageHandle(false);
  }

  async initContent(): Promise<void> {
    // this.currentIndex = await PageStateManager.getTabIndex();
    // this.currentIndexProvider = this.currentIndex;
    // this.changeTabs();
  }

  changeTabs(): void {
    // if (this.currentIndex === MenuIndex.ALARM) {
    //   if (this.isAlarmInit) {
    //     this.isAlarmShown = true;
    //   }
    //   this.isAlarmInit = true;
    //   this.isAlarmClockVisible = true;
    //   this.isWorldClockVisible = false;
    //   this.isStopWatchVisible = false;
    //   this.isTimerVisible = false;
    // } else if (this.currentIndex === MenuIndex.WORLD_CLOCK) {
    //   if (this.isWorldClockInit) {
    //     this.isWorldClockShown = true;
    //   }
    //   this.isWorldClockInit = true;
    //   this.isAlarmClockVisible = false;
    //   this.isWorldClockVisible = true;
    //   this.isStopWatchVisible = false;
    //   this.isTimerVisible = false;
    // } else if (this.currentIndex === MenuIndex.STOPWATCH) {
    //   this.isStopInit = true;
    //   this.isAlarmClockVisible = false;
    //   this.isWorldClockVisible = false;
    //   this.isStopWatchVisible = true;
    //   this.isTimerVisible = false;
    // } else if (this.currentIndex === MenuIndex.TIMER) {
    //   this.isTimerInit = true;
    //   this.isAlarmClockVisible = false;
    //   this.isWorldClockVisible = false;
    //   this.isStopWatchVisible = false;
    //   this.isTimerVisible = true;
    // }
  }

  /**
   * 查询/刷新闹钟页面数据
   * 在第一次进入应用和跳转到别的应用或页面有，再返回当前页面时调用
   */
  async refreshAlarmData(): Promise<void> {
    // LogUtil.info(TAG, 'refreshAlarmData');
    // this.alarmClockList = await AlarmManager.getAllAlarmsToShow();
    // LogUtil.info(TAG, 'alarmClockList:' + this.alarmClockList.length);
    // this.leftTimeToRingTime = await TimeUtil.getLeftTimeToRingTime(false);
    // const isFiring: boolean = await AlarmStateManager.isFiring();
    // LogUtil.info(TAG, 'alarm isFiring' + isFiring);
    // if (!isFiring) {
    //   AlarmCardUtil.notifyAlarmCardTimeUpdate();
    // }
    //
    // await this.addOpsLogs();
  }

  /**
   * addOpsLogs to diagnosis beta problems
   */
  async addOpsLogs(): Promise<void> {
    // for (const value of this.alarmClockList) {
    //   if (value.enabled) {
    //     LogUtil.info(TAG, `opsLogs has enabled alarm id: ${value.id}`);
    //     break;
    //   }
    // }
    // const timerId = await TimerManager.getTimerId();
    // const triggerTime = await TimerManager.getTriggerTime();
    // const triggerAlarmId = await TimerManager.getTriggerTimeID();
    // LogUtil.info(TAG, `opsLogs triggerAlarmId: ${triggerAlarmId}  triggerTime: ${triggerTime}  timerId: ${timerId}  `);
    //
    // const nearestAlarmTime: string = CommonUtil.getNearestAlarmTime();
    // LogUtil.info(TAG, `opsLogs nearestAlarmTime: ${nearestAlarmTime}  tips: ${this.leftTimeToRingTime}`);
  }

  /**
   * 刷新最近一次闹钟的状态
   */
  async refreshNearestAlarm(): Promise<void> {
    // LogUtil.info(TAG, 'refreshNearestAlarm');
    // let nearClock: AlarmInfo | undefined = await AlarmManager.getNearestAlarm();
    // LogUtil.info(TAG, `nearClock: ${JSON.stringify(nearClock)}`);
    // if (nearClock) {
    //   AlarmManager.updateAlarm(nearClock)
    //   this.leftTimeToRingTime = await TimeUtil.getLeftTimeToRingTime(true);
    //   const isFiring: boolean = await AlarmStateManager.isFiring();
    //   LogUtil.info(TAG, 'alarm isFiring' + isFiring);
    //   if (!isFiring) {
    //     AlarmCardUtil.notifyAlarmCardTimeUpdate();
    //   }
    // }
  }

  /**
   * refresh world clock list.
   */
  async refreshWorldClockData(): Promise<void> {
    // LogUtil.info(TAG, 'refreshWorldClockData');
    // let worldClockList = await WorldClockManager.getAllWorldClock();
    // this.cityList.clear();
    // for (let worldClock of worldClockList) {
    //   this.cityList.add(worldClock.cityIndex);
    //   worldClock.tag = await WorldClockUtil.updateTimeZoneInfo(worldClock.offset,
    //     worldClock.timezone, worldClock.cityIndex);
    // }
    // this.worldClockList = worldClockList;
  }

  private emitSwitchPageHandle(isShow: boolean): void {
    // emitter.emit({
    //   eventId: EVENT_ID_SWITCH_PAGE,
    //   priority: emitter.EventPriority.IMMEDIATE,
    // }, {
    //   data: {
    //     isPageShow: isShow,
    //   }
    // })
    // if (isShow) {
    //   emitter.emit({ eventId: TIMER_Toggle_FRONT_AND_BACKEND, priority: emitter.EventPriority.IMMEDIATE }, {
    //     data: { pageShow: true }
    //   })
    // }
  }

  /**
   * Do not modify the folding method
   */
  private getOrientation(isUp?: boolean) {
    // LogUtil.info(TAG, 'get orientation start, isUp:' + JSON.stringify(isUp));
    // display.getAllDisplay((err: BusinessError, data: Array<display.Display>) => {
    //   const errCode: number = err.code;
    //   if (errCode) {
    //     LogUtil.error(TAG, 'Failed to obtain all the display objects. Code: ' + JSON.stringify(err));
    //     return;
    //   }
    //   let result = 0
    //   if (data[0].rotation === 0 || data[0].rotation === 2 && isUp) {
    //     result = this.isFoldCross
    //   } else if (data[0].rotation === 1 || data[0].rotation === 3 && isUp) {
    //     result = this.isFoldVertical
    //   } else {
    //     result = data[0].width
    //   }
    //   AppStorage.SetOrCreate<number>('setOrientaion', result);
    // });
  }

  private async changeNavbarStatus() {
    // if (this.foldAbleScreen === 1) {
    //   this.getOrientation()
    // }
  }

  private async showToastWhenAlarmChanges(): Promise<void> {
    // if (this.alarmRingTime) {
    //   const string_less_than_one_minute = await ResourceManager.getStringByIdAsync($r('app.string.less_than_one_minute')
    //     .id);
    //   const STRING_RING_IN = await ResourceManager.getStringByIdAsync($r('app.string.ring_in').id);
    //   const remainingRingTime = this.alarmRingTime === LESS_THAN_ONE_MINUTE_FLAG
    //     ? string_less_than_one_minute : STRING_RING_IN.replace(FIRST_PARAM, this.alarmRingTime);
    //   promptAction.showToast({ message: remainingRingTime, duration: PROMPT_TIME });
    //   this.alarmRingTime = '';
    // }
  }

  /**
   * Subscription event, used to refresh the page
   */
  private subscribeEvents(): void {
    // // 监听处理闹钟启闹
    // emitter.on({
    //   eventId: EVENT_ID_ALARM_RING
    // }, async () => {
    //   LogUtil.info(TAG, 'receive EVENT_ID_ALARM_RING')
    //   await AlarmManager.updateTimer();
    //   this.refreshAlarmData();
    // });
    // // 监听处理闹钟编辑和创建
    // emitter.on({
    //   eventId: EVENT_ID_CHANGE_ALARM,
    // }, (eventData) => {
    //   LogUtil.info(TAG, 'receive EVENT_ID_CHANGE_ALARM')
    //   this.alarmRingTime = eventData.data ? eventData.data.KEY_ALARM_RING_TIME : '';
    //   LogUtil.info(TAG, 'receive alarmRingTime:' + this.alarmRingTime);
    //   this.showToastWhenAlarmChanges();
    //   this.refreshAlarmData();
    // });
    // // 监听处理闹钟批量删除
    // emitter.on({
    //   eventId: EVENT_ID_DELETE_ALARM,
    // }, (eventData) => {
    //   LogUtil.info(TAG, 'receive EVENT_ID_DELETE_ALARM')
    //   this.showToastWhenAlarmChanges();
    //   this.refreshAlarmData();
    // });
    // // 监听处理世界时钟左滑删除
    // emitter.on({
    //   eventId: EVENT_ID_CHANGE_WORLD_CLOCK,
    // }, () => {
    //   LogUtil.info(TAG, 'receive WORLD_CLOCK_CHANGE');
    //   this.UpdateCityList()
    // });
  }

  private UpdateCityList(): void {
    // this.cityList.clear();
    // for (let worldClock of this.worldClockList) {
    //   this.cityList.add(worldClock.cityIndex);
    // }
  }

  /**
   * Unsubscribe from events
   */
  private unSubscribeEvents(): void {
    // emitter.off(EVENT_ID_ALARM_RING);
    // emitter.off(EVENT_ID_CHANGE_ALARM);
    // emitter.off(EVENT_ID_DELETE_ALARM);
    // emitter.off(EVENT_ID_CHANGE_WORLD_CLOCK);
    // emitter.off(EVENT_ID_WORLDCLOCK_FORPC);
  }

  private async addNewWorldClock(cityId: string): Promise<void> {
    // if (cityId === '') {
    //   LogUtil.info(TAG, 'select no city');
    //   return;
    // }
    // if (this.cityList.has(cityId)) {
    //   promptAction.showToast({ message: $r('app.string.worldclock_city_exist_Toast'), duration: PROMPT_TIME });
    //   return;
    // }
    // if (this.cityList.size === MAX_CITY_NUM) {
    //   promptAction.showToast({ message: $r('app.string.city_full_Toast'), duration: PROMPT_TIME });
    //   return;
    // }
    // await WorldClockManager.addWorldClock(this.initWorldClockInfo(cityId));
  }

  // private initWorldClockInfo(cityId: string): WorldClockInfo {
    // const cityIndex = cityId;
    // const timezone = i18n.TimeZone.getTimezoneFromCity(cityId).getID();
    // const city = i18n.TimeZone.getCityDisplayName(cityId, i18n.getSystemLocale());
    // const offset = i18n.TimeZone.getTimezoneFromCity(cityId).getRawOffset();
    // return {
    //   sortOrder: DEFAULT_SORT_ORDER,
    //   cityIndex,
    //   timezone,
    //   city,
    //   offset,
    // };
  // }

  private reportTabEvent(index: number): void {
    // if (index === MenuIndex.ALARM) {
    //   EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_ALARM_CLOCK_TAB)
    // }
    // if (index === MenuIndex.WORLD_CLOCK) {
    //   EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_WORLD_CLOCK_TAB)
    // }
    // if (index === MenuIndex.STOPWATCH) {
    //   EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_STOPWATCH_TAB)
    // }
    // if (index === MenuIndex.TIMER) {
    //   EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_TIMER_TAB)
    // }
  }

  // private isPageVisible(index: MenuIndex): boolean {
    // return this.currentIndex == index;
  // }

  @Builder
  buildTitleBar(id: number): void {
    // TitleBar({
    //   title: (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager).getStringSync(id),
    //   operationArea: () => {
    //   },
    // })
    //   .margin(this.isPCLg() ? { left: $r('app.float.snooze_button_border_radius') } : (this.isPortraitOrientation ? {
    //     left: this.foldAbleScreen === 1 ? $r('app.float.change_vertical') : $r('app.float.change_cross'),
    //     right: this.foldAbleScreen === 1 ? $r('app.float.change_vertical') : $r('app.float.change_cross')
    //   } : { left: $r('app.float.change_vertical'), right: $r('app.float.change_vertical') }))
    //   .transition({ type: TransitionType.All, opacity: 0 })
    //   .shadow({
    //     radius: $r('app.float.button_shadow_radius'),
    //     color: $r('sys.color.ohos_id_background_secondary'),
    //     offsetX: $r('app.float.button_shadow_x'),
    //     offsetY: $r('app.float.button_shadow_y'),
    //   })
  }

  @Builder
  buildTitle(): void {
    Flex({ alignItems: ItemAlign.Start }) {
      GridRow() {
        GridCol({
          span: { xs: SMALL_SCREEN_CONTENT_SPAN, md: SMALL_SCREEN_CONTENT_SPAN, lg: BIG_SCREEN_CONTENT_SPAN },
          offset: { xs: SMALL_SCREEN_CONTENT_OFFSET, md: SMALL_SCREEN_CONTENT_OFFSET, lg: BIG_SCREEN_CONTENT_OFFSET },
        }) {
          Row() {
            if (this.currentIndex === MenuIndex.ALARM) {
              this.buildTitleBar(MENU_CONFIG[this.currentIndex].label.id);
            } else if (this.currentIndex === MenuIndex.WORLD_CLOCK) {
              this.buildTitleBar(MENU_CONFIG[this.currentIndex].label.id);
            } else if (this.currentIndex === MenuIndex.STOPWATCH) {
              this.buildTitleBar(MENU_CONFIG[this.currentIndex].label.id);
            } else if (this.currentIndex === MenuIndex.TIMER) {
              this.buildTitleBar(MENU_CONFIG[this.currentIndex].label.id);
            }
          }
          .width('100%')
          .margin(this.isPCLg() ? { left: '-192vp' } : '0')
          .height($r('app.float.title_bar_height'))
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Start)
          .backgroundColor($r('sys.color.ohos_id_background_secondary'))
          .shadow({
            radius: $r('app.float.title_bar_shadow_radius'),
            color: $r('sys.color.ohos_id_background_secondary'),
            offsetX: $r('app.float.title_bar_shadow_x'),
            offsetY: $r('app.float.title_bar_shadow_y')
          })
        }
        .backgroundColor($r('app.color.transparent'))
        .height($r('app.float.title_bar_height'))
      }
      .height('100%')
      .width(this.isPortraitOrientation || this.foldAbleScreen === 1 ? '100%' : this.currentBreakpoint !== BreakPoint.LG ? '39%' : '100%')
    }
    .renderGroup(true)
    .hitTestBehavior(HitTestMode.Transparent)
    .height('100%')
    .width('100%')
  }

  @Builder
  buildTabItem(item: MenuItem): void {
    Column() {
      if (this.currentIndex === item.index) {
        Stack() {
          Image(item.iconActivated)
            .width($r('app.float.appbar_icon_size'))
            .height($r('app.float.appbar_icon_size'))
            .draggable(false)
        }

        Text(item.label)
          .margin({ top: $r('app.float.main_tab_text_margin') })
          .fontSize($r('app.float.main_tab_text_size'))
          .fontWeight(FontWeight.Medium)
          .lineHeight($r('app.float.main_tab_line_height'))
          .fontColor($r('sys.color.ohos_id_icon_color_active'))
      } else {
        Image(item.icon)
          .fillColor($r('sys.color.ohos_fa_icon_secondary'))
          .width($r('app.float.appbar_icon_size'))
          .height($r('app.float.appbar_icon_size'))
          .draggable(false)
        Text(item.label)
          .margin({ top: $r('app.float.main_tab_text_margin') })
          .fontSize($r('app.float.main_tab_text_size'))
          .fontWeight(FontWeight.Medium)
          .lineHeight($r('app.float.main_tab_line_height'))
          .fontColor($r('sys.color.ohos_id_color_bottom_tab_text_off'))
      }
    }
    .tabBarBackground(item, {
      onHover: (isHover) => {
        const active: ITabBarActionOptions = { index: undefined, status: undefined };
        if (isHover) {
          active.index = item.index;
          active.status = 'hover';
        } else {
          active.index = undefined;
          active.status = undefined;
        }
        this.currentActiveTab = active;
      },
      onMouse: (event) => {
        if ((event.action === MouseAction.Press) && (event.button === MouseButton.Left)) {
          const active: ITabBarActionOptions = { index: undefined, status: undefined };
          active.index = item.index;
          active.status = 'press';
          this.currentActiveTab = active;
        } else if (event.action === MouseAction.Release) {
          const active: ITabBarActionOptions = { index: undefined, status: undefined };
          active.index = item.index;
          active.status = 'hover';
          this.currentActiveTab = active;
        }
      }
    }, this.currentActiveTab)
    .borderRadius($r('sys.float.ohos_id_corner_radius_default_s'))
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      animateTo({ duration: 1, curve: Curve.Friction }, () => {
        this.currentIndex = item.index;
        this.currentIndexProvider = this.currentIndex;
        PageStateManager.saveTabIndexToSp(this.currentIndex);
        this.changeTabs();
      });
      this.reportTabEvent(this.currentIndex)
    })
  }

  @Builder
  buildTabs(): void {
    if (this.currentBreakpoint !== BreakPoint.LG) {
      this.buildTabsLandSpace()
    } else {
      this.buildContTabs()
    }
  }

  @Builder
  buildTabsLandSpace(): void {
    Flex({ justifyContent: FlexAlign.End }) {
      this.buildContTabs()
    }
    .renderGroup(true)
  }

  @Builder
  buildContTabs(): void {
    Tabs({
      index: this.currentIndex,
      controller: this.tabController,
      barPosition: this.currentBreakpoint === BreakPoint.LG ? BarPosition.Start : BarPosition.End,
    }) {
      ForEach(MENU_CONFIG, (item: MenuItem) => {
        TabContent().tabBar(this.buildTabItem(item)).width(0)
      })
    }
    .renderGroup(true)
    .barWidth(this.isPCLg() ? '100%' : this.currentBreakpoint === BreakPoint.LG ? $r('app.float.tool_bar_width') : '100%')
    .barHeight(this.isPCLg() ? '50%' : this.currentBreakpoint === BreakPoint.LG ? '60%' : $r('app.float.title_bar_height'))
    .vertical(this.currentBreakpoint === BreakPoint.LG)
    .onChange((index: number) => {
      this.currentIndexCache = index
    })
    .onKeyEvent((event: KeyEvent) => {
      if (event.keyText === 'KEYCODE_ENTER' || event.keyText === 'KEYCODE_SPACE') {
        animateTo({ duration: 0, curve: Curve.Friction }, () => {
          this.currentIndex = this.currentIndexCache;
          this.currentIndexProvider = this.currentIndex;
          PageStateManager.saveTabIndexToSp(this.currentIndex);
          this.changeTabs();
        });
        this.reportTabEvent(this.currentIndex);
      }
    })
    .animationDuration(0)
    .scrollable(false)
    .backgroundColor($r('sys.color.ohos_id_background_secondary'))
    .width(this.currentBreakpoint === BreakPoint.LG ? $r('app.float.tool_bar_width') : this.isPortraitOrientation || this.foldAbleScreen === 1 ? '100%' : '60%')
    .height(this.currentBreakpoint === BreakPoint.LG ? '100%' : $r('app.float.title_bar_height'))
    .margin(this.isPortraitOrientation ? {} : { right: $r('app.float.tab_bar_margin_right') })
  }

  @Builder
  buildContent(): void {
    Flex({ direction: FlexDirection.Column }) {
      Stack() {
        if (this.isAlarmInit) {
          AlarmClock({
            alarmClockListFromEntry: $alarmClockList,
            leftTimeToRingTime: $leftTimeToRingTime,
            isAlarmClockVisible: this.isAlarmClockVisible,
            isPortraitOrientation: this.isPortraitOrientation,
            isBigView: this.currentBreakpoint,
          })
            .transition(TransitionEffect.opacity(this.isAlarmShown ? 1 : 0.99))
            // .visibility(this.isPageVisible(MenuIndex.ALARM) ? Visibility.Visible : Visibility.Hidden)
        }
        if (this.isWorldClockInit) {
          WorldClock({
            worldClockList: $worldClockList,
            isWorldClockVisible: this.isWorldClockVisible,
            isPortraitOrientation: this.isPortraitOrientation,
          })
            .transition(TransitionEffect.opacity(this.isWorldClockShown ? 1 : 0.99))
            // .visibility(this.isPageVisible(MenuIndex.WORLD_CLOCK) ? Visibility.Visible : Visibility.Hidden)
        }
        if (this.isStopInit) {
          Stopwatch({
            isStopwatchVisible: this.isStopWatchVisible,
            isPortraitOrientation: this.isPortraitOrientation,
            isClockHide: $isClockHide,
            isBigView: this.currentBreakpoint,
            isPageHide: this.isPageHide,
            currentIndex: this.currentIndex
          })
            .transition(TransitionEffect.opacity(0.99))
            // .visibility(this.isPageVisible(MenuIndex.STOPWATCH) ? Visibility.Visible : Visibility.Hidden)
        }
        if (this.isTimerInit) {
          Timer({
            isTimerVisible: this.isTimerVisible,
            isPortraitOrientation: this.isPortraitOrientation,
            isBigView: this.currentBreakpoint,
            isPageHide: this.isPageHide,
            currentIndex: this.currentIndex,
            isScreenEntry: this.isScreenEntry
          })
            .transition(TransitionEffect.opacity(0.99))
            // .visibility(this.isPageVisible(MenuIndex.TIMER) ? Visibility.Visible : Visibility.Hidden)
        }
      }
      .width('100%')
    }
    .padding({ top: $r('app.float.content_offset'), bottom: $r('app.float.title_bar_height') })
    .width('100%')
    .height('100%')
  }

  @Builder
  routerMap(name: string, param: ObservedAlarmInfo | object): void {
   if (name === MANAGE_NEW_ALARM) {
      ManageAlarmClock();
    } else if (name === MANAGE_EDIT_ALARM) {
      ManageAlarmClock({ alarmInfoParam: param as ObservedAlarmInfo });
    } else if (name === MANAGE_NEW_WORLD_CLOCK) {
      AddCity();
    } else if (name === MANAGE_EDIT_WORLD_CLOCK) {
      EditCities();
    } else if (name === MANAGE_EDIT_WORLD_CLOCK_PC) {
      EditCitiesForPC()
    }
  }

  build() {
    Navigation(this.pageInfos) {
      // Stack({ alignContent: this.currentBreakpoint === BreakPoint.LG ? Alignment.Start : Alignment.Bottom }) {
      //   this.buildContent();
      //   this.buildTitle();
      //   this.buildTabs();
      // }
      // .width('100%')
      // .height('100%')
      // .backgroundColor(this.currentBreakpoint === BreakPoint.LG ? $r('sys.color.ohos_id_color_sub_background') : $r('sys.color.ohos_id_background_secondary'))
      Text('111111')
        .backgroundColor(Color.Red)
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .hideBackButton(true)
    .navDestination(this.routerMap)
    .mode(NavigationMode.Stack)
    .expandSafeArea([SafeAreaType.KEYBOARD])
  }

  async initPresetCity(cityId: string) {
    // LogUtil.info(TAG, 'initPresetCity cityId: ' + cityId);
    // if (cityId) {
    //   cityId && await WorldClockManager.addWorldClock(this.initWorldClockInfo(cityId));
    //   this.refreshWorldClockData();
    // }
  }
}