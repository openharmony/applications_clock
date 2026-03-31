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

import mediaQuery from '@ohos.mediaquery';
import rdb from '@ohos.data.relationalStore';

import { FormatTime } from '../utils';

// RDB 数据库的初始化配置
export const STORE_CONFIG: rdb.StoreConfig = { name: 'Clock.db', securityLevel: 1 };

// RDB 数据库的版本
export const RDB_VERSION: number = 3;

export interface FormInfo {
  formId: string;
  formName: string;
  parameters?: string[];
}

// 闹钟信息类型定义
export interface AlarmInfo {
  id?: string,
  title: string,
  hour: number,
  minute: number,
  second?: number,
  reStart?: string,
  daysOfWeek: number[], // 设置每个星期哪一天重复提醒，范围从 1 到 7
  daysOfWakeType?: number, //设置单次或者法定工作日
  alarmTime?: number, // 最近一次响铃时间，使用 Date 的 getTime 方法获取
  enabled: boolean, // 是否打开
  ringPath?: string,
  ringDuration: number, // 响铃时间
  snoozeDuration: number, // 再响间隔
  snoozeTimes: number, // 再响次数
  snoozeCount?: number, // 某次响铃中，已再响的次数，与 snoozeTimes 相等时，不再重新响铃
  alarmTimeIntent?: number //意图框架模式下的最近一次响铃时间 时间戳
}

// 用于前台展示的闹钟对象，在 AlarmInfo 的基础上，加入 时间段标签、组装后的时间 和 每周重复时间的文字版本
export interface AlarmInfoToShow extends AlarmInfo, FormatTime {
  daysOfWeekDesc?: string, // 每周重复时间的文字版本，如 "周一 周二 周六"
}

// 用于表单展示的闹钟对象，在 AlarmInfo 的基础上，加入 用于表单展示再响设置的文字描述 和 用于表单展示响铃时长的文字描述
export interface AlarmInfoProperty extends AlarmInfo {
  snoozeDesc?: string, // 用于表单展示再响设置的文字描述
  ringDurationDesc?: string, // 用于表单展示响铃时长的文字描述
}

// 数据库表名
export const ALARM_CLOCK_DATA_TABLE = 'ALARM_CLOCK';

export const WORLD_CLOCK_DATA_TABLE = 'WORLD_CLOCK';

// 数据库表名
export const DATA_TABLE = 'ALARM_CLOCK';

// 数据库的建表 SQL
export const SQL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS ${DATA_TABLE} (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    REMINDER_ID INTEGER,
    HOUR INTEGER NOT NULL,
    MINUTE INTEGER NOT NULL,
    SECOND INTEGER NOT NULL,
    ALARM_TIME INTERGER NOT NULL,
    ENABLED INTEGER NOT NULL,
    TITLE TEXT NOT NULL,
    RING_DURATION INTEGER NOT NULL,
    SNOOZE_DURATION INTEGER NOT NULL,
    SNOOZE_TIMES INTEGER NOT NULL,
    SNOOZE_COUNT INTEGER NOT NULL,
    DAYS_OF_WEEK BLOB,
    DAYS_OF_WAKE_TYPE INTEGER,
    ALARM_TIME_INTENT INTEGER,
    RESTART INTEGER
  )
`;

// 数据库的建表 SQL
export const CREATE_ALARM_CLOCK_TABLE_QUERY = `
  CREATE TABLE IF NOT EXISTS ${ALARM_CLOCK_DATA_TABLE} (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    REMINDER_ID INTEGER,
    HOUR INTEGER NOT NULL,
    MINUTE INTEGER NOT NULL,
    SECOND INTEGER NOT NULL,
    ALARM_TIME INTEGER NOT NULL,
    ENABLED INTEGER NOT NULL,
    TITLE TEXT NOT NULL,
    RING_DURATION INTEGER NOT NULL,
    SNOOZE_DURATION INTEGER NOT NULL,
    SNOOZE_TIMES INTEGER NOT NULL,
    SNOOZE_COUNT INTEGER NOT NULL,
    DAYS_OF_WEEK BLOB,
    ALARM_TIME_INTENT INTEGER,
    RESTART TEXT
  )
