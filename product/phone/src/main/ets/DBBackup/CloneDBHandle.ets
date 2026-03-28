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

import dataRdb from '@ohos.data.relationalStore';
import { ValuesBucket, ValueType } from '@ohos.data.ValuesBucket';
import { AlarmInfo, LogUtil } from '@hmos/common';

type TQueryFn = (predicates: dataRdb.RdbPredicates) => void;
type TQueryReadFn = (resultSet: dataRdb.ResultSet) => void;

const TAG: string = 'CloneDBHandle';

class CloneDBHandle {
  public rdbStore: dataRdb.RdbStore = {} as dataRdb.RdbStore;
  public dbConfig: IRelationalStoreConfig

  constructor(options: IRelationalStoreConfig) {
    this.dbConfig = options
  }

  async getRdbStore(context: Context, storeConfig: dataRdb.StoreConfig, createSql?: string): Promise<CloneDBHandle> {
    LogUtil.info(TAG, 'getRdbStore', context.databaseDir, JSON.stringify(storeConfig));
    /*
     * 获取关系型数据库
     * context 上下文
     * storeConfig 数据库配置 { name: 数据库名， securityLevel: 数据安全级别 }
     * */
    // 获取关系型数据库
    try {
      const rdbStore: dataRdb.RdbStore = await dataRdb.getRdbStore(context, storeConfig);
      this.rdbStore = rdbStore;
      LogUtil.info(TAG, 'create rdb success', JSON.stringify(this.rdbStore));
      if (createSql) {
        await this.createTable(createSql);
      }
    } catch (error) {
      LogUtil.info(TAG, 'create rdb fail', JSON.stringify(error));
    }
    return this;
  }

  async createTable(createSql: string) {
    LogUtil.info(TAG, 'createSQL', JSON.stringify(createSql))
    try {
      const r = await this.rdbStore.executeSql(createSql);
      LogUtil.info(TAG, 'create rdb table success', String(r));
    } catch (error) {
      LogUtil.info(TAG, 'create rdb table fail', JSON.stringify(error));
    }
  }

  async dbQuery(tableName: string, fieldQueryFn: TQueryFn, readHandle?: TQueryReadFn): Promise<dataRdb.ResultSet> {
    const predicates: dataRdb.RdbPredicates = new dataRdb.RdbPredicates(tableName);
    fieldQueryFn(predicates);
    let result: dataRdb.ResultSet = {} as dataRdb.ResultSet;
    try {
      const resultSet: dataRdb.ResultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG, 'query data success', String(resultSet.rowCount));
      result = resultSet
    } catch (error) {
      LogUtil.info(TAG, 'query data fail', error);
    }
    return result
  }

  async dbInsert(tableName: string, row: ValuesBucket) {
    try {
      const r: number = await this.rdbStore.insert(tableName, row);
      LogUtil.info(TAG, 'insert data success', String(r));
      return r
    } catch (error) {
      LogUtil.info(TAG, 'insert data fail', error.code);
    }
    return -1;
  }

  async dbBatchInsert(tableName: string, rows: Array<ValuesBucket>) {
    try {
      const r: number = await this.rdbStore.batchInsert(tableName, rows);
      LogUtil.info(TAG, 'insert data success');
      LogUtil.info(TAG, 'insert 0', tableName, JSON.stringify(rows));
      return r
    } catch (error) {
      LogUtil.info(TAG, 'insert data fail', error);
    }
    return -1;
  }

  async dbClearTable(sql: string): Promise<boolean> {
    try {
      const r = await this.rdbStore.executeSql(sql);
      LogUtil.info(TAG, 'clear table success');
      return true;
    } catch (error) {
      LogUtil.info(TAG, 'clear table fail', JSON.stringify(error));
    }
    return false;
  }

  async deleteDoubleRdb(context: Context, rdbName: string) {
    LogUtil.info(TAG, 'start delete double rdb: ', JSON.stringify(rdbName));
    try {
      await dataRdb.deleteRdbStore(context, rdbName);
      LogUtil.info(TAG, 'delete double rdb success');
    } catch (error) {
      LogUtil.info(TAG, 'delete double rdb fail: ', JSON.stringify(error));
    }
  }

  readResultSet(resultSet: dataRdb.ResultSet): Array<AlarmInfo> {
    let a: AlarmInfo[] = [];
    while (resultSet.goToNextRow()) {
      const daysOfWeekNative: Uint8Array = resultSet.getBlob(resultSet.getColumnIndex('DAYS_OF_WEEK'));
      const daysOfWeek: number[] = [];
      daysOfWeekNative.forEach(day => {
        daysOfWeek.push(day);
      });

      let id: string = resultSet.getString(resultSet.getColumnIndex('ID'));
      let hour: number = resultSet.getLong(resultSet.getColumnIndex('HOUR'));
      let minute: number = resultSet.getLong(resultSet.getColumnIndex('MINUTE'));
      let second: number = resultSet.getLong(resultSet.getColumnIndex('SECOND'));
      let enabled: boolean = !!resultSet.getLong(resultSet.getColumnIndex('ENABLED'));
      let alarmTime: number = resultSet.getLong(resultSet.getColumnIndex('ALARM_TIME'));
      let title: string = resultSet.getString(resultSet.getColumnIndex('TITLE'));
      let ringDuration: number = resultSet.getLong(resultSet.getColumnIndex('RING_DURATION'));
      let snoozeDuration: number = resultSet.getLong(resultSet.getColumnIndex('SNOOZE_DURATION'));
      let snoozeTimes: number = resultSet.getLong(resultSet.getColumnIndex('SNOOZE_TIMES'));
      let snoozeCount: number = resultSet.getLong(resultSet.getColumnIndex('SNOOZE_COUNT'));
      resultSet.getBlob(resultSet.getColumnIndex('DAYS_OF_WEEK'));


      a.push({
        id,
        hour,
        minute,
        second,
        enabled,
        alarmTime,
        title,
        ringDuration,
        snoozeDuration,
        snoozeTimes,
        snoozeCount,
        daysOfWeek
      })
    }
    return a;
  }
}

export { CloneDBHandle }

export type TReadDataSetHandle = <T>(arg: dataRdb.ResultSet) => T

export interface IRelationalStoreConfig {
  context: Context
  storeConfig: dataRdb.StoreConfig
  createSql?: string
  readDataSetHandle?: TReadDataSetHandle
}

export default function (config: IRelationalStoreConfig): Promise<CloneDBHandle> {
  const dbHandle = new CloneDBHandle(config);
  return new Promise((resolve) => {
    dbHandle.getRdbStore(config.context, config.storeConfig, config.createSql).then((rdbh) => {
      resolve(rdbh);
    })
  })
}