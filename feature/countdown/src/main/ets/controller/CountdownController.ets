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

import dataStorage from '@ohos.data.preferences';
import { ConfigData, LogUtil } from '@ohos/common';

const TAG = 'CountdownController : ';

export enum CountdownState {
  /**
   * The total time in the initial state is not set. The default is 0, but can be triggered by the reset() method or PREPARED to set it to 0
   */
  IDLE,

  /**
   * Set the legal time (positive number) at this time to cancel the ash can click Start
   */
  PREPARED,

  /**
   * Continuously update the time starting from click on PREPARE or PAUSED
   */
  RUNNING,

  /**
   * Click Pause from the RUNNING state
   */
  PAUSED,

  /**
   * RUNNING status Automatically transitions to STOPPED when the countdown ends. This state is not triggered externally
   */
  STOPPED
}

export class CountdownController {
  private totalTimeMs: number = 0;
  private currentTimeMs: number = 0;
  private notifierId: number = 0;
  private startTimestamp: number = 0;
  private startAnchorTimeMs: number = 0;
  private state: CountdownState = CountdownState.IDLE;
  private timeUpdateListener: (currentTimeMs: number, totalTimeMs: number) => void = undefined;
  private stateUpdateListener: (CountdownState) => void = undefined;
  private preferences = null;
  private totalTimeMsStr: string = 'totalTimeMs';
  private countdownStr: string = 'Countdown';
  private countdownStateStr: string = 'CountdownState';
  private startAnchorTimeMsStr: string = 'startAnchorTimeMs';
  private startTimestampStr: string = 'startTimestamp';

  /**
   * Set time listener.
   */
  public setTimeUpdateListener(listener: (currentTimeMs: number, totalTimeMs: number) => void) {
    this.timeUpdateListener = listener;
  }

  /**
   * Set countdownState listener.
   */
  public setStateUpdateListener(listener: (CountdownState) => void) {
    this.stateUpdateListener = listener;
  }

  /**
   * Set countdown time.
   */
  public setTime(totalTimeMs: number) {
    LogUtil.info(`${TAG} set countdown time. `);
    if (this.state != CountdownState.IDLE && this.state != CountdownState.PREPARED) {
      throw ('only support set time before start!');
    }
    if (totalTimeMs < 0) {
      throw ('illegal totalTimeMs!');
    }
    this.totalTimeMs = totalTimeMs;
    LogUtil.info(`${TAG} countdown totalTime: ${this.totalTimeMs}ms. `);
    this.startAnchorTimeMs = this.totalTimeMs;
    this.updateData(this.totalTimeMsStr, this.totalTimeMs);
    this.updateData(this.startAnchorTimeMsStr, this.startAnchorTimeMs);
    this.currentTimeMs = totalTimeMs;
    this.notifyTimeChanges();
    if (this.state == CountdownState.IDLE && totalTimeMs > 0) {
      this.state = CountdownState.PREPARED;
      this.updateData(this.countdownStateStr, this.state);
      this.notifyStateChanges();
    } else if (this.state == CountdownState.PREPARED && totalTimeMs == 0) {
      this.state = CountdownState.IDLE;
      this.updateData(this.countdownStateStr, this.state);
      this.notifyStateChanges();
    }
  }

  private notifyTimeChanges() {
    if (this.timeUpdateListener) {
      this.timeUpdateListener(this.currentTimeMs, this.totalTimeMs);
    }
  }

  private notifyStateChanges() {
    if (this.stateUpdateListener) {
      this.stateUpdateListener(this.state);
    }
  }

  /**
   * Countdown start.
   */
  public start() {
    LogUtil.info(`${TAG} countdown start. `);
    if (this.state != CountdownState.PREPARED && this.state != CountdownState.PAUSED) {
      return;
    }
    LogUtil.info(`${TAG} countdown start in. `);
    if (this.totalTimeMs > 0 && this.currentTimeMs > 0) {
      if (this.currentTimeMs >= ConfigData.NOTIFY_INTERVAL_MS) {
        this.startTimestamp = new Date().getTime();
        this.updateData(this.startTimestampStr, this.startTimestamp);
        this.countdown();
      } else {
        this.lastRefresh();
      }
    }
    this.state = CountdownState.RUNNING;
    this.updateData(this.countdownStateStr, this.state);
    this.notifyStateChanges();
  }

