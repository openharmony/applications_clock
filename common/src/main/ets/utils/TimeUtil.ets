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

import i18n from '@ohos.i18n';
import Intl from '@ohos.intl';
import intl from '@ohos.intl';
import resmgr from '@ohos.resourceManager';
// import systemTimer from '@ohos.systemTimer';
import SnoozeManager from '../manager/SnoozeManager'
import { AlarmInfo, AlarmManager, ResourceManager, TimerManager, TRIGGER_TIME_NEVER } from '../manager';
import preferencesUtil from '@ohos.data.preferences';
import { BusinessError } from '@ohos.base';
import {
  AFTERNOON_START_POINT,
  CalendarFiled,
  DAYS_OF_WEEK_COUNT,
  DAYS_OF_WEEK_WORK_DAY_COUNT,
  DEFAULT_DAY,
  DIGIT_TIME_FORMAT,
  FormatTime,
  HOUR_12_TIME_FORMAT_REG_EXP,
  HOUR_12_TIME_FORMAT_REG_EXP_WITH_SECOND,
  INDEX_FRIDAY,
  INDEX_OFFSET,
  INDEX_SATURDAY,
  LANGUAGE_ZH,
  LAST_TAG_ID,
  LESS_THAN_ONE_MINUTE_FLAG,
  NO_ALARM_ENABLED,
  ONE_DAY,
  ONE_MINUTE,
  SINGLE_NUMBER_END_POINT,
  TIME_TAG_GROUP_SIZE,
  TIME_TAG_ID_LIST_IN_ZH,
  TimeFormatIndex,
  WEEK_DAY_BASIC_MONTH,
  WEEK_DAY_BASIC_YEAR,
  WeekDayFormat,
  WAKE_DAYS_TYPE,
  SUNDAY,
  SATURDAY,
  MONTH_LIST,
  CACHE_HOLIDAYS_LIST,
  HolidaysType,
  NetHolidaysType
} from './types';
import { HOURS_IN_ONE_DAY, MILLIS_IN_SECOND, MINUTE_IN_HOUR, SECOND_IN_MINUTE } from '../types';
import { LogUtil } from './LogUtil';
import { GlobalContext } from '../utils';
import { CommonUtil } from './CommonUtil';
import http from '@ohos.net.http';

const TAG: string = 'TimeUtil';
let nextDay: number = 0;

export interface urlType {
  url: string,
}

/**
 * Time processing tool class
 *
 * @since 2022-07-06
 */
export class TimeUtil {
  private static daysOfWeekLabelCache: Map<string, string[]> = new Map<string, string[]>();
  public static getDayOfWeekByDate: (date: Date) => string = CommonUtil.getDayOfWeekByDateNotHO;

  /**
   * Get the tag of the time segment based on the hour in Chinese.
   * If 23 is transferred, "半夜" is returned.
   *
   * @param hour Hour to be queried
   * @return The tag of the time segment based on the hour in Chinese
   */
  static getChinaTimeTag(hour: number): string {
    if (hour === 0) {
      // 0 点取最后一个时间段（即 23 点 到 0 点）的标签
      return ResourceManager.getStringById(LAST_TAG_ID);
    }
    const index = Math.floor((hour - INDEX_OFFSET) / TIME_TAG_GROUP_SIZE); // 将小时转换为时间段标签的下标
    return ResourceManager.getStringById(TIME_TAG_ID_LIST_IN_ZH[index]);
  }

