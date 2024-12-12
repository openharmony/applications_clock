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

import rdb from '@ohos.data.relationalStore';
import preferencesUtil from '@ohos.data.preferences';
import resmgr from '@ohos.resourceManager';
import dataRdb from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import { ValueType } from '@ohos.data.ValuesBucket';
import DatabaseManager from './DatabaseManager';
import SnoozeManager from './SnoozeManager';
import TimerManager from './TimerManager';
import ResourceManager from './ResourceManager';
import { EventName, EventReportUtil, EventResult, GlobalContext, LogUtil, TimeUtil, CommonUtil } from '../utils';
import {
  ALARM_CLOCK_DATA_TABLE,
  ALARM_TIME_NEVER,
  AlarmInfo,
  AlarmInfoToShow,
  ALERT_TIME_DEFAULT_DATA,
  APP_CONFIG,
  DATA_TABLE,
  ENABLED_FALSE,
  ENABLED_TRUE,
  INIT_SNOOZE_COUNT,
  IS_FIRST_ENTER,
  NEAREST_ALARM_COUNT,
  PRESET_ALARMS,
  PRESET_ALARMS_TITLE,
  SQL_CREATE_TABLE,
  TRIGGER_TIME_NEVER,
  WAKE_DAYS_TYPE,
  IS_FIRST_ENTER_PRESET_CITY_WORLD
} from './types';
import { MILLIS_IN_SECOND, SECOND_IN_MINUTE } from '../types';
import { TIME_TAG_ID_LIST_IN_ZH } from '../utils/types';
// import hiSysEvent from '@ohos.hiSysEvent';

const TAG = 'AlarmManager';

const AM_HOUR_START = 7;

const AM_HOUR_END = 12;

/**
 * 闹钟管理工具类
 *
 * @since 2022-07-06
 */
class AlarmManager extends DatabaseManager {
  // Whether the default alarm data is set.
  private hasInitDefaultAlarms: boolean = false;

