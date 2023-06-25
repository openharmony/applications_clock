/**
 * Copyright (c) 2022 HiHope Open Source Organization.
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

class ConfigData {
  ONE_SECOND_TIME = 1000;
  ONE_MINUTE_TIME = 60000;
  ONE_HOUR_TIME = 3600000;
  ONE_DAY_TIME = 86400000;
  SCALE_NUM = 120;
  COLOR_R = 98;
  COLOR_G_START = 175;
  COLOR_G_END = 125;
  COLOR_B = 255;
  HOUR_SELECT = 100;
  MINUTE_SELECT = 60;
  SECOND_SELECT = 60;
  NOTIFY_INTERVAL_MS = 50;
  STANDARD_SIZE = 280;
  DIALS_CENTER_OFFSET_X = 1 / 2;
  MINUTE_DIALS_CENTER_OFFSET_Y = 5 / 16;
  SECOND_DIALS_CENTER_OFFSET_Y = 1 / 2;
  SHADOW_RADIUS = 20;
  CIRCLE_WIDTH_COLOR = '#FFFFFF';
  SECOND_HAND_COLOR = '#007DFF';
  TICK_MARK_COLOR = '#66182431';
  HOUR_TICK_MARK_COLOR = '#22182431';
  TICK_MARK_WIDTH = 2;
  HOUR_TICK_MARK_WIDTH = 4;
  SECOND_DISTANCE = 5;
  SECOND_POINTER_OVER = 12;
  SECOND_CIRCLE_WIDTH = 6;
  SECOND_FONT_SIZE = 16;
  SECOND_HAND_WIDTH = 2;
  SECOND_TICK_MARK_DISTANCE = 12;
  HOUR_SECOND_TICK_MARK_DISTANCE = 16;
  HOUR_SECOND_TIMER_DISTANCE = 28;
  MINUTE_DISTANCE = 1;
  MINUTE_TICK_MARK_WIDTH = 1.5;
  MINUTE_TICK_MARK_DISTANCE = 6;
  MINUTE_POINTER_DISTANCE = 20;
  MINUTE_CIRCLE_WIDTH = 4;
  MINUTE_CENTER_CIRCLE_WIDTH = 2.5;
  MINUTE_FONT_SIZE = 12;
  HOUR_MINUTE_TIMER_DISTANCE = 14;
  WH_100_100 = '100%';
  WH_33_100 = '33%';
}

let configData = new ConfigData();

export default configData as ConfigData;