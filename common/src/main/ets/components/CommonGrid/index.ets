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

import { BreakPoint } from '../../manager';
import { COMMON_GRID_COL_OPTIONS, LG_8_GRID_COL_OPTIONS } from './types';

@Builder
function dummyFunction() {
};

/**
 * Common Grid Component
 *
 * @since 2023-01-10
 */
@Component
export struct CommonGrid {
  @StorageProp('currentBreakpoint') @Watch('updateMargin') currentBreakpoint: string = '';
  @BuilderParam content: () => void = dummyFunction;
  @State gridMargin: Resource = this.currentBreakpoint === BreakPoint.LG ? $r('app.float.common_grid_margin') : $r('app.float.common_grid_margin_zero');
  @Prop lg8: boolean = false;

  private updateMargin(): void {
    this.gridMargin = this.currentBreakpoint === BreakPoint.LG ? $r('app.float.common_grid_margin') : $r('app.float.common_grid_margin_zero');
  }

  build() {
    GridRow() {
      GridCol(this.lg8 ? LG_8_GRID_COL_OPTIONS : COMMON_GRID_COL_OPTIONS) {
        this.content()
      }
    }
    .id('id_common_grid')
    .margin({
      left: this.gridMargin,
      right: this.gridMargin,
    })
  }
}