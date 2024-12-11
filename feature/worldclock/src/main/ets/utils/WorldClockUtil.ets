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

import i18n from '@ohos.i18n';
import resmgr from '@ohos.resourceManager';
import {
  MINUTE_IN_HOUR,
  SECOND_IN_MINUTE,
  MILLIS_IN_SECOND,
  HOURS_IN_ONE_DAY,
  FIRST_PARAM,
  SECOND_PARAM,
  CalendarFiled,
  GlobalContext
} from '@hmos/common';

/**
 * Word Clock Util
 *
 * @since 2022-12-08
 */
export class WorldClockUtil {
  /**
   * update timezone information
   *
   * @param the offset of timezone
   * @return the formatted timezone info
   */
  static async updateTimeZoneInfo(rawOffset: number, timeZone: string, cityIndex: string): Promise<string> {
    const calendar = i18n.getCalendar(i18n.getSystemLocale());
    calendar.setTimeZone(timeZone);
    let year = calendar.get(CalendarFiled.Year)
    let month = calendar.get(CalendarFiled.Month);
    let date = calendar.get(CalendarFiled.Date)
    let hour = calendar.get(CalendarFiled.Hour_OF_Day)
    let minute = calendar.get(CalendarFiled.Minute)
    const timeStamp = new Date(year, month, date, hour, minute).getTime();
    const currentOffset = i18n.TimeZone.getTimezoneFromCity(cityIndex).getOffset(timeStamp);
    const offset = i18n.getTimeZone().getRawOffset();
    const cityOffset = currentOffset - offset;
    const hours = cityOffset / (MINUTE_IN_HOUR * SECOND_IN_MINUTE * MILLIS_IN_SECOND);
    const minutes = Math.abs(cityOffset / (SECOND_IN_MINUTE * MILLIS_IN_SECOND)) % MINUTE_IN_HOUR;

    let minSeq: string;
    let hourSeq: string;
    if ((hours == 0) || minutes == 0) {
      minSeq = (minutes == 0) ? '' : (await (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getPluralStringValue(
        $r('app.plural.minute').id, minutes));
      hourSeq = (hours == 0) ? '' : (await (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getPluralStringValue(
        $r('app.plural.hour').id, Math.abs(hours)));
    } else {
      minSeq = (await (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getPluralStringValue($r('app.plural.minute')
        .id, minutes));
      hourSeq = (await (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getPluralStringValue(
        $r('app.plural.hour').id, Math.abs(hours))) + ' ';
    }
    if (currentOffset > rawOffset) {
      let cityTimeZoneInfo: string = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('text_with_separate')
        .replace(FIRST_PARAM, WorldClockUtil.getDayString(hours, hourSeq, minSeq))
        .replace(SECOND_PARAM, (GlobalContext.getContext()
          .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('world_digital_dst_tv'));
      return cityTimeZoneInfo;
    }
    return WorldClockUtil.getDayString(hours, hourSeq, minSeq);
  }

  private static getDayString(hours: number, hourSeq: string, minSeq: string) {
    let cityTimeZoneInfo: string = '';
    const date = new Date();
    const hour = date.getHours() + hours;

    let fast: string = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('fastGMT')
      .replace(FIRST_PARAM, hourSeq)
      .replace(SECOND_PARAM, minSeq);
    let late: string = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('lateGMT')
      .replace(FIRST_PARAM, hourSeq)
      .replace(SECOND_PARAM, minSeq);

    if (hour >= 0 && hour <= HOURS_IN_ONE_DAY) {
      let today: string = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('today');
      if (hour > date.getHours()) {
        cityTimeZoneInfo = (GlobalContext.getContext()
          .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('text_with_separate')
          .replace(FIRST_PARAM, today)
          .replace(SECOND_PARAM, fast);
      } else if (hour < date.getHours()) {
        cityTimeZoneInfo = (GlobalContext.getContext()
          .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('text_with_separate')
          .replace(FIRST_PARAM, today)
          .replace(SECOND_PARAM, late);
      } else {
        cityTimeZoneInfo = today;
      }
    } else if (hour < 0) {
      let yesterday: string = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('yesterday');
      cityTimeZoneInfo = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('text_with_separate')
        .replace(FIRST_PARAM, yesterday)
        .replace(SECOND_PARAM, late);
    } else if (hour > HOURS_IN_ONE_DAY) {
      let tomorrow: string = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('tomorrow');
      cityTimeZoneInfo = (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('text_with_separate')
        .replace(FIRST_PARAM, tomorrow)
        .replace(SECOND_PARAM, fast);
    }
    return cityTimeZoneInfo;

  }
}