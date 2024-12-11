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

import inputConsumer from '@ohos.multimodalInput.inputConsumer'

type KeyOptions = inputConsumer.KeyOptions;

export const FULL_SCREEN_ALARM_PAGE = 'pages/FullScreenTimer';

export const BANNER_ALARM_PAGE = 'pages/BannerAlarm';

export const ALARM_WINDOW_TYPE = 2123;

export const ALARM_WINDOW_NAME = 'FullScreenTimerWindow';

export const BANNER_ALARM_WINDOW_NAME = 'BannerTimerWindow';

const KEYCODE_VOLUME_UP = 16;

const KEYCODE_VOLUME_DOWN = 17;

export const VOLUME_UP_KEY_OPTIONS: KeyOptions = {
  preKeys: [],
  finalKey: KEYCODE_VOLUME_UP,
  isFinalKeyDown: true,
  finalKeyDownDuration: 0,
};

// export const VOLUME_DOWN_KEY_OPTIONS: KeyOptions = {
//   preKeys: [],
//   finalKey: KEYCODE_VOLUME_DOWN,
//   isFinalKeyDown: true,
//   finalKeyDownDuration: 0,
// };

export const FD_PREFIX = 'fd://';

export const FILE_SEPARATOR = '/';

export const WRITE_MODE = 'w+';

export const RING_FILE_NAME = 'ring.wav';

export const READ_INTERVAL = 16;