  /**
   * Get the formatted time information in the current language and time system based on the hour and minute.
   *
   * For example, if 23:16 is transferred in Chinese and the time format is 12 hours,
   * the following information will be returned：
   * { time: '11:16', tag: '半夜', isTagLeft: true }
   *
   * @param hour
   * @param minute
   * @param second
   * @return The formatted time information
   */
  static getFormattedTimeObj(hour: number, minute: number, second ?: number): FormatTime {
    const is24HourClock = i18n.is24HourClock();
    let option: intl.DateTimeOptions;
    let timeObj: Date;
    const currentDate = new Date();
    if (second || second === 0) {
      option = {
        hour: DIGIT_TIME_FORMAT,
        minute: DIGIT_TIME_FORMAT,
        second: DIGIT_TIME_FORMAT,
        hour12: !is24HourClock,
      };
      timeObj = new Date(currentDate.getFullYear(), currentDate.getMonth(), DEFAULT_DAY, hour, minute, second);
    } else {
      option = { hour: DIGIT_TIME_FORMAT, minute: DIGIT_TIME_FORMAT, hour12: !is24HourClock };
      timeObj = new Date(currentDate.getFullYear(), currentDate.getMonth(), DEFAULT_DAY, hour, minute);
    }
    let locale = new Intl.Locale(i18n.System.getSystemLanguage());
    const timeWithFormat = new Intl.DateTimeFormat(locale.toString(), option).format(timeObj);
    let hours = hour;
    if (hour === 0 && !is24HourClock) {
      hours = AFTERNOON_START_POINT;
    } else if (hour > AFTERNOON_START_POINT) {
      hours = hour - AFTERNOON_START_POINT;
    }
    if (is24HourClock) {
      return {
        time: (hour < SINGLE_NUMBER_END_POINT ? `0${hour}` : hour) + timeWithFormat.substring(TimeFormatIndex.HOUR, timeWithFormat.length),
      };
    }
    const parts = timeWithFormat.match(second || second === 0 ? HOUR_12_TIME_FORMAT_REG_EXP_WITH_SECOND :
      HOUR_12_TIME_FORMAT_REG_EXP);
    const leftTag: string = parts ? parts[TimeFormatIndex.LEFT_TAG].trim() : '';
    const isChinaTime: boolean = i18n.getSystemLanguage().startsWith(LANGUAGE_ZH);
    const time: string = parts ? hours + parts.slice(TimeFormatIndex.MINUTE - 1, second || second === 0 ?
    TimeFormatIndex.RIGHT_TAG_WITH_SECOND : TimeFormatIndex.RIGHT_TAG)
      .join('') : '';
    const rightTag: string = parts ? parts[second || second === 0 ? TimeFormatIndex.RIGHT_TAG_WITH_SECOND : TimeFormatIndex.RIGHT_TAG].trim() : '';
    return {
      time: time,
      tag: isChinaTime ? TimeUtil.getChinaTimeTag(hour) : (leftTag || rightTag),
      isTagLeft: !!leftTag,
    }
  }

  /**
   * Get formatted time
   *
   * @param time Time to format. If this parameter is undefined or zero, get the current time.
   * @return Formatted time like '8:10 AM' in English or '早上8:10' in Chinese.
   */
  static getFormattedTime(time?: number): string {
    const nowDate = time ? new Date(time) : new Date();
    const timeObj = TimeUtil.getFormattedTimeObj(nowDate.getHours(), nowDate.getMinutes());
    if (timeObj.tag) {
      return timeObj.isTagLeft ? `${timeObj.tag}${timeObj.time}` : `${timeObj.time} ${timeObj.tag}`;
    }
    return timeObj.time as string;
  }

  /**
   * Get formatted time of specific timezone ID
   *
   * @param timeZone
   * @return The formatted time information.
   */
  static getFormattedTimeZoneTimeObjByTimeZone(timeZone: string): FormatTime {
    const calendar = i18n.getCalendar(i18n.getSystemLocale());
    calendar.setTimeZone(timeZone);
    let hour = calendar.get(CalendarFiled.Hour_OF_Day)
    let minute = calendar.get(CalendarFiled.Minute)
    let second = calendar.get(CalendarFiled.Second);
    const timeObj = TimeUtil.getFormattedTimeObj(hour, minute);
    return {
      time: timeObj.time,
      tag: timeObj.isTagLeft == undefined ? '' : timeObj.tag,
      isTagLeft: timeObj.isTagLeft,
    }
  }