`;

export const CREATE_WORLD_CLOCK_TABLE_QUERY = `
  CREATE TABLE IF NOT EXISTS ${WORLD_CLOCK_DATA_TABLE} (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    SORT_ORDER INTEGER NOT NULL,
    CITY_INDEX TEXT NOT NULL,
    TIMEZONE TEXT NOT NULL,
    CITY TEXT NOT NULL,
    OFFSET INTEGER NOT NULL
  );`;

// ENABLED 字段在数据库中代表 true 和 false 的值
export const ENABLED_TRUE = 1;

export const ENABLED_FALSE = 0;

// 闹钟不重复，且未激活时，其 ALARM_TIME 的字段值
export const ALARM_TIME_NEVER = 0;

// 查询最近闹钟的个数，通常只查一个，即最快被触发的闹钟
export const NEAREST_ALARM_COUNT = 1;

// 没有计时器在触发时，trigger time 的取值
export const TRIGGER_TIME_NEVER = -1;

// 再响次数计数器步长
export const SNOOZE_COUNT_STEP = 1;

// 再响次数计数器初始值
export const INIT_SNOOZE_COUNT = 0;

// 计时器使用的内部数据存储名称
export const ALARM_CLOCK_TIMER_STORE = 'ALARM_CLOCK_TIMER_STORE';

// 计时器使用的内部数据存储中，TIMER ID 的键值
export const ALARM_CLOCK_TIMER_ID = 'ALARM_CLOCK_TIMER_ID';

// 计时器使用的内部数据存储中，起闹时间 的键值
export const ALARM_CLOCK_TRIGGER_TIME = 'ALARM_CLOCK_TRIGGER_TIME';

export const ALARM_CLOCK_TRIGGER_TIME_ID = 'ALARM_CLOCK_TRIGGER_TIME_ID';

// Nap-related data
export const ALARM_CLOCK_SNOOZE_STORE = 'ALARM_CLOCK_SNOOZE_STORE';

export const PAGE_STATE_STORE = 'PAGE_STATE_STORE';

export const CLOCK_SHOW_STATE_STORE = 'CLOCK_SHOW_STATE_STORE';

export const FROM_DATA_STORE = 'FROM_DATA_STORE';

export const STOP_WATCH_DATA_STORE = 'STOP_WATCH_DATA_STORE';

export const TIMER_DATA_STORE = 'TIMER_DATA_STORE';

// Snoozed alarm ids data key saved in sharePreference
export const SNOOZE_ID = 'SNOOZE_ID';

// Separator of the Snoozed ID
export const SNOOZE_SEPARATOR = ',';

// 如果在内部存储中获取不到 TIMER ID，则返回这个值
export const NO_TIMER = -1;

// UserConfigs
export const APP_CONFIG = 'APP_CONFIG';

// Key for first enter app
export const IS_FIRST_ENTER = 'IS_FIRST_ENTER';

// Key for PRESET_ALARMS
export const PRESET_ALARMS = 'PRESET_ALARMS';

// Key for PRESET_ALARMS_NAME
export const PRESET_ALARMS_TITLE = 'PRESET_ALARMS_TITLE_';

// Subscribe to event alarm start eventId
export const EVENT_ID_ALARM_RING = 1;

// Subscribe finish ability eventId
export const EVENT_ID_FINISH_ABILITY = 2;

// Subscribe add or modify alarm eventId
export const EVENT_ID_CHANGE_ALARM = 3;

// Subscribe Delete alarm eventId
export const EVENT_ID_DELETE_ALARM = 4;

//Subscribe edit world clock eventId
export const EVENT_ID_EDIT_WORLD_CLOCK = 5;

//Subscribe add or modify world clock eventId
export const EVENT_ID_CHANGE_WORLD_CLOCK = 6;

//Subscribe alarm service kill alarm timeout message eventId
export const EVENT_ID_KILL_ALARM_TIMEOUT_MESSAGE = 7;

export const EVENT_ID_TIMER_FULL_SCREEN_CLOSE = 8

// Subscribe full screen alarm eventId
export const EVENT_ID_FULL_SCREEN_ALARM = 9527;

export const EVENT_ID_BANNER_ALARM = 9528;

export const EVENT_ID_TIMEPICK_FORPC = 999099

export const EVENT_ID_WORLDCLOCK_FORPC = 999098

export const EVENT_ID_SEND_ALARM = 999097

export const TIME_PAUSE_OR_CONTINUE_ID = 666669

export const TIMEOUT_FULL_SCREEN_ID = 666666

export const TIMEOUT_FULL_SCREEN_CLOSE_ID = 666664

export const TIMEOUT_FULL_SCREEN_REPATE_ID = 666662

export const TIMEOUT_FLAG_ID = 666000

export const FULLSCREEN_SLIPUP_ID = 666601

export const TIMER_Toggle_FRONT_AND_BACKEND = 666110

// Next start time default data
export const ALERT_TIME_DEFAULT_DATA = -1;

// Key for alarm id default value
export const DEFAULT_ALARM_ID = -1;

// alarm ring time key
export const KEY_ALARM_RING_TIME = 'alarmRingTime';

// toast show time
export const PROMPT_TIME = 2000;

// Maximum length of the alarm name
export const ALARM_NAME_INPUT_LIMIT = 200;

// Min length of the alarm name
export const ALARM_NAME_INPUT_MIN = 0;

// Alarm is Alerting
export const STATE_FIRING = 1;

// Alarm is Snoozed
export const STATE_SNOOZE = 2;

// Alarm is Stopped and before AlarmService is destroyed
export const STATE_STOP = 3;

// AlarmService is destroyed after STATE_STOP
export const STATE_IDLE = 0;

export enum BreakPoint {
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
}

export enum MatchRule {
  SM = '(320vp<=width<520vp)',
  MD = '(520vp<=width<840vp)',
  LG = '(840vp<=width)',
}

export const MIN_LG_WIDTH = 840;

export const MIN_MD_WIDTH = 520;

export const COMMON_GRID_COL_OPTIONS: GridColOptions = {
  span: {
    xs: 12,
    md: 12,
    lg: 8,
  },
  offset: {
    xs: 0,
    md: 0,
    lg: 2,
  },
};

export interface BreakPointListener {
  listener: mediaQuery.MediaQueryListener,
  breakPoint: BreakPoint,
}

export const RING_FILE_NAME = 'ring.wav';

export const READ_INTERVAL = 16;

export const FILE_SEPARATOR = '/';

export const WRITE_MODE = 'w+';

export const TIMER_SELECTED_RING = 'TIMER_SELECTED_RING';

export const ALARM_LAST_SELECTED_RING = 'ALARM_LAST_SELECTED_RING';

export const CURRENT_DATABASE_VERSION = 'CURRENT_DATABASE_VERSION';

export const WAKE_DAYS_TYPE = 4;

export const ONES_TYPE = 0;

export const TIMER_PREFERENCES_CLOCK = 'TIMER_PREFERENCES_CLOCK';

export const START_DATE_TIMER_PREFERENCES_CLOCK = 'START_DATE_TIMER_PREFERENCES_CLOCK';

export const LEFT_TIME_TIMER_PREFERENCES_CLOCK = 'LEFT_TIME_TIMER_PREFERENCES_CLOCK';

export const TOTAL_TIME_TIMER_PREFERENCES_CLOCK = 'TOTAL_TIME_TIMER_PREFERENCES_CLOCK';

export const PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK = 'PASSED_TIME_TIME_TIMER_PREFERENCES_CLOCK';

export const IS_FIRST_ENTER_PRESET_CITY_WORLD = 'IS_FIRST_ENTER_PRESET_CITY_WORLD';





