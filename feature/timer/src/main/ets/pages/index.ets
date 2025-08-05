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

import {
  AlarmInfo,
  AlarmManager,
  CLOCK_RATIO_FOR_NORMAL,
  CLOCK_RATIO_FOR_NORMAL_CUSTOM,
  FloatingActionButton,
  FloatingActionButtonColor,
  HALF,
  LogUtil,
  MILLIS_IN_SECOND,
  ResourceAudioManager,
  ResourceManager,
  RINGTONE_SELECTION,
  BreakPoint,
  EventReportUtil,
  EventName,
  WantAgentUtil,
  GlobalContext,
  FROM_DATA_STORE,
  SoundPool,
  EVENT_ID_TIMEPICK_FORPC,
  MINUTE_IN_HOUR,
  SECOND_IN_MINUTE,
  TIME_PAUSE_OR_CONTINUE_ID,
  TIMEOUT_FULL_SCREEN_ID,
  TIMEOUT_FULL_SCREEN_CLOSE_ID,
  TIMEOUT_FULL_SCREEN_REPATE_ID,
  AlarmStateManager,
  TIMER_NOTICE_ID,
  TimerStateManager,
  CommonUtil,
  EVENT_ID_SEND_ALARM,
  TimerSystemTimer,
  START_DATE_TIMER_PREFERENCES_CLOCK,
  LEFT_TIME_TIMER_PREFERENCES_CLOCK,
  TOTAL_TIME_TIMER_PREFERENCES_CLOCK,
  PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK,
  TIMEOUT_FLAG_ID,
  FULLSCREEN_SLIPUP_ID,
  TIMER_Toggle_FRONT_AND_BACKEND,
  TIMER_DATA_STORE
} from '@hmos/common';
// import hiSysEvent from '@ohos.hiSysEvent';
import preferencesUtil from '@ohos.data.preferences';
import emitter from '@ohos.events.emitter';
import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import { AnalogTimer, TimerPicker, TimerPickerForPC } from '../components';
import window from '@ohos.window';
import { RingtoneSelectionUtil } from '@hmos/common/src/main/ets/utils/RingtoneSelectionUtil';
import { DateObject, formatMillisecondToObject } from '../common/Utils';
// import lottie, { AnimationItem } from '../../../../../../common/oh_modules/@ohos/lottie';
import deviceInfo from '@ohos.deviceInfo'
import notificationManager from '@ohos.notificationManager'
import worker from '@ohos.worker';
import { NotificationContentUtil } from '@hmos/common/src/main/ets/utils/NotificationContentUtil'
import image from '@ohos.multimedia.image';
import resmgr from '@ohos.resourceManager';
import TimerAudioPlayer from '../manager/timerAudioPlayer';
import screenLock from '@ohos.screenLock';
import { timerPreferencesManagerUtil } from '../common/preferencesUtil';
import { TimerNotificationUtil } from '../utils';
import CommonEventManager from '@ohos.commonEventManager';

type NotificationRequest = notificationManager.NotificationRequest;

const SECOND_IN_HOUR = SECOND_IN_MINUTE * MINUTE_IN_HOUR;
const TAG = 'Timer_index';
const TICK_FILE_NAME: string = 'timer_tick.ogg';
const TIMER_BEEP: string = 'Timer_Beep.ogg';
const UPDATE_INTERVAL: number = 150;

const SCALE_DIAMETER_RATIO = 0.94;
const FOLDSCREEN_CLOCK_TIMER_NORMAL_CUSTOM = 0.85;
const SPECAIL_CLOCK_TIMER_NORMAL_CUSTOM = 0.7;

let GLOBAL_PREV_START_DATE = 0;
const noticeUpdateCycle = 1000 * 60 * 5; //5min更新一次实况数据
const limitTimeLeft = 300;


interface PageInfos {
  isTimerRingtone: boolean,
  onRingtoneSelected: (path: string) => void
}

interface ReportParams {
  PACKAGE_NAME: string;
  PROCESS_NAME: string;
  RESULT: string;
  VALUE?: string;
  STATUS?: string
}

interface Time {
  hours: string,
  minutes: string,
  seconds: string
}

const SHUTDOWN_SUBSCRIBE_INFO: CommonEventSubscribeInfo = {
  events: [
    CommonEventManager.Support.COMMON_EVENT_SHUTDOWN,
  ],
};

// This type is not exported from @ohos.commonEvent, so we get it by exported function.
type CommonEventSubscriber = CommonEventManager.CommonEventSubscriber
type CommonEventSubscribeInfo = CommonEventManager.CommonEventSubscribeInfo

/**
 * Timer home page
 *
 * Used to display the timer.
 *
 * @since 2023-09-05
 */
@Component
export struct Timer {
  @Prop @Watch('updateAnalogTimer') isPortraitOrientation: boolean = true; //纵向 true 横向 false
  @Prop isFocus: Boolean = false;
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @StorageProp('setOrientaion') getOrientaion: number = 0;
  @Prop isBigView: string = '';
  @Prop @Watch('pageVisibilityChanged') isTimerVisible: boolean = true;
  @StorageProp('windowStandardHeight') windowStandardHeight: number = 0;
  @StorageLink('mainWindow') mainWindow: window.Window | undefined = undefined;
  @Prop @Watch('onPageToggle') isPageHide: boolean = true;
  @Prop @Watch('currentIndexChange') currentIndex: number = 0;
  @Prop isScreenEntry: boolean = false;
  @Consume('pageInfos') pageInfos: NavPathStack;
  @State @Watch('listenTime') totalTime: number = 0;
  @State @Watch('timeLeftChanged') timeLeft: number = 0;
  @State @Watch('initAnimation') canvasOpacity: number = 0.4;
  @State timeOutFlag: boolean = false;
  @State started: boolean = false;
  @State paused: boolean = false;
  @State reset: boolean = false;
  @State @Watch('diameterChanged') diameter: number = 0;
  @State timeToLeave: number = 0;
  @State hours: string = '00';
  @State minutes: string = '00';
  @State seconds: string = '00';
  @State resetZero: string = '00';
  @State screenFull: boolean = false
  @State isRepeatTiming: boolean = false;
  @State showTimerData: DateObject = new DateObject('00', '00', '00', '00');
  @State @Watch('isTickPlayingChanged') isTickPlaying: boolean = false;
  @State isShowPage: boolean = true;
  @State timeoutDuration: number = 0;
  @State deviceType: string = deviceInfo.deviceType; // 设备类型
  @State @Watch('listenTimerRunning') private isTimerRunning: boolean = false;
  @State selfFocus: boolean = false;
  @State passedTime: number = 0;
  @State timerTimeout: number = -1;
  private dateToFormat: Date = new Date();
  private alarm: AlarmInfo = {
    id: TIMER_NOTICE_ID,
    title: '',
    hour: new Date().getHours(),
    minute: new Date().getMinutes(),
    second: new Date().getSeconds(),
    ringDuration: 1,
    snoozeDuration: 0,
    snoozeTimes: 0,
    daysOfWeek: [],
    enabled: false,
  };
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private currentAnimateName: string = 'pauseTimer';
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  private shutDownSubscriber?: CommonEventSubscriber;

