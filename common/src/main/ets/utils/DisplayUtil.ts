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

const BASE_DPI = 160;

/**
 * Display Util
 *
 * @since 2023-01-10
 */
export class DisplayUtil {
  /**
   * Convert the value in unit of vp to px.
   *
   * The api named 'vp2px' provided by the framework cannot be used in the TS file, so we need this function.
   * The function is applicable only to TS file.
   * For UI components or pages, use vp2px provided by the framework.
   *
   * @param vpValue Value in the unit of vp
   * @param deviceDpi DPI of the device, which can be obtained from the display object.
   * @return vpValue Value in the unit of px
   */
  static vp2pxInTs(vpValue: number, deviceDpi: number): number {
    return vpValue * deviceDpi / BASE_DPI;
  }
}