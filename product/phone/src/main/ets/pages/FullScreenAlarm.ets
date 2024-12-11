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

import { FullScreenAlarm } from '@hmos/alarmclock';
import { LogUtil, EVENT_ID_FULL_SCREEN_ALARM } from '@hmos/common';
import emitter from '@ohos.events.emitter';

const TAG = 'FullScreenAlarmPage';

/**
 * Full Screen Alarm Page
 *
 * @since 2022-08-18
 */
@Entry
@Component
struct FullScreenAlarmPage {
  @State isBackImageShown: boolean = false;

  onBackPress() {
    emitter.emit({ eventId: EVENT_ID_FULL_SCREEN_ALARM });
    LogUtil.info(TAG, 'onBackPress');
    return false;
  }

  build() {
    Column() {
      FullScreenAlarm({ isBackImageShown: $isBackImageShown });
    }
    .visibility(this.isBackImageShown ? Visibility.Visible : Visibility.Hidden)
  }
}