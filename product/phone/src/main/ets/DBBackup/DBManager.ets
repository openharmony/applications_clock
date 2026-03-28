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

import DB, { DBHandle, IRelationalStoreConfig } from './index';
import relationalStore from '@ohos.data.relationalStore';
import { ValuesBucket, ValueType } from '@ohos.data.ValuesBucket';
import rdb from '@ohos.data.rdb';
import { SQL_CREATE_TABLE } from '@hmos/common'
import {
  TimeUtil,
  GlobalContext,
  ALARM_TIME_NEVER,
  AlarmInfo,
  ENABLED_FALSE,
  ENABLED_TRUE,
  INIT_SNOOZE_COUNT,
  LogUtil
} from '@hmos/common';
import cloneDBManager from './CloneDBManager';

interface IDoubleDataRow {
  _id: string,
  hour: number,
  minutes: number,
  daysofweek: number,
  alarmtime: number,
  enabled: boolean,
  vibrate: number,
  volume: number,
  message: string,
  alert: string,
  daysofweektype: number,
  daysofweekshow: string,
  alarmtype: number,
  ringduration: number,
  snoozeduration: number,
  snoozetimes: number,
}

interface DoubleWorldDataRow {
  _id: number,
  timezone: string,
  homecity: number,
  sort_order: number,
  city_index: string
}

interface TDBManager {
  getRDBH: (config: IRelationalStoreConfig) => Promise<DBHandle>;
  getResourcesTitle: (resource: Resource) => Promise<string>;
  singleReadData: () => Promise<Array<AlarmInfo>>;
  singleReadResultSet: (resultSet: relationalStore.ResultSet) => Array<AlarmInfo>;
  doubleReadData: () => Promise<Array<IDoubleDataRow>>;
  doubleReadWorldClockData: () => Promise<Array<DoubleWorldDataRow>>;
  doubleReadResultSet: (resultSet: relationalStore.ResultSet) => Array<IDoubleDataRow>;
  doubleReadWorldClockResultSet: (resultSet: relationalStore.ResultSet) => Array<DoubleWorldDataRow>;
  formatToSingle: (doubleData: Array<IDoubleDataRow>) => Array<AlarmInfo>;
  doubleToSingle: () => Promise<boolean>;
  singleRowformatVB: (alarmInfo: AlarmInfo) => ValuesBucket;
  singleInsertTest?: () => Promise<number>;
  transformDayOfWeek: (num: number) => Array<number>;
  clearSingleTable: (tableName: string) => Promise<boolean>;
  intertBigData: (num: number) => Promise<number>;
}

const TAG: string = 'DBManager';
const context = GlobalContext.getContext().getObject('clockBackupContext') as Context;
const singleStoreConfig: relationalStore.StoreConfig = { name: 'Clock.db', securityLevel: 1 };
const doubleStoreConfig: relationalStore.StoreConfig = { name: 'alarms.db', securityLevel: 1 };
const singleTableName: string = 'ALARM_CLOCK';
const singleWorldClockTableName: string = 'WORLD_CLOCK';
// 数据库的建表 SQL
const singleCreateSql: string = SQL_CREATE_TABLE;
const doubleTableName: string = 'alarms';
const doubleWorldTableName: string = 'locations';
// 数据库的建表 SQL
const doubleCreateSql = `
      CREATE TABLE IF NOT EXISTS ${doubleTableName} (
      _id INTEGER PRIMARY KEY,
      hour INTEGER,
      minutes INTEGER,
      daysofweek INTEGER,
      alarmtime INTEGER,
      enabled INTEGER,
      vibrate INTEGER,
      volume INTEGER,
      message TEXT,
      alert TEXT,
      daysofweektype INTEGER,
      daysofweekshow TEXT,
      alarmtype INTEGER DEFAULT 0,
      ringduration INTEGER DEFAULT 5,
      snoozeduration INTEGER DEFAULT 10,
      snoozetimes INTEGER DEFAULT 3)
  `;
// 双框架世界时钟的建表 SQL
const worldCreateSql = `
      CREATE TABLE IF NOT EXISTS ${doubleWorldTableName} (
      _id INTEGER PRIMARY KEY AUTOINCREMENT,
      homecity INTEGER,
      sort_order INTEGER,
      timezone TEXT,
      city_index TEXT)
  `;

// 默认时钟标签
let defaultTitle: string = '';
let defaultDemoTitle: string = '';
const DEFAULT_ALARM_TITLE_RESOURCES: Resource = $r('app.string.alarm_clock');
const DEFAULT_ALARM_DEMO_TITLE_RESOURCES: Resource = $r('app.string.default_alarm_label');

