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

import power from '@ohos.power';
// import brightness from '@system.brightness';
import audio from '@ohos.multimedia.audio';
import emitter from '@ohos.events.emitter';
import media from '@ohos.multimedia.media';
import resmgr from '@ohos.resourceManager';
// import inputConsumer from '@ohos.multimodalInput.inputConsumer';
import observer from '@ohos.telephony.observer';
import call from '@ohos.telephony.call';
import screenLock from '@ohos.screenLock';
import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import worker from '@ohos.worker';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import {
  AlarmInfo,
  AlarmManager,
  AlarmServiceType,
  AlarmStateManager,
  TimerStateManager,
  TIMEOUT_FULL_SCREEN_CLOSE_ID,
  CommonUtil,
  EVENT_ID_ALARM_RING,
  EventName,
  EventReportUtil,
  EventResult,
  GlobalContext,
  LogUtil,
  TimeUtil,
  EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE,
  WantAgentUtil,
  FullScreenType
} from '@hmos/common';
import { NotificationUtil, AlarmCardUtil } from '../utils';
import { RING_FILE_NAME } from './types';

// import hiSysEvent from '@ohos.hiSysEvent';
import deviceInfo from '@ohos.deviceInfo'
import { BusinessError } from '@ohos.base';

interface ReportParams {
  PACKAGE_NAME: string;
  PROCESS_NAME: string;
  RESULT: string;
  VALUE?: string;
  STATUS?: string
}

const deviceType: string = deviceInfo.deviceType;

const TAG = 'AlarmServiceManager';

// type ServiceExtensionContext = common.ServiceExtensionContext;

/**
 * Alarm Service Manager
 *
 * @since 2022-08-25
 */
class AlarmServiceManager {
  public workerInstance?: media.AVPlayer = undefined;

  constructor() {
    // Bind snoozeCallback to current context
    this.snoozeCallback;
  }

