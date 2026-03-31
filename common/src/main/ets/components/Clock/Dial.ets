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

import { BLUR_VALUE, HALF_CIRCLE_ANGLE } from './types';

/**
 * Clock dial
 *
 * @since 2022-07-05
 */
@Component
struct Dial {
  @Prop private diameter: number = 0; // Dial diameter

  build() {
    Flex({ alignItems: ItemAlign.Center, alignContent: FlexAlign.Center }) {
      Column() {
        Column()
          .width(this.diameter)
          .height(this.diameter)
          .borderRadius(this.diameter)
          .linearGradient({
            angle: HALF_CIRCLE_ANGLE,
            direction: GradientDirection.Top,
            colors: [
              [$r('app.color.dial_top'), $r('app.float.dial_top_position')],
              [$r('app.color.dial_center'), $r('app.float.dial_center_position')],
              [$r('app.color.dial_bottom'), $r('app.float.dial_bottom_position')],
            ]
          })
          .shadow({
            radius: $r('app.float.dial_shadow_radius'),
            color: $r('app.color.dial_shadow_inside'),
            offsetX: $r('app.float.dial_shadow_inside_x'),
            offsetY: $r('app.float.dial_shadow_inside_y'),
          })
      }
      .width(this.diameter)
      .height(this.diameter)
      .borderRadius(this.diameter)
      .shadow({
        radius: $r('app.float.dial_shadow_radius'),
        color: $r('app.color.dial_shadow_outside'),
        offsetX: $r('app.float.dial_shadow_outside_x'),
        offsetY: $r('app.float.dial_shadow_outside_y'),
      })
    }
    .width(this.diameter + BLUR_VALUE) // Reserve space for the blurring effect of the dial
    .height(this.diameter + BLUR_VALUE)
    .borderRadius(this.diameter + BLUR_VALUE)
    .blur(BLUR_VALUE)
  }
}

export default Dial;
