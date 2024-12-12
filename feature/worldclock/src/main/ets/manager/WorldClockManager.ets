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

import dataRdb from '@ohos.data.relationalStore';
import i18n from '@ohos.i18n';
import Intl from '@ohos.intl';
import { DatabaseManager, LogUtil, EventReportUtil, EventName } from '@hmos/common';
import { WorldClockInfo } from '../manager/types';
import { BusinessError } from '@ohos.base'
import rdb from '@ohos.data.relationalStore'
// import hiSysEvent from '@ohos.hiSysEvent';

const TAG = 'WorldClockManager';

const DATA_TABLE = 'WORLD_CLOCK';

const SQL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS ${DATA_TABLE} (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    SORT_ORDER INTEGER NOT NULL,
    CITY_INDEX TEXT NOT NULL,
    TIMEZONE TEXT NOT NULL,
    CITY TEXT NOT NULL,
    OFFSET INTEGER NOT NULL
  );
`;

/**
 * utils for world clock management
 *
 * @since 2022-10-19
 */
class WorldClockManager extends DatabaseManager {
  /**
   *  rdb store
   *
   * @return rdb store object
   */
  async getRdbStore(): Promise<dataRdb.RdbStore> {
    return await super.getRdbStore(SQL_CREATE_TABLE);
  }

  /**
   * get all world clock
   *
   * @return world clock object array
   */
  async getAllWorldClock(): Promise<WorldClockInfo[]> {
    const rdbStore = await this.getRdbStore();
    let resultSet: rdb.ResultSet = {} as rdb.ResultSet;
    try {
      const predicates = new dataRdb.RdbPredicates(DATA_TABLE);
      predicates.orderByAsc('SORT_ORDER');
      resultSet = await rdbStore.query(predicates);
      return this.getWorldClockListFromResultSet(resultSet);
    } catch (error) {
      LogUtil.error(TAG, 'getAllWorldClocks failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return []
  }

  /**
   * get world clock list from result set
   *
   * @param the result set returned from querying database
   * @return world clock object array
   */
  async getWorldClockListFromResultSet(resultSet: rdb.ResultSet): Promise<WorldClockInfo[]> {
    const worldClockList: WorldClockInfo[] = [];
    while (resultSet.goToNextRow()) {
      const worldClockInfo: WorldClockInfo = {
        id: resultSet.getString(resultSet.getColumnIndex('ID')),
        sortOrder: resultSet.getLong(resultSet.getColumnIndex('SORT_ORDER')),
        cityIndex: resultSet.getString(resultSet.getColumnIndex('CITY_INDEX')),
        timezone: resultSet.getString(resultSet.getColumnIndex('TIMEZONE')),
        city: resultSet.getString(resultSet.getColumnIndex('CITY')),
        offset: resultSet.getLong(resultSet.getColumnIndex('OFFSET')),
      }
      worldClockList.push(worldClockInfo);
    }
    return worldClockList;
  }

  /**
   * add world clock
   *
   * @param world clock object
   */
  async addWorldClock(worldClockInfo: WorldClockInfo): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const ret = await rdbStore.insert(DATA_TABLE,
        {
          'CITY_INDEX': worldClockInfo.cityIndex,
          'SORT_ORDER': worldClockInfo.sortOrder,
          'TIMEZONE': worldClockInfo.timezone,
          'CITY': worldClockInfo.city,
          'OFFSET': worldClockInfo.offset,
        });
      LogUtil.info(TAG, 'addWorldClock success: ' + ret);
      rdbStore.commit();
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_ADD_CITY)
    } catch (error) {
      LogUtil.error(TAG, 'addWorldClock failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * delete world clock
   *
   * @param world clock object
   */
  async removeWorldClock(worldClockInfo: WorldClockInfo): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new dataRdb.RdbPredicates(DATA_TABLE);
      if (worldClockInfo.id) {
        predicates.equalTo('ID', worldClockInfo.id);
      }
      await rdbStore.delete(predicates);
      rdbStore.commit();
      LogUtil.info(TAG, 'removeWorldClock successfully.');
    } catch (error) {
      LogUtil.error(TAG, 'removeWorldClock failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * modify world clock data
   *
   * @param world clock object
   */
  async updateWorldClock(worldClockInfo: WorldClockInfo): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new dataRdb.RdbPredicates(DATA_TABLE);
      if (worldClockInfo.id) {
        predicates.equalTo('ID', worldClockInfo?.id);
      }
      await rdbStore.update(this.getDbBucketFromWorldClock(worldClockInfo), predicates);
      rdbStore.commit();
      LogUtil.info(TAG, 'updateWorldClockDatabase successfully.');
    } catch (error) {
      LogUtil.error(TAG, 'updateWorldClockDatabase failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * transfer world clock object to value bucket needed by database
   *
   * @param world clock object
   * @return value bucket needed by database
   */
  getDbBucketFromWorldClock(worldClockInfo: WorldClockInfo): dataRdb.ValuesBucket {
    return {
      'SORT_ORDER': worldClockInfo.sortOrder,
      'CITY_INDEX': worldClockInfo.cityIndex,
      'TIMEZONE': worldClockInfo.timezone,
      'CITY': worldClockInfo.city,
      'OFFSET': worldClockInfo.offset,
    };
  }

  /**
   * getDisplayCityName
   *
   * @param cityIndex cityIndex
   */
  getDisplayCityName(cityIndex: string): string {
    const locale = new Intl.Locale(i18n.System.getSystemLanguage());
    const city: string = i18n.TimeZone.getCityDisplayName(cityIndex, locale.toString());
    LogUtil.info("TAG", 'worldClockList index = ' + cityIndex + "; local = " + locale.toString() + "; city = " + city);
    if (city === '' && cityIndex === 'Beijing') {
      return '北京';
    }
    if (city === '' && cityIndex === 'Paris') {
      return '巴黎';
    }
    if (city.includes('(')) {
      return city.substr(0, city.indexOf('('));
    } else {
      return city;
    }
  }
}

export default new WorldClockManager();