  /**
   * Countdown start-up.
   */
  public countdown() {
    LogUtil.info(`${TAG} countdown start up. `);
    this.notifierId = setInterval(() => {
      let timestamp = new Date().getTime();
      this.currentTimeMs = this.startAnchorTimeMs - (timestamp - this.startTimestamp);
      if (this.currentTimeMs <= 0) {
        this.currentTimeMs = 0;
        clearInterval(this.notifierId);
        this.notifierId = 0;
      } else if (this.currentTimeMs < ConfigData.NOTIFY_INTERVAL_MS) {
        clearInterval(this.notifierId);
        this.notifierId = 0;
        this.lastRefresh();
      }
      this.notifyTimeChanges();
      if (this.currentTimeMs == 0) {
        this.state = CountdownState.STOPPED;
        this.updateData(this.countdownStateStr, this.state);
        this.notifyStateChanges();
      }
    }, ConfigData.NOTIFY_INTERVAL_MS);
  }

  /**
   * Countdown reStart.
   */
  public reStart() {
    LogUtil.info(`${TAG} countdown reStart. `)
    if (this.state == CountdownState.STOPPED) {
      this.state = CountdownState.PREPARED;
      this.updateData(this.countdownStateStr, this.state);
      this.notifyStateChanges();
    }
  }

  /**
   * Countdown lastRefresh.
   */
  public lastRefresh() {
    LogUtil.info(`${TAG} countdown lastRefresh. `);
    setTimeout(() => {
      this.currentTimeMs = 0;
      this.notifyTimeChanges();
      this.state = CountdownState.STOPPED;
      this.updateData(this.countdownStateStr, this.state);
      this.notifyStateChanges();
    }, this.currentTimeMs);
  }

  /**
   * Countdown pause.
   */
  public pause() {
    LogUtil.info(`${TAG} countdown pause. `);
    if (this.state != CountdownState.RUNNING) {
      return;
    }
    LogUtil.info(`${TAG} countdown pause in. `);
    let timestamp = new Date().getTime();
    clearInterval(this.notifierId);
    this.startAnchorTimeMs = this.startAnchorTimeMs - (timestamp - this.startTimestamp);
    this.updateData(this.startAnchorTimeMsStr, this.startAnchorTimeMs);
    this.notifierId = 0;
    this.state = CountdownState.PAUSED;
    this.updateData(this.countdownStateStr, this.state);
    this.notifyStateChanges();
  }

  /**
   * Countdown reset.
   */
  public reset() {
    LogUtil.info(`${TAG} countdown reset. `);
    if (this.state == CountdownState.IDLE) {
      return;
    }
    LogUtil.info(`${TAG} countdown reset in. `);
    if (this.notifierId != 0) {
      clearInterval(this.notifierId);
      this.notifierId = 0;
    }
    this.totalTimeMs = 0;
    this.updateData(this.totalTimeMsStr, this.totalTimeMs);
    this.currentTimeMs = 0;
    this.startTimestamp = 0;
    this.updateData(this.startTimestampStr, this.startTimestamp);
    this.startAnchorTimeMs = 0;
    this.notifyTimeChanges();
    this.state = CountdownState.IDLE;
    this.updateData(this.countdownStateStr, this.state);
    this.notifyStateChanges();
  }

  /**
   * Get preferences data.
   */
  public async getPreferences() {
    if (!this.preferences) {
      this.preferences = await dataStorage.getPreferences(globalThis.abilityContext, this.countdownStr);
    }
  }

  /**
   * Instance matching a specified preferences file name.
   */
  public async getData() {
    await this.getPreferences();
    this.state = await this.preferences.get(this.countdownStateStr, CountdownState.IDLE);
    this.startTimestamp = await this.preferences.get(this.startTimestampStr, 0);
    this.totalTimeMs = await this.preferences.get(this.totalTimeMsStr, 0);
    this.startAnchorTimeMs = await this.preferences.get(this.startAnchorTimeMsStr, 0);

    if (this.state == CountdownState.PREPARED) {
      this.currentTimeMs = this.totalTimeMs;
    } else if (this.state == CountdownState.RUNNING) {
      this.countdown();
    } else if (this.state == CountdownState.PAUSED) {
      this.currentTimeMs = this.startAnchorTimeMs;
    }
    this.notifyStateChanges();
    this.notifyTimeChanges();
  }

  /**
   * Put and flush preferences data.
   */
  public async updateData(key: string, defValue: string | number) {
    if (this.preferences) {
      await this.preferences.put(key, defValue);
      await this.preferences.flush();
    }
  }
}