  /**
   * Get the formatted time information in the current language and time system based on the hour and minute.
   *
   * For example, if 23:16:00 is transferred in Chinese and the time format is 12 hours,
   * the following information will be returned：
   * { time: '11:16:00', tag: '半夜', isTagLeft: true }
   *
   * @param time Time to format. If this parameter is undefined or zero, get the current time.
   * @return The formatted time information
   */
  static getFullFormattedTimeObj(time?: number): FormatTime {
    const nowDate = time ? new Date(time) : new Date();
    const timeObj = TimeUtil.getFormattedTimeObj(nowDate.getHours(), nowDate.getMinutes(), nowDate.getSeconds());
    return {
      time: timeObj.time,
      tag: timeObj.isTagLeft == undefined ? '' : timeObj.tag,
      isTagLeft: timeObj.isTagLeft,
    }
  }

  /**
   * Get current formatted date with week day
   *
   * @return Current formatted date with week day like 'Friday, August 19'
   */
  static getCurrentFormattedDateWithWeek(): string {
    const nowDate = new Date();
    return nowDate.toLocaleDateString(i18n.getSystemLanguage(), {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    });
  }

  /**
   * Query which day of the week the Nth day is.
   *
   * @param day Index of the queried week day
   * @param weekDayFormat The format of week day, the default value is WeekDayFormat.Short
   * @return The description of the queried day of a week in the corresponding language.
   */
  static getDayOfWeek(day: number, weekDayFormat: WeekDayFormat): string {
    const options: intl.DateTimeOptions = { weekday: weekDayFormat || WeekDayFormat.Short };
    const date = new Date(WEEK_DAY_BASIC_YEAR, WEEK_DAY_BASIC_MONTH);
    date.setDate(day + 1);
    let locale = new Intl.Locale(i18n.System.getSystemLanguage());
    const timeWithFormat = new Intl.DateTimeFormat(locale.toString(), options).format(date);
    return timeWithFormat;
  }

  /**
   * Get the description of each day of a week in the corresponding language.
   *
   * @return The description of each day of a week in the corresponding language.
   */
  static getDaysOfWeekLabels(): string[] {
    const language = i18n.getSystemLanguage();
    let weekLabels = TimeUtil.daysOfWeekLabelCache.get(language);
    if (weekLabels) {
      return weekLabels;
    }
    // In Chinese, '周 X' is always used instead of '星期 X', therefore, the short format is used here.
    const weekDayFormat = language.startsWith(LANGUAGE_ZH) ? WeekDayFormat.Short : WeekDayFormat.Long;
    weekLabels = [0, 1, 2, 3, 4, 5, 6].map(weekDay => TimeUtil.getDayOfWeek(weekDay, weekDayFormat));
    TimeUtil.daysOfWeekLabelCache.set(language, weekLabels);
    return weekLabels;
  }

  /**
   * Convert the Days-of-week information of an alarm to the repetition information displayed in the alarm list.
   *
   * @param daysOfWeek Days-of-week information for repetition
   * @return The repetition information to display
   */
  static getDaysOfWeekDesc(resourceManager: resmgr.ResourceManager, daysOfWeek: number[]): string {
    const daysOfWeekLength = daysOfWeek.length;
    if (daysOfWeekLength === 0) {
      return resourceManager.getStringSync($r('app.string.only_ring_once').id);
    }
    if (daysOfWeekLength === DAYS_OF_WEEK_COUNT) {
      return resourceManager.getStringSync($r('app.string.every_day').id);
    }
    if (daysOfWeekLength === DAYS_OF_WEEK_WORK_DAY_COUNT &&
      daysOfWeek[daysOfWeekLength - 1] === INDEX_FRIDAY && daysOfWeek[0] === 1) {
      return resourceManager.getStringSync($r('app.string.monday_to_friday').id);
    }
    if (daysOfWeekLength > 1 && daysOfWeek[daysOfWeek.length - 1] === INDEX_SATURDAY) {
      daysOfWeek.pop();
      daysOfWeek.unshift(INDEX_SATURDAY);
    }
    return daysOfWeek.map(weekDay => {
      return TimeUtil.getDayOfWeek(weekDay, WeekDayFormat.Short);
    }).join(' ');
  }

