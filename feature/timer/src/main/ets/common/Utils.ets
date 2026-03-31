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

import { LogUtil } from '@hmos/common';
import { DateObject } from '../model/Index'

export { DateObject }

const TAG: string = 'Timer_Utils';

/**
 * 0 到 9 数字变双位数：00 09
 *
 */
export function prevInsertZero(num: number = 0): string {
  return String(num).padStart(2, '0');
}

/**
 * 毫秒转 时分秒
 *
 */
export function formatMillisecondToObject(allMillisecond: number = 0): DateObject {
  let ms = Math.floor(allMillisecond % 1000);
  let s = Math.floor(allMillisecond / 1000);
  let m = Math.floor(s / 60);
  let h = Math.floor(m / 60);

  s %= 60;
  m %= 60;

  let hours = prevInsertZero(h);
  let minute = prevInsertZero(m);
  let seconds = prevInsertZero(s);
  let millisecond = prevInsertZero(ms);
  LogUtil.info(TAG, `allMillisecond=>${allMillisecond},${hours}:${minute}:${seconds}:${millisecond}`)
  return new DateObject(hours, minute, seconds, millisecond)
}