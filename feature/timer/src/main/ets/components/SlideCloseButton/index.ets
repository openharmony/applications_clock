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

import {
  LogUtil,
  AlarmInfo,
  WantAgentUtil,
  EventReportUtil,
  EventName,
  EventResult,
  TIMEOUT_FULL_SCREEN_CLOSE_ID,
  CommonUtil
} from '@hmos/common';
// import hiSysEvent from '@ohos.hiSysEvent';
import emitter from '@ohos.events.emitter';

const FIRST_FINGER = 0;
const TAG = 'SlideCloseButton';
const MOVE_SCALE = 1;

/**
 * Button for sliding to turn off
 *
 * @since 2022-08-18
 */
@Component
export default struct SlideCloseButton {
  private alarmInfo?: AlarmInfo;
  private preX: number = 0;
  private preY: number = 0;
  private curX: number = 0;
  private curY: number = 0;
  private startX: number = 0;
  private startY: number = 0;
  private isMoved: boolean = false;
  @State positionX: number = 0;

  private updateActionMove(event: TouchEvent): void {
    this.curX = event.touches[FIRST_FINGER].windowX;
    this.curY = event.touches[FIRST_FINGER].windowY;
    LogUtil.info(TAG, 'curX: ' + this.curX, 'curY: ' + this.curY);

    if (Math.abs(this.curX - this.startX) <= Math.abs(this.curY - this.startY)) {
      // Move in Y-direction, no response.
      LogUtil.info(TAG, 'move Y direction=' + Math.abs(this.curY - this.startY));
      this.isMoved = false;
    } else {
      // Move in X-direction, make the button move.
      LogUtil.info(TAG, 'move X direction=' + Math.abs(this.curX - this.startX));
      if (Math.abs(this.curX - this.startX) >= 100) {
        this.isMoved = true;
      }
    }
    this.positionX += (this.curX - this.preX) * MOVE_SCALE;

    // Record the previous coordinate
    this.preX = this.curX;
    this.preY = this.curY;
  }

  private async onSlideButton(event: TouchEvent): Promise<void> {
    switch (event.type) {
      case TouchType.Down: {
        LogUtil.info(TAG, 'touch down');
        this.startX = event.touches[FIRST_FINGER].screenX;
        this.startY = event.touches[FIRST_FINGER].screenY;
        LogUtil.info(TAG, 'startX: ' + this.startX, 'startY: ' + this.startY);
        this.preX = this.startX;
        this.preY = this.startY;
        break;
      }
      case TouchType.Up: {
        LogUtil.info(TAG, 'touch up');
        if (this.isMoved) {
          // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.LOCK_SCREEN_SWIPE_CLOSE_ALARM);
          emitter.emit({ eventId: TIMEOUT_FULL_SCREEN_CLOSE_ID, priority: emitter.EventPriority.IMMEDIATE });
          CommonUtil.terminateFullScreenAbility();
        } else {
          this.positionX = 0;
        }
        break;
      }
      case TouchType.Move: {
        LogUtil.info(TAG, 'touch move');
        this.updateActionMove(event);
        break;
      }
      case TouchType.Cancel: {
        LogUtil.info(TAG, 'touch cancel');
        break;
      }
      default: {
        LogUtil.info(TAG, 'default');
        break;
      }
    }
  }

  build() {
    Column()
      .borderWidth($r('app.float.slide_to_turn_off_button_border_width'))
      .borderColor(Color.White)
      .borderRadius($r('app.float.slide_to_turn_off_button_size'))
      .width($r('app.float.slide_to_turn_off_button_size'))
      .height($r('app.float.slide_to_turn_off_button_size'))
      .offset({ x: this.positionX, y: 0 })
      .onTouch((event?: TouchEvent) => this.onSlideButton(event as TouchEvent));
  }
}