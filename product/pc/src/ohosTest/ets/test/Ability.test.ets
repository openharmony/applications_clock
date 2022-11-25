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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium'
import { TimerController, TimerState } from '@ohos/timer';
import { CountdownController, CountdownState } from '@ohos/countdown';
import { TimerUtil } from '@ohos/common';

export default function abilityTest() {
  describe('ActsAbilityTest', function () {

    it('startState', 0, function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(TimerState.RUNNING);
          testState = false;
        }
      });
      testState = true;
      mTimerController.start();
    })

    it('startTime', 0, function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(time > 0).assertTrue();
          testState = false;
        }
      });
      testState = true;
      mTimerController.start();
    })

    it('clockUpdate', 0, function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setClockUpdateListener((time) => {
        if (testState) {
          expect(time > 0).assertTrue();
          testState = false;
        }
      });
      testState = true;
      mTimerController.start();
    })

    it('pauseState', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(TimerState.PAUSED);
          testState = false;
        }
      });
      await mTimerController.start();
      testState = true;
      setTimeout(async () => {
        await mTimerController.pause();
      }, 100);
    })

    it('pauseTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      let testTime = 0;
      mTimerController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(testTime).assertEqual(time);
          testState = false;
        } else {
          testTime = time;
        }
      });
      await mTimerController.start();
      await mTimerController.pause();
      testState = true;
      setTimeout(async () => {
        await mTimerController.start();
      }, 100);
    })

    it('resetAfterStartState', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(TimerState.IDLE);
          testState = false;
        }
      });
      await mTimerController.start();
      testState = true;
      setTimeout(async () => {
        await mTimerController.reset();
      }, 100);
    })

    it('resetAfterStartTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(time).assertEqual(0);
          testState = false;
        }
      });
      await mTimerController.start();
      testState = true;
      setTimeout(async () => {
        await mTimerController.reset();
      }, 100);
    })

    it('reStartState', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(TimerState.RUNNING);
          testState = false;
        }
      });
      await mTimerController.start();
      setTimeout(async () => {
        await mTimerController.pause();
        testState = true;
        await mTimerController.start();
      }, 100);
    })

    it('reStartStateTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      let testTime = 0;
      mTimerController.setTimeUpdateListener((time) => {
        if (testTime > 0) {
          expect(testTime < time).assertTrue();
          testState = false;
        } else if (testState == true) {
          testTime = time;
        }
      });
      await mTimerController.start();
      await mTimerController.pause();
      testState = true;
      setTimeout(async () => {
        await mTimerController.start();
      }, 100);
    })

    it('resetAfterPauseState', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(TimerState.IDLE);
          testState = false;
        }
      });
      await mTimerController.start();
      setTimeout(async () => {
        await mTimerController.pause();
        testState = true;
        await mTimerController.reset();
      }, 100);
    })

    it('resetAfterPauseTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(time).assertEqual(0);
          testState = false;
        }
      });
      await mTimerController.start();
      setTimeout(async () => {
        await mTimerController.pause();
        testState = true;
        await mTimerController.reset();
      }, 100);
    })

    it('writeTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setTimeListUpdateListener((timeList) => {
        if (testState) {
          expect(timeList.length > 1).assertTrue();
          testState = false;
        }
      });
      await mTimerController.start();
      setTimeout(async () => {
        testState = true;
        await mTimerController.writeTime();
      }, 100);
    })

    it('resetWriteTime', 0, async function () {
      let mTimerController = new TimerController();
      let testState = false;
      mTimerController.setTimeListUpdateListener((timeList) => {
        if (testState) {
          expect(timeList.length).assertEqual(0);
          testState = false;
        }
      });
      await mTimerController.start();
      setTimeout(async () => {
        await mTimerController.writeTime();
        testState = true;
        mTimerController.reset();
      }, 100);
    })

    it('addZeroMin', 0, async function () {
      let num = 0
      let res = TimerUtil.addZero(num)
      expect(res).assertEqual('00')
    })

    it('addZeroMinus', 0, async function () {
      let num = -1
      let res = TimerUtil.addZero(num)
      expect(res).assertEqual('0-1')
    })

    it('addZeroMax', 0, async function () {
      let num = 9
      let res = TimerUtil.addZero(num)
      expect(res).assertEqual('09')
    })

    it('addZeroOver', 0, async function () {
      let num = 10
      let res = TimerUtil.addZero(num)
      expect(res).assertEqual('10')
    })

    it('addZeroNaN', 0, async function () {
      let num = NaN
      let res = TimerUtil.addZero(num)
      expect(res).assertEqual('NaN')
    })

    it('timeFormatZero', 0, async function () {
      let num = 0
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`00:00.00`)
    })

    it('timeFormatMinus', 0, async function () {
      let num = -1
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`00:00.00`)
    })

    it('timeFormatMinMs', 0, async function () {
      let num = 9
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`00:00.00`)
    })

    it('timeFormatMs', 0, async function () {
      let num = 10
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`00:00.01`)
    })

    it('timeFormatSec', 0, async function () {
      let num = 1000
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`00:01.00`)
    })

    it('timeFormatMin', 0, async function () {
      let num = 1000 * 60
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`01:00.00`)
    })

    it('timeFormatHour', 0, async function () {
      let num = 1000 * 60 * 60
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`01:00:00.00`)
    })

    it('timeFormatDay', 0, async function () {
      let num = 1000 * 60 * 60 * 24
      let res = TimerUtil.timeFormat(num)
      expect(res).assertEqual(`01:00:00:00.00`)
    })
  })

  describe('CountdownTest', function () {
    it('setTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testState) {
          expect(totalTimeMs).assertEqual(100);
          testState = false;
        }
      });
      testState = true;
      mCountdownController.setTime(100);
    })

    it('setTimeState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.PREPARED);
          testState = false;
        }
      });
      testState = true;
      mCountdownController.setTime(100);
    })

    it('startState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.RUNNING);
          testState = false;
        }
      });
      mCountdownController.setTime(100);
      testState = true;
      mCountdownController.start();
    })

    it('startTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testState) {
          expect(currentTimeMs > 0).assertTrue();
          testState = false;
        }
      });
      mCountdownController.setTime(100);
      testState = true;
      mCountdownController.start();
    })

    it('pauseState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.PAUSED);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      testState = true;
      setTimeout(() => {
        mCountdownController.pause();
      }, 100);
    })

    it('pauseTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      let testTime = 0;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testState) {
          expect(testTime).assertEqual(totalTimeMs);
          testState = false;
        } else {
          testTime = totalTimeMs;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      mCountdownController.pause();
      testState = true;
      setTimeout(() => {
        mCountdownController.start();
      }, 100);
    })

    it('resetAfterStartState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.IDLE);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      testState = true;
      setTimeout(() => {
        mCountdownController.reset();
      }, 100);
    })

    it('resetAfterStartTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testState) {
          expect(totalTimeMs).assertEqual(0);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      testState = true;
      setTimeout(() => {
        mCountdownController.reset();
      }, 100);
    })

    it('reStartState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.RUNNING);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      setTimeout(() => {
        mCountdownController.pause();
        testState = true;
        mCountdownController.start();
      }, 100);
    })

    it('reStartStateTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      let testTime = 0;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testTime > 0) {
          expect(testTime < totalTimeMs).assertTrue();
          testState = false;
        } else if (testState == true) {
          testTime = currentTimeMs;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      mCountdownController.pause();
      testState = true;
      setTimeout(() => {
        mCountdownController.start();
      }, 100);
    })

    it('resetAfterPauseState', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(CountdownState.IDLE);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      setTimeout(() => {
        mCountdownController.pause();
        testState = true;
        mCountdownController.reset();
      }, 100);
    })

    it('resetAfterPauseTime', 0, function () {
      let mCountdownController = new CountdownController();
      let testState = false;
      mCountdownController.setTimeUpdateListener((currentTimeMs: number, totalTimeMs: number) => {
        if (testState) {
          expect(totalTimeMs).assertEqual(0);
          testState = false;
        }
      });
      mCountdownController.setTime(10000);
      mCountdownController.start();
      setTimeout(() => {
        mCountdownController.pause();
        testState = true;
        mCountdownController.reset();
      }, 100);
    })
  })
}