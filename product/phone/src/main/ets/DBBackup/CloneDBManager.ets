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

import relationalStore from '@ohos.data.relationalStore';
import { ValuesBucket, ValueType } from '@ohos.data.ValuesBucket';
import contextConstant from '@ohos.app.ability.contextConstant';
import i18n from '@ohos.i18n';
import { BusinessError } from '@ohos.base';
import {
  TimeUtil,
  GlobalContext,
  ALARM_TIME_NEVER,
  AlarmInfo,
  AlarmManager,
  ENABLED_FALSE,
  ENABLED_TRUE,
  INIT_SNOOZE_COUNT,
  LogUtil,
  ResourceManager,
  TimerManager,
  CommonUtil,
  SQL_CREATE_TABLE
} from '@hmos/common';
import { WorldClockInfo, WorldClockManager } from '@hmos/worldclock';
import CloneDB, { CloneDBHandle, IRelationalStoreConfig } from './CloneDBHandle';
import cloneManager from '../BackupExtension/CloneManager';


interface IDoubleDataRow {
  enabled: boolean,
  ringduration: number,
  volume: number,
  alarmtime: number,
  daysofweektype: number,
  hour: number,
  alert: string,
  snoozetimes: number,
  vibrate: number,
  message: string,
  daysofweek: number,
  minutes: number,
  snoozeduration: number,
}

interface DoubleWorldDataRow {
  _id: number,
  timezone: string,
  homecity: number,
  sort_order: number,
  city_index: string
}

interface TDBManager {
  getRDBH: (config: IRelationalStoreConfig) => Promise<CloneDBHandle>
  singleReadData: () => Promise<Array<AlarmInfo>>,
  singleReadResultSet: (resultSet: relationalStore.ResultSet) => Array<AlarmInfo>,
  doubleReadData: () => Promise<Array<IDoubleDataRow>>,
  worldClockReadData: () => Promise<Array<DoubleWorldDataRow>>,
  readRestoreAlarmData: () => Promise<Array<AlarmInfo>>,
  readRestoreWorldData: () => Promise<Array<WorldClockInfo>>,
  doubleReadResultSet: (resultSet: relationalStore.ResultSet) => Array<IDoubleDataRow>,
  worldReadResultSet: (resultSet: relationalStore.ResultSet) => Array<DoubleWorldDataRow>,
  formatToSingle: (doubleData: Array<IDoubleDataRow>) => Array<AlarmInfo>,
  doubleToSingle: () => Promise<boolean>,
  singleRowformatVB: (alarmInfo: AlarmInfo) => ValuesBucket,
  singleInsertTest?: () => Promise<number>,
  transformDayOfWeek: (num: number) => Array<number>,
  clearSingleTable: (tableName: string) => Promise<boolean>;
  getWorldClockCityId: (cityIndex: string) => string;
  initWorldClockInfo: (cityIndex: string) => WorldClockInfo;
  updateTimer: () => Promise<void>;
  addWorldClockList: (worldClockList: Array<DoubleWorldDataRow>) => Promise<void>;
  restoreClock: () => Promise<boolean>;
}

const TAG: string = 'CloneDBManager';
const DEFAULT_SORT_ORDER = 9999;
const singleStoreConfig: relationalStore.StoreConfig = { name: 'Clock.db', securityLevel: 1 };
const alarmStoreConfig: relationalStore.StoreConfig = { name: 'alarm.db', securityLevel: 1 };
const worldStoreConfig: relationalStore.StoreConfig = { name: 'worldClock.db', securityLevel: 1 };
const restoreConfig: relationalStore.StoreConfig = { name: 'cloneClock.db', securityLevel: 1 };
const singleTableName: string = 'ALARM_CLOCK';
const singleWorldTableName: string = 'WORLD_CLOCK';
const alarmTableName: string = 'deskclock_alarm_tb';
// 数据库的建表 SQL
const alarmCreateSql = `
      CREATE TABLE IF NOT EXISTS ${alarmTableName} (
      _ID INTEGER PRIMARY KEY AUTOINCREMENT,
      enabled INTEGER,
      ringduration INTEGER DEFAULT 5,
      volume INTEGER,
      alarmtime INTEGER,
      daysofweektype INTEGER,
      hour INTEGER,
      alert TEXT,
      snoozetimes INTEGER DEFAULT 3,
      vibrate INTEGER,
      message TEXT,
      minutes INTEGER,
      daysofweek INTEGER,
      snoozeduration INTEGER DEFAULT 10)
  `;
