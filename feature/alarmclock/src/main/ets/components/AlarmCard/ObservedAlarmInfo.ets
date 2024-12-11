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

import { AlarmInfoToShow } from '@hmos/common';

/**
 * AlarmInfoToShow decorated with @Observed
 *
 * When the variable of the normal AlarmInfoToShow object changes, the subcomponent cannot be refreshed.
 * Object instantiated from this class can do so with the parameter of the subcomponent,
 * which is decorated with @ObjectLink.
 */
@Observed
export class ObservedAlarmInfo implements AlarmInfoToShow {
  public title: string;
  public time: string;
  public tag?: string;
  public isTagLeft?: boolean;
  public daysOfWeekDesc: string;
  public enabled: boolean;
  public id?: string;
  public reStart?: string;
  public hour: number;
  public minute: number;
  public second: number;
  public daysOfWeek: number[];
  public daysOfWakeType?: number;
  public alarmTime?: number;
  public ringDuration: number;
  public snoozeDuration: number;
  public snoozeTimes: number;
  public snoozeCount?: number;

  /**
   * Constructor
   *
   * @param alarmInfoToShow The normal AlarmInfoToShow object
   */
  constructor(alarmInfoToShow: AlarmInfoToShow) {
    this.title = alarmInfoToShow.title!;
    this.second = alarmInfoToShow.second!;
    this.time = alarmInfoToShow.time!;
    this.tag = alarmInfoToShow.tag;
    this.isTagLeft = alarmInfoToShow.isTagLeft;
    this.daysOfWeekDesc = alarmInfoToShow.daysOfWeekDesc!;
    this.enabled = alarmInfoToShow.enabled!;
    this.id = alarmInfoToShow.id;
    this.hour = alarmInfoToShow.hour!;
    this.minute = alarmInfoToShow.minute!;
    this.daysOfWeek = alarmInfoToShow.daysOfWeek!;
    this.daysOfWakeType = alarmInfoToShow.daysOfWakeType || 0;
    this.alarmTime = alarmInfoToShow.alarmTime;
    this.ringDuration = alarmInfoToShow.ringDuration!;
    this.snoozeDuration = alarmInfoToShow.snoozeDuration!;
    this.snoozeTimes = alarmInfoToShow.snoozeTimes!;
    this.snoozeCount = alarmInfoToShow.snoozeCount;
    this.reStart = alarmInfoToShow.reStart;
  }
}