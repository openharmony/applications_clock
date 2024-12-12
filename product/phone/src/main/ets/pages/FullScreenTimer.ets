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

import { FullScreenTimer } from '@hmos/timer';
import { EVENT_ID_TIMER_FULL_SCREEN_CLOSE, LogUtil, } from '@hmos/common';
import emitter from '@ohos.events.emitter';

const TAG = 'FullScreenTimerPage';

/**
 * Full Screen Alarm Page
 *
 * @since 2022-08-18
 */
@Entry
@Component
struct FullScreenTimerPage {
  @State isBackImageShown: boolean = false;
  @State timeoutDuration: number = 0;

  onBackPress() {
    LogUtil.info(TAG, `onBackPress`)
    emitter.emit({
      eventId: EVENT_ID_TIMER_FULL_SCREEN_CLOSE, priority: emitter.EventPriority.IMMEDIATE
    });
    return false;
  }

  build() {
    Column() {
      FullScreenTimer({ isBackImageShown: $isBackImageShown, timeoutDuration: $timeoutDuration });
    }
    .visibility(this.isBackImageShown ? Visibility.Visible : Visibility.Hidden)
  }
}