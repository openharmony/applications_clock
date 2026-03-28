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
import intl from '@ohos.intl';
import Settings from '@ohos.settings';

export interface cityInfo {
  settingSummary?: string
  zoneId: string,
  cityId: string,
  cityDisplayName: string,
  offset: number,
  zoneDisplayName: string,
  rawOffset: number
}

export interface Obj {
  A?: number,
  B?: number,
  C?: number,
  D?: number,
  E?: number,
  F?: number,
  G?: number,
  H?: number,
  I?: number,
  J?: number,
  K?: number,
  L?: number,
  M?: number,
  N?: number,
  O?: number,
  P?: number,
  Q?: number,
  R?: number,
  S?: number,
  T?: number,
  U?: number,
  V?: number,
  W?: number,
  X?: number,
  Y?: number,
  Z?: number,
}

const RAW_OFFSET_HOUR_MOD: number = 3600000;
const RAW_OFFSET_MINUTE_MOD: number = 60000;

/**
 * 时区相关工具类
 *
 * @since 2022-12-09
 */
export class TimeZoneUtil {
  private static readonly TAG: string = 'TimeZoneUtil : ';
  private static readonly TIME_FORMAT_KEY: string = Settings.date.TIME_FORMAT;

  /**
   * 获取系统支持的时区ID集合
   *
   */
  static getAvailableTimeZoneIDs(): Array<string> {
    return i18n.TimeZone.getAvailableIDs();
  }

  /**
   * 获取系统支持的时区城市ID集合
   *
   */
  static getAvailableZoneCityIDs(): Array<string> {
    return i18n.TimeZone.getAvailableZoneCityIDs();
  }

  /**
   * 获取某时区城市的本地化显示
   *
   */
  static getCityLocalDisplayName(cityID: string): string {
    let locale = new intl.Locale(i18n.System.getSystemLanguage());
    return i18n.TimeZone.getCityDisplayName(cityID, locale.toString());
  }

  static getSystemLanguage(): string {
    let locale = new intl.Locale(i18n.System.getSystemLanguage());
    return locale.toString();
  }

  /**
   * 获取某时区城市在locale下的本地化显示
   *
   */
  static getCityDisplayName(cityID: string, locale: string): string {
    return i18n.TimeZone.getCityDisplayName(cityID, locale);
  }

  /**
   * 创建某时区城市对应的时区对象
   *
   */
  static getTimezoneFromCity(cityID: string): i18n.TimeZone {
    return i18n.TimeZone.getTimezoneFromCity(cityID);
  }
}


export class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): cityInfo | null {
    return null;
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }
}

export class MyDataSource extends BasicDataSource {
  private dataArray: cityInfo[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): cityInfo | null {
    return this.dataArray[index];
  }

  public addData(index: number, data: cityInfo): void {
    this.dataArray.splice(index, 0, data);
    this.notifyDataAdd(index);
  }

  public refreshData(dataList: cityInfo[]) {
    this.dataArray = dataList;
    this.notifyDataReload();
  }

  public pushData(data: cityInfo): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }
}