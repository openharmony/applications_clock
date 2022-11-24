/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http:// www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { ConfigData } from '@ohos/common';

const DOUBLE: number = 2;
const TIME_DECIMAL: number = 60;
const MS_DECIMAL: number = 1000;
const FLAG_BIT: number = 5;

@Component
export struct TimerView {
  @Prop currentTime: number;
  private sSize: number = vp2px(ConfigData.STANDARD_SIZE);
  private mSize: number = 0;
  private dialsContext: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true });
  private secondContext: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true });
  private minutesContext: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true });
  // Second disc radius
  private sRadius: number = 0;
  // Points set radius
  private mRadius: number = 0;
  // scale
  private mScale: number = 1;
  // Second hand time scale value
  private times: Array<number> = [60, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
  // Minute hand time scale value
  private minTimes: Array<number> = [30, 5, 10, 15, 20, 25];

  aboutToAppear() {
    this.mScale = this.sSize / ConfigData.STANDARD_SIZE;
    this.mSize = this.sSize / DOUBLE / DOUBLE;
    // Get the radius
    this.sRadius = this.sSize / DOUBLE - ConfigData.SECOND_DISTANCE * this.mScale;
    this.mRadius = this.mSize / DOUBLE - ConfigData.MINUTE_DISTANCE * this.mScale;
  }

  build() {
    Row() {
      Stack() {
        Canvas(this.dialsContext)
          .height(this.sSize)
          .aspectRatio(1.0)
          .onReady(() => {
            this.drawDials();
          })
          .backgroundColor($r('app.color.background_color_white'))
          .borderRadius(this.sSize / DOUBLE)
          .shadow({ radius: ConfigData.SHADOW_RADIUS * this.mScale, color: $r('app.color.shadow_color') });
        Canvas(this.minutesContext)
          .height(this.sSize)
          .aspectRatio(1.0)
          .onReady(() => {
            this.drawMinutes(this.currentTime % (TIME_DECIMAL * TIME_DECIMAL * MS_DECIMAL) / (TIME_DECIMAL * MS_DECIMAL));
          });
        Canvas(this.secondContext)
          .height(this.sSize)
          .aspectRatio(1.0)
          .onReady(() => {
            this.drawSecond(this.currentTime % (TIME_DECIMAL * MS_DECIMAL) / MS_DECIMAL);
          });
      }
    }
    .justifyContent(FlexAlign.Center)
    .width(ConfigData.WH_100_100)
  }

  /**
   * Draw a Second hand
   *
   * @param second
   */
  private drawSecond(second: number): void {
    this.secondContext.clearRect(0, 0, this.sSize, this.sSize);
    this.secondContext.lineCap = 'round';
    this.secondContext.save();
    this.secondContext.strokeStyle = ConfigData.SECOND_HAND_COLOR;
    // Pointer Angle The second hand is divided into 60 parts
    let theta = second * DOUBLE * Math.PI / TIME_DECIMAL;
    this.secondContext.beginPath();
    // A pointer to draw
    let x_move = this.sRadius * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
    let y_move = -this.sRadius * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;
    let x_to = -(ConfigData.SECOND_POINTER_OVER * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
    let y_to = (ConfigData.SECOND_POINTER_OVER * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;

    this.secondContext.lineWidth = ConfigData.SECOND_HAND_WIDTH * this.mScale;
    this.secondContext.moveTo(x_move, y_move);
    this.secondContext.lineTo(x_to, y_to);
    this.secondContext.stroke();
    this.secondContext.restore();
  }

  /**
   * Draw a minute hand
   *
   * @param minutes
   */
  private drawMinutes(minutes: number): void {
    this.minutesContext.clearRect(0, 0, this.sSize, this.sSize);
    this.minutesContext.lineCap = 'round';
    this.minutesContext.save();
    // Pointer Angle The minute hand is divided into 30 parts
    let theta = minutes * DOUBLE * Math.PI / (TIME_DECIMAL / DOUBLE);
    this.minutesContext.beginPath();
    // Start position of scale
    let x_move = (this.mRadius - ConfigData.MINUTE_POINTER_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
    let y_move = -(this.mRadius - ConfigData.MINUTE_POINTER_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y;
    // End of scale position
    let x_to = (ConfigData.MINUTE_CIRCLE_WIDTH * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
    let y_to = (-ConfigData.MINUTE_CIRCLE_WIDTH * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y;
    this.minutesContext.lineWidth = ConfigData.MINUTE_TICK_MARK_WIDTH * this.mScale;
    this.minutesContext.moveTo(x_move, y_move);
    this.minutesContext.lineTo(x_to, y_to);
    this.minutesContext.stroke();
    this.minutesContext.restore();
  }

  private drawDials() {
    this.dialsContext.clearRect(0, 0, this.sSize, this.sSize);
    this.drawSecDials();
    this.drawMinDials();
  }

  /**
   * Draw the second hand disc
   */
  private drawSecDials(): void {
    this.dialsContext.lineCap = 'round';
    // Draw the origin
    this.dialsContext.save();
    this.dialsContext.fillStyle = ConfigData.SECOND_HAND_COLOR;
    this.dialsContext.beginPath();

    this.dialsContext.arc(this.sSize * ConfigData.DIALS_CENTER_OFFSET_X, this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y, ConfigData.SECOND_CIRCLE_WIDTH * this.mScale, 0, Math.PI * DOUBLE);
    this.dialsContext.fill();
    this.dialsContext.restore();
    this.dialsContext.strokeStyle = ConfigData.TICK_MARK_COLOR;
    // Font style
    this.dialsContext.font = 'normal 500 ' + vp2px(ConfigData.SECOND_FONT_SIZE * this.mScale) + 'px';
    this.dialsContext.textBaseline = 'middle';
    this.dialsContext.textAlign = 'center';
    // Drawing scale
    for (let n = 0; n < TIME_DECIMAL; n++) {
      // Gets an Angle of 60 scales
      let theta = n * (Math.PI * DOUBLE) / TIME_DECIMAL;
      this.dialsContext.save();
      // Setting the scale width
      this.dialsContext.lineWidth = ConfigData.TICK_MARK_WIDTH * this.mScale;
      this.dialsContext.beginPath();
      // Start position of scale
      let x_move = this.sRadius * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
      let y_move = -this.sRadius * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;
      // End position of non - hour scale
      let x_to = (this.sRadius - ConfigData.SECOND_TICK_MARK_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
      let y_to = -(this.sRadius - ConfigData.SECOND_TICK_MARK_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;
      // Integral point calibration
      if (n % FLAG_BIT == 0) {
        // The scale width of the hour
        this.dialsContext.lineWidth = ConfigData.HOUR_TICK_MARK_WIDTH * this.mScale;
        // End position of the mark on the hour
        x_to = (this.sRadius - ConfigData.HOUR_SECOND_TICK_MARK_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
        y_to = -(this.sRadius - ConfigData.HOUR_SECOND_TICK_MARK_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;
        // Time position on the hour
        let x_time = (this.sRadius - ConfigData.HOUR_SECOND_TIMER_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
        let y_time = -(this.sRadius - ConfigData.HOUR_SECOND_TIMER_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.SECOND_DIALS_CENTER_OFFSET_Y;
        // Plot the hour
        this.dialsContext.fillText(this.times[n / FLAG_BIT] + '', x_time, y_time);
      }
      // Draw the scale
      this.dialsContext.moveTo(x_move, y_move);
      this.dialsContext.lineTo(x_to, y_to);
      this.dialsContext.stroke();
      this.dialsContext.restore();
    }
  }

  /**
   * Draw the minute hand dial
   */
  private drawMinDials(): void {
    // Draw the origin
    this.dialsContext.save();
    this.dialsContext.beginPath();
    this.dialsContext.arc(this.sSize * ConfigData.DIALS_CENTER_OFFSET_X, this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y, ConfigData.MINUTE_CIRCLE_WIDTH * this.mScale, 0, Math.PI * DOUBLE);
    this.dialsContext.fill();
    this.dialsContext.fillStyle = ConfigData.CIRCLE_WIDTH_COLOR;
    this.dialsContext.beginPath();
    this.dialsContext.arc(this.sSize * ConfigData.DIALS_CENTER_OFFSET_X, this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y, ConfigData.MINUTE_CENTER_CIRCLE_WIDTH * this.mScale, 0, Math.PI * DOUBLE);
    this.dialsContext.fill();
    this.dialsContext.restore();
    // Font style
    this.dialsContext.font = 'normal 400 ' + vp2px(ConfigData.MINUTE_FONT_SIZE * this.mScale) + 'px';
    // Drawing scale
    for (let n = 0; n < (TIME_DECIMAL / DOUBLE); n++) {
      this.dialsContext.strokeStyle = ConfigData.TICK_MARK_COLOR;
      let theta = n * (Math.PI * DOUBLE) / (TIME_DECIMAL / DOUBLE);
      this.dialsContext.save();
      // Scale width
      this.dialsContext.lineWidth = ConfigData.TICK_MARK_WIDTH * this.mScale;
      this.dialsContext.beginPath();
      // Start position of scale
      let x_move = this.mRadius * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
      let y_move = -this.mRadius * Math.cos(theta) + this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y;
      // End of scale position
      let x_to = (this.mRadius - ConfigData.MINUTE_TICK_MARK_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
      let y_to = -(this.mRadius - ConfigData.MINUTE_TICK_MARK_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y;
      // Integral point calibration
      if (n % FLAG_BIT == 0) {
        this.dialsContext.strokeStyle = ConfigData.HOUR_TICK_MARK_COLOR;
        // Time position on the hour
        let x_time = (this.mRadius - ConfigData.HOUR_MINUTE_TIMER_DISTANCE * this.mScale) * Math.sin(theta) + this.sSize * ConfigData.DIALS_CENTER_OFFSET_X;
        let y_time = -(this.mRadius - ConfigData.HOUR_MINUTE_TIMER_DISTANCE * this.mScale) * Math.cos(theta) + this.sSize * ConfigData.MINUTE_DIALS_CENTER_OFFSET_Y;
        // Plot the hour
        this.dialsContext.fillText(this.minTimes[n / FLAG_BIT] + '', x_time, y_time);
      }
      // Draw the scale
      this.dialsContext.moveTo(x_move, y_move);
      this.dialsContext.lineTo(x_to, y_to);
      this.dialsContext.stroke();
      this.dialsContext.restore();
    }
  }
}
