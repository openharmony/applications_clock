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

import {
  HALF,
  TWICE,
  SCALE_UNIT_WIDTH,
  SCALE_UNIT_BOLD_WIDTH,
  SCALE_UNIT_HEIGHT,
  SCALE_UNIT_BOLD_HEIGHT,
  SCALE_UNIT_RADIUS,
  SCALE_UNIT_BOLD_RADIUS,
  HALF_CIRCLE_ANGLE,
  FULL_CIRCLE_ANGLE,
  SCALE_COLOR,
  SCALE_COLOR_BOLD,
  SCALE_ANGLES,
  SCALE_ANGLES_BOLD,
  SCALE_HIDE_CYCLE,
  ROTATION_CENTER,
} from './types';

/**
 * Clock scale
 *
 * @since 2022-07-05
 */
@Component
struct Scale {
  @Prop @Watch('updateOffset') diameter: number = 0;
  // Offset that adjusts the scale to the edge of the scale ring
  @State scaleUnitBoldOffset: number = 0;
  @State scaleUnitOffset: number = 0;
  // Offset that adjusts the scale text next to the scale
  @State scaleTextOffset: number = 0;

  aboutToAppear() {
    this.updateOffset();
  }

  private updateOffset(): void {
    this.scaleUnitBoldOffset = (this.diameter - SCALE_UNIT_BOLD_WIDTH) * HALF;
    this.scaleUnitOffset = (this.diameter - SCALE_UNIT_WIDTH) * HALF;
    this.scaleTextOffset = -this.diameter * HALF + SCALE_UNIT_BOLD_HEIGHT * TWICE;
  }

  private getScaleUnit(isBold: boolean): RectAttribute {
    const sliceShape: RectAttribute = new Rect({
      width: isBold ? SCALE_UNIT_BOLD_WIDTH : SCALE_UNIT_WIDTH,
      height: isBold ? SCALE_UNIT_BOLD_HEIGHT : SCALE_UNIT_HEIGHT,
      radius: isBold ? SCALE_UNIT_BOLD_RADIUS : SCALE_UNIT_RADIUS
    });
    return sliceShape.offset({ x: isBold ? this.scaleUnitBoldOffset : this.scaleUnitOffset, y: 0 });
  }

  @Builder
  buildScaleUnit(angle: number, isBold: boolean, scaleText: string) {
    Stack() {
      Column()
        .width(this.diameter)
        .height(this.diameter)
        .borderRadius(this.diameter)
        .linearGradient({
          angle: HALF_CIRCLE_ANGLE - angle,
          direction: GradientDirection.Bottom,
          colors: isBold ? SCALE_COLOR_BOLD : SCALE_COLOR
        })
        .clip(this.getScaleUnit(isBold)) // Use the shape of the pointer to clip the background color.
      if (isBold) {
        Text(scaleText)
          .offset({ x: 0, y: -this.diameter * HALF + SCALE_UNIT_BOLD_HEIGHT * TWICE })
          .rotate({ z: 1, angle: FULL_CIRCLE_ANGLE - angle })
          .fontColor($r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_L'))
          .fontWeight(FontWeight.Medium)
      }
    }
    .rotate({ z: ROTATION_CENTER, angle })
  }

  @Builder
  buildScale(isBold: boolean) {
    ForEach(isBold ? SCALE_ANGLES_BOLD : SCALE_ANGLES, (angle: number, index: number | undefined) => {
      if (index && (isBold || index % SCALE_HIDE_CYCLE !== 0)) {
        // When there is a bold scale unit, the thin scale unit will not be rendered.
        this.buildScaleUnit(angle, isBold, `${index + 1}`)
      }
    })
  }

  build() {
    Stack() {
      this.buildScale(true)
      this.buildScale(false)
    }
  }
}

export default Scale;
