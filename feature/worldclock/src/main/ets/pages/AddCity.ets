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

import { LogUtil } from '@hmos/common';

const TAG = 'AddCity';
const SETTINGS_BUNDLE_NAME = 'com.ohos.settings';
const SETTINGS_ABILITY_NAME = 'TimeZoneAbility';
const topMargin: number = 30;

/**
 * Page: Add world city
 *
 * @since 2023-01-06
 */
@Component
export struct AddCity {
  build() {
    Row() {
      Column() {
        // AbilityComponent({
        //   want: {
        //     bundleName: SETTINGS_BUNDLE_NAME,
        //     abilityName: SETTINGS_ABILITY_NAME,
        //   },
        // })
        //   .onConnect(() => {
        //     LogUtil.info(TAG, 'AbilityComponent connect');
        //   })
        //   .onDisconnect(() => {
        //     LogUtil.info(TAG, 'AbilityComponent disconnect');
        //   })
      }
      .width('100%')
    }
    .height('100%')
  }
}
