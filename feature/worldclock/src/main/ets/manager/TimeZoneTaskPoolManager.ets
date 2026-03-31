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

import I18n from '@ohos.i18n';
import intl from '@ohos.intl';
import { LogUtil } from '@hmos/common';

interface cityInfo {
  settingSummary?: string,
  zoneId: '',
  cityId: '',
  cityDisplayName: '',
  offset: 0,
  zoneDisplayName: '',
  rawOffset: 0
}

const TAG = 'World Clock Add City'

class TimeZoneTaskPoolManager {
  public cityList: cityInfo[] = [];
  public timeZoneCityItemArray: cityInfo[] = [];

  getTimeZoneInfo(locale: string, isFirstLoading: boolean, firstLoadNum: number): Array<cityInfo> {


    // if (this.timeZoneCityItemArray.length < 1) {
    //   this.timeZoneCityItemArray = I18n.SystemLocaleManager.getTimeZoneCityItemArray();
    //   LogUtil.info(TAG + 'get timeZoneCityArray success')
    // }

    let cityId: string;
    let timeZone: I18n.TimeZone;
    let rawOffSet: string = '';
    let is24hFormat: boolean = I18n.is24HourClock();
    let itemCount: number = 0;


    // 获取底层时区信息
    // let timeZoneCityItemArray: cityInfo[] = I18n.SystemLocaleManager.getTimeZoneCityItemArray();
    LogUtil.info(TAG + 'get timeZoneCityArray success')


    if (isFirstLoading) {
      this.cityList = []
    }
    for (let i = 0; i < this.timeZoneCityItemArray.length; i++) {
      cityId = '';
      timeZone = I18n.TimeZone.getTimezoneFromCity(cityId);
      let getTimeInfoFlag: boolean = (isFirstLoading && itemCount < firstLoadNum) ||
        (!isFirstLoading && itemCount >= firstLoadNum);
      if (getTimeInfoFlag) {
        let currentDateFormat: intl.DateTimeFormat = new intl.DateTimeFormat(locale, { month: 'long', day: 'numeric' });
        let dateFormat: intl.DateTimeFormat = new intl.DateTimeFormat(locale.toString(), {
          month: 'long',
          day: 'numeric',
          timeZone: timeZone.getID()
        });
        let timeFormat: intl.DateTimeFormat = new intl.DateTimeFormat(locale.toString(), {
          timeStyle: 'short',
          hour12: !is24hFormat,
          timeZone: timeZone.getID()
        });
        let obj: Date = new Date();
        let currentDate: string = currentDateFormat.format(obj);
        let date: string = dateFormat.format(obj);
        let time: string = timeFormat.format(obj);
        if (date === currentDate) {
          rawOffSet = time;
        } else {
          rawOffSet = date + ' ' + time;
        }
      }


      if (isFirstLoading) {
        this.cityList.push({
          cityId: this.timeZoneCityItemArray[i].cityId,
          zoneId: this.timeZoneCityItemArray[i].zoneId,
          cityDisplayName: this.timeZoneCityItemArray[i].cityDisplayName,
          offset: this.timeZoneCityItemArray[i].offset,
          zoneDisplayName: this.timeZoneCityItemArray[i].zoneDisplayName,
          rawOffset: this.timeZoneCityItemArray[i].rawOffset,
          settingSummary: itemCount < firstLoadNum ? rawOffSet : ' '
        })
      } else {
        // 第二次只替换clockSummary讯息
        if (i > 49) {
          this.cityList[i].settingSummary = rawOffSet;
        }
      }
      itemCount++;
    }
    return this.cityList;
  }
}

export class BasicTimeZoneInfo {
  public keyArray: string[] = [];
  public titleArray: string[] = [];
  public clockSummary: string[] = [];
  public extra: string[] = [];
}

export class ClockBaseMenu {
  public key?: string;
  public title?: string;
  public summary?: string;
  public extra?: string;
}

export default new TimeZoneTaskPoolManager();