  private isPCLg() {
    return this.deviceType === '2in1'
  }

  // 动画名称
  private timerCanvasAnimateName: string = 'playAnimate';
  private canvasTimerPauseAnimateName: string = 'timerPauseAnimate';
  private canvasTimerPauseAnimatePath: string = 'resources/rawfile/pauseToPlay.json';
  // 动画json
  private canvasAnimatePath: string = 'resources/rawfile/playToPause.json';
  // private animateItem: AnimationItem | null = null;

  private listenTime() {
    this.canvasOpacity = this.totalTime > 0 ? 1 : 0.4;
    if (this.totalTime === 0) {
      this.timerPreferencesClear();
    }
  }

  async currentIndexChange() {
  }

  async updateAnalogTimer() {
    const windowSize = this.mainWindow?.getWindowProperties()?.windowRect || { width: 0, height: 0 };
    this.updateDiameter(windowSize);
  }

  async onPageToggle(): Promise<void> {
    if (this.isTickPlaying) {
      if (this.isPageHide) {
        await SoundPool.stopForPageHide('time')
      } else { // 入口页面
        const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
          .getObject('clockContext') as Context, FROM_DATA_STORE);
        const alarm_active = await preferences.get('ALARM_CLOCK_TAB', '');
        LogUtil.info(TAG, `on page show alarm_active=${alarm_active}`);
        if (alarm_active) {
          await SoundPool.stopForPageHide('time');
        } else {
          if (this.currentIndex == 3) {
            if (this.isScreenEntry) {
              SoundPool.playTimeForDelay();
            } else {
              await SoundPool.playSoundPool('time');
            }
          }
        }
      }
    }
  }

  async timerPreferencesInit() {
    GLOBAL_PREV_START_DATE = Number(await timerPreferencesManagerUtil.getKey(START_DATE_TIMER_PREFERENCES_CLOCK));
    const _totalTime = Number(await timerPreferencesManagerUtil.getKey(TOTAL_TIME_TIMER_PREFERENCES_CLOCK));
    const _now = new Date().getTime();
    this.totalTime = _totalTime;

    //  GLOBAL_PREV_START_DATE  == 0: 暂停状态
    //  GLOBAL_PREV_START_DATE != 0: 计时状态
    LogUtil.info(TAG, `timerPreferencesInit=>${GLOBAL_PREV_START_DATE},timerPreferencesInit=>${new Date().getTime()}`)

    if (GLOBAL_PREV_START_DATE !== 0 && this.isTimerVisible) {
      let _prevPassedTime = Number(await timerPreferencesManagerUtil.getKey(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK));
      let _passedTime = _now - GLOBAL_PREV_START_DATE >= _totalTime ? _totalTime :
        _now - GLOBAL_PREV_START_DATE + _prevPassedTime;
      const _timeLeft = _totalTime - _passedTime;
      const _showTimerData = formatMillisecondToObject(_totalTime);
      this.passedTime = _passedTime;
      this.timeLeft = _timeLeft;
      this.hours = _showTimerData.hours;
      this.minutes = _showTimerData.minute;
      this.seconds = _showTimerData.seconds;
    } else {
      return
    }
  }

  listenTimerRunning() {
    if (this.isTimerRunning) {
      this.initPauseAnimation();
    } else {
      this.initAnimation();
    }
  }

  timerPreferencesClear() {
    timerPreferencesManagerUtil.del(TOTAL_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(LEFT_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(START_DATE_TIMER_PREFERENCES_CLOCK);
  }

  async aboutToAppear(): Promise<void> {
    LogUtil.info(TAG, `aboutToAppear=>`);
    clearTimeout(this.timerTimeout);
    this.deviceType = deviceInfo.deviceType;

    this.listeningAlarm();
    emitter.on({
      eventId: EVENT_ID_TIMEPICK_FORPC,
    }, (eventData) => {
      this.showTimerData.hours = eventData.data?.hours;
      this.showTimerData.minute = eventData.data?.minutes;
      this.showTimerData.seconds = eventData.data?.seconds;
    });
    const windowSize = this.mainWindow?.getWindowProperties()?.windowRect || { width: 0, height: 0 };
    this.updateDiameter(windowSize);
    this.mainWindow?.on('windowSizeChange', sizeInfo => this.updateDiameter(sizeInfo));
    this.emitterFunc();
    this.subscribeShutDownEvent();
  }

  async aboutToDisappear(): Promise<void> {
    LogUtil.info(TAG, `aboutToDisappear=>`);
    clearTimeout(this.timerTimeout);
    this.IsTimerRunFunc('destroy');
    emitter.off(TIME_PAUSE_OR_CONTINUE_ID);
    emitter.off(TIMEOUT_FULL_SCREEN_CLOSE_ID);
    emitter.off(TIMEOUT_FULL_SCREEN_REPATE_ID);
    emitter.off(TIMEOUT_FLAG_ID);
    emitter.off(FULLSCREEN_SLIPUP_ID);
    emitter.off(TIMER_Toggle_FRONT_AND_BACKEND);
    this.timerPreferencesClear();
    this.unSubscribeTimeChangedEvent();
  }

  private async systemShutDown(): Promise<void> {
    LogUtil.info(TAG, `systemShutDown====>`);
    this.stopOutTime();
  }

  private async subscribeShutDownEvent(): Promise<void> {
    // Create a subscriber and subscribe to shutDown event.订阅手机关机事件
    this.shutDownSubscriber = await CommonEventManager.createSubscriber(SHUTDOWN_SUBSCRIBE_INFO);
    LogUtil.info(TAG, `shutDownSubscriber=${this.shutDownSubscriber}`);
    if (!this.shutDownSubscriber) {
      return;
    }
    CommonEventManager.subscribe(this.shutDownSubscriber, () => this.systemShutDown());
  }

  private unSubscribeTimeChangedEvent() {
    if (this.shutDownSubscriber) {
      CommonEventManager.unsubscribe(this.shutDownSubscriber, error => {
        if (error) {
          LogUtil.error(TAG, `Unsubscribe to shut-down event failed: ${JSON.stringify(error)}`);
          return;
        }
        LogUtil.info(TAG, 'Unsubscribe to shut-down event successfully!');
      });
    }

  }

  private async timerReapte() {
    LogUtil.info(TAG, `timerReapte=>${this.totalTime}&&${this.started}&&${this.paused}`);
    this.passedTime = 0;
    this.started = false;
    this.paused = false;
    this.totalTime = Number(await timerPreferencesManagerUtil.getKey(TOTAL_TIME_TIMER_PREFERENCES_CLOCK))
    this.isRepeatTiming = false;
    this.timeoutDuration = 0;
    this.timeOutFlag = false;
    TimerAudioPlayer.stopTick(TIMER_BEEP);
    TimerNotificationUtil.cancel(TIMER_NOTICE_ID);
    GLOBAL_PREV_START_DATE = 0;
    timerPreferencesManagerUtil.del(LEFT_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK);
    timerPreferencesManagerUtil.del(START_DATE_TIMER_PREFERENCES_CLOCK);
    this.cacheStopWatchData();
    await this.onTimerToggled();
    await WantAgentUtil.triggerTimerMainPage('TIMER_TAB');
    CommonUtil.terminateFullScreenAbility();
  }

  private emitterFunc() {
    emitter.on({ eventId: TIME_PAUSE_OR_CONTINUE_ID }, (eventData) => {
      this.onTimerToggled('fullScreen');
      this.canvasOpacity = 1;
      LogUtil.info(TAG, `pause_or_coutinue=> ${eventData}`);
    });
    emitter.on({ eventId: TIMEOUT_FULL_SCREEN_CLOSE_ID }, (eventData) => {
      if (this.isPCLg()) {
        this.stopOutTimePC();
      } else {
        this.stopOutTime();
      }
      this.canvasOpacity = 1;
      LogUtil.info(TAG, `closeTimer=> ${eventData}`);
    });
    emitter.on({ eventId: TIMEOUT_FULL_SCREEN_REPATE_ID }, async (eventData) => {
      this.screenFull = eventData.data?.isFullScreen;
      this.timerReapte();
      this.canvasOpacity = 1;
      LogUtil.info(TAG, `repateTimer=> ${eventData}`);
    });
    emitter.on({ eventId: TIMEOUT_FLAG_ID }, (eventData) => {
      this.canvasOpacity = 0.4;
      LogUtil.info(TAG, `TIMEOUT_FLAG=> ${eventData}`);
    });
    emitter.on({ eventId: FULLSCREEN_SLIPUP_ID }, async (eventData) => {
      this.timeOutFlag = true;
      this.timeLeft = 0;
      this.passedTime = Number(await timerPreferencesManagerUtil.getKey(TOTAL_TIME_TIMER_PREFERENCES_CLOCK))
    });
    emitter.on({ eventId: TIMER_Toggle_FRONT_AND_BACKEND }, (eventData) => {
      if (eventData.data?.pageShow) {
        LogUtil.info(TAG, `Timer_Index_FRONT_AND_BACKEND=>pageShow`)
        this.timerPreferencesInit();
      } else {
        return;
      }
    });
  }

  private listeningAlarm() {
    emitter.on({ eventId: EVENT_ID_SEND_ALARM }, async (target) => {
      if (this.isTickPlaying) {
        if (target.data?.toggle === 'show') {
          await SoundPool.stopForPageHide('time');
        }
        if (target.data?.toggle === 'hide' && this.currentIndex === 3 && !this.isPageHide) {
          await SoundPool.playSoundPool('time');
        }
      }
    });
  }

  private changeShowTime() {
    let showTime: Time = {
      hours: this.timeOutFlag ? this.resetZero : (this.started ? this.showTimerData.hours :
        (this.showTimerData.hours !== '00' ? this.showTimerData.hours : this.hours)),
      minutes: this.timeOutFlag ? this.resetZero : (this.started ? this.showTimerData.minute :
        (this.showTimerData.minute !== '00' ? this.showTimerData.minute : this.minutes)),
      seconds: this.timeOutFlag ? this.resetZero : (this.started ? this.showTimerData.seconds :
        (this.showTimerData.seconds !== '00' ? this.showTimerData.seconds : this.seconds))
    }
    return showTime
  }

  private async IsTimerRunFunc(param: string) {
    switch (param) {
      case 'storedValue_and_create': {
        LogUtil.info(TAG, `IsTimerRunFunc=>storedValue_and_create`);
        timerPreferencesManagerUtil.save(TOTAL_TIME_TIMER_PREFERENCES_CLOCK, this.totalTime);
        if (GLOBAL_PREV_START_DATE === 0) { // 只在 从暂停状态开始的流程存储数据，杀死进程再进入计时器不做存储
          GLOBAL_PREV_START_DATE = new Date().getTime();
          timerPreferencesManagerUtil.save(START_DATE_TIMER_PREFERENCES_CLOCK, GLOBAL_PREV_START_DATE);
          const _delay = this.totalTime === this.timeLeft ? this.totalTime : this.timeLeft;
          await TimerSystemTimer.create(_delay);
        }
        break;
      }
      case 'storedValue_and_destory': {
        LogUtil.info(TAG, `IsTimerRunFunc=>storedValue_and_destory`);
        timerPreferencesManagerUtil.save(TOTAL_TIME_TIMER_PREFERENCES_CLOCK, this.totalTime);
        GLOBAL_PREV_START_DATE = 0;
        timerPreferencesManagerUtil.save(START_DATE_TIMER_PREFERENCES_CLOCK, GLOBAL_PREV_START_DATE);
        timerPreferencesManagerUtil.save(LEFT_TIME_TIMER_PREFERENCES_CLOCK, this.timeLeft);
        timerPreferencesManagerUtil.save(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK, this.passedTime);
        await TimerSystemTimer.destory();
        break;
      }
      case 'stopOutTime_and_destory': {
        LogUtil.info(TAG, `IsTimerRunFunc=>stopOutTime_and_destory`);
        timerPreferencesManagerUtil.save(TOTAL_TIME_TIMER_PREFERENCES_CLOCK, this.totalTime);
        GLOBAL_PREV_START_DATE = 0;
        timerPreferencesManagerUtil.save(LEFT_TIME_TIMER_PREFERENCES_CLOCK, 0);
        timerPreferencesManagerUtil.save(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK, 0);
        timerPreferencesManagerUtil.save(START_DATE_TIMER_PREFERENCES_CLOCK, GLOBAL_PREV_START_DATE);
        await TimerSystemTimer.destory();
        break;
      }
      case 'destroy': {
        LogUtil.info(TAG, `IsTimerRunFunc=>destroy`);
        GLOBAL_PREV_START_DATE = 0;
        timerPreferencesManagerUtil.save(LEFT_TIME_TIMER_PREFERENCES_CLOCK, 0);
        timerPreferencesManagerUtil.save(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK, 0);
        timerPreferencesManagerUtil.save(START_DATE_TIMER_PREFERENCES_CLOCK, GLOBAL_PREV_START_DATE);
        await TimerSystemTimer.destory();
        break;
      }
      default: {
        break;
      }
    }
  }

  private timeLeftChanged(...args: Array<string | number>) {
    let tlr = Math.ceil(this.timeLeft / 1000) * 1000;
    let d = this.started ? Math.min(tlr, this.totalTime) : this.totalTime;
    this.showTimerData = formatMillisecondToObject(d);
    if (this.timeLeft <= 0) {
      this.pauseAnimation();
    }
  }

  private playTick() {
    if (!this.isTickPlaying && this.isTimerVisible) {
      SoundPool.playSoundPool('time');
      this.isTickPlaying = true;
    }
  }

  private async stopTick() {
    SoundPool.stopForPageHide('time');
    this.isTickPlaying = false;
  }

  //页面进入获取缓存秒表数据
  private async getStopWatchData() {
    let passedTime: number = this.passedTime;
    let nowDate = new Date().getTime();
    let timeDiff = nowDate - this.timeToLeave;
    passedTime += timeDiff;
    this.passedTime = passedTime;
    LogUtil.info(TAG, `nowDate=${nowDate},timeToLeave=${this.timeToLeave},this.passedTime=${this.passedTime}`);
  }

  //页面离开缓存秒表数据
  private async cacheStopWatchData() {
    this.timeToLeave = new Date().getTime();
    LogUtil.info(TAG, `cacheStopWatchData timeToLeave=${this.timeToLeave},this.passedTime=${this.passedTime}`);
  }

  private pageVisibilityChanged() {
    if (this.started && !this.paused) {
      if (this.isTimerVisible) {
        this.getStopWatchData();
        this.refreshTime();
        SoundPool.playSoundPool('time');
        this.isTickPlaying = true;
      } else {
        SoundPool.stopForPageHide('time');
        this.cacheStopWatchData();
      }
    }
  }

  private stopTimer() {
    this.started = false;
    this.paused = false;
    this.timeLeft = 0;
    this.stopTick();
    this.timeoutDuration = 0;
    this.timeOutFlag = false;
  }

  private CloseTimer() {
    TimerAudioPlayer.stopTick(TIMER_BEEP);
    WantAgentUtil.triggerCloseTimer(TIMER_NOTICE_ID);
  }

  private diameterChanged() {
    if (this.isPortraitOrientation) {
      this.updateAnalogTimer();
    }
  }

  private async stopOutTime() {
    LogUtil.info(TAG, `stopOutTime`);
    this.getEventReportUtil(EventName.CLICK_TIMER_CLOSE);
    this.passedTime = 0;
    this.timeLeft = 0;
    this.timeoutDuration = 0;
    GLOBAL_PREV_START_DATE = 0;
    this.timeOutFlag = false;
    this.started = false;
    this.paused = false;
    this.reset = true;
    this.isTimerRunning = false;
    this.isRepeatTiming = false;
    this.timerTimeout = -1;
    clearTimeout(this.timerTimeout);
    this.stopTick();
    this.CloseTimer();
    this.IsTimerRunFunc('stopOutTime_and_destory')
  }

  private async stopOutTimePC() {
    LogUtil.info(TAG, `stopOutTimepc`);
    this.getEventReportUtil(EventName.CLICK_TIMER_CLOSE);
    this.passedTime = 0;
    this.timeLeft = 0;
    this.timeoutDuration = 0;
    GLOBAL_PREV_START_DATE = 0;
    this.timeOutFlag = false;
    this.started = false;
    this.paused = false;
    this.reset = true;
    this.isTimerRunning = false;
    this.isRepeatTiming = false;
    this.timerTimeout = -1;
    clearTimeout(this.timerTimeout);
    this.IsTimerRunFunc('stopOutTime_and_destory')
  }

  private timer(localTime: number): void {
    clearTimeout(this.timerTimeout);
    const now = new Date().getTime(); // 获取当前本地时间
    const timeGap = now - localTime; // 计算时间差
    //下一次计时器应该触发的时间
    const nextTickTime = UPDATE_INTERVAL - (timeGap % UPDATE_INTERVAL);
    if (this.isTimerRunning && !this.timeOutFlag && this.isTimerVisible) {
      this.timerTimeout = setTimeout(() => {
        let passedTime = this.passedTime;
        passedTime += UPDATE_INTERVAL;
        this.passedTime = passedTime;
        this.timeLeft = this.totalTime - passedTime;
        if (passedTime % noticeUpdateCycle == 0) {
          LogUtil.info(TAG, `noticeUpdateCycle`);
          WantAgentUtil.triggerStartTimer(
            TIMER_NOTICE_ID,
            this.timeLeft
          );
        }
        if (this.timeLeft <= 0) {
          this.passedTime = 0;
          this.stopTimer();
          (this.deviceType != '2in1') && (this.timeOutFlag = true);
          (this.deviceType === '2in1') &&
            (this.totalTime != 0) && (this.timeLeft = this.totalTime);
        }
        this.timer(localTime); // 递归调用,实现循环
      }, nextTickTime);
    }
    if (this.reset) {
      this.passedTime = 0;
      this.stopTimer();
    }
  }

  private refreshTime(): void {
    let localTime = new Date().getTime(); //记录本地时间
    this.timer(localTime); // 启动计时器
  }

  private updateDiameter(sizeInfo: window.Size): void {
    if (!sizeInfo || !sizeInfo.height || !sizeInfo.width) {
      return;
    }
    const height = sizeInfo.height || this.windowStandardHeight;
    const longEdge = Math.max(height, sizeInfo.width);
    const shortEdge = Math.min(height, sizeInfo.width);
    this.diameter = px2vp(Math.min(longEdge * HALF, shortEdge) * CLOCK_RATIO_FOR_NORMAL);
  }

  private formatTimeString(time: number): string {
    this.dateToFormat.setTime(time);
    let hours = (this.dateToFormat.getUTCDate() - 1) * 24 + this.dateToFormat.getUTCHours();
    return (hours > 10 ? hours : '0' + hours) + this.dateToFormat.toISOString().slice(13, 19);
  }

  private resetDialTime() {
    this.hours = '00';
    this.minutes = '00';
    this.seconds = '00';
    this.showTimerData.hours = '00';
    this.showTimerData.minute = '00';
    this.showTimerData.seconds = '00';
  }

  private resetTimer() {
    if (this.timeLeft < limitTimeLeft && GLOBAL_PREV_START_DATE !== 0) {
      LogUtil.info(TAG, 'timeLeft:' + this.timeLeft);
      return;
    }
    this.isTimerRunning = false;
    this.isRepeatTiming = false;
    this.reset = true;
    this.passedTime = 0;
    LogUtil.info(TAG, 'totalTimeChanged1:' + this.totalTime);
    if (!this.started && this.reset) {
      this.totalTime = 0;
    } else {
      LogUtil.info(TAG, 'timeLeftChanged1:' + this.timeLeft);
      if (this.timeLeft > 0) {
        LogUtil.info(TAG, 'totalTimeChanged2:' + this.totalTime);
        this.reset = true;
        if (this.deviceType === '2in1') {
          this.timeLeft = this.totalTime;
          this.pauseAnimation();
        } else {
          LogUtil.info(TAG, 'totalTimeChanged3:' + this.totalTime);
          this.timeLeft = 0;
        }
        timerPreferencesManagerUtil.del(LEFT_TIME_TIMER_PREFERENCES_CLOCK);
        timerPreferencesManagerUtil.del(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK);
        timerPreferencesManagerUtil.del(START_DATE_TIMER_PREFERENCES_CLOCK);
        this.stopTimer();
        this.CloseTimer();
      } else {
        this.resetDialTime();
        this.totalTime = 0;
        this.timeLeft = 0;
        timerPreferencesManagerUtil.del(TOTAL_TIME_TIMER_PREFERENCES_CLOCK);
        timerPreferencesManagerUtil.del(LEFT_TIME_TIMER_PREFERENCES_CLOCK);
        timerPreferencesManagerUtil.del(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK);
        timerPreferencesManagerUtil.del(START_DATE_TIMER_PREFERENCES_CLOCK);
        LogUtil.info(TAG, 'totalTimeChanged4:' + this.totalTime);
      }
    }
    this.timeOutFlag = false;
    this.getEventReportUtil('TIMER_RESET_BANNER');
    this.getEventReportUtil(EventName.CLICK_TIMER_RESET);
    this.timerTimeout = -1;
    clearTimeout(this.timerTimeout);
    WantAgentUtil.triggerCloseTimer(TIMER_NOTICE_ID);
    this.IsTimerRunFunc('destroy')
  }

  private async onTimerToggled(entry?: string) {
    this.reset = false;
    this.isTimerRunning = false;
    this.pauseAnimation();
    if (this.started) {

      if (this.paused) {
        this.isTimerRunning = true;
        this.IsTimerRunFunc('storedValue_and_create')
        this.paused = false;
        this.playAnimation();
        this.refreshTime()
        if (entry) {
          !this.isPageHide && this.playTick();
          this.isPageHide && (this.isTickPlaying = true)
        } else {
          this.playTick();
        }
        LogUtil.info(TAG, 'continue==>');
        this.getEventReportUtil('TIMER_COUNTDOWN_BANNER');
        if (this.deviceType !== '2in1') {
          WantAgentUtil.triggerStartTimer(
            TIMER_NOTICE_ID,
            Number(await timerPreferencesManagerUtil.getKey(TOTAL_TIME_TIMER_PREFERENCES_CLOCK)) -
            Number(await timerPreferencesManagerUtil.getKey(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK))
          );
        }
        this.getEventReportUtil(EventName.CLICK_START_TIMER, this.totalTime);
      } else {
        this.isTimerRunning = false;
        this.IsTimerRunFunc('storedValue_and_destory')
        this.paused = true;
        this.pauseAnimation()
        if (this.alarm) {
          AlarmManager.removeAlarm(this.alarm);
        }
        if (entry) {
          !this.isPageHide && this.stopTick();
          this.isPageHide && (this.isTickPlaying = false)
        } else {
          this.stopTick();
        }
        LogUtil.info(TAG, 'paused==>')
        this.getEventReportUtil('TIMER_PAUSE_BANNER');
        this.timeOutFlag = false;
        if (this.deviceType !== '2in1') {
          WantAgentUtil.triggerPauseTimer(
            TIMER_NOTICE_ID,
            Number(await timerPreferencesManagerUtil.getKey(TOTAL_TIME_TIMER_PREFERENCES_CLOCK)) -
            Number(await timerPreferencesManagerUtil.getKey(PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK))
          );
        }
        this.getEventReportUtil(EventName.CLICK_TIMER_PAUSE);
      }
    } else if (this.totalTime > 0) {
      const isScreenLocked: boolean = await screenLock.isScreenLocked();
      LogUtil.info('isScreenLocked_play,isPageHide=' + this.isPageHide);
      this.started = true;
      this.paused = false;
      this.timeLeft = this.totalTime;
      LogUtil.info(TAG, `${this.timeLeft}"aaaaaaaa==>"this.passedtime=${this.passedTime}`);
      !isScreenLocked && !this.isPageHide && this.playTick();
      this.screenFull && (this.isTickPlaying = true) && (this.screenFull = false);
      this.isTimerRunning = true;
      this.IsTimerRunFunc('storedValue_and_create');
      this.playAnimation();
      LogUtil.info(TAG, 'started==>init');
      this.getEventReportUtil('TIMER_COUNTDOWN_BANNER');
      this.getEventReportUtil(EventName.CLICK_START_TIMER, this.totalTime);
      this.refreshTime();
      if (this.deviceType !== '2in1') {
        WantAgentUtil.triggerStartTimer(TIMER_NOTICE_ID, this.timeLeft);
      }
    }
  }

  private getEventReportUtil(EVENT_NAME: string, timer?: number): void {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EVENT_NAME, timer);
  }

  private isTickPlayingChanged() {
    this.isTimerRunning = this.isTickPlaying
  }

  private onTinkleChange() {
    this.getEventReportUtil(EventName.CLICK_TIMER_MUSIC);
    return
    // TODO
    this.pageInfos.pushPath(new NavPathInfo(RINGTONE_SELECTION, {
      isTimerRingtone: true,
      onRingtoneSelected: (path: string) => {
        LogUtil.info(TAG, 'New timer ringtone = ' + path);
      }
    } as PageInfos))
  }

  // 初始化动画
  private initAnimation() {
    // if (!this.started) {
    //   this.pauseAnimation();
    // } else if (!this.paused) {
    //   this.playAnimation();
    // } else {
    //   this.pauseAnimation();
    // }
    // if (this.animateItem != null) {
    //   this.animateItem.destroy()
    //   this.animateItem = null
    // }
    // this.currentAnimateName = 'pauseTimer';
    // this.animateItem = lottie.loadAnimation({
    //   container: this.controller,
    //   renderer: 'canvas',
    //   loop: false,
    //   autoplay: false,
    //   name: this.timerCanvasAnimateName,
    //   path: this.canvasAnimatePath
    // })
  }

  // 初始动画
  private initPauseAnimation() {
    // if (this.animateItem != null) {
    //   this.animateItem.destroy()
    //   this.animateItem = null
    // }
    // this.currentAnimateName = 'playTimer';
    // this.animateItem = lottie.loadAnimation({
    //   container: this.controller,
    //   renderer: 'canvas',
    //   loop: false,
    //   autoplay: false,
    //   name: this.canvasTimerPauseAnimateName,
    //   path: this.canvasTimerPauseAnimatePath
    // })
  }

  // 暂停到开始动画
  private playAnimation() {
    // lottie.setDirection(this.currentAnimateName == 'pauseTimer' ? 1 : -1, this.getCurrentCanvasName());
    // lottie.play(this.getCurrentCanvasName());
  }

  // 开始到暂停动画
  private pauseAnimation() {
    // lottie.setDirection(this.currentAnimateName == 'pauseTimer' ? -1 : 1, this.getCurrentCanvasName());
    // lottie.play(this.getCurrentCanvasName());
  }

  getCurrentCanvasName(): string {
    return this.currentAnimateName == 'pauseTimer' ? this.timerCanvasAnimateName : this.canvasTimerPauseAnimateName
  }

  getDeviceRatio(): number {
    if (this.isPCLg()) {
      return SPECAIL_CLOCK_TIMER_NORMAL_CUSTOM
    }
    if (this.foldAbleScreen === 1) {
      return this.getOrientaion === this.isFoldCross ? SCALE_DIAMETER_RATIO : FOLDSCREEN_CLOCK_TIMER_NORMAL_CUSTOM
    } else {
      return this.isPortraitOrientation ? SCALE_DIAMETER_RATIO : SPECAIL_CLOCK_TIMER_NORMAL_CUSTOM
    }
  }

  getTimerPadding(): Padding {
    if (this.isPCLg()) {
      return {}
    }
    if (this.foldAbleScreen === 1) {
      return {
        top: $r('app.float.timer_clock_padding_19')
      }
    } else if (this.foldAbleScreen === 2) {
      return {
        top: $r('app.float.timer_clock_padding_17')
      }
    } else {
      return this.isPortraitOrientation ? { top: $r('app.float.timer_picker_portrait_top_margin_18') } : {
        right: $r('app.float.timer_picker_portrait_top_margin_48')
      }
    }
  }

  @Builder
  buildAnalogTimer(): void {
    Row() {
      AnalogTimer({
        getOrientaion: this.getOrientaion,
        isPortraitOrientation: this.isPortraitOrientation,
        scaleDiameterRatio: this.getDeviceRatio(),
        diameter: this.diameter,
        timeLeft: this.timeLeft,
        totalTime: this.totalTime,
        reset: this.reset,
        passedTime: this.passedTime
      })
    }
    .transition(TransitionEffect.opacity(1))
    .justifyContent(FlexAlign.Center)
    .visibility(this.isTimerVisible ? Visibility.Visible : Visibility.Hidden)
    .width('100%')
    .padding(this.getTimerPadding())
    .margin(this.isPCLg() ? {} : (this.foldAbleScreen === 1 ?
      {
        top: $r('app.float.stack_timer_picker_padding_fold_32'),
        bottom: $r('app.float.stack_timer_picker_padding_fold_18')
      } :
      {
        top: this.isPortraitOrientation ? $r('app.float.stack_timer_picker_padding_fold_32') :
        $r('app.float.stack_timer_picker_padding_top_25'),
        bottom: this.isPortraitOrientation ? $r('app.float.stack_timer_picker_padding_bottom_3') : 0
      }
    ))
  }

  @Styles
  pressedButtonStyle() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  @Builder
  buildButtons() {
    Flex({
      direction: this.isPCLg() ? FlexDirection.Column : FlexDirection.Row,
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      FloatingActionButton({
        src: $r('app.media.ic_reset'),
        colorSchemeName: FloatingActionButtonColor.WHITE,
        playButton: false,
        onButtonClick: (): void => this.resetTimer(),
        isEnabled: this.totalTime > 0 && !this.timeOutFlag
      })
        .transition(TransitionEffect.opacity(1))
        .visibility(this.isTimerVisible ? Visibility.Visible : Visibility.Hidden)

      Stack() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Canvas(this.controller)
            .draggable(false)
            .borderRadius($r('app.float.canvas_border_radius'))
            .width($r('app.float.canvas_size'))
            .height($r('app.float.canvas_size'))
            .onReady(() => {
              if (this.isTimerRunning) {
                this.initPauseAnimation();
              } else {
                this.initAnimation();
              }
            })
            .onDisAppear(() => {
              LogUtil.info(TAG, `canvas onDisAppear...`);
            })
            .onClick(() => {
              LogUtil.info(TAG, 'canvas click.')
              if (this.totalTime > 0 && !this.timeOutFlag) {
                this.onTimerToggled();
              }
            })
        }
        .id('id_add_button')
        .backgroundColor($r('sys.color.ohos_id_container_color_active'))
        .width($r('app.float.pc_add_button_size'))
        .height($r('app.float.pc_add_button_size'))
        .opacity(this.canvasOpacity)
        .stateStyles({
          pressed: this.pressedButtonStyle,
        })
        .shadow(this.canvasOpacity === 1 ? {
          radius: $r('app.float.button_shadow_radius'),
          color: CommonUtil.changeShadowColor($r('sys.color.ohos_id_container_color_active')),
          offsetX: 0,
          offsetY: $r('app.float.button_shadow_y2'),
        } : { radius: 0 })

        if (this.isPCLg() && this.canvasOpacity === 1) {
          Button({ type: ButtonType.Circle, stateEffect: true })
            .opacity(0)
            .width($r('app.float.pc_add_button_size'))
            .height($r('app.float.pc_add_button_size'))
            .onClick(() => {
              if (this.totalTime > 0 && !this.timeOutFlag) {
                this.onTimerToggled();
              }
            })
            .onFocus(() => {
              this.selfFocus = true
            })
            .onBlur(() => {
              this.selfFocus = false
            })
        }
      }
      .padding('2vp')
      .border(this.isPCLg() ? {
        width: '2vp',
        color: this.selfFocus ? $r('sys.color.ohos_id_icon_color_active') : Color.Transparent,
        radius: 32
      } : {})
      .width('64vp')
      .offset({
        x: 0
      })

      // FloatingActionButton({
      //   src: $r('app.media.ic_ringtone'),
      //   colorSchemeName: FloatingActionButtonColor.WHITE,
      //   playButton: false,
      //   isEnabled: false,
      //   onButtonClick: (): void => this.onTinkleChange()
      // })
      //   .transition(TransitionEffect.opacity(1))
      //   .visibility(this.isTimerVisible ? Visibility.Visible : Visibility.Hidden)
    }
    .borderRadius($r('app.float.timer_bottom_borderRadius'))
    .backgroundColor(Color.Transparent)
    .padding({
      left: this.isPCLg() ? '' : $r('app.float.timer_bottom_padding'),
      right: this.isPCLg() ? '' : $r('app.float.timer_bottom_padding'),
      top: this.isPCLg() ? $r('app.float.timer_bottom_padding') : 0,
      bottom: this.isPCLg() ? $r('app.float.timer_bottom_padding') : 0
    })
    .width(this.isPCLg() ? $r('app.float.timer_button_width') : $r('app.float.timer_bottom_width'))
    .height(this.isPCLg() ? $r('app.float.timer_bottom_width') : $r('app.float.timer_button_width'))
    .margin({
      bottom: this.isPCLg() ? '' : $r('app.float.timer_bottom_margin_bottom')
    })
  }

  @Builder
  buildTimerText() {
    Column() {
      Text(`${this.changeShowTime().hours}:${this.changeShowTime().minutes}:${this.changeShowTime().seconds}`)
        .lineHeight(
          this.isPCLg() ? $r('app.float.timer_PC_text_line_height')
            : (this.isPortraitOrientation || this.foldAbleScreen === 1
            ? $r('app.float.line_height_56')
            : $r('app.float.line_height_26')))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(
          this.isPCLg() ? $r('app.float.timer_PC_text_size') :
            (this.isPortraitOrientation || this.foldAbleScreen === 1
              ? $r('app.float.size42')
              : $r('app.float.size20')
            ))
        .fontWeight(FontWeight.Medium)
        .height(this.isPCLg() || this.isPortraitOrientation ? $r('app.float.timer_PC_text_line_height') : '')
    }
    .padding({
      bottom: this.isPortraitOrientation || this.foldAbleScreen === 1 && !this.isPCLg() ?
      $r('app.float.padding_bottom_4') : '',
    })
    .width('100%')
    .justifyContent(this.isPCLg() ? FlexAlign.Start : FlexAlign.Center)
    .height(
      this.isPCLg() ? $r('app.float.timer_Hints_High') : (this.isPortraitOrientation || this.foldAbleScreen === 1
        ? $r('app.float.build_text_height_108') : ''))
    .margin({
      top: this.isPCLg() ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? '' : '-1vp'),
      right: this.isPortraitOrientation || this.foldAbleScreen === 1 || this.isPCLg() ? '0' :
      $r('app.float.timer_picker_portrait_top_margin_48'),
    })
    .visibility(this.isPCLg() ? Visibility.Visible : this.foldAbleScreen === 1 ?
      (((this.started || !this.isPortraitOrientation) || this.timeOutFlag) && this.isTimerVisible) ?
        this.foldAbleScreen === 1 && this.started || this.timeOutFlag ?
        Visibility.Visible : Visibility.None : Visibility.None : (((this.started ||
        !this.isPortraitOrientation) || this.timeOutFlag) && this.isTimerVisible) ?
      Visibility.Visible : Visibility.None
    )
  }

  @Builder
  buildPicker() {
    Row() {
      TimerPicker({
        planHours: $hours,
        planMinutes: $minutes,
        planSeconds: $seconds,
        time: $totalTime,
        isPortraitOrientation: $isPortraitOrientation,
        isMdView: this.isBigView === BreakPoint.MD,
        isTabIndexChange: this.isTimerVisible
      })
        .visibility(this.isTimerVisible ? Visibility.Visible : Visibility.Hidden)
    }
    .alignItems(this.isPortraitOrientation || this.foldAbleScreen === 1 ? VerticalAlign.Center : VerticalAlign.Top)
    .visibility((this.started || this.timeOutFlag) || this.isRepeatTiming ? Visibility.None : Visibility.Visible)
    .margin({ top: this.foldAbleScreen === 1 && this.getOrientaion === this.isFoldVertical ? '-16vp' : '0', })
  }

  @Builder
  buildTimerStack() {
    Stack({
      alignContent: Alignment.Center
    }) {
      if (this.isPortraitOrientation || this.foldAbleScreen === 1) {
        this.buildTimerText();
      }
      if (!this.started && !this.timeOutFlag) {
        this.buildPicker();
      }
    }
    .height(this.isPortraitOrientation || this.foldAbleScreen === 1 ? '210vp' : '')
  }

  @Builder
  buildPC() {
    Row() {
      // 时钟
      Column() {
        // this.buildAnalogTimer();
        this.buildTimerText();
      }
      .width(this.started ? '100%' : `calc(100% - 40% - 268vp)`)
      .margin({ left: this.started ? 0 : $r('app.float.timer_PC_main_padding_left') })
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Column() {
        TimerPickerForPC({
          time: $totalTime,
          scaleDiameterRatio: this.isPortraitOrientation ? SCALE_DIAMETER_RATIO : CLOCK_RATIO_FOR_NORMAL_CUSTOM,
          diameter: this.diameter,
          totalTime: this.totalTime
        })
          .visibility(this.started ? Visibility.None : Visibility.Visible)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: $r('app.float.timer_PC_main_padding_right') })
      .width(this.started ? $r('app.float.timer_PC_time_picker_defalut_min_width') : '40%')
      .height('100%')

      // 按钮
      if (this.isTimerVisible) {
        Column() {
          this.buildButtons()
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({
          right: $r('app.float.timer_PC_main_padding_right'),
          left: this.started ? $r('app.float.timer_PC_main_margin_left') : 0
        })
      }
    }
    .height('100%')
  }

  @Builder
  buildPortrait() { // 纵向
    Flex({
      direction: this.isPortraitOrientation || this.foldAbleScreen === 1 ? FlexDirection.Column : FlexDirection.Row,
      alignItems: ItemAlign.Center
    }) {
      // 计时器表盘
      Column() {
        // this.buildAnalogTimer();
        if (!this.isPortraitOrientation && this.foldAbleScreen !== 1) {
          this.buildTimerText();
        }
      }
      .flexShrink(0)
      .width(this.isPortraitOrientation || this.foldAbleScreen === 1 ? '' : '40%')

      Rect()
        .fill($r('sys.color.ohos_id_color_list_separator'))
        .width('1px')
        .height($r('app.float.line_height'))
        .margin({ left: '-1vp' })
        .visibility(this.isPortraitOrientation || this.foldAbleScreen === 1 ? Visibility.None : Visibility.Visible)

      // 时间拨盘和按钮
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center
      }) {
        Row() {
          this.buildTimerStack();
        }
        .margin(this.getTimerStack())

        Row() {
          if (this.isTimerVisible) {
            this.buildButtons();
          }
        }
      }
      .width(this.isPortraitOrientation || this.foldAbleScreen === 1 ? '100%' : '60%')
      .padding(this.isPortraitOrientation || this.foldAbleScreen === 1 ? {} : {
        left: $r('app.float.stack_timer_picker_padding_top_48')
      })
      .height(this.isPortraitOrientation || this.foldAbleScreen === 1 ? '350vp' : '100%')
      .flexGrow(this.isPortraitOrientation || this.foldAbleScreen === 1 ? 1 : 2)
    }
    .width('100%')
    .padding(this.foldAbleScreen === 1 ? {
      left: $r('app.float.timer_fold_padding_vertical'),
      right: $r('app.float.timer_fold_padding_vertical')
    } : {
      left: this.isPortraitOrientation ? $r('app.float.timer_picker_padding_vertical') : $r('app.float.timer_picker_portrait_top_margin_48'),
      right: this.isPortraitOrientation ? $r('app.float.timer_picker_padding_vertical') : $r('app.float.timer_picker_portrait_top_margin_48')
    })
  }

  getTimerStack(): Margin {
    if (this.deviceType === 'tablet' && !this.isPortraitOrientation) {
      return {
        top: '25%'
      }
    } else if (this.isPCLg()) {
      return {}
    }
    if (this.foldAbleScreen === 1) {
      return { top: $r('app.float.timer_stack_margin_11') }

    } else if (this.foldAbleScreen === 2) {
      return { top: $r('app.float.timer_stack_margin_42') }
    } else {
      return this.isPortraitOrientation ? { top: $r('app.float.timer_stack_margin_28') } : { top: '' }
    }
  }

  @Builder
  buildLandscape() { // 横向
    Row() {
      Column() {
        // this.buildAnalogTimer();
        this.buildTimerText();
      }
      .width('40%')

      Rect()
        .fill($r('sys.color.comp_divider'))
        .width('1px')
        .height($r('app.float.line_height'))
        .margin({ left: $r('app.float.rect_margin_left') })

      Stack({ alignContent: Alignment.Bottom }) {
        this.buildPicker();
        this.buildButtons();
      }
      .width('60%')
      .height('100%')
    }
    .width('100%')
  }

  build() {
    if (this.isPCLg()) {
      // PC
      this.buildPC()
    } else {
      // 移动
      this.buildPortrait();
    }
  }
}