export let singleRDBH: DBHandle;

export let doubleRDBH: DBHandle;

export let doubleWorldRDBH: DBHandle;

function getContext(): Context {
  return GlobalContext.getContext().getObject('clockBackupContext') as Context;
}

export async function getSingleRDBH(context?: Context): Promise<DBHandle> {
  if (singleRDBH) {
    return singleRDBH;
  }
  const _context = context || getContext();
  singleRDBH = await dbManager.getRDBH({
    context: _context,
    storeConfig: singleStoreConfig,
    createSql: singleCreateSql
  });
  return singleRDBH;
}

export async function getDoubleRDBH(context?: Context): Promise<DBHandle> {
  if (doubleRDBH) {
    return doubleRDBH;
  }
  const _context = context || getContext();
  doubleRDBH = await dbManager.getRDBH({
    context: _context,
    storeConfig: doubleStoreConfig,
    createSql: doubleCreateSql
  });
  return doubleRDBH;
}

export async function getDoubleWorldRDBH(context?: Context): Promise<DBHandle> {
  if (doubleWorldRDBH) {
    return doubleWorldRDBH;
  }
  const _context = context || getContext();
  doubleWorldRDBH = await dbManager.getRDBH({
    context: _context,
    storeConfig: doubleStoreConfig,
    createSql: doubleCreateSql
  });
  return doubleWorldRDBH;
}