  /**
   * Modify Alarm Database Data
   * isIntentMode 意图框架调用此方法的标识
   * @param alarmInfo alarm object
   */
  private async updateAlarmDatabase(alarmInfo: AlarmInfo, isIntentMode?: boolean): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new rdb.RdbPredicates(DATA_TABLE);
      if (alarmInfo && alarmInfo.id) {
        predicates.equalTo('ID', alarmInfo.id);
        await rdbStore.update(this.getDbBucketFromAlarm(alarmInfo, isIntentMode), predicates);
        rdbStore.commit();
        LogUtil.info(TAG, 'updateAlarmDatabase successfully.');
      }
    } catch (error) {
      LogUtil.error(TAG, 'updateAlarm failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * 获取关系数据库存储对象
   * 如果已初始化过，则直接返回之前获取的对象
   * 如果没有初始化过，则使用接口获取对象，并执行数据库建表命令，如果表未创建，则会创建一张新的表
   *
   * @return 关系数据库存储对象
   */
  async getRdbStore(): Promise<rdb.RdbStore> {
    const rdbStore = await super.getRdbStore(SQL_CREATE_TABLE);
    await this.initDefaultAlarms(rdbStore);
    return rdbStore;
  }

  initAlarmStatus(alarmList: Array<AlarmInfo>) {
    const firstOpenStatusAlarm = alarmList.find(item => (item.enabled));
    if (firstOpenStatusAlarm) {
      this.updateAlarm(firstOpenStatusAlarm);
      TimeUtil.getLeftTimeToRingTime(true);
    }
  }

  async getFirstEnterApp(worldClockListLength: number): Promise<Boolean> {
    try {
      const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
        .getObject('clockContext') as Context, APP_CONFIG);
      const isFirstEnter = await preferences.get(IS_FIRST_ENTER_PRESET_CITY_WORLD, true);
      LogUtil.info(TAG, 'AlarmManager isFirstEnter: ' + isFirstEnter);
      LogUtil.info(TAG, 'AlarmManager worldClockListLength: ' + worldClockListLength);
      if (isFirstEnter && worldClockListLength) {
        await preferences.put(IS_FIRST_ENTER_PRESET_CITY_WORLD, false);
        await preferences.flush();
        return false;
      } else if (!isFirstEnter && worldClockListLength) {
        await preferences.put(IS_FIRST_ENTER_PRESET_CITY_WORLD, false);
        await preferences.flush();
        return false;
      }
      if (Boolean(isFirstEnter)) {
        await preferences.put(IS_FIRST_ENTER_PRESET_CITY_WORLD, false);
        await preferences.flush();
        return true;
      }
    } catch (error) {
      LogUtil.error(TAG, 'getFirstEnterApp failed: ', (error as BusinessError).message);
    }
    return false;
  }

  async initDefaultAlarms(rdbStore: rdb.RdbStore): Promise<void> {
    if (this.hasInitDefaultAlarms) {
      return;
    }
    this.hasInitDefaultAlarms = true;
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    const isFirstEnter = await preferences.get(IS_FIRST_ENTER, true);
    let allAlarms = await this.getAllAlarms();
    LogUtil.info(TAG, 'read all alarms', JSON.stringify(allAlarms.length));
    LogUtil.info(TAG, `isFirstEnter: ${isFirstEnter}`);
    if (isFirstEnter && allAlarms.length) { // 如果是安装时钟后首次进入，判断数据库是否有数据，如果有数据可能是双升单或者克隆场景，不创建默认数据
      this.initAlarmStatus(allAlarms);
      await preferences.put(IS_FIRST_ENTER, false);
      await preferences.flush();
      return;
    }
    if (Boolean(isFirstEnter)) {
      await preferences.put(IS_FIRST_ENTER, false);
      await preferences.flush();
      const defaultAlarm1: AlarmInfo = {
        title: '',
        hour: 7,
        minute: 30,
        second: 0,
        daysOfWeek: [1, 2, 3, 4, 5],
        daysOfWakeType: 3,
        enabled: false,
        ringDuration: 5,
        snoozeDuration: 10,
        snoozeTimes: 3,
      }
      const defaultAlarm2: AlarmInfo = {
        title: '',
        hour: 9,
        minute: 0,
        second: 0,
        daysOfWeek: [6, 0],
        daysOfWakeType: 3,
        enabled: false,
        ringDuration: 5,
        snoozeDuration: 10,
        snoozeTimes: 3,
      }
      try {
        rdbStore.beginTransaction();
        defaultAlarm1.alarmTimeIntent = TimeUtil.getAlarmTime(defaultAlarm1)
        defaultAlarm2.alarmTimeIntent = TimeUtil.getAlarmTime(defaultAlarm2)
        const firstAlarmId = await rdbStore.insert(DATA_TABLE, this.getDbBucketFromAlarm(defaultAlarm1));
        const twoAlarmId = await rdbStore.insert(DATA_TABLE, this.getDbBucketFromAlarm(defaultAlarm2));
        const preSetAlarmIds = firstAlarmId + ',' + twoAlarmId;
        await preferences.put(PRESET_ALARMS, preSetAlarmIds);
        await preferences.put(PRESET_ALARMS_TITLE + firstAlarmId, '');
        await preferences.put(PRESET_ALARMS_TITLE + twoAlarmId, '');
        await preferences.flush();
        rdbStore.commit();
      } catch (error) {
        LogUtil.error(TAG, 'add default alarm failed: ', (error as BusinessError).message);
        rdbStore.rollBack();
      }
      let alarmListByDB = await this.getAllAlarms();
      this.initAlarmStatus(alarmListByDB);
    }
  }

  // 根据闹钟id查询数据
  async getIDAlarmFrom(alarmId: string | undefined): Promise<AlarmInfo[]> {
    const rdbStore = await this.getRdbStore();
    const predicates = new dataRdb.RdbPredicates(ALARM_CLOCK_DATA_TABLE);
    predicates.equalTo('ID', alarmId);
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      return this.getAlarmListFromResultSet(resultSet);
    } catch (error) {
      LogUtil.error(TAG, 'getAllAlarms failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return [];
  }

  /**
   * 获取所有闹钟列表
   *
   * @return 闹钟列表
   */
  async getAllAlarms(): Promise<AlarmInfo[]> {
    const rdbStore = await this.getRdbStore();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    predicates.orderByAsc('HOUR');
    predicates.orderByAsc('MINUTE');
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      return this.getAlarmListFromResultSet(resultSet);
    } catch (error) {
      LogUtil.error(TAG, 'getAllAlarms failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return [];
  }

  async getAllTimerAlarms(): Promise<AlarmInfo[]> {
    const timerTitle = ResourceManager.getStringById($r('app.string.timer_title_new').id);
    const rdbStore = await this.getRdbStore();
    let resultSet: rdb.ResultSet = {} as rdb.ResultSet;
    try {
      const predicates = new dataRdb.RdbPredicates(ALARM_CLOCK_DATA_TABLE);
      predicates.equalTo('TITLE', timerTitle);
      predicates.orderByAsc('HOUR');
      predicates.orderByAsc('MINUTE');
      predicates.orderByAsc('SECOND');
      resultSet = await rdbStore.query(predicates);
      return this.getAlarmListFromResultSet(resultSet);
    } catch (error) {
      LogUtil.error(TAG, 'getAllAlarms failed: ', error?.message);
    } finally {
      resultSet && resultSet.close();
    }
    return [];
  }

  /**
   * 获取用于页面展示的所有闹钟列表
   * 在数据库返回的数据上，做进一步加工，用于页面展示
   *
   * @return 用于页面展示的闹钟列表
   */
  async getAllAlarmsToShow(): Promise<AlarmInfoToShow[]> {
    const alarmClockListFromDatabase: AlarmInfo[] = await this.getAllAlarms();
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    const preSetAlarmIds = await preferences.get(PRESET_ALARMS, '');
    const snoozedIds = await SnoozeManager.getSnoozedAlarmId();
    const noFind = -1;
    await ResourceManager.preloadStringResources(TIME_TAG_ID_LIST_IN_ZH);
    return alarmClockListFromDatabase.map(alarmInfo => {
      alarmInfo.enabled = alarmInfo.enabled || snoozedIds.includes(alarmInfo.id as string);
      const resourceManager = GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager;
      const daysOfWeekDesc = TimeUtil.getDaysOfWeekDesc(resourceManager, alarmInfo.daysOfWeek);
      const formatTime = TimeUtil.getFormattedTimeObj(alarmInfo.hour, alarmInfo.minute);
      if (String(preSetAlarmIds).indexOf(alarmInfo.id as string) !== noFind && alarmInfo.title === '') {
        alarmInfo.title = resourceManager.getStringSync($r('app.string.default_alarm_label').id);
      }
      const alarmInfoToShow: AlarmInfoToShow = {
        id: alarmInfo.id,
        second: alarmInfo.second,
        title: alarmInfo.title,
        hour: alarmInfo.hour,
        minute: alarmInfo.minute,
        daysOfWeek: alarmInfo.daysOfWeek,
        daysOfWakeType: alarmInfo.daysOfWakeType,
        alarmTime: alarmInfo.alarmTime,
        enabled: alarmInfo.enabled,
        ringDuration: alarmInfo.ringDuration,
        snoozeDuration: alarmInfo.snoozeDuration,
        snoozeTimes: alarmInfo.snoozeTimes,
        snoozeCount: alarmInfo.snoozeCount,
        tag: formatTime.tag,
        time: formatTime.time,
        isTagLeft: formatTime.isTagLeft,
        daysOfWeekDesc,
        alarmTimeIntent: alarmInfo.alarmTimeIntent,
        reStart: alarmInfo.reStart
      };
      return alarmInfoToShow;
    });
  }

  /**
   * 判断是否获取默认闹钟名称
   *
   * @param alarmId 闹钟Id
   */
  async getDefaultAlarmTitle(alarmId: string, hour: number): Promise<string> {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    const preSetAlarmIds = await preferences.get(PRESET_ALARMS, '');
    const preSetAlarmName = await preferences.get(PRESET_ALARMS_TITLE + alarmId, '');
    const noFind = -1;
    const defaultTitleFirst = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringSync($r('app.string.alarm_clock')
      .id);
    const defaultTitleSecond = (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringSync($r('app.string.default_alarm_label_new')
      .id);
    let isDefaultTitle: boolean = ['', defaultTitleFirst, defaultTitleSecond].includes(preSetAlarmName as string)
    if (String(preSetAlarmIds).indexOf(alarmId) !== noFind && isDefaultTitle) {
      if (hour >= AM_HOUR_START && hour < AM_HOUR_END) {
        return (GlobalContext.getContext()
          .getObject('resourceManager') as resmgr.ResourceManager).getStringSync($r('app.string.default_alarm_label_new')
          .id);
      } else {
        return (GlobalContext.getContext()
          .getObject('resourceManager') as resmgr.ResourceManager).getStringSync($r('app.string.alarm_clock').id);
      }
    }
    return '';
  }

  /**
   * 保存预置闹钟名称
   *
   * @param alarmId 闹钟Id
   * @param alarmName 闹钟Id
   */
  async saveDefaultAlarmTitle(alarmId: string, alarmTitle: string): Promise<void> {
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    const preSetAlarmIds = await preferences.get(PRESET_ALARMS, '');
    const noFind = -1;
    if (String(preSetAlarmIds).indexOf(alarmId) !== noFind) {
      await preferences.put(PRESET_ALARMS_TITLE + alarmId, alarmTitle);
      await preferences.flush();
    }
  }

  /**
   * 新增闹钟
   *
   * @param alarmInfo 闹钟对象
   */
  async addAlarm(alarmInfo: AlarmInfo, isIntentMode?: boolean, isCloneMode?: boolean): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      if (!isCloneMode) {
        alarmInfo.enabled = true;
      }
      LogUtil.info(TAG, 'before addAlarm: ' + JSON.stringify(alarmInfo))
      const ret = await rdbStore.insert(DATA_TABLE, this.getDbBucketFromAlarm(alarmInfo, isIntentMode));
      LogUtil.info(TAG, 'addAlarm: ' + ret);
      rdbStore.commit();
      await this.updateTimer();
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_ALARM_CLOCK_ADD)
    } catch (error) {
      LogUtil.error(TAG, 'addAlarm failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_ALARM_CLOCK_ADD)
    }
  }

  /**
   * 修改闹钟，同时更新闹钟的提醒信息
   * isIntentMode  意图框架调用此方法的标识
   * @param alarmInfo 闹钟对象
   */
  async updateAlarm(alarmInfo: AlarmInfo, isIntentMode?: boolean): Promise<void> {
    if (!alarmInfo.id) {
      LogUtil.error(TAG, 'Execute method updateAlarm failed, params is incorrect.');
      return;
    }
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_SAVE_SETTING)
    await this.updateAlarmDatabase(alarmInfo, isIntentMode);
    await this.updateTimer(alarmInfo.id, alarmInfo.reStart);
  }

  /**
   * 停止提醒，并根据重复模式更新闹钟状态
   *
   * @param alarmInfo 闹钟对象
   */
  async stopAlarm(alarmInfo: AlarmInfo): Promise<void> {
    alarmInfo.enabled = (alarmInfo.daysOfWeek || []).length !== 0 || alarmInfo.daysOfWakeType === 4;
    // 重复模式为“不重复时”，同时关闭闹钟
    await this.updateAlarm(alarmInfo)
  }

  /**
   * 延迟闹钟，并返回根据再响配置更新过下次响铃时间的闹钟对象
   *
   * @param alarmInfo 闹钟对象
   * @param isAuto 是否为自动延迟响铃，不传视为否，自动延迟的场景，会更新闹钟延迟次数的计时器
   * @return 根据再响配置更新过下次响铃时间的闹钟对象
   */
  async delayAlarm(alarmInfo: AlarmInfo, isAuto?: boolean): Promise<number> {
    if (isAuto) {
      await SnoozeManager.increaseSnoozedTimes(alarmInfo.id as string);
    } else {
      await SnoozeManager.clearSnoozeTimes(alarmInfo.id as string);
    }
    const nextAlertTime = new Date().getTime() + alarmInfo.snoozeDuration * MILLIS_IN_SECOND * SECOND_IN_MINUTE;
    await SnoozeManager.saveSnoozedAlarmData(alarmInfo.id as string, nextAlertTime);
    return nextAlertTime;
  }

  /**
   * Obtains the real start time of the alarm.
   *
   * @param alarmInfo AlarmInfo
   * @return Real start time of the alarm in milliseconds.
   */
  async getRealAlertTime(alarmInfo: AlarmInfo): Promise<number> {
    if (!alarmInfo?.id) {
      LogUtil.error(TAG, 'Execute method getRealAlertTime failed, params is incorrect.');
      return ALERT_TIME_DEFAULT_DATA;
    }
    const delayedAlarmTime = await SnoozeManager.getNextAlertTime(alarmInfo.id);
    LogUtil.info(TAG, `Real alert time is: ${delayedAlarmTime}`);
    if (delayedAlarmTime !== ALERT_TIME_DEFAULT_DATA) {
      return delayedAlarmTime;
    }
    if (alarmInfo?.alarmTime) {
      return alarmInfo.alarmTime;
    }
    return ALERT_TIME_DEFAULT_DATA;
  }

  /**
   * 删除闹钟
   *
   * @param alarmInfo 闹钟对象
   */
  async removeAlarm(alarmInfo: AlarmInfo): Promise<void> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new rdb.RdbPredicates(DATA_TABLE);
      predicates.equalTo('ID', alarmInfo.id as string);
      await rdbStore.delete(predicates);
      rdbStore.commit();
      await this.updateTimer();
      LogUtil.info(TAG, 'removeAlarm successfully.');
    } catch (error) {
      LogUtil.error(TAG, 'removeAlarm failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * 批量删除闹钟
   *
   * @param alarmIdSet  要删除的闹钟id集合
   */
  async removeAlarms(alarmIdSet: Set<string>): Promise<void> {
    const idList = Array.from(alarmIdSet);
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new rdb.RdbPredicates(DATA_TABLE);
      predicates.in('ID', idList);
      await rdbStore.delete(predicates);
      rdbStore.commit();
      await this.updateTimer();
      LogUtil.info(TAG, 'remove alarms successfully.');
    } catch (error) {
      LogUtil.error(TAG, 'remove alarms failed because: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
  }

  /**
   * 将前台使用的闹钟对象，转换为新增修改数据库的入参对象
   * isIntentMode 意图框架调用此方法的标识 意图框架的alarmTime为时间戳
   * @param alarmInfo 前台定义的闹钟对象
   * @return 新增、修改数据的入参对象
   */
  getDbBucketFromAlarm(alarmInfo: AlarmInfo, isIntentMode?: boolean): rdb.ValuesBucket {
    LogUtil.info(TAG, 'before getDbBucketFromAlarm alarm is : ' + JSON.stringify(alarmInfo) + isIntentMode)
    if (!isIntentMode) {
      return {
        'TITLE': alarmInfo.title,
        'HOUR': alarmInfo.hour,
        'MINUTE': alarmInfo.minute as ValueType,
        'SECOND': alarmInfo.second || 0,
        'DAYS_OF_WEEK': new Uint8Array(alarmInfo.daysOfWeek || []),
        'DAYS_OF_WAKE_TYPE': alarmInfo.daysOfWakeType || 0,
        'ALARM_TIME': alarmInfo.enabled ? TimeUtil.getAlarmTime(alarmInfo) : ALARM_TIME_NEVER,
        'ENABLED': alarmInfo.enabled ? ENABLED_TRUE : ENABLED_FALSE,
        'RING_DURATION': alarmInfo.ringDuration as ValueType,
        'SNOOZE_DURATION': alarmInfo.snoozeDuration,
        'SNOOZE_TIMES': alarmInfo.snoozeTimes,
        'SNOOZE_COUNT': alarmInfo.snoozeCount || INIT_SNOOZE_COUNT,
        'ALARM_TIME_INTENT': alarmInfo.alarmTimeIntent as number === 0 ? TimeUtil.getAlarmTime(alarmInfo)
          : alarmInfo.alarmTimeIntent as number,
        'RESTART': alarmInfo.reStart ? alarmInfo.reStart : ''
      };
    }

    LogUtil.info(TAG, 'intentMode before getDbBucketFromAlarm alarm is : ' + alarmInfo.alarmTime)
    return {
      'TITLE': alarmInfo.title,
      'HOUR': alarmInfo.hour,
      'MINUTE': alarmInfo.minute as ValueType,
      'SECOND': alarmInfo.second || 0,
      'DAYS_OF_WEEK': new Uint8Array(alarmInfo.daysOfWeek || []),
      'DAYS_OF_WAKE_TYPE': alarmInfo.daysOfWakeType || 0,
      'ALARM_TIME': alarmInfo.alarmTime!,
      'ENABLED': alarmInfo.enabled ? ENABLED_TRUE : ENABLED_FALSE,
      'RING_DURATION': alarmInfo.ringDuration as ValueType,
      'SNOOZE_DURATION': alarmInfo.snoozeDuration,
      'SNOOZE_TIMES': alarmInfo.snoozeTimes,
      'SNOOZE_COUNT': alarmInfo.snoozeCount || INIT_SNOOZE_COUNT,
      'ALARM_TIME_INTENT': alarmInfo.alarmTimeIntent as number,
      'RESTART': alarmInfo.reStart ? alarmInfo.reStart : ''
    };
  }

  /**
   * 从数据库查询的返回对象中，获取前台可用的闹钟信息列表
   *
   * @param resultSet 数据库返回的结果集对象
   * @return 闹钟信息列表
   */
  async getAlarmListFromResultSet(resultSet: rdb.ResultSet): Promise<AlarmInfo[]> {
    const alarmClockList: AlarmInfo[] = [];
    while (resultSet.goToNextRow()) {
      const daysOfWeekNative: Uint8Array = resultSet.getBlob(resultSet.getColumnIndex('DAYS_OF_WEEK'));
      const daysOfWeek: number[] = [];
      daysOfWeekNative.forEach(day => {
        daysOfWeek.push(day);
      });
      const alarmInfo: AlarmInfo = {
        daysOfWeek,
        id: resultSet.getString(resultSet.getColumnIndex('ID')),
        hour: resultSet.getLong(resultSet.getColumnIndex('HOUR')),
        minute: resultSet.getLong(resultSet.getColumnIndex('MINUTE')),
        second: resultSet.getLong(resultSet.getColumnIndex('SECOND')),
        enabled: !!resultSet.getLong(resultSet.getColumnIndex('ENABLED')),
        alarmTime: resultSet.getLong(resultSet.getColumnIndex('ALARM_TIME')),
        title: resultSet.getString(resultSet.getColumnIndex('TITLE')),
        ringDuration: resultSet.getLong(resultSet.getColumnIndex('RING_DURATION')),
        snoozeDuration: resultSet.getLong(resultSet.getColumnIndex('SNOOZE_DURATION')),
        snoozeTimes: resultSet.getLong(resultSet.getColumnIndex('SNOOZE_TIMES')),
        snoozeCount: resultSet.getLong(resultSet.getColumnIndex('SNOOZE_COUNT')),
        daysOfWakeType: resultSet.getColumnIndex('DAYS_OF_WAKE_TYPE') > -1 ? resultSet.getLong(resultSet.getColumnIndex('DAYS_OF_WAKE_TYPE')) : 0,
        alarmTimeIntent: resultSet.getColumnIndex('ALARM_TIME_INTENT') > -1 ? resultSet.getLong(resultSet.getColumnIndex('ALARM_TIME_INTENT')) : 0,
        reStart: resultSet.getString(resultSet.getColumnIndex('RESTART')) ? resultSet.getString(resultSet.getColumnIndex('RESTART')) : ''
      }
      alarmClockList.push(alarmInfo);
    }
    return alarmClockList;
  }

  /**
   * 获取最近一次需要提醒的闹钟
   * 搜索条件是已开启的闹钟，只返回一个结果，按提醒时间排序
   *
   * @return 最近一次需要提醒的闹钟
   */
  async getNearestAlarm(): Promise<AlarmInfo | undefined> {
    const rdbStore = await this.getRdbStore();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    const snoozedIds = await SnoozeManager.getSnoozedAlarmId();
    if (snoozedIds?.length > 0) {
      predicates.in('ID', snoozedIds).or().equalTo('ENABLED', ENABLED_TRUE);
    } else {
      predicates.equalTo('ENABLED', ENABLED_TRUE);
    }
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      const alarmList = await this.getAlarmListFromResultSet(resultSet);
      const currentTime = new Date().getTime();
      let nearestAlarm: AlarmInfo | undefined = undefined;
      for (const alarm of alarmList) {
        let tempAlarmTime: number | undefined = undefined;
        if (snoozedIds.includes(alarm.id as string)) {
          tempAlarmTime = alarm.alarmTime;
          alarm.alarmTime = await SnoozeManager.getNextAlertTime(alarm.id as string);
        }
        if (alarm.alarmTime && alarm.alarmTime < currentTime) {
          await SnoozeManager.deleteSnoozedAlarmId(alarm.id as string);
          if (alarm.daysOfWeek.length <= 0 && alarm.daysOfWakeType !== WAKE_DAYS_TYPE) {
            alarm.alarmTime = tempAlarmTime;
            alarm.enabled = false;
            await this.updateAlarmDatabase(alarm);
            continue;
          }
          if (alarm.daysOfWeek.length > 0 || alarm.daysOfWakeType === WAKE_DAYS_TYPE) {
            alarm.alarmTime = TimeUtil.getAlarmTime(alarm);
            await this.updateAlarmDatabase(alarm);
          }
        }
        if (!nearestAlarm || (nearestAlarm.alarmTime && alarm.alarmTime && alarm.alarmTime < nearestAlarm.alarmTime)) {
          nearestAlarm = alarm;
        }
      }
      return nearestAlarm;
    } catch (error) {
      LogUtil.error(TAG, 'getNextAlarm failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return undefined;
  }

  /**
   * Query the latest alarm data from the database.
   *
   * @param the latest alarm data
   */
  async getLatestAlarmFromDb(alarmId: string | number): Promise<AlarmInfo | undefined> {
    if (!alarmId) {
      LogUtil.info(TAG, 'get latest alarm from db occurs error, alarmId is empty');
      return undefined;
    }
    const rdbStore = await this.getRdbStore();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    predicates.equalTo('ID', alarmId);
    predicates.limitAs(NEAREST_ALARM_COUNT);
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      const alarmList = await this.getAlarmListFromResultSet(resultSet);
      const snoozedIds = await SnoozeManager.getSnoozedAlarmId();
      if (alarmList[0] && snoozedIds && snoozedIds.includes(alarmId.toString())) {
        alarmList[0].alarmTime = await SnoozeManager.getNextAlertTime(alarmId.toString());
      }
      if (alarmList[0].title === '') {
        let list = await this.getAllAlarmsToShow()
        list.forEach((item) => {
          if (item.id === alarmList[0].id) {
            alarmList[0].title = item.title
          }
        })
      }
      LogUtil.info(TAG, `alarmList==> ${JSON.stringify(alarmList)}}`)
      return alarmList[0];
    } catch (error) {
      LogUtil.error(TAG, `getLatestAlarmDataInBb failed: ${JSON.stringify(error)}`);
    } finally {
      resultSet && resultSet.close();
    }
    return undefined;
  }

  /**
   * 根据最新的最近一次需要触发的闹钟，更新计时器
   * 如果时间相对之前没有变化，则不更新
   * 如果时间变化（包括从无到有，从有到无），则需要更新记录计时器的缓存
   */
  async updateTimer(changedAlarmId?: string | number, reStart?: string): Promise<void> {
    const triggerTime = await TimerManager.getTriggerTime();
    const triggerAlarmID = await TimerManager.getTriggerTimeID();
    const nearestAlarm = await this.getNearestAlarm();
    if (changedAlarmId && reStart && reStart !== '') {
      const restartAlarmList = await this.getAlarmById(changedAlarmId as string);
      if (restartAlarmList && restartAlarmList.length !== 0) {
        const restartAlarm = restartAlarmList[0];
        await TimerManager.startRepeatAlarm(restartAlarm);
      }
      const timeStamp = await TimerManager.getTriggerTime();
      CommonUtil.refreshNearestAlarmTime(timeStamp);
      return;
    }
    if (!nearestAlarm) {
      LogUtil.info(TAG, 'No alarm enabled!');
      // 数据库中不再有最近闹钟，但是还有开启的计时器，需要停止计时器
      triggerTime && triggerTime !== TRIGGER_TIME_NEVER && await TimerManager.stopAlarm();
      CommonUtil.refreshNearestAlarmTime(0);
      return;
    }
    const isDifferentTime = (triggerTime !== nearestAlarm.alarmTime);
    const isDifferentId = (triggerAlarmID !== Number(nearestAlarm.id) ||
      (changedAlarmId && Number(changedAlarmId) !== Number(nearestAlarm.id)));
    if (nearestAlarm.alarmTime && (isDifferentTime || isDifferentId)) {
      LogUtil.info(TAG, 'The latest start time has changed.');
      await TimerManager.startAlarm(nearestAlarm);
      const timeStamp = await TimerManager.getTriggerTime();
      CommonUtil.refreshNearestAlarmTime(timeStamp);
      return;
    }
    // If the parameters of the latest alarm are modified, the timer still needs to be updated.
    if (changedAlarmId && changedAlarmId === nearestAlarm.id) {
      LogUtil.info(TAG, 'nearestAlarm alarm parameters has changed, still need to startAlarm');
      await TimerManager.startAlarm(nearestAlarm);
      const timeStamp = await TimerManager.getTriggerTime();
      CommonUtil.refreshNearestAlarmTime(timeStamp);
      return;
    }
    LogUtil.info(TAG, 'nearestAlarm alarm has no change');
  }

  /**
   * Refresh the timer immediately regardless of whether the latest start time changes.
   */
  async updateTimerImmediately(): Promise<void> {
    const triggerTime = await TimerManager.getTriggerTime();
    const nearestAlarm = await this.getNearestAlarm();
    if (!nearestAlarm) {
      LogUtil.info(TAG, 'No alarms enabled!');
      triggerTime && triggerTime !== TRIGGER_TIME_NEVER && await TimerManager.stopAlarm();
      return;
    }
    if (nearestAlarm.alarmTime) {
      LogUtil.info(TAG, 'Update timer immediately.');
      await TimerManager.startAlarm(nearestAlarm);
      return;
    }
    LogUtil.info(TAG, `nearestAlarm alarmTime is incorrect: ${nearestAlarm.alarmTime}`);
  }

  /**
   * Queries and disables all alarms that are unique and
   * whose start time is the same as that of alarmInfo in the alarm list.
   * Query and reset the alarm time of all duplicate alarms in the alarm list.
   * The alarm time is the same as that of alarmInfo.
   *
   * @param alarmTime alarm clock that is being started
   */
  async closeNoRepeatAlarms(alarmInfo: AlarmInfo): Promise<void> {
    const rdbStore = await this.getRdbStore();
    rdbStore.beginTransaction();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    predicates.equalTo('ALARM_TIME', alarmInfo.alarmTime as number);
    predicates.equalTo('ENABLED', ENABLED_TRUE);
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      rdbStore.commit();
      const alarmList = await this.getAlarmListFromResultSet(resultSet);
      alarmList.forEach(async alarmInfo => {
        if (alarmInfo.daysOfWeek.length === 0 && alarmInfo.daysOfWakeType !== WAKE_DAYS_TYPE) {
          alarmInfo.enabled = false;
        } else {
          alarmInfo.alarmTime = TimeUtil.getAlarmTime(alarmInfo);
        }
        await this.updateAlarmDatabase(alarmInfo);
      });
      await this.updateTimer();
    } catch (error) {
      LogUtil.error(TAG, 'closeNoRepeatAlarms failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    } finally {
      resultSet && resultSet.close();
    }
  }

  async closeNoRepeatAlarmsDB(alarmTime: number): Promise<void> {
    const rdbStore = await this.getRdbStore();
    rdbStore.beginTransaction();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    predicates.equalTo('ALARM_TIME', alarmTime);
    predicates.equalTo('ENABLED', ENABLED_TRUE);
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      rdbStore.commit();
      const alarmList = await this.getAlarmListFromResultSet(resultSet);
      alarmList.forEach(async alarmInfo => {
        LogUtil.info(TAG, 'closeNoRepeatAlarmsDB before:' + JSON.stringify(alarmInfo));
        if (alarmInfo.daysOfWeek.length === 0 && alarmInfo.daysOfWakeType !== WAKE_DAYS_TYPE) {
          alarmInfo.enabled = false;
        } else {
          alarmInfo.alarmTime = TimeUtil.getAlarmTime(alarmInfo);
        }
        LogUtil.info(TAG, 'closeNoRepeatAlarmsDB after:' + JSON.stringify(alarmInfo));
        await this.updateAlarmDatabase(alarmInfo);
      });
    } catch (error) {
      LogUtil.error(TAG, 'closeNoRepeatAlarmsDB failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    } finally {
      resultSet && resultSet.close();
    }
  }

  /**
   * Has the nap limit been reached
   *
   * @return true if reached the upper limit
   */
  async hasReachedLimitedSnoozeTimes(alarmInfo: AlarmInfo): Promise<boolean> {
    const hasSnoozedTimes = await SnoozeManager.getSnoozedTimes(alarmInfo.id as string);
    return hasSnoozedTimes >= alarmInfo.snoozeTimes;
  }

  /**
   * Clear snooze data in sharedPreference by alarm id.
   *
   * @param alarmInfo Alarm info
   * @param isEditMode Whether user proactively edits the alarm
   * @return cleared alarm ids
   */
  async clearSnoozedData(alarmInfo: AlarmInfo, isEditMode: boolean): Promise<string[]> {
    // The following situations will walk up here
    // 1: User proactively edits the alarm
    // 2: Close the alarm
    // 3: User clicks the button for closing the notification bar
    if (isEditMode) {
      await SnoozeManager.deleteSnoozedAlarmId(alarmInfo.id as string);
      await SnoozeManager.clearSnoozeTimes(alarmInfo.id as string);
    }
    if (!alarmInfo.enabled) {
      return [];
    }
    const clearedAlarmIds: string[] = [];
    if (alarmInfo.id) {
      clearedAlarmIds.push(alarmInfo.id);
    }
    const snoozeIds = await SnoozeManager.getSnoozedAlarmId();
    for (const id of snoozeIds) {
      const alertTime = await SnoozeManager.getNextAlertTime(id);
      // Snoozed alert time is later than current edited alarm. in this case, we need to clear snoozed data.
      if (alertTime !== ALERT_TIME_DEFAULT_DATA && alertTime > TimeUtil.getAlarmTime(alarmInfo)) {
        await SnoozeManager.deleteSnoozedAlarmId(id);
        await SnoozeManager.clearSnoozeTimes(id);
        clearedAlarmIds.push(id);
      }
    }
    return clearedAlarmIds;
  }

  /**
   * Refresh all alarms ALARM_TIME in database.
   */
  async recalculateAllAlarmsAlarmTime(isIntentMode?: boolean): Promise<void> {
    const alarmList = await this.getAllAlarms();
    if (!alarmList || alarmList.length <= 0) {
      LogUtil.info(TAG, 'There is no alarm, no need to recalculate');
      return;
    }
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      for (const alarmInfo of alarmList) {
        const predicates = new rdb.RdbPredicates(DATA_TABLE);
        predicates.equalTo('ID', alarmInfo.id as string);
        const valuesBucket = this.getDbBucketFromAlarm(alarmInfo, isIntentMode);
        await rdbStore.update(valuesBucket, predicates);
      }
      rdbStore.commit();
      LogUtil.info(TAG, 'recalculate successfully.');
    } catch (error) {
      LogUtil.error(TAG, `recalculate failed:${(error as BusinessError).message}`);
      rdbStore.rollBack();
    }
  }

  /**
   * 通过id删除闹钟
   *
   * @param alarmID 闹钟id
   */
  async removeAlarmById(alarmID: string): Promise<string> {
    const rdbStore = await this.getRdbStore();
    try {
      rdbStore.beginTransaction();
      const predicates = new rdb.RdbPredicates(DATA_TABLE);
      predicates.equalTo('ID', alarmID as string);
      let deleteResult = await rdbStore.delete(predicates);
      rdbStore.commit();
      await this.updateTimer();
      if (deleteResult) {
        LogUtil.info(TAG, 'removeAlarm successfully.');
        return 'success'
      }
      LogUtil.info(TAG, 'removeAlarm failed , no this alarmId');
      return 'failed'
    } catch (error) {
      LogUtil.error(TAG, 'removeAlarm failed: ', (error as BusinessError).message);
      rdbStore.rollBack();
    }
    return 'error'
  }

  /**
   *  根据条件查询对应的闹钟
   *  id
   *
   * @return 当前条件对应的闹钟
   */
  async getAlarmById(alarmID: string): Promise<AlarmInfo [] | undefined> {
    if (!alarmID) {
      LogUtil.info(TAG, 'get alarm by id failed, alarmId is empty')
      return undefined
    }
    const rdbStore = await this.getRdbStore();
    const predicates = new rdb.RdbPredicates(DATA_TABLE);
    predicates.equalTo('ID', alarmID)
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      let alarmList = await this.getAlarmListFromResultSet(resultSet);
      return alarmList
    } catch (error) {
      LogUtil.error(TAG, 'get alarm by id  failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return undefined;
  }

  /**
   *  根据id排序闹钟列表
   *  sortAlarmListById  根据id排序闹钟列表
   *
   * @return 当前条件对应的闹钟
   */
  async sortAlarmListById(): Promise<AlarmInfo [] | undefined> {
    const alarmList = await this.getAllAlarmsToShow();
    LogUtil.info(TAG, 'intentExecutor createAlarm alarmList is : ' + JSON.stringify(alarmList))
    let idList = alarmList.map((alarmInfo) => {
      return alarmInfo.id
    })
    let sortedIdList = idList.sort()
    let resultId = sortedIdList[sortedIdList.length - 1]
    let sortByIdList = alarmList.filter((alarmInfo) => {
      return alarmInfo.id == resultId
    })
    LogUtil.info(TAG, 'intentExecutor createAlarm sortByIdList is : ' + JSON.stringify(sortByIdList))
    return sortByIdList
  }

  /**
   *  并列查询  支持一起查 id、闹钟名称、启用状态、响铃时间段
   *
   *
   * @return 当前条件对应的闹钟列表
   */
  async searchAlarmInfo(entityId?: string, title?: string, enabled?: boolean, alarmTimeArr?: string[]):
    Promise<AlarmInfo[] | undefined> {
    const rdbStore = await this.getRdbStore();
    let predicates = new dataRdb.RdbPredicates(ALARM_CLOCK_DATA_TABLE);

    if (entityId) {
      predicates = predicates.equalTo('ID', entityId)
      if (title) {
        predicates = predicates.contains('TITLE', title)
        if (enabled && enabled == true || enabled == false) {
          predicates = predicates.equalTo('ENABLED', enabled)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      } else {
        if (enabled && enabled == true || enabled == false) {
          predicates = predicates.equalTo('ENABLED', enabled)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      }
    }

    if (title) {
      predicates = predicates.contains('TITLE', title)
      if (entityId) {
        predicates = predicates.equalTo('ID', entityId)

        if (enabled && enabled == true || enabled == false) {
          predicates = predicates.equalTo('ENABLED', enabled)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      } else {
        if (enabled && enabled == true || enabled == false) {
          predicates = predicates.equalTo('ENABLED', enabled)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      }
    }

    if (enabled && enabled == true || enabled == false) {
      predicates = predicates.equalTo('ENABLED', enabled)
      if (entityId) {
        predicates = predicates.equalTo('ID', entityId)

        if (title) {
          predicates = predicates.contains('TITLE', title)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      } else {
        if (title) {
          predicates = predicates.contains('TITLE', title)
          if (alarmTimeArr && alarmTimeArr.length === 2) {
            predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
          }
        }
      }
    }

    if (alarmTimeArr && alarmTimeArr.length === 2) {
      predicates.between('ALARM_TIME_INTENT', alarmTimeArr[0], alarmTimeArr[1])
      if (entityId) {
        predicates = predicates.equalTo('ID', entityId)

        if (title) {
          predicates = predicates.contains('TITLE', title)
          if (enabled && enabled == true || enabled == false) {
            predicates = predicates.equalTo('ENABLED', enabled)
          }
        }
      } else {
        if (title) {
          predicates = predicates.contains('TITLE', title)
          if (enabled && enabled == true || enabled == false) {
            predicates = predicates.equalTo('ENABLED', enabled)
          }
        }
      }
    }
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      let alarmList = await this.getAlarmListFromResultSet(resultSet);
      return alarmList
    } catch (error) {
      LogUtil.error(TAG, 'get alarms failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return undefined;
  }

  /**
   *  根据条件查询对应的闹钟
   *  alarmTimeIntent  只有意图框架才能用这个方法
   *
   * @return 当前条件对应的闹钟
   */
  async getAlarmByAlarmTimeIntent(alarmTimeIntent: number): Promise<AlarmInfo[] | undefined> {
    const rdbStore = await this.getRdbStore();
    let predicates = new dataRdb.RdbPredicates(ALARM_CLOCK_DATA_TABLE);
    predicates = predicates.equalTo('ALARM_TIME_INTENT', alarmTimeIntent);
    let resultSet: rdb.ResultSet = await rdbStore.query(predicates);
    try {
      const alarmList = await this.getAlarmListFromResultSet(resultSet);
      return alarmList
    } catch (error) {
      LogUtil.error(TAG, 'get alarm by alarmTimeIntent failed: ', (error as BusinessError).message);
    } finally {
      resultSet && resultSet.close();
    }
    return undefined;
  }
}

export default new AlarmManager();