  private getEventReportUtil(event_name: string): void {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, event_name,);
  }

  private async typeStart(alarmInfo: AlarmInfo, latestAlarmInfo?: AlarmInfo) {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_IS_ON);
    this.getEventReportUtil('ALARM_RINGDOWN_BANNER');
    if (!latestAlarmInfo) {
      LogUtil.info(TAG, `alarmInfo is not available:  ${JSON.stringify(alarmInfo)}`);
      return;
    }
    await TimeUtil.getFreeday(); // Obtaining statutory holidays data in the database.
    await this.startAlarm(alarmInfo);
    // After the alarm is generated, you need to update the data in the database.
    // 1. The enable attribute of alarms with the same time is set to false.
    // 2. Recalculate the alarmTime of the repeated alarms with the same time as the alarmInfo.
    // Update the next start time.
    await AlarmManager.closeNoRepeatAlarms(alarmInfo);
    this.notifyRefreshMainPage();
  }

  private async typeReStart(alarmInfo: AlarmInfo) {
    alarmInfo.enabled = true;
    alarmInfo.reStart = '';
    await AlarmManager.updateAlarm(alarmInfo);
    emitter.emit({
      eventId: EVENT_ID_ALARM_RING,
      priority: emitter.EventPriority.IMMEDIATE,
    });
  }

  private async typeClose(alarmInfo: AlarmInfo, isSnooze?: boolean, isCloseButton?: boolean) {
    this.getEventReportUtil('ALARM_CLOSE_BANNER');
    if (isCloseButton) {
      if (isSnooze) {
        EventReportUtil.write(EventName.NOTIFICATION_CANCEL_ALARM_SNOOZE, hiAppEvent.EventType.BEHAVIOR, {
          'result': EventResult.EVENT_RESULT_SUCCESS });
      } else {
        EventReportUtil.write(EventName.NOTIFICATION_CLOSE_ALARM, hiAppEvent.EventType.BEHAVIOR, {
          'result': EventResult.EVENT_RESULT_SUCCESS });
      }
    }
    await this.stopAlarm(alarmInfo);
    this.notifyRefreshMainPage();
  }

  private async typeDelay(alarmInfo: AlarmInfo) {
    this.getEventReportUtil('ALARM_REMINDER_LATER_BANNER');
    EventReportUtil.write(EventName.NOTIFICATION_SNOOZE_ALARM, hiAppEvent.EventType.BEHAVIOR, {
      'result': EventResult.NOTIFICATION_SNOOZE_ALARM });
    await this.delayAlarm(alarmInfo);
  }

  /**
   * Deal with the alarm processing request based on the service type.
   *
   * @param alarmInfo Alarm information
   * @param serviceType Alarm service type which could be Start, Stop, or Delay.
   */
  async dealAlarmWithServiceType(alarmInfo: AlarmInfo, serviceType: AlarmServiceType,
                                 isCloseButton?: boolean, isSnooze?: boolean): Promise<void> {
    if (!alarmInfo || !serviceType) {
      LogUtil.error(TAG, 'Execute method dealAlarmWithServiceType failed, params is incorrect.');
      return;
    }
    const latestAlarmInfo = await AlarmManager.getLatestAlarmFromDb(alarmInfo?.id as string);
    if (latestAlarmInfo) {
      alarmInfo = latestAlarmInfo;
      LogUtil.info(TAG, 'Get latest alarm from db success.');
    } else {
      LogUtil.info(TAG, 'This alarm has not been found in db.');
    }
    switch (serviceType) {
      case AlarmServiceType.Start: {
        await this.typeStart(alarmInfo, latestAlarmInfo);
        break;
      }
      case AlarmServiceType.ReStart: {
        await this.typeReStart(alarmInfo);
        break;
      }
      case AlarmServiceType.Close: {
        await this.typeClose(alarmInfo, isSnooze, isCloseButton);
        break;
      }
      case AlarmServiceType.Delay: {
        await this.typeDelay(alarmInfo);
        break;
      }
      default: {
        LogUtil.error(TAG, 'Service type is not right:', serviceType);
        break;
      }
    }
  }

  setScreenOn(): void {
    try {
      LogUtil.info(TAG, `setScreenOn`);
      // brightness.setKeepScreenOn({ keepScreenOn: true,
      //   success: () => {
      //     LogUtil.info(TAG, `setScreenOn success`);
      //   },
      //   fail: (data: string, code: number) => {
      //     LogUtil.error(TAG, `setScreenOn fail ${data} ${code}`);
      //   },
      //   complete: () => {
      //     LogUtil.info(TAG, `setScreenOn complete`);
      //   } });
    } catch (error) {
      LogUtil.info(TAG, `setScreenOn failed because: ${JSON.stringify(error)}`);
    }
  }

  setScreenOff(): void {
    try {
      LogUtil.info(TAG, `setScreenOff`);
      // brightness.setKeepScreenOn({ keepScreenOn: false,
      //   success: () => {
      //     LogUtil.info(TAG, `setScreenOff success`);
      //   },
      //   fail: (data: string, code: number) => {
      //     LogUtil.error(TAG, `setScreenOff fail ${data} ${code}`);
      //   },
      //   complete: () => {
      //     LogUtil.info(TAG, `setScreenOff complete`);
      //   } });
    } catch (error) {
      LogUtil.info(TAG, `setScreenOff failed because: ${JSON.stringify(error)}`);
    }
  }

  /**
   * Start alarm
   *
   * @param alarmInfo Alarm information
   */
  async startAlarm(alarmInfo: AlarmInfo): Promise<void> {
    if (!alarmInfo?.id) {
      LogUtil.error(TAG, 'Execute method startAlarm failed, params is incorrect.');
      return;
    }
    const isFiring = await AlarmStateManager.isFiring();
    if (isFiring) {
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      LogUtil.info(TAG, `current is firing: firing alarm id is: ${firingAlarmId}`);
      const firingAlarm = await AlarmManager.getLatestAlarmFromDb(firingAlarmId);
      await this.delayAlarm(firingAlarm, true);
    }
    const timerIsFiring = await TimerStateManager.isFiring();
    if (timerIsFiring) {
      LogUtil.info(TAG, `timerIsFiring=>${timerIsFiring}`);
      emitter.emit({ eventId: TIMEOUT_FULL_SCREEN_CLOSE_ID, priority: emitter.EventPriority.IMMEDIATE });
      CommonUtil.terminateFullScreenAbility();
    }
    try {
      this.listenSnoozeInput();
      if (CommonUtil.isDevicePhone()) {
        this.listenCallStateChange();
      }
      await AlarmStateManager.setStateFiring(alarmInfo.id);
      const isScreenLocked: boolean = await screenLock.isScreenLocked();
      LogUtil.info(TAG, 'isScreenLocked is ' + isScreenLocked);
      if (deviceType !== '2in1') {
        if (!isScreenLocked) {
          // When the screen is unlocked, send notification.
          this.setScreenOn();
          if (alarmInfo.alarmTime) {
            await NotificationUtil.publishAlarmReminder(alarmInfo.id!, alarmInfo?.alarmTime, alarmInfo.title!);
          }
          this.startAudioWorker();
          return;
        }
        // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_LOCK_SCREEN_ALARM);
        // power.wakeup('alarm');
        // When the screen is locked, the alarm starts in full screen.
        await WantAgentUtil.triggerFullScreenAbility(FullScreenType.Alarm);
      } else {
        if (alarmInfo.alarmTime) {
          await NotificationUtil.publishAlarmReminder(alarmInfo.id!, alarmInfo?.alarmTime, alarmInfo.title!);
        }
        this.startAudioWorker();
        return;
      }

    } catch (error) {
      LogUtil.error(TAG, `Request alarm failed because: ${JSON.stringify(error)}`);
    }
  }

  async audioStateHandle(player: media.AVPlayer) {
    if (!player) {
      return;
    }
    player.on('stateChange', async (state) => {
      LogUtil.info(TAG, 'audioStateHandle stateChange:' + state);
      switch (state) {
        case 'initialized': {
          let audioRendererInfo: audio.AudioRendererInfo = {
            content: audio.ContentType.CONTENT_TYPE_UNKNOWN,
            usage: audio.StreamUsage.STREAM_USAGE_ALARM,
            rendererFlags: 0
          }
          player.audioRendererInfo = audioRendererInfo;
          player.prepare();
          break;
        }
        case 'prepared': {
          player.setVolume(1.0);
          player.loop = true;
          player.play();
          break;
        }
        default: {
        }
      }
    });
    player.on('error', async (error: BusinessError) => {
      LogUtil.error(TAG, 'audio player error:' + JSON.stringify(error));
    });
    player.on('audioInterrupt', async (info: audio.InterruptEvent) => {
      LogUtil.info(TAG, 'audioInterrupt:' + JSON.stringify(info));
      if (info.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
        this.stopAudioWorker(true);
      }
    });
  }

  public async createAudioWorker(init?: boolean): Promise<void> {
    try {
      LogUtil.info(TAG, 'create AudioWorker');
      let audioPlayer = await media.createAVPlayer();
      const resourceManager = (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager);
      const fileDescriptor = await resourceManager.getRawFd(RING_FILE_NAME);
      let avFileDescriptor: media.AVFileDescriptor = {
        fd: fileDescriptor.fd,
        offset: fileDescriptor.offset,
        length: fileDescriptor.length
      };
      audioPlayer.fdSrc = avFileDescriptor;
      this.workerInstance = audioPlayer;
      if (!init) {
        this.audioStateHandle(this.workerInstance);
      }
    } catch (err) {
      let message = (err as BusinessError).message;
      let errCode = (err as BusinessError).code;
      LogUtil.error(TAG, `createAudioWorker error: code: ${errCode}, message: ${message} `);
    }
  }

  /**
   * start Audio Worker
   */
  public async startAudioWorker(): Promise<void> {
    try {
      if (!this.workerInstance) {
        LogUtil.info(TAG, 'start to create AudioWorker');
        await this.createAudioWorker();
      } else {
        LogUtil.info(TAG, 'AudioWorker has been create, state:' + this.workerInstance.state);
        this.audioStateHandle(this.workerInstance);
        if (this.workerInstance.state === 'completed' || this.workerInstance.state === 'prepared') {
          LogUtil.info(TAG, 'completed');
          this.workerInstance.setVolume(1.0);
          this.workerInstance.loop = true;
          this.workerInstance.play();
        } else if (this.workerInstance.state === 'initialized') {
          LogUtil.info(TAG, 'initialized');
          let audioRendererInfo: audio.AudioRendererInfo = {
            content: audio.ContentType.CONTENT_TYPE_UNKNOWN,
            usage: audio.StreamUsage.STREAM_USAGE_ALARM,
            rendererFlags: 0
          }
          this.workerInstance.audioRendererInfo = audioRendererInfo;
          this.workerInstance.prepare();
        } else if (this.workerInstance.state === 'playing') {
          LogUtil.info(TAG, 'playing');
        } else {
          LogUtil.info(TAG, 'not completed/playing/initialized/prepared');
          await this.stopAudioWorker();
          await this.createAudioWorker();
        }
      }
    } catch (err) {
      let message = (err as BusinessError).message;
      let errCode = (err as BusinessError).code;
      LogUtil.error(TAG, `startAudioWorker error: code: ${errCode}, message: ${message} `);
    }
  }

  /**
   * stop Audio Worker
   */
  public async stopAudioWorker(isForce: boolean = false): Promise<void> {
    const isFiring = await AlarmStateManager.isFiring();
    LogUtil.info(TAG, 'stopAudioWorker isFiring: ' + isFiring + ' isForce=' + isForce);
    if (isFiring && !isForce) {
      return;
    }
    if (this.workerInstance) {
      LogUtil.info(TAG, 'start to stop AudioWorker');
      let player: media.AVPlayer = this.workerInstance;
      this.workerInstance = undefined;
      try {
        await player.stop();
      } catch (err) {
        let message = (err as BusinessError).message;
        let errCode = (err as BusinessError).code;
        LogUtil.error(TAG, `stopAudioWorker error: code: ${errCode}, message: ${message} `);
      }
      try {
        await player.release();
      } catch (err) {
        let message = (err as BusinessError).message;
        let errCode = (err as BusinessError).code;
        LogUtil.error(TAG, `releaseAudioWorker error: code: ${errCode}, message: ${message} `);
      }
    }

  }

  /**
   * Stop alarm
   *
   * @param alarmInfo Alarm information
   */
  async stopAlarm(alarmInfo: AlarmInfo): Promise<void> {
    if (!alarmInfo?.id) {
      LogUtil.error(TAG, 'Execute method stopAlarm failed, params is incorrect.');
      return;
    }
    this.cancelSnoozeInput();
    LogUtil.info(TAG, 'alarm stop alarmInfo = ' + JSON.stringify(alarmInfo))
    await AlarmStateManager.setStateStop(alarmInfo.id);
    this.stopAudioWorker();
    await AlarmManager.clearSnoozedData(alarmInfo, true);
    await AlarmCardUtil.notifyAlarmCardTimeUpdate();
    await AlarmManager.stopAlarm(alarmInfo);
    await NotificationUtil.cancel(alarmInfo.id);
  }

  /**
   * Delay alarm
   *
   * @param alarmInfo Alarm information
   * @param isAuto Indicates whether the automatic delay scenario is used.
   */
  async delayFiringAlarm(isTimer?: boolean): Promise<void> {
    const isFiring = await AlarmStateManager.isFiring();
    LogUtil.info(TAG, `delayFiringAlarm: isFiring: ${isFiring}`);
    if (isFiring) {
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      const firingAlarm = await AlarmManager.getLatestAlarmFromDb(firingAlarmId);
      LogUtil.info(TAG, `firingAlarm: ${JSON.stringify(firingAlarm)}`);
      await this.delayAlarm(firingAlarm);
      emitter.emit({ eventId: EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE, priority: emitter.EventPriority.IMMEDIATE });
    }
  }

  /**
   * Delay alarm
   *
   * @param alarmInfo Alarm information
   * @param isAuto Indicates whether the automatic delay scenario is used.
   */
  async delayAlarm(alarmInfo?: AlarmInfo, isAuto?: boolean): Promise<void> {
    if (!alarmInfo?.id) {
      LogUtil.error(TAG, 'Execute method delayAlarm failed, params is incorrect.');
      return;
    }
    if (isAuto && await AlarmManager.hasReachedLimitedSnoozeTimes(alarmInfo)) {
      LogUtil.info(TAG, 'stop the alarm as it has reached limited snooze times.');
      let delayedTime = await AlarmManager.getRealAlertTime(alarmInfo);
      if (delayedTime > 0) {
        LogUtil.info(TAG, `alarmInfo:  ${alarmInfo.hour} ${alarmInfo.minute}`);
        LogUtil.info(TAG, `delayedTime : ${new Date(delayedTime)} ${delayedTime}`);
        let curDate = new Date(delayedTime);
        if (curDate.getHours() < alarmInfo.hour) {
          curDate.setDate(curDate.getDate() - 1);
        }
        curDate.setSeconds(0);
        curDate.setHours(alarmInfo.hour);
        curDate.setMinutes(alarmInfo.minute);
        LogUtil.info(TAG, `new delayedTime: ${curDate} ${curDate.getTime()}`);
        delayedTime = curDate.getTime();
      }
      await this.stopAlarm(alarmInfo);
      if (deviceType === '2in1') {
        await NotificationUtil.cancel(alarmInfo.id!);
        await NotificationUtil.publishAlarmMissedPC(alarmInfo.id!, delayedTime, alarmInfo.title!);
      } else {
        await NotificationUtil.publishAlarmMissed(alarmInfo.id!, delayedTime, alarmInfo.title!);
      }
      CommonUtil.terminateFullScreenAbility();
      return;
    }
    this.cancelSnoozeInput();
    await AlarmStateManager.setStateSnooze(alarmInfo.id);
    const nextAlertTime = await AlarmManager.delayAlarm(alarmInfo, isAuto);
    await AlarmManager.updateTimer();
    AlarmCardUtil.notifyAlarmCardTimeUpdate();
    if (deviceType === '2in1') {
      await NotificationUtil.publishAlarmSnoozePC(alarmInfo.id!, nextAlertTime, alarmInfo.title!);
    } else {
      await NotificationUtil.publishAlarmSnooze(alarmInfo.id!, nextAlertTime,
        alarmInfo.snoozeDuration, alarmInfo.title!);
    }
    this.notifyRefreshMainPage();
    CommonUtil.terminateFullScreenAbility();
    this.stopAudioWorker();
  }

  /**
   * Refresh next alert time when system time changes
   *
   * @param forceRefreshTimer The timer needs to be reset during startup.
   */
  async refreshNextAlertTime(forceRefreshTimer?: boolean, isIntentMode?: boolean): Promise<void> {
    LogUtil.info(TAG, 'do refreshNextAlertTime');
    await AlarmManager.recalculateAllAlarmsAlarmTime(isIntentMode);
    if (forceRefreshTimer) {
      await AlarmManager.updateTimerImmediately();
    } else {
      await AlarmManager.updateTimer();
    }
  }

  /**
   * Initiate the snooze input listening.
   */
  listenSnoozeInput(): void {
  }

  /**
   * Cancel the snooze input listening.
   */
  cancelSnoozeInput(): void {
  }

  /**
   * listen call state Change
   */
  listenCallStateChange(): void {
    const SLOT_TWO = 1;
    const SLOT_ONE = 0;
    observer.on('callStateChange', { slotId: SLOT_TWO }, value => {
      LogUtil.info(TAG, 'on slot two callStateChange, state:' + value.state + ', number:' + value.number);
      this.callRingSnoozeCallBack(value.state);
    });
    observer.on('callStateChange', { slotId: SLOT_ONE }, value => {
      LogUtil.info(TAG, 'on slot one callStateChange, state:' + value.state + ', number:' + value.number);
      this.callRingSnoozeCallBack(value.state);
    });
  }

  /**
   * callRingSnoozeCallBack
   * @param state
   */
  private async callRingSnoozeCallBack(state: call.CallState): Promise<void> {
    const isFiring = await AlarmStateManager.isFiring();
    if (state === call.CallState.CALL_STATE_RINGING && isFiring) {
      LogUtil.info(TAG, 'CALL_STATE_RINGING');
      const alarmInfo: AlarmInfo = ((GlobalContext.getContext()
        .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
      if (!alarmInfo) {
        LogUtil.info(TAG, 'callRingSnoozeCallBack not alarmInfo');
        return;
      }
      LogUtil.info(TAG, 'callRingSnoozeCallBack alarmInfo:' + JSON.stringify(alarmInfo));
      this.delayAlarm(alarmInfo);
      emitter.emit({ eventId: EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE, priority: emitter.EventPriority.IMMEDIATE });
    }
  }

  /**
   * cancel call state Change
   */
  private cancelCallStateChange(): void {
    observer.off('callStateChange', value => {
      LogUtil.info(TAG, 'on cancel CallStateChange');
    });
  }

  private snoozeCallback(): void {
    try {
      const alarmInfo: AlarmInfo = ((GlobalContext.getContext()
        .getObject('abilityWant') as Want)?.parameters?.alarmInfo) as AlarmInfo;
      LogUtil.info(TAG, 'snoozeCallback alarmInfo: ', JSON.stringify(alarmInfo));
      if (!alarmInfo) {
        return;
      }
      this.delayAlarm(alarmInfo);
    } catch (error) {
      LogUtil.error(TAG, 'snoozeCallback failed: ', (error as BusinessError).message);
    }
  }

  private notifyRefreshMainPage(): void {
    emitter.emit({
      eventId: EVENT_ID_ALARM_RING,
      priority: emitter.EventPriority.IMMEDIATE,
    });
  }

  /**
   * Delay alarm and return this alarmInfo
   *
   * @param alarmInfo Alarm information
   * @param isAuto Indicates whether the automatic delay scenario is used.
   */
  async delayAlarmAndReturn(): Promise<AlarmInfo | undefined> {
    const isFiring = await AlarmStateManager.isFiring();
    LogUtil.info(TAG, `delayFiringAlarm: isFiring: ${isFiring}`);
    if (isFiring) {
      const firingAlarmId = await AlarmStateManager.getAlarmId();
      const firingAlarm = await AlarmManager.getLatestAlarmFromDb(firingAlarmId);
      LogUtil.info(TAG, `firingAlarm: ${JSON.stringify(firingAlarm)}`);
      await this.delayAlarm(firingAlarm);
      return firingAlarm
    }
    return;
  }
}

export default new AlarmServiceManager();
