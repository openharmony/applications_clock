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

// 时段标签的资源ID列表，当前只有中文有时段区分，英文只区分 AM、PM
export const TIME_TAG_ID_LIST_IN_ZH = [
  $r('app.string.very_early_morning').id, // 凌晨 1 ~ 4 点，4 个小时，此列表一格占两个小时，"凌晨"重复两次
  $r('app.string.very_early_morning').id,
  $r('app.string.dawn').id, // 清晨 5 ~ 6 点
  $r('app.string.early_morning').id, // 早上 7 ~ 8 点
  $r('app.string.morning').id, // 上午 9 ~ 10 点
  $r('app.string.midday').id, // 中午 11 ~ 12 点
  $r('app.string.afternoon').id, // 下午 13 ~ 16 点，4 个小时，此列表一格占两个小时，"下午"重复两次
  $r('app.string.afternoon').id,
  $r('app.string.evening').id, // 傍晚 17 ~ 18 点
  $r('app.string.night').id, // 晚上 19 ~ 22 点，4 个小时，此列表一格占两个小时，"晚上"重复两次
  $r('app.string.night').id,
  $r('app.string.midnight').id, // 半夜，23点到0点
];

// 中文的语言编码
export const LANGUAGE_ZH = 'zh';

// 时间段描述分组大小，此处取值为2，表示 TIME_TAG_ID_LIST 列表中一个元素代表两个小时
export const TIME_TAG_GROUP_SIZE = 2;

// 时间段描述的下标偏移量，此处取值为1，则下标为 0 的时间段，对应的开始时间为 0 + 1 点
export const INDEX_OFFSET = 1;

// 最后一个时间段的资源 ID，用于对 0 点的特殊处理
export const LAST_TAG_ID = TIME_TAG_ID_LIST_IN_ZH[TIME_TAG_ID_LIST_IN_ZH.length - 1];

// Days of a week
export const DAYS_OF_WEEK_COUNT = 7;

// Number of working days of the week
export const DAYS_OF_WEEK_WORK_DAY_COUNT = 5;

// Friday index in daysOfWeek
export const INDEX_FRIDAY = 5;

// Number of days off in the week
export const DAYS_OF_WEEK_FREE_DAY_COUNT = 2;

// daysOfWeek数组内周六的索引
export const INDEX_SATURDAY = 6;

export const AFTERNOON_START_POINT = 12;

export const SINGLE_NUMBER_END_POINT = 10;

export const ONE_DAY = 1;

export const ONE_MINUTE = 1;

// 距离响铃时间少于一分钟的标记，用于前台展示时，读取不同的字符串资源
export const LESS_THAN_ONE_MINUTE_FLAG = 'LESS_THAN_ONE_MINUTE_FLAG';

export const NO_ALARM_ENABLED = 'NO_ALARM_ENABLED';

// 时间相关的资源ID列表，前台资源预加载时传入，预加载后即可在同步方法中获取相关字段
const timeDescStringIdList: number[] = [
  $r('app.string.only_ring_once').id,
  $r('app.string.every_day').id,
  $r('app.string.monday_to_friday').id,
  $r('app.string.default_alarm_label').id,
  $r('app.string.default_alarm_label_new').id,
]
for (let i = 0; i < TIME_TAG_ID_LIST_IN_ZH.length; ++i) {
  timeDescStringIdList.push(TIME_TAG_ID_LIST_IN_ZH[i])
}

export const TIME_DESC_STRING_ID_LIST = timeDescStringIdList

// 获取 “某个数字对应的是周几” 时，调用 JS 接口使用的格式（资料推荐使用 JS 接口查询，而不是提翻译）
export enum WeekDayFormat {
  Short = 'short', // 中文是周一、周二、周三等，英文是Mon、Tue、Web等，小语种按照业界通用方式翻译
  Long = 'long', // 中文是星期一、星期二、星期三等，英文是Monday、Tuesday、Wednesday等，小语种按照业界通用方式翻译
}

