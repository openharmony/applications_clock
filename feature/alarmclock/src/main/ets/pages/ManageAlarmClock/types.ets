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

import { AlarmInfo } from '@hmos/common';

export interface SnoozeInfo {
  times: number; // Snooze times
  duration: number; // Snooze duration
}

export interface ManageAlarmClockParam {
  alarmInfoToEdit?: AlarmInfo;
}

// Default ringing duration(5 minutes)
export const DFT_RING_DURATION = 5;

// Default snooze duration(10 minutes)
export const DFT_SNOOZE_DURATION = 10;

// Default snooze times(3 times)
export const DFT_SNOOZE_TIMES = 3;

export const DFT_SNOOZE_INFO: SnoozeInfo = {
  duration: DFT_RING_DURATION,
  times: DFT_SNOOZE_TIMES,
}

// Snooze times(minutes)
export const SNOOZE_TIMES_OPTIONS = [0, 1, 3, 5, 10];

// Snooze duration options(minutes)
export const SNOOZE_DURATION_OPTIONS = [5, 10, 15, 20, 25, 30];

// Ringing duration options(minutes)
export const RING_DURATION_OPTIONS = [1, 5, 10, 15, 20, 30];

export const TIME_PICKER_HEIGHT = '30%';

export const TIME_PICKER_WIDTH = '100%';

export const DELETE_BUTTON_WIDTH = '50%';

export const HTTP_TIMEOUT_TIMER = 1000;