  /**
   * Gets the number of days until the next alarm
   *
   * @param daysOfWeek Days-of-week information for repetition
   * @param nearWeekDay The nearest day of week that the alarm may ring
   * @return The number of days until the next alarm
   */
  static getDaysToNextAlarm(daysOfWeek: number[], nearWeekDay: number): number {
    let dayCount = 0;
    for (; dayCount < DAYS_OF_WEEK_COUNT; dayCount++) {
      const day = (nearWeekDay + dayCount) % DAYS_OF_WEEK_COUNT;
      if (daysOfWeek.some(item => item === day)) {
        break;
      }
    }
    return dayCount;
  }

  /**
   * Get the next alarm time
   *
   * @param daysOfWeek Days-of-week information for repetition
   * @return The next alarm time
   */
  static getAlarmTime(alarmInfo: AlarmInfo): number {
    const daysOfWeek: number[] = alarmInfo.daysOfWeek;
    const hour: number = alarmInfo.hour;
    const minute: number = alarmInfo.minute;

    const alarmTime = new Date();
    alarmTime.setHours(hour);
    alarmTime.setMinutes(minute);
    alarmTime.setSeconds(0);
    alarmTime.setMilliseconds(0);

    const now = new Date();
    if (hour < now.getHours() || hour === now.getHours() && minute <= now.getMinutes()) {
      // If the alarm time of the current day has passed, the next alarm time must ring at least one day later.
      alarmTime.setDate(alarmTime.getDate() + ONE_DAY);
    }

    if (alarmInfo.daysOfWakeType === WAKE_DAYS_TYPE) { //选择法定工作日
      return TimeUtil.getFassDay(alarmInfo);
    }

    if (daysOfWeek.length === 0) {
      // The alarm is not repeated
      return alarmTime.getTime();
    }

    //  If the alarm is repeated,
    //  needs to find the next alarm time according to the days-of-week information for repetition.
    const daysToAdd = TimeUtil.getDaysToNextAlarm(daysOfWeek, alarmTime.getDay());
    alarmTime.setDate(alarmTime.getDate() + daysToAdd);
    return alarmTime.getTime();
  }

  /**
   * Get the next workdays alarm time
   *
   * @param Current alarmInfo
   * @return The next alarm time
   */
  static getFassDay(alarmInfo: AlarmInfo) {
    let cacheHolidaysList = AppStorage.get<HolidaysType>(CACHE_HOLIDAYS_LIST);
    LogUtil.info(TAG, ' getFassDay  cacheHolidaysList:' + JSON.stringify(cacheHolidaysList));
    let nowDay: number = TimeUtil.getNumberDay() - ONE_DAY;
    LogUtil.info(TAG, ' getFassDay  nowDay:' + nowDay);
    const hour: number = alarmInfo.hour;
    const minute: number = alarmInfo.minute;
    const now = new Date();

    const alarmTime = new Date();
    alarmTime.setHours(hour);
    alarmTime.setMinutes(minute);
    alarmTime.setSeconds(0);
    alarmTime.setMilliseconds(0);

    let freeDay: number[] = cacheHolidaysList?.freeday || [];
    let workday: number[] = cacheHolidaysList?.workday || [];

    let tomorrowDay: number = 0;
    if (hour < now.getHours() || hour === now.getHours() && minute <= now.getMinutes()) {
      tomorrowDay = 1;
    }

    // Network holidays data is not exit.
    if (!freeDay || !freeDay.length) {
      alarmTime.setDate(alarmTime.getDate() + tomorrowDay);
      return alarmTime.getTime();
    }

    TimeUtil.getNextDay(nowDay + tomorrowDay, freeDay);
    alarmTime.setDate(alarmTime.getDate() + (nextDay - nowDay));

    // Is saturday and not work, set alarm day add 1.
    if (alarmTime.getDay() === SATURDAY && !workday.includes(TimeUtil.getNumberDay(alarmTime.getTime()) - ONE_DAY)) {
      alarmTime.setDate(alarmTime.getDate() + ONE_DAY);
    }

    // Is sunday and not work, set alarm day add 1.
    if (alarmTime.getDay() === SUNDAY && !workday.includes(TimeUtil.getNumberDay(alarmTime.getTime()) - ONE_DAY)) {
      alarmTime.setDate(alarmTime.getDate() + ONE_DAY);
    }

    LogUtil.info(TAG, ' getFassDay  alarmTime.getTime:' + JSON.stringify(new Date(alarmTime.getTime())));
    return alarmTime.getTime();
  }


