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

import i18n from '@ohos.i18n'
import {
  CalendarFiled,
  FormManager,
  FormUtil,
  LogUtil,
  MILLIS_IN_SECOND,
  MINUTE_IN_HOUR,
  ResourceManager,
  SECOND_IN_MINUTE,
  TIME_TAG_ID_LIST_IN_ZH,
  TimeUtil,
} from '@hmos/common';
import { FaCityData } from '../manager/types'

const TAG: string = 'ClockCardUtil';

export interface formDataInterface {
  city: string,
  date: string,
  hoursWests?: number,
}

export interface formDataInterfaceSecond {
  cityFirst: string,
  dateFirst: string,
  hourswests1?: number,
  citySecond: string,
  dateSecond: string,
  hourswests2?: number,
  cityThird: string,
  dateThird: string,
  hourswests3?: number,
}

/**
 * City Clock Card Util
 *
 * @since 2023-06-16
 */
export class CityClockCardUtil {
  /**
   * notify City Clock Card Content Update
   *
   * @param formId formId
   * @param cityIndex cityIndex
   * @returns
   */
  public static async notifyCityClockCardUpdate(formId: string, cityIndex: string): Promise<void> {
    const formData = CityClockCardUtil.initCityClockCard(cityIndex);
    FormUtil.notifyFormDataChanged(formId, formData);
  }


  /**
   * notify World Clock Card Content Update
   *
   * @param formId formId
   * @param cityIndexList cityIndexList
   * @returns
   */
  public static async notifyWorldClockCardUpdate(formId: string, cityIndexList: string[]): Promise<void> {
    const formData = CityClockCardUtil.initWorldClockCard(cityIndexList);
    FormUtil.notifyFormDataChanged(formId, formData);
  }

  /**
   * initCityClockCard
   *
   * @param cityIndex cityIndex
   * @returns
   */
  public static initCityClockCard(cityIndex: string): object {
    const faCityFirst: FaCityData = CityClockCardUtil.getCityNameAndDate(cityIndex);
    let formData: formDataInterface = {
      city: faCityFirst.cityName,
      date: faCityFirst.cityDate,
      hoursWests: faCityFirst.hoursWests,
    };
    return formData;
  }

  /**
   * initWorldClockCard
   *
   * @param cityIndexList cityIndexList
   * @returns
   */
  public static initWorldClockCard(cityIndexList: string[]): object {
    const faCityFirst: FaCityData = CityClockCardUtil.getCityNameAndDate(cityIndexList[0]);
    const faCitySecond: FaCityData = CityClockCardUtil.getCityNameAndDate(cityIndexList[1]);
    const faCityThird: FaCityData = CityClockCardUtil.getCityNameAndDate(cityIndexList[2]);
    let formData: formDataInterfaceSecond = {
      cityFirst: faCityFirst.cityName,
      dateFirst: faCityFirst.cityDate,
      hourswests1: faCityFirst.hoursWests,
      citySecond: faCitySecond.cityName,
      dateSecond: faCitySecond.cityDate,
      hourswests2: faCitySecond.hoursWests,
      cityThird: faCityThird.cityName,
      dateThird: faCityThird.cityDate,
      hourswests3: faCityThird.hoursWests,
    };
    return formData;
  }

  /**
   * get CityName Date hoursWests
   *
   * @param cityIndex cityIndex
   * @returns
   */
  public static getCityNameAndDate(cityIndex: string): FaCityData {
    const timezone: string = i18n.TimeZone.getTimezoneFromCity(cityIndex).getID();
    const hoursWests = CityClockCardUtil.getHourWest(timezone, cityIndex);
    LogUtil.info(TAG, 'getCityNameAndDate cityIndex:' + cityIndex + ', hoursWests:' + hoursWests);
    const cityDate: string = CityClockCardUtil.getCurrentFormattedDateWithWeek(timezone);
    const cityDisplayName = i18n.TimeZone.getCityDisplayName(cityIndex, i18n.System.getSystemLanguage());
    const cityName = cityDisplayName.substr(0, cityDisplayName.indexOf('('));
    const faCity: FaCityData = {
      cityName: cityName,
      cityDate: cityDate,
      hoursWests: hoursWests,
    };
    return faCity;
  }

  /**
   * getHourWest
   *
   * @param timeZone timeZone
   * @param cityIndex cityIndex
   * @returns
   */
  public static getHourWest(timeZone: string, cityIndex: string): number {
    const calendar = i18n.getCalendar(i18n.System.getSystemLocale());
    calendar.setTimeZone(timeZone);
    let year = calendar.get(CalendarFiled.Year)
    let month = calendar.get(CalendarFiled.Month);
    let date = calendar.get(CalendarFiled.Date)
    let hour = calendar.get(CalendarFiled.Hour_OF_Day)
    let minute = calendar.get(CalendarFiled.Minute)
    const timeStamp = new Date(year, month, date, hour, minute).getTime();
    const currentOffset = i18n.TimeZone.getTimezoneFromCity(cityIndex).getOffset(timeStamp);
    const hourWest = (currentOffset / MILLIS_IN_SECOND / SECOND_IN_MINUTE / MINUTE_IN_HOUR) * -1;
    return hourWest;
  }

  /**
   * getCurrentFormattedDateWithWeek
   *
   * @param timeZone timeZone
   * @returns
   */
  public static getCurrentFormattedDateWithWeek(timeZone: string): string {
    const calendar = i18n.getCalendar(i18n.System.getSystemLocale());
    calendar.setTimeZone(timeZone);
    let year: number = calendar.get(CalendarFiled.Year);
    let month: number = calendar.get(CalendarFiled.Month);
    let date: number = calendar.get(CalendarFiled.Date);
    let hour: number = calendar.get(CalendarFiled.Hour_OF_Day);
    let minute: number = calendar.get(CalendarFiled.Minute);
    const timeZoneDate = new Date(year, month, date, hour, minute);
    const language: string = i18n.System.getSystemLanguage();
    return timeZoneDate.toLocaleDateString(language, {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
    });
  }
}