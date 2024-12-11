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

/**
 * 日志时分秒数据对象
 */

export default class DateObject {
  public hours: string;
  public minute: string;
  public seconds: string;
  public millisecond: string;

  constructor(hours: string, minute: string, seconds: string, millisecond: string) {
    this.hours = hours;
    this.minute = minute;
    this.seconds = seconds;
    this.millisecond = millisecond;
  }
}