// 获取 “某个数字对应的是周几” 时，使用的基准时间（相关JS 接口，年、月传 0，日传入 daysOfWeek 中存放的数字，即可完成周几的本地化转换）
export const WEEK_DAY_BASIC_YEAR = 2023;

export const WEEK_DAY_BASIC_MONTH = 0;

// 填充 Date 对象入参的默认年、月、日，此处的年和月
export const DEFAULT_YEAR = 0;

export const DEFAULT_MONTH = 0;

export const DEFAULT_DAY = 0;

// 拆分12 小时制格式化时间各部分的正则表达式
export const HOUR_12_TIME_FORMAT_REG_EXP: RegExp = new RegExp('(\\D*)(\\d+)(.)(\\d+)(.*)');

// The regular expression for splitting each part of the 12-hour format time,
// for example:"zh: 9:30:00 a.m. en:9:30:00 AM."
export const HOUR_12_TIME_FORMAT_REG_EXP_WITH_SECOND: RegExp = new RegExp('(\\D*)(\\d+)(.)(\\d+)(.)(\\d+)(.*)');

// 格式化时间拆分后的下标
export enum TimeFormatIndex {

  LEFT_TAG = 1,
  HOUR = 2,
  MINUTE = 4,
  RIGHT_TAG = 5,
  RIGHT_TAG_WITH_SECOND = 7,
}

// 格式化时间返回的对象类型
export interface FormatTime {
  tag?: string, // 时间段标签，凌晨、清晨、早上等
  time: string, // 时间，用于前台展示，如 08:10
  isTagLeft?: boolean, // 时间段标签是否在左边
}

type DigitTimeFormat = '2-digit' | 'numeric';

// 数字时间格式 (个位数时，在前面填一个零)
export const DIGIT_TIME_FORMAT: DigitTimeFormat = '2-digit';

// 闹钟触发时，拉起的 ability 归属的包名
export const TIMER_ALERT_BUNDLE = 'com.ohos.clock';

// 闹钟触发时，拉起的 ability 的名称
export const TIMER_ALERT_ABILITY = 'com.ohos.clock.AlarmService';

// 定时器触发时，拉起的 ability 的名称
export const TIMER_TIMER_ABILITY = 'com.ohos.clock.TimerService';

export const FULL_SCREEN_ABILITY = 'com.ohos.clock.FullScreenAbility';

// Ability to pull up when full screen starts
export const FULL_SCREEN_ALARM_ABILITY = 'com.ohos.clock.ForegroundAbility';

// Name of the home page.
export const MAIN_ABILITY = 'com.ohos.clock.phone';

// want agent 的 request code
export const AGENT_REQUEST_CODE_NORMAL = 0;

export enum AlarmServiceType {
  Start = 'Start',
  Close = 'Close',
  ReStart = 'ReStart',
  Delay = 'Delay',
  Update = 'Update',
  ToggleFullScreen = 'ToggleFullScreen',
}

export enum TimerServiceType {
  Start = 'Start',
  Pause = 'Pause',
  Close = 'Close',
  Firing = 'Firing',
  ToggleFullScreen = 'ToggleFullScreen',
}

export enum FullScreenType {
  Timer = 'Timer',
  Alarm = 'Alarm',
}

export enum CalendarFiled {
  Hour_OF_Day = 'hour_of_day',
  Minute = 'minute',
  Second = 'second',
  Date = 'date',
  Year = 'year',
  Month = 'month',
}

export const WAKE_DAYS_TYPE = 4;

export const ONES_TYPE = 0;

export const MONTH_LIST = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

export const SATURDAY = 6;

export const SUNDAY = 0;

export const CACHE_HOLIDAYS_LIST = 'cache_holidays_list';

export interface HolidaysType {
  year: number,
  version: String,
  workday: number[],
  freeday: number[]
}

export interface NetHolidaysType {
  year: number,
  version: String,
  workday: number[],
  freeday: number[],
  allRecess: HolidaysType[]
}

export const TIMER_NOTICE_ID = '99999'

export const PRESET_CITY_BEIJING: string = 'Beijing';

export const PRESET_CITY_LONDON: string = 'London';

export const PRESET_CITY_PARIS: string = 'Paris';
