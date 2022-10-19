/**
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
import ConfigData from "./ConfigData"

export class TimerUtil {
  /**
   * Time format conversion
   * @param timestamp
   */
  timeFormat(timestamp: number) {
    if (timestamp <= 0) {
      return "00:00.00"
    }
    let timeStr = ""
    let day = Math.floor(timestamp / ConfigData.ONE_DAY_TIME)
    if (day > 0) {
      timeStr += this.addZero(day) + ":"
    }
    let hour = Math.floor(timestamp % ConfigData.ONE_DAY_TIME / ConfigData.ONE_HOUR_TIME)
    if (hour > 0 || day > 0) {
      timeStr += this.addZero(hour) + ":"
    }
    let min = Math.floor(timestamp % ConfigData.ONE_HOUR_TIME / ConfigData.ONE_MINUTE_TIME)
    timeStr += this.addZero(min) + ":"
    let sec = Math.floor(timestamp % ConfigData.ONE_MINUTE_TIME / ConfigData.ONE_SECOND_TIME)
    timeStr += this.addZero(sec) + "."
    let mSec = Math.floor(timestamp % ConfigData.ONE_SECOND_TIME / 10)
    timeStr += this.addZero(mSec)
    return timeStr
  }

  /**
   * If the number is less than 10, add "0".
   * @param num
   */
  addZero(num) {
    return (num < 10 ? "0" + num : num).toString()
  }
}

let mTimerUtil = new TimerUtil()

export default mTimerUtil as TimerUtil