const dbManager: TDBManager = {
  getRDBH: async (config: IRelationalStoreConfig) => {
    return await DB({ context: config.context, storeConfig: config.storeConfig, createSql: config.createSql });
  },
  getResourcesTitle: async (resource) => {
    let value: string = '';
    try {
      const context = getContext();
      const resourceManager = context.resourceManager;
      value = await resourceManager.getStringValue(resource);
      // app.string.alarm_clock 'app.string.default_alarm_label'
      LogUtil.info(TAG, `get getResourcesTitle success ${value}`);
    } catch (error) {
      LogUtil.error(TAG, `get getResourcesTitle fail. code: ${error.code}, message: ${error.message}`);
    }

    return value;
  },
  singleReadData: async (): Promise<Array<AlarmInfo>> => {
    let rdbHandle = await getSingleRDBH();
    let resultSet = await rdbHandle.dbQuery(singleTableName, (predicates) => {
      predicates.orderByAsc('HOUR');
      predicates.orderByAsc('MINUTE');
    });
    let result = dbManager.singleReadResultSet(resultSet);
    resultSet.close();
    return result;
  },
  singleReadResultSet: (resultSet: relationalStore.ResultSet): Array<AlarmInfo> => {
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
  },
  doubleReadData: async (): Promise<Array<IDoubleDataRow>> => {
    let rdbHandle = doubleRDBH = await getDoubleRDBH();
    let resultSet = await rdbHandle.dbQuery(doubleTableName, (predicates) => {
      predicates.orderByAsc('hour');
      predicates.orderByAsc('minutes');
    });

    let result = dbManager.doubleReadResultSet(resultSet);
    resultSet.close();
    return result;
  },
  doubleReadWorldClockData: async (): Promise<Array<DoubleWorldDataRow>> => {
    let rdbHandle = doubleWorldRDBH = await getDoubleWorldRDBH();
    let resultSet = await rdbHandle.dbQuery(doubleWorldTableName, (predicates) => {
      predicates.orderByAsc('sort_order');
    });

    let result = dbManager.doubleReadWorldClockResultSet(resultSet);
    resultSet.close();
    return result;
  },
  doubleReadResultSet: (resultSet: relationalStore.ResultSet): Array<IDoubleDataRow> => {
    let a: IDoubleDataRow[] = [];
    while (resultSet.goToNextRow()) {
      let _id: string = resultSet.getString(resultSet.getColumnIndex('_id'));
      let hour: number = resultSet.getLong(resultSet.getColumnIndex('hour'));
      let minutes: number = resultSet.getLong(resultSet.getColumnIndex('minutes'));
      let daysofweek = resultSet.getLong(resultSet.getColumnIndex('daysofweek'));
      let alarmtime: number = resultSet.getLong(resultSet.getColumnIndex('alarmtime'));
      let enabled: boolean = !!resultSet.getLong(resultSet.getColumnIndex('enabled'));
      let vibrate: number = resultSet.getLong(resultSet.getColumnIndex('vibrate'));
      let volume: number = resultSet.getLong(resultSet.getColumnIndex('volume'));
      let message: string = resultSet.getString(resultSet.getColumnIndex('message'));
      let alert: string = resultSet.getString(resultSet.getColumnIndex('alert'));
      let daysofweektype: number = resultSet.getLong(resultSet.getColumnIndex('daysofweektype'));
      let daysofweekshow: string = resultSet.getString(resultSet.getColumnIndex('daysofweekshow'));
      let alarmtype: number = resultSet.getLong(resultSet.getColumnIndex('alarmtype'));
      let ringduration: number = resultSet.getLong(resultSet.getColumnIndex('ringduration'));
      let snoozeduration: number = resultSet.getLong(resultSet.getColumnIndex('snoozeduration'));
      let snoozetimes: number = resultSet.getLong(resultSet.getColumnIndex('snoozetimes'));


      a.push({
        _id,
        hour,
        minutes,
        daysofweek,
        alarmtime,
        enabled,
        vibrate,
        volume,
        message,
        alert,
        daysofweektype,
        daysofweekshow,
        alarmtype,
        ringduration,
        snoozeduration,
        snoozetimes
      })
    }
    return a;
  },
  doubleReadWorldClockResultSet: (resultSet: relationalStore.ResultSet): Array<DoubleWorldDataRow> => {
    let result: DoubleWorldDataRow[] = [];
    while (resultSet.goToNextRow()) {
      let _id: number = resultSet.getLong(resultSet.getColumnIndex('_id'));
      let timezone: string = resultSet.getString(resultSet.getColumnIndex('timezone'));
      let homecity: number = resultSet.getLong(resultSet.getColumnIndex('homecity'));
      let sort_order: number = resultSet.getLong(resultSet.getColumnIndex('sort_order'));
      let city_index: string = resultSet.getString(resultSet.getColumnIndex('city_index'));

      result.push({
        _id,
        timezone,
        homecity,
        sort_order,
        city_index
      })
    }
    return result
  },
  doubleToSingle: async () => {
    GlobalContext.getContext()
      .setObject('clockContext', GlobalContext.getContext().getObject('clockBackupContext') as Context);
    const data: IDoubleDataRow[] = await dbManager.doubleReadData(); // 读取双框架闹钟数据
    LogUtil.info(TAG, 'get double clock data success');
    defaultTitle = await dbManager.getResourcesTitle(DEFAULT_ALARM_TITLE_RESOURCES);
    defaultDemoTitle = await dbManager.getResourcesTitle(DEFAULT_ALARM_DEMO_TITLE_RESOURCES);
    let formatData = dbManager.formatToSingle(data)
      .map<ValuesBucket>(item => dbManager.singleRowformatVB(item)); // 转换为单框架数据格式
    LogUtil.info(TAG, 'format to single clock data success', JSON.stringify(formatData));
    if (!singleRDBH) {
      LogUtil.info(TAG, 'singleRDBH is undefined');
      await getSingleRDBH();
    }
    LogUtil.info(TAG, 'clear single clock table start');
    const cr = await dbManager.clearSingleTable(singleTableName);
    if (cr) {
      LogUtil.info(TAG, 'clear single clock table success');
    }
    const r = await singleRDBH.dbBatchInsert(singleTableName, formatData);
    if (r === -1) {
      LogUtil.info(TAG, 'insert to single DB fail');
      return false;
    }
    LogUtil.info(TAG, 'start to handle world clock data');
    const worldClockData: DoubleWorldDataRow[] = await dbManager.doubleReadWorldClockData(); // 读取双框架世界时钟数据
    LogUtil.info(TAG, 'get double worldClock data success', JSON.stringify(worldClockData));
    const isClear = await dbManager.clearSingleTable(singleWorldClockTableName);
    if (isClear) {
      LogUtil.info(TAG, 'clear world clock table success');
    }
    await cloneDBManager.addWorldClockList(worldClockData);
    LogUtil.info(TAG, 'insert to single DB success');
    LogUtil.info(TAG, 'success over');
    return true;

  },
  formatToSingle(doubleData) {
    let formatResult = doubleData.map<AlarmInfo>((item) => {
      let id = item._id;
      let hour = item.hour;
      let minute = item.minutes;
      let second = 0;
      let enabled = item.enabled;
      let alarmTime = item.alarmtime;
      let title = item.message || defaultTitle;
      let ringDuration = item.ringduration;
      let snoozeDuration = item.snoozeduration;
      let snoozeTimes = item.snoozetimes;
      let snoozeCount = item.snoozetimes;
      let daysOfWakeType = item.daysofweektype || 0;

      // 以下为双有的列，单目前没有的列
      let vibrate = item.vibrate;
      let volume = item.volume;
      let alert = item.alert;
      let daysofweekshow = item.daysofweekshow;
      let alarmtype = item.alarmtype;

      LogUtil.info(TAG, `title ${title}, ${title.length}`);

      /**
       * 双框架示例数据无标题问题
       * 判断是否为双的示例数据
       * */
      if (!item.message && Number(item.volume) === 3) {
        LogUtil.info(TAG, `demo data ${defaultTitle}`);
        title = defaultDemoTitle;
      }

      /**
       * 针对双框架数据库字段 daysofweek 字段说明
       * 双框架 daysofweek 在数据库中存储为 10进制数字，例如：31, 96 需要转2进制进行星期识别
       * 31 转 2进制结果为 11111， 5个1 表示设置了 周五，周四，周三，周二，周一
       * 96 转 2进制结果为 1100000， 2个1和5个0 表示设置了 周日，周六； （周五，周四，周三，周二，周一 为0 表示未设置）；
       * 针对双框数据 转换为 [0,0,0,0,0,0,0] 表示 [周日，周一，周二，周三，周四，周五，周六]
       *
       * 单框架数据 0：周日,1：周一,2：周二,3：周三,4：周四,5：周五,6：周六
       *  daysOfWeek = [2]
       * */
      let daysOfWeek = dbManager.transformDayOfWeek(item.daysofweek);
      return {
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
        daysOfWeek,
        daysOfWakeType
      }
    })
    return formatResult;
  },
  transformDayOfWeek: (num) => {
    let str: string = Number(num).toString(2).padStart(7, '0');
    if (str) {
      let arr: string[] = str.split('').reverse();
      if (arr && arr.length > 0) {
        arr!.unshift(arr.pop() as string);
      }
      let rst: number[] = arr.reduce<Array<number>>((r, it, i) => {
        (Number(it) === 1) && r.push(Number(i));
        return r
      }, []);
      return rst;
    } else {
      return [];
    }
  },
  singleRowformatVB: (alarmInfo) => {
    return {
      'TITLE': alarmInfo.title,
      'HOUR': alarmInfo.hour,
      'MINUTE': alarmInfo.minute,
      'SECOND': alarmInfo.second || 0,
      'DAYS_OF_WEEK': new Uint8Array(alarmInfo.daysOfWeek || []),
      'ALARM_TIME': alarmInfo.enabled ? TimeUtil.getAlarmTime(alarmInfo) : ALARM_TIME_NEVER,
      'ENABLED': alarmInfo.enabled ? ENABLED_TRUE : ENABLED_FALSE,
      'RING_DURATION': alarmInfo.ringDuration as ValueType,
      'SNOOZE_DURATION': alarmInfo.snoozeDuration,
      'SNOOZE_TIMES': alarmInfo.snoozeTimes,
      'SNOOZE_COUNT': alarmInfo.snoozeCount || INIT_SNOOZE_COUNT,
      'DAYS_OF_WAKE_TYPE': alarmInfo.daysOfWakeType as ValueType
    };
  },
  clearSingleTable: async (tableName) => {
    LogUtil.info(TAG, 'enter clearSingleTable');
    let rdbHandle = await getSingleRDBH();
    let CLEAR_TABLE_SQL = `DELETE FROM ${tableName}`;
    let r = await rdbHandle.dbClearTable(CLEAR_TABLE_SQL);
    return r;
  },
  intertBigData: async (num = 100) => {
    const arr: ValuesBucket[] = [];

    for (let i = 0; i < num; i++) {
      let title = `clock_${i}`;
      let hour = i % 23;
      let minute = i % 59;
      let second = i % 59;
      let daysOfWeek = [6, 0];
      let enabled = true;
      let ringDuration = 5;
      let snoozeDuration = 10;
      let snoozeTimes = 3;
      let d = {
        hour,
        minute,
        second,
        enabled,
        title,
        ringDuration,
        snoozeDuration,
        snoozeTimes,
        daysOfWeek
      } as AlarmInfo;
      arr.push(dbManager.singleRowformatVB(d));
    }
    if (!singleRDBH) {
      LogUtil.info(TAG, 'insert big data singleRDBH is undefined');
      await getSingleRDBH();
    }
    const r = await singleRDBH.dbBatchInsert(singleTableName, arr);
    LogUtil.info(TAG, `insert big data ${num}`);
    return r;
  }
}

export default dbManager;
