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
import { BusinessError } from '@ohos.base';
import { GlobalContext, LogUtil } from '../utils';
import { AlarmInfo, STORE_CONFIG } from './types';
import AlarmManager from './AlarmManager';

const TAG = 'DatabaseManager';

const DATA_TABLE = 'ALARM_CLOCK';

let IS_FIRST_OTA = true;

/**
 * 数据库管理基类
 * 通过继承实现具体能力，如: 被 AlarmManager 继承，通过 AlarmManager 进一步封装对外提供闹钟管理功能
 *
 * @author XiaHan
 * @since 2022-07-06
 */
export default abstract class DatabaseManager {
  private rdbStore: dataRdb.RdbStore | undefined = undefined;

  /**
   * 获取关系数据库存储对象
   * 如果已初始化过，则直接返回之前获取的对象
   * 如果没有初始化过，则使用接口获取对象，并执行数据库建表命令，如果表未创建，则会创建一张新的表
   *
   * @param createTableSql 创建新表使用的 SQL
   * @return 关系数据库存储对象
   */
  async getRdbStore(createTableSql: string): Promise<dataRdb.RdbStore> {
    if (this.rdbStore) {
      return this.rdbStore;
    }
    try {
      this.rdbStore = await dataRdb.getRdbStore(GlobalContext.getContext()
        .getObject('clockContext') as Context, STORE_CONFIG);

      let noNewColumn = await this.hasNoNewColumns();
      if (noNewColumn && IS_FIRST_OTA) {
        LogUtil.info(TAG, 'noNewColumn: ' + noNewColumn)
        IS_FIRST_OTA = false;
        let allOldAlarms: AlarmInfo[] = await AlarmManager.getAllAlarms();
        LogUtil.info(TAG, 'allOldAlarms:' + JSON.stringify(allOldAlarms));

        const SQL_DROP_TABLE = `DROP TABLE IF EXISTS ${DATA_TABLE}`;
        await this.rdbStore.executeSql(SQL_DROP_TABLE);
        LogUtil.info(TAG, 'SQL_DROP_TABLE');
        this.rdbStore.commit();

        await this.rdbStore.executeSql(createTableSql);
        this.rdbStore.commit();
        LogUtil.info(TAG, 'createTableSql');

        if (allOldAlarms.length > 0) {
          LogUtil.info(TAG, 'being ota insert');
          this.rdbStore.beginTransaction();
          allOldAlarms.map(async item => {
            if (item.daysOfWeek.length > 0) {
              // WAKE_DAYS = 4, USER_DEFINED = 3, ONES = 0
              item.daysOfWakeType = 3;
            }
            if (this.rdbStore) {
              await this.rdbStore.insert(DATA_TABLE, AlarmManager.getDbBucketFromAlarm(item));
              this.rdbStore.commit();
              LogUtil.info(TAG, 'do insert, item=' + JSON.stringify(item) + ', after=' + JSON.stringify(AlarmManager.getDbBucketFromAlarm(item)));
            }
          });

          await AlarmManager.updateTimer();
          LogUtil.info(TAG, 'updateTimer end');
        }
      } else {
        await this.rdbStore.executeSql(createTableSql);
      }
      LogUtil.info(TAG, 'Get RdbStore successfully.');
    } catch (error) {
      LogUtil.error(TAG, 'Get RdbStore failed, err:', (error as BusinessError).message);
    }
    return this.rdbStore as dataRdb.RdbStore;
  }

  async hasNoNewColumns(): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    const predicates = new dataRdb.RdbPredicates(DATA_TABLE);
    let resultSet: dataRdb.ResultSet = await this.rdbStore.query(predicates);
    let columnNames = JSON.stringify(resultSet.columnNames);
    LogUtil.info(TAG, 'resultSet:' + JSON.stringify(resultSet) + ', columns:' + JSON.stringify(resultSet.columnNames));

    if (columnNames && columnNames !== '[]' && (columnNames.indexOf('DAYS_OF_WAKE_TYPE') === -1 ||
      columnNames.indexOf('ALARM_TIME_INTENT') === -1 || columnNames.indexOf('RESTART') === -1)) {
      return true;
    }
    return false;
  }
}