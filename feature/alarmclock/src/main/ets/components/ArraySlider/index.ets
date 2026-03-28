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

import { MIN_INDEX_STEP, INDEX_STEP } from './types';

// The font style of the label of the slider bar
@Extend(Text)
function labelText() {
  .fontColor($r('sys.color.font_secondary'))
  .fontWeight(FontWeight.Regular)
}

/**
 * The slider which the to-be-selected values can be transferred through an array
 *
 * @since 2022-07-19
 */
@Component
export struct ArraySlider {
  private label: ResourceStr = '';
  private value: number = 0;
  private scales: number[] = [];
  private testKey: string = ''; // Key for unit testing
  private onChange?: (value: number) => void;

  /**
   * Description label of the slider bar
   */
  @Builder
  buildLabel() {
    Row() {
      Text(this.label).fontSize($r('app.float.slider_label_size')).labelText()
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .align(Alignment.Center)
  }

  /**
   * Builder of the slider bar
   */
  @Builder
  buildSlider() {
    Slider({
      value: this.scales.findIndex(step => step === this.value),
      min: MIN_INDEX_STEP,
      max: this.scales.length - INDEX_STEP,
      step: INDEX_STEP,
      style: SliderStyle.OutSet,
    })
      .key(this.testKey)
      .blockColor($r('sys.color.comp_background_primary_contrary'))
      .selectedColor($r('sys.color.comp_background_emphasize'))
      .onChange((index: number) => this.onChange!(this.scales[index.toFixed()]))
      .margin({
        top: $r('app.float.snooze_setting_margin_vertical_max'),
        bottom: $r('app.float.snooze_setting_margin_vertical_min'),
        left: $r('app.float.slider_margin_horizontal'),
      })
      .offset({ x: $r('app.float.slider_margin_offset_left') })
  }

  /**
   * Scales of the slider bar
   */
  @Builder
  buildScales() {
    Flex({ justifyContent: FlexAlign.SpaceBetween }) {
      ForEach(this.scales, (scale: number) => {
        Text(scale.toString()).fontSize($r('app.float.slider_step_label_size')).labelText()
      })
    }
  }

  build() {
    Column() {
      this.buildLabel()
      this.buildSlider()
      this.buildScales()
    }
  }
}