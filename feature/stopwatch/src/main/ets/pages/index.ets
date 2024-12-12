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
  Card,
  CommonGrid,
  FloatingActionButton,
  FloatingActionButtonColor,
  LogUtil,
  SPECAIL_CLOCK_RATIO_FOR_NORMAL_CUSTOM,
  BreakPoint,
  EventReportUtil,
  EventName,
  GlobalContext,
  FROM_DATA_STORE,
  STOP_WATCH_DATA_STORE,
  SoundPool,
  CommonUtil,
  EVENT_ID_SEND_ALARM
} from '@hmos/common';
// import hiSysEvent from '@ohos.hiSysEvent';
import { StopwatchDial } from '../components';
import preferencesUtil from '@ohos.data.preferences';
import device, { DeviceResponse } from '@system.device'
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import {
  VERTICAL_HEIGHT,
  CROSS_HEIGHT,
  PC_HEIGHT,
  COMMEN_X,
  VERTICAL_Y,
  COMMEN_Z,
  COMMEN_Y,
  COMMEN_HEIGHT,
  ADD_HEIGHT,
  INIT_VERHEIGHT,
  ADD_VERHEIGHT,
  FRIST_H,
  SECOND_H,
  THIRD_H,
  FOURTH_H,
  FIVE_H,
  SIX_H,
  RESTRICT,
  STOPTIME,
  RESTRICT_MAXTIME,
  BREAKLG,
  RESTRICT_HEIGHT,
  BREAKLG_HEIGHT,
  FLOD_ALL_HEIGHT,
  VERTICAL_OHOS_HEIGHT,
  FLOD_CROSS_HEIGHT,
  FLOD_VERTICAL_HEIGHT_SECOND,
  PRIVATE_FIRST_HEIGHT,
  PRIVATE_SECOND_HEIGHT,
  DEFAULT_HEIGHT
} from './types'
import promptAction from '@ohos.promptAction'
import curves from '@ohos.curves';
import lottie, { AnimationItem } from '../../../../../../common/oh_modules/@ohos/lottie';
import deviceInfo from '@ohos.deviceInfo'
import emitter from '@ohos.events.emitter';

/**
 * Main page for stopwatch
 *
 * @since 2023-08-15
 */
const TAG: string = 'Stopwatch---';
const CLOCK_DIAL_AREA_OFFSET = 340;
const TICK_FILE_NAME = 'stopwatch_tick.wav';
const LAP_FILE_NAME = 'stopwatch_lap.wav';
const SCALE_DIAMETER_RATIO = 0.94;
const FOLD_SCREEN_DIAMETER_RATIO = 0.85;

interface LapItem {
  index: number;
  fromPrevLapTime: number;
  totalTime: number;
}

interface ReportParams {
  PACKAGE_NAME: string;
  PROCESS_NAME: string;
  RESULT: string;
  VALUE?: string;
  STATUS?: string
}

interface OffsetNum {
  yOffset: number
}

interface ITranslateList {
  x: number,
  y: number,
  z: number
}


@Component
export struct Stopwatch {
  @StorageProp('currentAbleScreen') @Watch('listenFoldScreen') foldAbleScreen: number = 0;
  @Prop @Watch('listenProationChangeg') isPortraitOrientation: boolean = true;
  @Prop @Watch('pageVisibilityChanged') isStopwatchVisible: boolean = true;
  @StorageProp('setOrientaion') @Watch('listenOrientaion') getOrientaion: number = 0;
  @Prop currentIndex: number = 0
  @Prop @Watch('onPageToggle') isPageHide: boolean = true;
  @Prop isBigView: string = ''
  @State translateList: ITranslateList = { x: 0, y: 0, z: 0 };
  @Link isClockHide: boolean;
  @State iHeight: number = 0;
  @State playTimer: number = 0;
  @State @Watch('listenStopwatchRunning') private isStopwatchRunning: boolean = false;
  @State @Watch('stopTimesShow') private passedTime: number = 0;
  @State private passedFromLastLapTime: number = 0;
  @State private lastLapTime: number = 0;
  @State private pauseTime: number = 0;
  @State private interValFq: number = 90; //计时器频率ms
  @State private interValCount: number = 0; //计时器计次数
  @State private laps: LapItem[] = [];
  @State private maxNum: number = 0;
  @State private minNum: number = 0;
  @State private listItemTranslateY: string = '-95vp';
  @State deviceType: string = deviceInfo.deviceType; // 设备类型
  @State recorDing: boolean = false
  @State selfFocus: boolean = false;
  private startTime: number = 0;
  private dateToFormat: Date = new Date();
  private scrollerForScroll: Scroller = new Scroller();
  private textFoldVerticalPadding: number = 54;
  private textFoldCrossPadding: number = 62.5;
  private titletoppadding: number = 60.5;
  private initStopTime: string = '';
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private controller: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // 动画名称
  private canvasAnimateName: string = 'stopWatchPlayAnimate';
  private canvasPauseAnimateName: string = 'stopWatchPauseAnimate';
  private currentAnimateName: string = 'pause';
  // 动画json
  private canvasAnimatePath: string = 'resources/rawfile/playToPause.json';
  private canvasPauseAnimatePath: string = 'resources/rawfile/pauseToPlay.json';
  private animateItem: AnimationItem | null = null;
  private isDeviceModels: string = 'NOH-AN00'
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  private setCode: boolean = false;
  private isFoldHeight: number = 485;
  @State windowClass: window.Window | undefined = AppStorage.Get<window.Window>('mainWindow')
  private timerTimeout: number = -1;