const worldTableName: string = 'comandroiddeskclockbackuplocation_items_tb';
// 双框架世界时钟的建表 SQL
const worldCreateSql = `
      CREATE TABLE IF NOT EXISTS ${worldTableName} (
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

export let singleRDBH: CloneDBHandle;

export let doubleRDBH: CloneDBHandle;

export let worldRDBH: CloneDBHandle;

export let restoreRDBH: CloneDBHandle;

function getContext(): Context {
  let context: Context = GlobalContext.getContext().getObject('clockBackupContext') as Context
  context.area = contextConstant.AreaMode.EL1;
  return context;
}

async function getSingleRDBH(): Promise<CloneDBHandle> {
  if (singleRDBH) {
    return singleRDBH;
  }
  singleRDBH = await cloneDBManager.getRDBH({
    context: getContext(),
    storeConfig: singleStoreConfig,
    createSql: SQL_CREATE_TABLE
  });
  return singleRDBH;
}

async function getAlarmRDBH(): Promise<CloneDBHandle> {
  if (doubleRDBH) {
    return singleRDBH;
  }
  doubleRDBH = await cloneDBManager.getRDBH({
    context: getContext(),
    storeConfig: alarmStoreConfig,
    createSql: alarmCreateSql
  });
  return doubleRDBH;
}

async function getWorldRDBH(): Promise<CloneDBHandle> {
  worldRDBH = await cloneDBManager.getRDBH({
    context: getContext(),
    storeConfig: worldStoreConfig,
    createSql: worldCreateSql
  });
  return worldRDBH;
}

async function getRestoreRDBH(): Promise<CloneDBHandle> {
  restoreRDBH = await cloneDBManager.getRDBH({
    context: getContext(),
    storeConfig: restoreConfig
  });
  return restoreRDBH;
}

const cloneDBManager: TDBManager = {
  getRDBH: async (config: IRelationalStoreConfig) => {
    return await CloneDB({ context: getContext(), storeConfig: config.storeConfig, createSql: config.createSql });
  },

  singleReadData: async (): Promise<Array<AlarmInfo>> => {
    let rdbHandle = await getSingleRDBH();
    let resultSet = await rdbHandle.dbQuery(singleTableName, (predicates) => {
      predicates.orderByAsc('HOUR');
      predicates.orderByAsc('MINUTE');
    });
    let result = await cloneDBManager.singleReadResultSet(resultSet);
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
    let rdbHandle = doubleRDBH = await getAlarmRDBH();
    let resultSet = await rdbHandle.dbQuery(alarmTableName, (predicates) => {
      predicates.orderByAsc('hour');
      predicates.orderByAsc('minutes');
    });

    let result = await cloneDBManager.doubleReadResultSet(resultSet);
    await resultSet.close();
    return result;
  },

  worldClockReadData: async (): Promise<Array<DoubleWorldDataRow>> => {
    LogUtil.info(TAG, 'start to read world clock')
    let rdbHandle = worldRDBH = await getWorldRDBH();
    LogUtil.info(TAG, 'get world rdbh success')
    let resultSet = await rdbHandle.dbQuery(worldTableName, (predicates) => {
      predicates.orderByAsc('sort_order');
    });
    let result = await cloneDBManager.worldReadResultSet(resultSet);
    await resultSet.close();
    return result;
  },

  readRestoreAlarmData: async (): Promise<Array<AlarmInfo>> => {
    LogUtil.info(TAG, 'start to read restore alarm clock');
    let rdbHandle = await getRestoreRDBH();
    LogUtil.info(TAG, 'get alarm restore rdbh success');
    let resultSet = await rdbHandle.dbQuery(singleTableName, (predicates) => {
      predicates.orderByAsc('HOUR');
      predicates.orderByAsc('MINUTE');
    });
    let result = await AlarmManager.getAlarmListFromResultSet(resultSet);
    await resultSet.close();
    LogUtil.info(TAG, JSON.stringify(result));
    return result;
  },

  readRestoreWorldData: async (): Promise<Array<WorldClockInfo>> => {
    LogUtil.info(TAG, 'start to read restore world clock')
    let rdbHandle = await getRestoreRDBH();
    LogUtil.info(TAG, 'get restore world rdbh success')
    let resultSet = await rdbHandle.dbQuery(singleWorldTableName, (predicates) => {
      predicates.orderByAsc('ID');
    });
    let result = await WorldClockManager.getWorldClockListFromResultSet(resultSet);
    await resultSet.close();
    LogUtil.info(TAG, JSON.stringify(result));
    return result;
  },

  doubleReadResultSet: (resultSet: relationalStore.ResultSet): Array<IDoubleDataRow> => {
    let a: IDoubleDataRow[] = [];
    while (resultSet.goToNextRow()) {
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
      let ringduration: number = resultSet.getLong(resultSet.getColumnIndex('ringduration'));
      let snoozeduration: number = resultSet.getLong(resultSet.getColumnIndex('snoozeduration'));
      let snoozetimes: number = resultSet.getLong(resultSet.getColumnIndex('snoozetimes'));


      a.push({
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
        ringduration,
        snoozeduration,
        snoozetimes
      })
    }
    return a;
  },

  worldReadResultSet: (resultSet: relationalStore.ResultSet): Array<DoubleWorldDataRow> => {
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
    const existData = await cloneManager.judgeDBExist();
    LogUtil.info(TAG, 'Exist:', JSON.stringify(existData));
    GlobalContext.getContext()
      .setObject('clockContext', GlobalContext.getContext().getObject('clockBackupContext') as Context);
    defaultTitle = await ResourceManager.getStringByIdAsync((DEFAULT_ALARM_TITLE_RESOURCES).id);
    defaultDemoTitle = await ResourceManager.getStringByIdAsync((DEFAULT_ALARM_DEMO_TITLE_RESOURCES).id);
    LogUtil.info(`${TAG}, defaultTitle is ${JSON.stringify(defaultTitle)}; defaultDemoTitle is ${JSON.stringify(defaultDemoTitle)}`);
    if (existData.alarmExist) {
      const data: IDoubleDataRow[] = await cloneDBManager.doubleReadData(); // 读取双框架闹钟数据
      LogUtil.info(TAG, 'get double data success');
      let formatData = await cloneDBManager.formatToSingle(data)
        .map<ValuesBucket>(item => cloneDBManager.singleRowformatVB(item)); // 转换为单框架数据格式
      LogUtil.info(TAG, 'format to single data success', JSON.stringify(formatData));
      if (!singleRDBH) {
        LogUtil.info(TAG, 'singleRDBH is undefined');
        singleRDBH = await getSingleRDBH();
      }
      LogUtil.info(TAG, 'clear single table start');
      const cr = await cloneDBManager.clearSingleTable(singleTableName);
      if (cr) {
        LogUtil.info(TAG, 'clear single table success');
      }
      const r = await singleRDBH.dbBatchInsert(singleTableName, formatData);
      if (r === -1) {
        LogUtil.info(TAG, 'insert to single DB fail');
        return false;
      }
      ;
      await cloneDBManager.updateTimer();
      LogUtil.info(TAG, 'insert to single DB success');
      await singleRDBH.deleteDoubleRdb(getContext(), 'alarm.db')
      LogUtil.info(TAG, 'success over');
    }
    if (existData.worldClockExist) {
      LogUtil.info(TAG, 'start to handle world clock data')
      const data: DoubleWorldDataRow[] = await cloneDBManager.worldClockReadData(); // 读取双框架世界时钟数据
      LogUtil.info(TAG, 'get double worldClock data success', JSON.stringify(data));
      const cr = await cloneDBManager.clearSingleTable(singleWorldTableName);
      if (cr) {
        LogUtil.info(TAG, 'clear world clock table success');
      }
      await cloneDBManager.addWorldClockList(data);
      await worldRDBH.deleteDoubleRdb(getContext(), 'worldClock.db')
    }
    return true;
  },

  formatToSingle(doubleData) {
    LogUtil.info(TAG, 'doubleData is ', JSON.stringify(doubleData));
    let formatResult = doubleData.map<AlarmInfo>((item) => {
      let hour = item.hour;
      let minute = item.minutes;
      let second = 0;
      let enabled = item.enabled;
      let alarmTime = item.alarmtime;
      let title = item.message ? item.message : defaultTitle;
      let ringDuration = item.ringduration;
      let snoozeDuration = item.snoozeduration;
      let snoozeTimes = item.snoozetimes;
      let snoozeCount = item.snoozetimes;
      let daysOfWakeType = item.daysofweektype || 0;
      if (item.daysofweektype === 1) {
        daysOfWakeType = 3;
      }
      /**
       * 针对双框架数据库字段 daysofweek 字段说明
       * 双框架 daysofweek 在数据库中存储为 10进制数字，例如：31, 96 需要转2进制进行星期识别
       * 31 转 2进制结果为 11111， 5个1 表示设置了 周五，周四，周三，周二，周一
       * 96 转 2进制结果为 1100000， 2个1和5个0 表示设置了 周日，周六； （周五，周四，周三，周二，周一 为0 表示未设置）；
       * 针对双框数据 转换为 [0,0,0,0,0,0,0] 表示 [周日，周一，周二，周三，周四，周五，周六]
       *
       * 单框架数据 0：周日,1：周一,2：周二,3：周三,4：周四,5：周五,6：周六
       * */
      let daysOfWeek = cloneDBManager.transformDayOfWeek(item.daysofweek);

      /**
       * 双框架示例数据无标题问题
       * 判断是否为双的示例数据
       * */
      if (!item.message && Number(item.volume) === 3) {
        LogUtil.info(TAG, `demo data ${defaultTitle}`);
        title = defaultDemoTitle;
      }

      return {
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

  clearSingleTable: async (tableName) => {
    LogUtil.info(TAG, 'enter clearSingleTable');
    let rdbHandle = await getSingleRDBH();
    let CLEAR_TABLE_SQL = `DELETE FROM ${tableName}`;
    let r = await rdbHandle.dbClearTable(CLEAR_TABLE_SQL);
    return r;
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

  getWorldClockCityId(cityIndex) {
    let lastDeliver: number = cityIndex.lastIndexOf('_');
    let secondDeliver: number = cityIndex.lastIndexOf('_', (lastDeliver - 1));
    const spaceReg: RegExp = new RegExp('\\s', 'g');
    const sliceReg: RegExp = new RegExp('\-', 'g');
    const transAReg: RegExp = new RegExp('\á', 'g');
    const transSAReg: RegExp = new RegExp('\ã', 'g');
    const transEReg: RegExp = new RegExp('\é', 'g');
    const transIReg: RegExp = new RegExp('\í', 'g');
    const transOReg: RegExp = new RegExp('\ó', 'g');
    const transNReg: RegExp = new RegExp('\ñ', 'g');
    const deliverReg: RegExp = new RegExp('\'', 'g');
    const pointReg: RegExp = new RegExp('\\.', 'g');
    const andReg: RegExp = new RegExp('\&', 'g');
    let doubleCityIndex: string = cityIndex.substring((secondDeliver + 1), lastDeliver);
    let cityId: string = cityIndex.substring((secondDeliver + 1), lastDeliver)
      .replace(spaceReg, '_')
      .replace(sliceReg, '')
      .replace(transAReg, 'a')
      .replace(transSAReg, 'a')
      .replace(transEReg, 'e')
      .replace(transIReg, 'i')
      .replace(transOReg, 'o')
      .replace(transNReg, 'n')
      .replace(deliverReg, '')
      .replace(pointReg, '')
      .replace(andReg, 'amp');
    switch (doubleCityIndex) {
      case 'Kingston':
      case 'Santa Clara':
      case 'San Juan':
      case 'San Jose': {
        cityId = cityIndex.substring((secondDeliver + 1)).replace(spaceReg, '_');
        break;
      }
      case 'Basseterre': {
        cityId = 'Basseterre_St_Kitts_amp_Nevis';
        break;
      }
      case 'Basse-terre': {
        cityId = 'Basseterre_Guadeloupe';
        break;
      }
      case 'St. Johns': {
        cityId = cityIndex.substring((secondDeliver + 1)).replace(spaceReg, '_').replace(pointReg, '');
        break;
      }
      case `St. John's`: {
        cityId = cityIndex.substring((secondDeliver + 1))
          .replace(spaceReg, '_')
          .replace(pointReg, '')
          .replace(andReg, 'amp')
          .replace(deliverReg, '');
        break;
      }
    }
    LogUtil.info(TAG, 'cityId: ', JSON.stringify(cityId));
    return cityId;
  },

  initWorldClockInfo: (cityId) => {
    const cityIndex = cityId;
    const timezone = i18n.TimeZone.getTimezoneFromCity(cityId).getID();
    const city = i18n.TimeZone.getCityDisplayName(cityId, i18n.getSystemLocale());
    const offset = i18n.TimeZone.getTimezoneFromCity(cityId).getRawOffset();
    return {
      sortOrder: DEFAULT_SORT_ORDER,
      cityIndex,
      timezone,
      city,
      offset,
    };
  },

  updateTimer: async () => {
    const nearstAlarm = await AlarmManager.getNearestAlarm();
    if (!nearstAlarm) {
      LogUtil.info(TAG, 'No Alarm Enabled');
      return;
    } else {
      await TimerManager.startAlarm(nearstAlarm);
      const timeStamp = await TimerManager.getTriggerTime();
      CommonUtil.refreshNearestAlarmTime(timeStamp);
      return;
    }
  },

  addWorldClockList: async (worldClockList) => {
    for (const worldClockInfo of worldClockList) {
      let cityId: string = cloneDBManager.getWorldClockCityId(worldClockInfo.city_index);
      await WorldClockManager.addWorldClock(cloneDBManager.initWorldClockInfo(cityId));
    }
  },

  restoreClock: async () => {
    let alarmRestoreData: AlarmInfo[] = await cloneDBManager.readRestoreAlarmData();
    let worldRestoreData: WorldClockInfo[] = await cloneDBManager.readRestoreWorldData();
    GlobalContext.getContext()
      .setObject('clockContext', GlobalContext.getContext().getObject('clockBackupContext') as Context);
    const cleanAlarm = await cloneDBManager.clearSingleTable(singleTableName);
    if (cleanAlarm) {
      LogUtil.info(TAG, 'clear alarm table success');
    }
    ;
    const cleanWorld = await cloneDBManager.clearSingleTable(singleWorldTableName);
    if (cleanWorld) {
      LogUtil.info(TAG, 'clear world table success');
    }
    for (const alarmInfo of alarmRestoreData) {
      if (alarmInfo.title === '') {
        try {
          const PRE_ALARM_TITLE_LIST: number[] = [DEFAULT_ALARM_DEMO_TITLE_RESOURCES.id];
          await ResourceManager.preloadStringResources(PRE_ALARM_TITLE_LIST);
          alarmInfo.title = await ResourceManager.getStringByIdAsync(DEFAULT_ALARM_DEMO_TITLE_RESOURCES.id);
        } catch (error) {
          LogUtil.error(TAG, 'getString error:', (error as BusinessError).message);
        }

      }
      await AlarmManager.addAlarm(alarmInfo, false, true);
    }
    for (const worldClockInfo of worldRestoreData) {
      await WorldClockManager.addWorldClock(worldClockInfo);
    }
    await cloneDBManager.updateTimer();
    await restoreRDBH.deleteDoubleRdb(getContext(), 'cloneClock.db')
    return true
  }
}

export default cloneDBManager;
