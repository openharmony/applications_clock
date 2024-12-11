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

import { LogUtil, WantAgentUtil, TimerServiceType, TIMER_NOTICE_ID } from '../utils';
// import systemTimer from '@ohos.systemTimer';
import { BusinessError } from '@ohos.base';

const TAG = 'SystemTimerManager';
const DELAY_TIME = 300

class TimerSystemTimer {
  private timerId: number = -1;

  async create(delay: number) {
    try {
      // const _options: systemTimer.TimerOptions = {
      //   type: systemTimer.TIMER_TYPE_EXACT | systemTimer.TIMER_TYPE_WAKEUP,
      //   repeat: false,
      //   wantAgent: await WantAgentUtil.timerWantAgent(TimerServiceType.Firing, TIMER_NOTICE_ID, 0)
      // }
      const _delay: number = Date.now() + delay + DELAY_TIME;
      this.destory();
      // await systemTimer.createTimer(_options).then((timerId: number) => {
      //   LogUtil.info(TAG, `SystemTimer Create Success: ${timerId}`);
      //   this.timerId = timerId;
      //   this.start(_delay);
      // }).catch((error: BusinessError) => {
      //   LogUtil.info(TAG, `SystemTimer Create Fail: ${error.message}, code: ${error.code}`);
      // });
    } catch (error) {
      LogUtil.info(TAG, `SystemTimer Create Anomalies: ${error.message}, code: ${error.code}`);
    }
  }

  async start(_delay: number) {
    try {
      // await systemTimer.startTimer(this.timerId, _delay).then(() => {
      //   LogUtil.info(TAG, `SystemTimer Start Success`);
      // }).catch((error: BusinessError) => {
      //   LogUtil.info(TAG, `SystemTimer Start Fail: ${error.message}, code: ${error.code}`);
      // });
    } catch (error) {
      LogUtil.info(TAG, `SystemTimer Start Anomalies: ${error.message}, code: ${error.code}`);
    }
  }

  async destory() {
    try {
      if (this.timerId > -1) {
        // await systemTimer.destroyTimer(this.timerId).then(() => {
        //   LogUtil.info(TAG, `SystemTimer Destroy Success`);
        //   this.timerId = -1;
        // }).catch((error: BusinessError) => {
        //   LogUtil.info(TAG, `SystemTimer Destroy Fail: ${error.message}, code: ${error.code}`);
        // });
      } else {
        return;
      }
    } catch (error) {
      LogUtil.info(TAG, `SystemTimer Destroy Anomalies: ${error.message}, code: ${error.code}`);
    }

  }
}

export default new TimerSystemTimer();