  static getNextDay(nowDay: number, freeDay: number[]) {
    if (freeDay.indexOf(nowDay) !== -1) {
      nowDay++;
      TimeUtil.getNextDay(nowDay, freeDay);
    } else {
      nextDay = nowDay;
    }
  }

  /**
   *  Get the number of the current day in a year.
   *
   * @param a timestamp
   * @return Number of days corresponding to the current timestamp
   */
  static getNumberDay(time?: number): number {
    let dateArr = MONTH_LIST;
    let date = time ? new Date(time) : new Date();
    let day = date.getDate();
    let month = date.getMonth();
    let year = date.getFullYear();
    let netYear = AppStorage.get<HolidaysType>(CACHE_HOLIDAYS_LIST)?.year || new Date().getFullYear();
    let leapYear = (year % 4 === 0 && year % 100 !== 0) || year % 4 === 0;
    let result = 0;
    for (let i = 0; i < month; i++) {
      result += dateArr[i]
    }
    result += day;
    // Check whether the year is a leap year.
    if (month > 1 && leapYear) {
      result += 1
    }

    if (netYear > year) {
      result = leapYear ? result - 366 : result - 365;
    }

    return result;
  }

  /**
   * Gets the description of the time between the current and next ringing
   *
   * @return The description of the time between the current and next ringing like '3 days 2 hours 1 minute”
   */
  static async getLeftTimeToRingTime(isTimeChanged?: boolean): Promise<string> {
    let ringTimeInMs = await TimerManager.getTriggerTime();
    LogUtil.info(TAG, 'getLeftTimeToRingTime isTimeChanged:' + isTimeChanged)
    if (isTimeChanged) {
      LogUtil.info(TAG, 'start to deal TimeChanged event');
      const currentDate = new Date();
      const leftTimeInMs = ringTimeInMs - currentDate.getTime();
      if (leftTimeInMs <= 0) {
        LogUtil.info(TAG, 'leftTimeInMs less than zero, before ringTimeInMs:' + ringTimeInMs);
        await AlarmManager.updateTimer();
        ringTimeInMs = await TimerManager.getTriggerTime();
      }
    }
    const snoozeAlarmId = await SnoozeManager.getSnoozedAlarmId();
    LogUtil.info(TAG, 'snoozeAlarmId = ' + snoozeAlarmId);
    let alarmList = await AlarmManager.getAllAlarms();
    let alarmEnable = false;
    for (let i = 0; i < alarmList.length; i++) {
      if (alarmList[i].enabled === true) {
        alarmEnable = true;
      }
    }
    if (alarmEnable === false && snoozeAlarmId && snoozeAlarmId.length === 0) {
      return NO_ALARM_ENABLED;
    }
    return await TimeUtil.calculateRingTime(ringTimeInMs);
  }

  /**
   * Get Next Alarm Time
   *
   * @returns the next alarm time in ms
   */
  static async getNextAlarmTime(): Promise<number> {
    const ringTimeInMs = await TimerManager.getTriggerTime();
    return ringTimeInMs;
  }

