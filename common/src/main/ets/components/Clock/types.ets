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

export const HALF = 0.5;

export const TWICE = 2;

export const FULL_CIRCLE_ANGLE = 360;

export const HALF_CIRCLE_ANGLE = 180;

// 粗刻度尺寸
export const SCALE_UNIT_BOLD_WIDTH = 4;

export const SCALE_UNIT_BOLD_HEIGHT = 6.8;

export const SCALE_UNIT_BOLD_RADIUS = 2;

// 细刻度尺寸
export const SCALE_UNIT_WIDTH = 2;

export const SCALE_UNIT_HEIGHT = 6.8;

export const SCALE_UNIT_RADIUS = 2;

// 刻度数量
export const SCALE_COUNT = 60;

export const SCALE_COUNT_BOLD = 12;

// 粗刻度线文本的偏移量
export const SCALE_TEXT_OFFSET = -7;

// 细刻度线隐藏的周期（和粗刻度线重合的周期）
export const SCALE_HIDE_CYCLE = 5;

export const SCALE_COLOR_BOLD = [
  [$r('app.color.scale_bold_top'), $r('app.float.scale_top_position')],
  [$r('app.color.scale_bold_center'), $r('app.float.scale_center_position')],
  [$r('app.color.scale_bold_bottom'), $r('app.float.scale_bottom_position')],
];

export const SCALE_COLOR = [
  [$r('app.color.scale_top'), $r('app.float.scale_top_position')],
  [$r('app.color.scale_bottom'), $r('app.float.scale_bottom_position')],
];

export const TEXT_CLOCK_FORMAT_24H = 'HHmmss';

export const SECOND_ANGLE_STEP = 6;

export const ADD_MINUTE_ANGLE = 4;

export const MINUS_HOUR_ANGLE = 2;

export const CONST_POINTER = 24;

export const MINUTE_ANGLE_STEP = 6;

export const HOUR_ANGLE_STEP = 30;

export const HOUR_HAND_REFRESH_FREQUENCY = 12;

export const ACCURACY_ASSURANCE = 10;

export const HOUR_HAND_ROTATION_ANGEL_IN_TEN_MINUTES = 5;

export const HOUR_HAND_ROTATION_ANGEL_IN_120_SECONDS = 1;

// 刻度圆环直径占比
export const SCALE_DIAMETER_RATIO = 0.85;

export const DIAL_DIAMETER_RATIO = 1.58;

export const BLUR_VALUE = 4;

// 细刻度线、粗刻度线的角度列表，用于 build 方法中循环渲染刻度
const SCALE_ANGLES: number[] = [];
const SCALE_ANGLES_BOLD: number[] = [];
for (let angle = HOUR_ANGLE_STEP; angle <= FULL_CIRCLE_ANGLE; angle += HOUR_ANGLE_STEP) {
  // 为了方便 '小时' 的刻度文字和便宜角度对齐，'小时' 的偏移角度从1点钟方向开始
  SCALE_ANGLES_BOLD.push(angle);
}
for (let angle = 0; angle < FULL_CIRCLE_ANGLE; angle += SECOND_ANGLE_STEP) {
  SCALE_ANGLES.push(angle);
}

export { SCALE_ANGLES, SCALE_ANGLES_BOLD };

export interface SizeInfo {
  width: number;
  height: number;
}

export const CLOCK_RATIO_FOR_NORMAL = 0.70;

export const CLOCK_RATIO_FOR_LG = 0.60;

export const UPDATE_WIDTH_DELAY = 50;

export const ROTATION_CENTER = 1;

export const CLOCK_SCALE_VALUE = 0.9;

export const CLOCK_SCALE_DURATION_INCOMING = 300;

export const CLOCK_SCALE_DURATION_OUTGOING = 250;

export const CLOCK_SCALE_DELAY = 150;