  listenStopwatchRunning() {
    if (this.isStopwatchRunning) {
      this.initPauseAnimation();
    } else {
      this.initAnimation();
    }
  }

  aboutToAppear() {
    this.listeningAlarm()
    // 获取设备类型
    this.deviceType = deviceInfo.deviceType
  }

  private isPCLg() {
    return this.deviceType === '2in1'
  }

  aboutToDisappear() {
    LogUtil.info(TAG, 'aboutToDisPage');
  }

  private listeningAlarm() {
    emitter.on({ eventId: EVENT_ID_SEND_ALARM }, async (target) => {
      if (this.isStopwatchRunning) {
        if (target.data?.toggle === 'show') {
          await SoundPool.stopForPageHide('stopwatch')
        }
        if (target.data?.toggle === 'hide' && this.currentIndex === 2 && !this.isPageHide) {
          await SoundPool.playSoundPool('stopwatch')
        }
      }
    });
  }

  async onPageToggle(): Promise<void> {
    if (this.isStopwatchRunning) {
      if (this.isPageHide) {
        await SoundPool.stopForPageHide('stopwatch')
        this.setWindowKeepScreenOn(false)
      } else {
        const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
          .getObject('clockContext') as Context, FROM_DATA_STORE);
        const ALARM_ACTIVE = await preferences.get('ALARM_CLOCK_TAB', '');
        LogUtil.info(TAG, `on page show ALARM_ACTIVE=${ALARM_ACTIVE}`);
        if (ALARM_ACTIVE) {
          await SoundPool.stopForPageHide('stopwatch')
        } else {
          if (this.currentIndex == 2) {
            SoundPool.playStopwatchForDelay()
          }
        }
        this.setWindowKeepScreenOn(true)
      }
    } else {
      this.setWindowKeepScreenOn(false)
    }
  }

  // CALC LIST HEIGHT
  public changeIheight(count: number, code?: boolean) {
    switch (count) {
      case 1: {
        this.iHeight = FRIST_H;
        break;
      }
      case 2: {
        this.iHeight = SECOND_H;
        break;
      }
      case 3: {
        this.iHeight = THIRD_H;
        break;
      }
      case 4: {
        this.iHeight = FOURTH_H;
        break;
      }
      case 5: {
        this.iHeight = FIVE_H;
        break;
      }
      case 6: {
        this.iHeight = SIX_H;
        break;
      }
      default: {
        if (this.foldAbleScreen === 1) {
          this.getFoldHeight(code);
        } else {
          if (this.isDeviceModels === 'ALT-AL10') {
            this.iHeight = this.isFoldHeight;
          } else {
            this.iHeight = this.isDeviceModels !== 'NOH-AN00' ? VERTICAL_OHOS_HEIGHT : VERTICAL_HEIGHT;
          }
        }
        break;
      }
    }
  }

  /**
   * Do not modify the folding method
   */
  private getFoldHeight(code?: boolean) {
    if (code) {
      this.setCode = true
    }
    if (this.getOrientaion === this.isFoldCross) {
      this.iHeight = (code ? code : this.setCode) ? FLOD_VERTICAL_HEIGHT_SECOND : FLOD_VERTICAL_HEIGHT_SECOND

    } else {
      this.iHeight = (code ? code : this.setCode) ? FLOD_CROSS_HEIGHT : PRIVATE_SECOND_HEIGHT
    }
  }

  private onScroll(yOffset: number | string): void {

    if (this.deviceType === 'tablet' && this.isPortraitOrientation) {
    }
    if (yOffset > 0 && this.isClockHide || yOffset < 0 && !this.isClockHide) {
      return;
    }
    const offset = this.scrollerForScroll.currentOffset();
    if (this.deviceType !== 'tablet') {
      if (this.laps.length >= 1) {
        if (!this.isPortraitOrientation) {
          this.scrollerForScroll.scrollTo({ xOffset: 0, yOffset: 0 })
        } else {
          this.scrollerForScroll.scrollTo({ xOffset: 0, yOffset: 0 })
        }
      }
    }

    if (offset.yOffset > CLOCK_DIAL_AREA_OFFSET) {
      this.isClockHide = true;
    } else {
      this.isClockHide = false;
    }
  }

  private stopTimesShow() {
    if (this.passedTime >= STOPTIME) {
      this.initStopTime = RESTRICT_MAXTIME
      this.onStopwatchToggled(false)
    }
  }

  private listenProationChangeg() {
    if (this.foldAbleScreen === 1) {
      return;
    }
    if (!this.isPortraitOrientation) {
      this.listenUpdateCrossScreen()
    } else {
      this.listenUpdateVertaivalScreen()
    }
  }

  // listen foldScreen
  private listenFoldScreen() {
    if (this.foldAbleScreen === 1) {
      this.listenUpdateVertaivalScreen(true)
    } else {
      this.listenUpdateVertaivalScreen()
    }
  }

  private listenOrientaion() {
    if (this.foldAbleScreen === 1) {
      this.listenUpdateVertaivalScreen()
    }
  }

  private listenUpdateCrossScreen() {
    if (this.laps.length === 1) {
      this.iHeight = FRIST_H
    } else if (this.laps.length === 2) {
      this.iHeight = SECOND_H;
    } else if (this.laps.length === 3) {
      this.iHeight = THIRD_H;
    } else {
      this.iHeight = this.laps.length === 0 ? COMMEN_HEIGHT : CROSS_HEIGHT;
    }
    this.scrollerForScroll.scrollTo({ xOffset: 0, yOffset: 0 })
  }

  private listenUpdateVertaivalScreen(code?: boolean) {
    if (this.laps.length === 0) {
      this.titletoppadding = 60.5
      if (this.foldAbleScreen === 1) {
        this.textFoldCrossPadding = 62.5
      } else if (this.foldAbleScreen === 2) {
        this.textFoldVerticalPadding = 54
      }
    }
    if (this.laps.length >= 1) {
      this.titletoppadding = 0
      this.textFoldVerticalPadding = 0
      this.textFoldCrossPadding = 0
      this.changeIheight(this.laps.length, code)
    } else {
      this.iHeight = this.foldAbleScreen === 1 ? COMMEN_HEIGHT : COMMEN_HEIGHT;
    }

    this.scrollerForScroll.scrollTo({ xOffset: 0, yOffset: 0 })
  }

  //页面进入获取缓存秒表数据
  private async getStopWatchData() {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, STOP_WATCH_DATA_STORE);
    let timeToLeave = await preferences.get('timeToLeave', '');
    let nowDate = new Date().getTime();
    let timeDiff = nowDate - Number(timeToLeave);
    this.interValCount = this.interValCount + (timeDiff / this.interValFq);
  }

  //页面离开缓存秒表数据
  private async cacheStopWatchData() {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, STOP_WATCH_DATA_STORE);
    await preferences.put('timeToLeave', new Date().getTime());
    await preferences.flush()
  }

  private async pageVisibilityChanged() {
    LogUtil.info(TAG, 'soundPool---isStopwatchVisible=' + this.isStopwatchVisible + ',this.isStopwatchVisible=' + `Stopwatch page visibility changed to ${this.isStopwatchVisible}`);
    this.isStopwatchRunning ? this.setWindowKeepScreenOn(true) : this.setWindowKeepScreenOn(false)
    this.setWindowKeepScreenOn(true)
    if (this.isStopwatchVisible && this.isStopwatchRunning) {
      SoundPool.playSoundPool('stopwatch');
      this.getStopWatchData();
      this.refreshTime();
    } else if (!this.isStopwatchVisible) {
      LogUtil.info(TAG, 'soundPool---!isStopwatchVisible=' + !this.isStopwatchVisible + ',this.isStopwatchVisible=' + this.isStopwatchVisible)
      SoundPool.stopForPageHide('stopwatch');
      this.cacheStopWatchData();

    }

  }

  private setWindowKeepScreenOn(flag: boolean) {
    try {
      if (this.windowClass) {
        this.windowClass.setWindowKeepScreenOn(flag, (err: BusinessError) => {
          const errCode: number = err.code;
          if (errCode) {
            LogUtil.error(TAG, 'Failed to set the screen to be always on. Cause: ' + JSON.stringify(err));
            return;
          }
          LogUtil.info(TAG, 'Succeeded in setting the screen to be always on.');
        });
      }
    } catch (exception) {
      LogUtil.error(TAG, 'Failed to set the screen to be always on. Cause: ' + JSON.stringify(exception));
    }
  }

  private async onStopwatchToggled(running: boolean) {
    device.getInfo({
      success: (ret: DeviceResponse) => {
        const modelProduct = ret.model
        this.isDeviceModels = modelProduct
      }
    })
    if (this.isStopwatchRunning == running) {
      return;
    }
    if (this.initStopTime === RESTRICT_MAXTIME) {
      this.isStopwatchRunning = false
    } else {
      this.isStopwatchRunning = running;
    }

    if (this.isStopwatchRunning) {
      this.playAnimation();
      SoundPool.playSoundPool('stopwatch')
      this.setWindowKeepScreenOn(true)
      if (this.startTime == 0) {
        this.startTime = Date.now();
      } else {
        this.startTime = this.startTime;
      }
      this.refreshTime();
      this.getEventReportUtil(EventName.CLICK_START_STOPWATCH);
    } else {
      SoundPool.stopForPageHide('stopwatch');
      this.setWindowKeepScreenOn(false)
      this.pauseTime = this.startTime;
      this.getEventReportUtil(EventName.CLICK_STOPWATCH_PAUSE);
      this.pauseAnimation();
    }
  }

  private timer(localTime: number): void {
    clearTimeout(this.timerTimeout);
    this.timerTimeout = -1;
    const now = new Date().getTime(); // 获取当前本地时间
    const timeGap = now - localTime; // 计算时间差
    //下一次计时器应该触发的时间
    const nextTickTime = this.interValFq - (timeGap % this.interValFq);
    if (this.isStopwatchRunning && this.isStopwatchVisible) {
      this.timerTimeout = setTimeout(() => {
        this.interValCount++;
        this.passedTime = this.interValFq * this.interValCount;
        this.passedFromLastLapTime = this.passedTime - this.lastLapTime;
        LogUtil.info(TAG, `passedTime=${this.passedTime}`)
        this.timer(localTime); // 递归调用,实现循环
      }, nextTickTime);
    }
  }

  private refreshTime(): void {
    let localTime = new Date().getTime(); //记录本地时间
    this.timer(localTime); // 启动计时器
  }

  // 秒表重置
  private resetStopwatch() {
    this.recorDing = false
    LogUtil.info(TAG, `Stopwatch reset`);
    this.onStopwatchToggled(false);
    this.listItemTranslateY = '0vp';
    this.initStopTime = '';
    this.startTime = 0;
    this.passedTime = 0;
    this.interValCount = 0;
    this.lastLapTime = 0;
    this.pauseTime = 0;
    this.laps = [];
    if (this.isPortraitOrientation || this.foldAbleScreen === 1) {
      this.titletoppadding = 60.5;
      this.textFoldVerticalPadding = 54;
      this.textFoldCrossPadding = 62.5;
    } else {
      this.titletoppadding = 0
      this.textFoldVerticalPadding = 0
      this.textFoldCrossPadding = 0
    }
    // 重置表盘下移动画
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 131, 18),
      delay: 300,
      onFinish: () => {
        this.passedFromLastLapTime = 0;
      }
    }, () => {
      this.listItemTranslateY = '-95vp';

      if (!this.isPortraitOrientation) {

        this.iHeight = this.foldAbleScreen === 1 ? COMMEN_HEIGHT : COMMEN_HEIGHT;
      } else {
        // Iheight no update
        this.iHeight = this.foldAbleScreen === 1 ? COMMEN_HEIGHT : COMMEN_HEIGHT;
      }

    })

    this.getEventReportUtil(EventName.CLICK_STOPWATCH_RESET)
  }

  private getEventReportUtil(eventName: string): void {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, eventName);
  }

  private formatTimeString(time: number): string {
    this.dateToFormat.setTime(time);
    let hours = (this.dateToFormat.getUTCDate() - 1) * 24 + this.dateToFormat.getUTCHours();
    if (this.dateToFormat.toISOString().slice(14, 22) === RESTRICT_MAXTIME) {
      this.initStopTime = RESTRICT_MAXTIME
      this.onStopwatchToggled(false)
    }
    return this.passedTime / 1000 / 60 / 60 > 1 ? this.dateToFormat.toISOString()
      .slice(11, 22) : this.dateToFormat.toISOString().slice(14, 22)
  }

  testPlayAudio() {

  }

  private addLap() {
    // 计次声音
    SoundPool.playForRepeat()
    this.recorDing = true
    // 秒表计次
    if (this.laps.length >= 99) {
      return promptAction.showToast({
        message: $r('app.string.tips_title'), // 显示文本
        duration: 2000, // 显示时长
        bottom: null // 距离底部的距离
      })
    }
    LogUtil.info(TAG, `Stopwatch lap added at ${this.passedTime}`);
    if (this.laps == null) {
      this.laps = [];
    }
    let littleTime = Math.max((new Date().getTime() - this.startTime) % this.interValFq, 0);
    let time = this.passedTime + Math.floor(littleTime / 10) * 10;
    // 计次卡片出现动画
    animateTo({
      delay: 150,
      curve: curves.interpolatingSpring(0, 1, 131, 23),
      onFinish: () => {
      }
    }, () => {
      this.laps.unshift({
        index: this.laps.length + 1,
        fromPrevLapTime: time - this.lastLapTime,
        totalTime: time
      })
    })
    if (this.laps.length > 1) {
      const list: LapItem[] = JSON.parse(JSON.stringify(this.laps))
      const small: LapItem[] = JSON.parse(JSON.stringify(this.laps))
      list.sort((a, b) => {
        return a.fromPrevLapTime - b.fromPrevLapTime
      })
      small.sort((a, b) => {
        return b.fromPrevLapTime - a.fromPrevLapTime
      })
      this.minNum = list[0].fromPrevLapTime;
      this.maxNum = small[0].fromPrevLapTime;
    }
    // 卡片透明度动画
    animateTo(
      {
        duration: 150,
        curve: curves.interpolatingSpring(0, 1, 131, 23),
        playMode: PlayMode.Normal,
        onFinish: () => {
        }
      }, () => {
      if (!this.isPortraitOrientation) {
        if (this.foldAbleScreen === 1) {
          this.titletoppadding = 0
        }
        if (this.foldAbleScreen === 1) {
          this.calcDefaultScreenVetacial()
        } else {
          this.calcDefaultScreenCross()
        }
      } else if (this.deviceType === 'tablet') {
        this.calcDefaultTabletScreenVetacial()
      } else {
        this.calcDefaultScreenVetacial()
      }
    })
    this.lastLapTime = time;

    this.getEventReportUtil(EventName.CLICK_STOPWATCH_COUNT)
  }
  private calcDefaultTabletScreenVetacial() {
    this.titletoppadding = 0
    this.textFoldVerticalPadding = 0
    this.textFoldCrossPadding = 0
    this.iHeight += ADD_VERHEIGHT
    if (this.foldAbleScreen === 1 && !this.isPortraitOrientation && this.laps.length >= 6) {
      this.iHeight = PRIVATE_SECOND_HEIGHT
    } else {
      if (this.iHeight > 480) {
        this.commenCalcHeight()
      }
    }
  }

  private calcDefaultScreenCross() {
    if (this.isBigView === BreakPoint.LG) {
      if (this.laps.length < 6) {
        if (this.laps.length == 1) {
          this.iHeight = INIT_VERHEIGHT
          return
        }
        this.iHeight += BREAKLG
        if (this.iHeight > RESTRICT_HEIGHT) {
          this.iHeight = BREAKLG_HEIGHT;
        }
      } else {
        this.iHeight = BREAKLG_HEIGHT;
      }
    } else {
      this.iHeight += ADD_HEIGHT
      if (this.iHeight > CROSS_HEIGHT) {
        this.iHeight = CROSS_HEIGHT;
      }
    }
  }

  private calcDefaultScreenVetacial() {
    this.titletoppadding = 0
    this.textFoldVerticalPadding = 0
    this.textFoldCrossPadding = 0
    this.iHeight += ADD_VERHEIGHT
    if (this.foldAbleScreen === 1 && !this.isPortraitOrientation && this.laps.length >= 6) {
      this.iHeight = PRIVATE_SECOND_HEIGHT
    } else {
      if (this.iHeight > DEFAULT_HEIGHT) {
        this.commenCalcHeight()
      }
    }
  }

  private commenCalcHeight() {
    if (this.deviceType === 'tablet' && this.isPortraitOrientation) {
    } else if (this.foldAbleScreen === 1) {
      /**
       * Do not modify the folding method
       */
      if (this.getOrientaion === this.isFoldCross) {
        this.iHeight = this.setCode ? FLOD_VERTICAL_HEIGHT_SECOND : FLOD_VERTICAL_HEIGHT_SECOND
      } else {
        this.iHeight = this.setCode ? PRIVATE_FIRST_HEIGHT : PRIVATE_SECOND_HEIGHT
      }
    } else {
      if (this.isDeviceModels === 'ALT-AL10') {
        this.iHeight = this.isFoldHeight
      } else {
        this.iHeight = this.isBigView === BreakPoint.MD ? FLOD_ALL_HEIGHT : this.isDeviceModels !== 'NOH-AN00' ? VERTICAL_OHOS_HEIGHT : VERTICAL_HEIGHT;
      }
    }
  }

  // 初始动画
  private initAnimation() {
    if (this.animateItem != null) {
      this.animateItem.destroy()
      this.animateItem = null
    }
    this.currentAnimateName = 'pause';
    this.animateItem = lottie.loadAnimation({
      container: this.controller,
      renderer: 'canvas',
      loop: false,
      autoplay: false,
      name: this.canvasAnimateName,
      path: this.canvasAnimatePath
    })
  }

  // 初始动画
  private initPauseAnimation() {
    if (this.animateItem != null) {
      this.animateItem.destroy()
      this.animateItem = null
    }
    this.currentAnimateName = 'play';
    this.animateItem = lottie.loadAnimation({
      container: this.controller,
      renderer: 'canvas',
      loop: false,
      autoplay: false,
      name: this.canvasPauseAnimateName,
      path: this.canvasPauseAnimatePath
    })
  }

  // 开始动画
  private playAnimation() {
    lottie.setDirection(this.currentAnimateName == 'pause' ? 1 : -1, this.getCurrentCanvasName());
    lottie.play(this.getCurrentCanvasName());
  }

  // 暂停动画
  private pauseAnimation() {
    lottie.setDirection(this.currentAnimateName == 'pause' ? -1 : 1, this.getCurrentCanvasName());
    lottie.play(this.getCurrentCanvasName());
  }

  getCurrentCanvasName(): string {
    return this.currentAnimateName == 'pause' ? this.canvasAnimateName : this.canvasPauseAnimateName
  }

  getDeviceRatio(): number {
    if (this.isPCLg()) {
      return SPECAIL_CLOCK_RATIO_FOR_NORMAL_CUSTOM
    }
    if (this.foldAbleScreen === 1) {
      return this.getOrientaion === this.isFoldCross ? SCALE_DIAMETER_RATIO : FOLD_SCREEN_DIAMETER_RATIO
    } else {
      return this.isPortraitOrientation ? SCALE_DIAMETER_RATIO : SPECAIL_CLOCK_RATIO_FOR_NORMAL_CUSTOM
    }
  }

  private isVisibility(): Visibility {
    return this.isStopwatchVisible ? Visibility.Visible : Visibility.Hidden
  }

  private getTimerPadding(): Padding {
    if (this.isPCLg()) {
      return {}
    }
    if (this.foldAbleScreen === 1) {
      return this.getOrientaion === this.isFoldCross ? { top: $r('app.float.ban_padding_20') } : {
        top: $r('app.float.ban_padding_20')
      }
    } else if (this.foldAbleScreen === 2) {
      return {
        top: $r('app.float.ban_padding_17')
      }
    } else {
      return this.isPortraitOrientation ? { top: $r('app.float.ban_padding_19') } : {
        right: $r('app.float.ban_padding')
      }
    }
  }

  @Builder
  buildStopwatchDial(): void {
    Row() {
      StopwatchDial({
        isPortraitOrientation: false,
        passedTime: $passedTime,
        scaleDiameterRatio: this.getDeviceRatio()
      })
    }
    .translate(this.isPCLg() ? {} : this.isPortraitOrientation || this.foldAbleScreen === 1 ? this.translateList : {})
    .transition(TransitionEffect.opacity(1))
    .visibility(this.isStopwatchVisible ? Visibility.Visible : Visibility.Hidden)
    .padding(this.getTimerPadding())
    .margin(this.isPCLg() ? {} : (this.foldAbleScreen === 1 ?
      {
        top: $r('app.float.dial_margin_32'), bottom: ''
      } :
      {
        top: $r('app.float.dial_margin_32'),
        bottom: this.foldAbleScreen === 2 ? $r('app.float.dial_margin_46') : $r('app.float.dial_margin_24')
      }
    ))

  }

  @Builder
  buildTimePassed() {
    Column() {
      Column() {
        Text(this.formatTimeString(this.passedTime))
          .textAlign(TextAlign.Center)
          .lineHeight(
            this.isPCLg() ? $r('app.float.stopwatch_PC_text_line_height') :
              (this.isPortraitOrientation || this.foldAbleScreen === 1
                ? $r('app.float.stopwatch_time_title_line_height')
                : $r('app.float.stopwatch_time_title_line_change_height')))
          .fontColor($r('sys.color.font_primary'))
          .fontSize(
            this.isPCLg() ? $r('app.float.stopwatch_PC_text_size') :
              (this.isPortraitOrientation || this.foldAbleScreen === 1
                ? $r('app.float.stopwatch_time_title_text_size')
                : $r('app.float.stopwatch_time_title_change_text_size')))
          .fontWeight(FontWeight.Medium)
          .margin({
            bottom: this.isPCLg() ? $r('app.float.stopwatch_pc_bottom') : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? $r('app.float.stopwatch_time_title_margin_bottom') : $r('app.float.stopwatch_time_title_margin_change_bottom'))
          })
          .height(
            this.isPCLg() ? $r('app.float.stopwatch_PC_text_height') :
              (this.isPortraitOrientation || this.foldAbleScreen === 1
                ? $r('app.float.stopwatch_time_height')
                : $r('app.float.stopwatch_time_title_line_change_height')))
        Text(this.formatTimeString(this.passedFromLastLapTime))
          .fontColor($r('sys.color.ohos_fa_text_secondary'))
          .fontSize($r('app.float.stopwatch_time_subtitle_text_size'))
          .lineHeight(this.isPCLg() ? $r('app.float.stopwatch_time_subtitle_height') : $r('app.float.stopwatch_time_subtitle_line_height'))
          .height($r('app.float.stopwatch_time_subtitle_height'))
          .fontWeight(FontWeight.Regular)
          .margin(this.isPCLg() ? { bottom: '0' } : (this.foldAbleScreen === 1 ? {
            bottom: $r('app.float.stopwatch_laps_list_fold_top')
          } : {
            bottom: $r('app.float.stopwatch_laps_list_margin_top')
          }))
          .visibility(this.laps && this.laps.length > 0 ? Visibility.Visible : Visibility.Hidden)
          .transition(
            TransitionEffect.OPACITY.animation({ delay: 300, duration: 150, curve: Curve.Sharp }))
      }
      .visibility(this.isVisibility())
    }
    .translate(this.isPCLg() ? {} : this.isPortraitOrientation || this.foldAbleScreen === 1 ? this.translateList : {})
    .width('100%')
    .padding(this.getPassedPadding())
    .margin({
      top: this.isPCLg() ? '' : this.foldAbleScreen === 1 ? $r('app.float.passed_margin_44') : $r('app.float.passed_margin_23'),
      right: this.isPortraitOrientation || this.foldAbleScreen === 1 ? 0 : this.isPCLg() ? 0 : $r('app.float.passed_margin_48')
    })
    .visibility(this.isVisibility())
  }

  private getPassedPadding(): Padding {
    if (this.isPCLg()) {
      return {}
    }
    if (this.foldAbleScreen === 1) {
      return {
        top: this.textFoldCrossPadding,
        bottom: this.textFoldCrossPadding - 24
      }
    } else if (this.foldAbleScreen === 2) {
      return {
        top: this.textFoldVerticalPadding,
        bottom: this.textFoldVerticalPadding - 24
      }
    } else {
      return {
        top: this.titletoppadding,
        bottom: this.titletoppadding - 24
      }
    }
  }

  @Builder
  buildLapItem(lap: LapItem) {
    Card({ cancelDoubleCardMargin: true, openHoverStatus: true, restrictAlarmCardMargin: true }) {
      Row() {
        Row() {
          Text(lap.index <= 9 ? 0 + lap.index.toString() : lap.index.toString())
            .width($r('app.float.text_width'))
            .height($r('app.float.text_height'))
            .borderRadius(50)
            .fontSize(14)
            .backgroundColor(lap.fromPrevLapTime == this.maxNum ? $r('sys.color.warning') : lap.fromPrevLapTime == this.minNum ? $r('sys.color.confirm') : $r('sys.color.interactive_hover'))
            .textAlign(TextAlign.Center)
            .fontColor(lap.fromPrevLapTime == this.maxNum ? $r('sys.color.font_on_primary') : lap.fromPrevLapTime == this.minNum ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
            .animation({
              duration: 150,
              curve: Curve.Linear,
            })
          Text(`+${this.formatTimeString(lap.fromPrevLapTime)}`)
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Medium)
            .fontColor(lap.fromPrevLapTime == this.maxNum ? $r('sys.color.warning') : lap.fromPrevLapTime == this.minNum ? $r('app.color.stopwatch_fon_size_min') : $r('app.color.stopwatch_fon_size_default'))
        }
        .width('109vp')
        .height($r('app.float.stopwatch_lap_item_height_no_padding'))
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Text(this.formatTimeString(lap.totalTime))
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .height($r('app.float.stopwatch_lap_item_height_no_padding'))
      .clip(true)
      .borderRadius($r('sys.float.corner_radius_level10'))
    }
  }

  @Builder
  buildLapsList() {
    List({ space: 0 }) {
      ForEach(this.laps, (item: LapItem) => {
        ListItem() {
          this.buildLapItem(item);
        }
        .transition(
          TransitionEffect.translate({ y: this.listItemTranslateY })
            .combine(TransitionEffect.OPACITY.animation(
              { duration: 0, curve: Curve.Sharp }),
            )
        )
        .margin(this.isPCLg() ? {
          bottom: item.index === 1 ? 0 : $r('app.float.cancel_bottom_margin')
        } : (item.index == 1 ? {
          bottom: this.isPortraitOrientation || this.foldAbleScreen === 1 ?
            this.laps.length <= (this.foldAbleScreen === 1 && !this.isPortraitOrientation ? 6 : 7) ?
            $r('app.float.cross_bottom') :
              this.isBigView === BreakPoint.MD ? this.foldAbleScreen === 1 && this.getOrientaion === this.isFoldCross ?
              $r('app.float.fold_margin_bottom_second') : $r('app.float.fold_margin_bottom') :
              $r('app.float.cross_over')
            : this.laps.length === 1 || this.laps.length === 2 || this.laps.length === 3 ? $r('app.float.vertical_bottom') :
            $r('app.float.special_bottom')
        } : { bottom: $r('app.float.cancel_bottom_margin') }))
      }, (item: LapItem) => JSON.stringify(item))
    }
    .scrollBar(this.laps && this.laps.length > 1 ? BarState.On : BarState.Off)
    .edgeEffect(EdgeEffect.Spring) // 边缘效果设置为Spring
    .translate(this.isPCLg() ? {} : this.translateList)
    .alignListItem(ListItemAlign.Start)
    .visibility(this.isStopwatchVisible ? Visibility.Visible : Visibility.None)
    .width('100%')
    .height(this.isPCLg() ? PC_HEIGHT : (this.isPortraitOrientation ? this.iHeight : DEFAULT_HEIGHT))
    .margin(this.deviceType === 'tablet' && !this.isPortraitOrientation ? {
      top: $r('app.float.normal_tablet_margin')
    } : (this.isPCLg() ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? {
    } : this.isBigView !== BreakPoint.LG ? {
      top: $r('app.float.normal_margin') } : { top: $r('app.float.lg_margin') })))
    .padding(this.isPCLg() ? {} : (this.isBigView === BreakPoint.MD ? this.isPortraitOrientation ? {
      left: $r('app.float.fold_left'),
      right: $r('app.float.fold_right')
    } : this.foldAbleScreen === 1 ? {
      left: $r('app.float.fold_cross_padding'),
      right: $r('app.float.fold_cross_padding'),
    } : this.isPortraitOrientation ? {
      left: $r('app.float.time_list_padding'),
      right: $r('app.float.time_list_padding')
    } : {
      right: $r('app.float.ban_padding')
    } : {
      left: $r('app.float.time_list_padding'),
      right: $r('app.float.time_list_padding')
    }))
    .border({ width: 1, color: Color.Transparent })
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
      alignItems: ItemAlign.Center }) {
      FloatingActionButton({
        src: $r('app.media.ic_reset'),
        colorSchemeName: FloatingActionButtonColor.WHITE,
        isEnabled: !this.isStopwatchRunning && Math.abs(this.passedTime) > 0,
        playButton: false,
        onButtonClick: (): void => this.resetStopwatch()
      })
        .transition(TransitionEffect.opacity(1))
      Stack() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Canvas(this.controller)
            .draggable(false)
            .borderRadius($r('app.float.canvas_border_radius'))
            .width($r('app.float.canvas_size'))
            .height($r('app.float.canvas_size'))
            .onReady(() => {
              LogUtil.info(TAG, `${this.canvasAnimatePath} dasdasd}`);
              if (this.isStopwatchRunning) {
                this.initPauseAnimation()
              } else {
                this.initAnimation()
              }
            })
            .onDisAppear(() => {
              LogUtil.info(TAG, `${TAG} canvas onDisAppear...`);
            })
            .onClick(() => {
              LogUtil.info(TAG, '点击成功');
              this.onStopwatchToggled(!this.isStopwatchRunning)
            })
        }
        .id('id_add_button')
        .backgroundColor($r('sys.color.ohos_id_container_color_active'))
        .width($r('app.float.pc_add_button_size'))
        .height($r('app.float.pc_add_button_size'))
        .stateStyles({
          pressed: this.pressedButtonStyle,
        })
        .shadow({
          radius: $r('app.float.button_shadow_radius'),
          color: CommonUtil.changeShadowColor($r('sys.color.ohos_id_container_color_active')),
          offsetX: 0,
          offsetY: $r('app.float.button_shadow_y2'),
        })

        if (this.isPCLg()) {
          Button({ type: ButtonType.Circle, stateEffect: true })
            .opacity(0)
            .width($r('app.float.pc_add_button_size'))
            .height($r('app.float.pc_add_button_size'))
            .onClick(() => {
              this.onStopwatchToggled(!this.isStopwatchRunning)
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

      FloatingActionButton({
        src: $r('app.media.ic_stopwatch_lap'),
        colorSchemeName: FloatingActionButtonColor.WHITE,
        isEnabled: this.isStopwatchRunning,
        playButton: false,
        onButtonClick: (): void => this.addLap()
      })
        .transition(TransitionEffect.opacity(1))
    }
    .borderRadius($r('app.float.stopwatch_bottom_borderRadius'))
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .padding(this.isPCLg() ? {
      top: $r('app.float.stopwatch_bottom_padding'),
      bottom: $r('app.float.stopwatch_bottom_padding')
    } : { left: $r('app.float.stopwatch_bottom_padding'), right: $r('app.float.stopwatch_bottom_padding') })
    .width(this.isPCLg() ? $r('app.float.stopwatch_bottom_padding_height') : $r('app.float.stopwatch_bottom_width'))
    .height(this.isPCLg() ? $r('app.float.stopwatch_bottom_width') : $r('app.float.stopwatch_bottom_padding_height'))
    .margin({
      bottom: this.isPCLg() ? 0 : $r('app.float.stopwatch_bottom_margin_bottom')
    })
  }

  // 竖屏
  @Builder
  buildPortrait() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scrollerForScroll) {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
          // this.buildStopwatchDial()
          this.buildTimePassed()
          CommonGrid() {
            this.buildLapsList()
          }
        }
      }
      .edgeEffect(EdgeEffect.None)
      .scrollBar(BarState.Off)
      .onScroll((_: number, yOffset: number) => this.onScroll(yOffset))
      .align(Alignment.Top)
      .height('100%')
      .width('100%')

      if (this.isStopwatchVisible) {
        this.buildButtons()
      }
    }
  }

  //横屏
  @Builder
  buildLandscape() {
    Row() {
      Column() {
        // this.buildStopwatchDial();
        this.buildTimePassed();
      }
      .height('100%')
      .width('calc(40% - 19vp)')

      Rect()
        .fill($r('sys.color.comp_divider'))
        .width('1px')
        .height($r('app.float.line_height'))
        .margin({ left: $r('app.float.margin_left_1') })
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll(this.scrollerForScroll) {
          this.buildLapsList();
        }
        .height('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .onScroll((_: number, yOffset: number) => this.onScroll(yOffset))
        .align(Alignment.Top)

        if (this.isStopwatchVisible) {
          this.buildButtons()
        }
      }
      .padding({
        left: $r('app.float.ban_padding')
      })
      .height('100%')
      .width('calc(60% + 19vp)')
    }
    .height('100%')
    .width('100%')
    .padding({
      left: $r('app.float.ban_padding'),
    })
  }

  @Builder
  buildPC() {
    Row() {
      // 钟表
      Column() {
        // this.buildStopwatchDial()
        this.buildTimePassed()
      }
      .width(this.laps.length > 0 ? `calc(100% - 40% - 268vp)` : `calc(100% - 232vp)`)
      .margin({
        left: this.laps.length > 0 ? $r('app.float.stopwatch_pc_left') : $r('app.float.stopwatch_pc_left_max')
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 计时按钮
      if (this.isStopwatchVisible) {
        Column() {
          this.buildButtons()
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({
          right: $r('app.float.stopwatch_PC_button_margin'),
        })
      }
    }
    .height('100%')
  }

  build() {

    if (this.isPCLg()) {
      this.buildPC()
    } else {
      if (this.isPortraitOrientation || this.foldAbleScreen === 1) {
        this.buildPortrait();
      } else {
        this.buildLandscape()
      }
    }
  }
}