/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import { ConfigData, LogUtil } from '@ohos/common';
import data_preferences from '@ohos.data.preferences';

const TAG = "TimerController : ";

export enum TimerState {
  /**
   * The initial state
   */
  IDLE,
  /**
   * Continuously update time starting from IDLE or PAUSED state
   */
  RUNNING,
  /**
   * Click Pause from the RUNNING state
   */
  PAUSED,
}

export class TimerController {
  private currentTimeMs: number = 0;
  private beforePauseTime: number = 0;
  private state: TimerState = TimerState.IDLE;
  private startTimestamp: number = 0;
  private notifierId: number = -1;
  private timeList: Array<number> = [];
  private lastTimeMs: number = 0;
  private timeUpdateListener: (currentTimeMs: number) => void = undefined;
  private clockUpdateListener: (currentTimeMs: number) => void = undefined;
  private stateUpdateListener: (TimerState) => void = undefined;
  private timeListUpdateListener: (timeList: Array<number>, lastTimeMs: number) => void = undefined;
  private preferences: data_preferences.Preferences = undefined;

  /**
   * Timer start
   */
  public async start() {
    LogUtil.info(`${TAG} timer start `);
    this.startTimestamp = new Date().getTime();
    if (this.notifierId != -1) {
      clearInterval(this.notifierId);
      this.notifierId = -1;
    }
    this.notifierId = setInterval(() => {
      let timestamp = new Date().getTime();
      this.currentTimeMs = this.beforePauseTime + timestamp - this.startTimestamp;
      this.notifyTimeChanges();
    }, ConfigData.NOTIFY_INTERVAL_MS);
    if (this.preferences) {
      await this.preferences.put("startTimestamp", this.startTimestamp);
    }
    this.state = TimerState.RUNNING;
    this.notifyStateChanges();
  }

  /**
   * Timer pause
   */
  public async pause() {
    LogUtil.info(`${TAG} timer pause `);
    clearInterval(this.notifierId);
    this.beforePauseTime += new Date().getTime() - this.startTimestamp;
    this.currentTimeMs = this.beforePauseTime;
    this.notifyTimeChanges();
    this.notifierId = -1;
    this.state = TimerState.PAUSED;
    if (this.preferences) {
      await this.preferences.put("beforePauseTime", this.beforePauseTime);
    }
    this.notifyTimeChanges();
    this.notifyStateChanges();
  }

  /**
   * Timer reset
   */
  public reset() {
    LogUtil.info(`${TAG} timer reset `);
    this.beforePauseTime = 0;
    this.startTimestamp = 0;
    this.timeList = [];
    this.lastTimeMs = 0;
    this.notifierId = -1;
    this.currentTimeMs = 0;
    this.state = TimerState.IDLE;
    this.notifyTimeChanges();
    this.notifyStateChanges();
    this.notifyTimeListChanges();
    this.preferences.clear();
  }

  /**
   * Read the previous state from the preferences
   */
  public async reload() {
    LogUtil.info(`${TAG} Read the previous data `);
    this.preferences = await data_preferences.getPreferences(globalThis.abilityContext, 'myClockStore');
    this.state = <TimerState> await this.preferences.get("state", TimerState.IDLE);
    this.lastTimeMs = <number> await this.preferences.get("lastTimeMs", 0);
    this.beforePauseTime = <number> await this.preferences.get("beforePauseTime", 0);
    this.startTimestamp = <number> await this.preferences.get("startTimestamp", 0);

    let timeList = await this.preferences.get("timeList", 0);
    if (timeList == 0) {
      this.timeList = [];
    } else {
      this.timeList = <Array<number>> timeList;
    }

    if (this.state == TimerState.RUNNING) {
      if (this.notifierId != -1) {
        clearInterval(this.notifierId);
        this.notifierId = -1;
      }
      this.notifierId = setInterval(() => {
        let timestamp = new Date().getTime();
        this.currentTimeMs = this.beforePauseTime + timestamp - this.startTimestamp;
        this.notifyTimeChanges();
      }, ConfigData.NOTIFY_INTERVAL_MS);
    } else if (this.state == TimerState.PAUSED) {
      this.currentTimeMs = this.beforePauseTime;
    } else {
      this.reset();
    }
    this.notifyTimeChanges();
    if (this.timeList.length > 0) {
      this.notifyTimeListChanges();
    }
    this.notifyStateChanges();
  }

  /**
   * Recording the Current Time
   */
  public writeTime() {
    LogUtil.info(`${TAG} Recording time `);
    let timestamp = new Date().getTime();
    this.lastTimeMs = Math.floor((this.beforePauseTime + timestamp - this.startTimestamp) / 10) * 10;
    this.timeList.push(this.lastTimeMs);
    this.notifyTimeListChanges();
  }

  /**
   * Notice time change
   */
  private notifyTimeChanges() {
    if (this.timeUpdateListener) {
      this.timeUpdateListener(this.currentTimeMs);
    }
    if (this.clockUpdateListener) {
      this.clockUpdateListener(this.currentTimeMs);
    }
  }

  /**
   * Notifies record time list changes
   */
  private async notifyTimeListChanges() {
    if (this.timeListUpdateListener) {
      this.timeListUpdateListener(this.timeList, this.lastTimeMs);
    }
    if (this.preferences) {
      await this.preferences.put("timeList", this.timeList);
      await this.preferences.put("lastTimeMs", this.lastTimeMs);
      this.flush();
    }
  }

  /**
   * Notification of status change
   */
  private async notifyStateChanges() {
    LogUtil.info(`${TAG} state update ${this.state}`);
    if (this.stateUpdateListener) {
      this.stateUpdateListener(this.state);
    }
    if (this.preferences) {
      await this.preferences.put("state", this.state);
      this.flush();
    }
  }

  /**
   * Persist preferences
   */
  private flush() {
    this.preferences.flush(function (err) {
      if (err) {
        console.warn("Failed flush. Cause: " + err);
        return;
      }
      console.warn("Succeeded flush.");
    })
  }

  /**
   * Set listening for state changes
   * @param listener
   */
  public setStateUpdateListener(listener: (TimerState) => void) {
    LogUtil.info(`${TAG} setStateUpdateListener`);
    this.stateUpdateListener = listener;
  }

  /**
   * Set time change listening
   * @param listener
   */
  public setTimeUpdateListener(listener: (currentTimeMs: number) => void) {
    LogUtil.info(`${TAG} setTimeUpdateListener`);
    this.timeUpdateListener = listener;
  }

  /**
   *  Set time clock change listening
   * @param listener
   */
  public setClockUpdateListener(listener: (currentTimeMs: number) => void) {
    LogUtil.info(`${TAG} setClockUpdateListener`);
    this.clockUpdateListener = listener;
  }

  /**
   * Set the record time list change listening
   * @param listener
   */
  public setTimeListUpdateListener(listener: (timeList: Array<number>, lastTimeMs: number) => void) {
    LogUtil.info(`${TAG} setTimeListUpdateListener`);
    this.timeListUpdateListener = listener;
  }
}