  /**
   * Calculate remaining ringing time
   *
   * @return The description of the time between the current and next ringing like '3 days 2 hours 1 minute”
   */
  static async calculateRingTime(ringTimeInMs: number): Promise<string> {
    const currentDate = new Date();
    const leftTimeInMs = ringTimeInMs - currentDate.getTime();
    if (leftTimeInMs <= 0) {
      return NO_ALARM_ENABLED;
    }
    const leftTime = new Date(leftTimeInMs);
    const leftMinutes = leftTime.getUTCMinutes();
    const leftHours = leftTime.getUTCHours();
    const leftDays = leftTime.getUTCDate() - ONE_DAY;
    if (leftDays === 0 && leftHours === 0 && leftMinutes < ONE_MINUTE) {
      return LESS_THAN_ONE_MINUTE_FLAG;
    }
    const leftTimeStrParts: string[] = [];
    if (leftDays != 0) {
      // If the number of remaining days is not 0, the description of remaining days needs to be assembled.
      const leftDayStr = await ResourceManager.getPluralStringAsync($r('app.plural.day').id, leftDays);
      leftTimeStrParts.push(leftDayStr);
    }
    if (leftHours != 0) {
      // If the number of remaining hours is not 0, the description of remaining hours needs to be assembled.
      const leftHourStr = await ResourceManager.getPluralStringAsync($r('app.plural.hour').id, leftHours);
      leftTimeStrParts.push(leftHourStr);
    }
    if (leftMinutes != 0) {
      // If the number of remaining minutes is not 0, the description of the remaining minutes needs to be assembled.
      const leftMinuteStr = await ResourceManager.getPluralStringAsync($r('app.plural.minute').id, leftMinutes);
      leftTimeStrParts.push(leftMinuteStr);
    }
    return `${leftTimeStrParts.join(' ')}`;
  }

  static async getUrl(): Promise<string> {
    let urlString: string = await CommonUtil.getStringByFile(GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager, 'config.json')
    let urlJson: urlType = JSON.parse(urlString);
    LogUtil.info(TAG, 'getUrl:' + urlJson.url);
    return urlJson.url;
  }

  /**
   * Get Network Data on Official Workdays.
   *
   * Description: The obtained data is stored in AppStorage.
   *
   * @returns void
   */
  static async getWorkDaysNetData(): Promise<boolean> {
    const url = await TimeUtil.getUrl();
    let httpRequest = http.createHttp();
    return httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 60000,
        connectTimeout: 60000
      }).then((data) => {
      LogUtil.info(TAG, 'httpSeccuss' + JSON.stringify(data));
      let resultList: NetHolidaysType = JSON.parse(data.result.toString());
      if (!resultList) {
        return false;
      }
      let holidaysData: HolidaysType = {
        year: resultList.year,
        version: resultList.version,
        freeday: resultList.freeday,
        workday: resultList.workday
      };
      let yearData: HolidaysType | undefined = resultList?.allRecess?.find(item => item?.year === resultList?.year);
      let newYearHolidaysData: number[] = yearData?.freeday?.filter(item => item < 0) || [];
      holidaysData.freeday = holidaysData.freeday?.concat(newYearHolidaysData).sort((a, b) => a - b);
      preferencesUtil.removePreferencesFromCache(GlobalContext.getContext()
        .getObject('clockContext') as Context, 'WORK_DAY');
      TimeUtil.PutFreeday(JSON.stringify(holidaysData));
      AppStorage.SetOrCreate<HolidaysType>(CACHE_HOLIDAYS_LIST, holidaysData);
      return true;
    }).catch((err: Error) => {
      LogUtil.info(TAG, 'httpReqError' + JSON.stringify(err));
      return false;
    })
  }

  static async PutFreeday(list: string) {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, 'WORK_DAY');
    await preferences.put(CACHE_HOLIDAYS_LIST, list);
    await preferences.flush();
  }

  static async getFreeday() {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, 'WORK_DAY');
    let list = await preferences.get(CACHE_HOLIDAYS_LIST, '{}')
    LogUtil.info(TAG, 'getFreeday' + list);
    AppStorage.SetOrCreate<HolidaysType>(CACHE_HOLIDAYS_LIST, JSON.parse(list as string) as HolidaysType);
  }
}