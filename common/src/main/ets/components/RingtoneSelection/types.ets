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

export interface RingtoneItem {
  id: number,
  name: string,
  path: string
}

export const DEFAULT_RINGTONE_ID = 8;

export const NONE_RINGTONE_ID = 0;

export const noneRingtone: RingtoneItem = {
  id: NONE_RINGTONE_ID,
  name: 'None',
  path: ''
}

export const ringtones: RingtoneItem[] = [
  {
    id: 1,
    name: 'Aegean Sea',
    path: '/sys_prod/resource/media/audio/alarms/Aegean_Sea.ogg'
  },
  {
    id: 2,
    name: 'Amazing Morning',
    path: '/sys_prod/resource/media/audio/alarms/Amazing_Morning.ogg'
  },
  {
    id: 3,
    name: 'Awakening',
    path: '/sys_prod/resource/media/audio/alarms/Awakening.ogg'
  },
  {
    id: 4,
    name: 'Creek',
    path: '/sys_prod/resource/media/audio/alarms/Creek.ogg'
  },
  {
    id: 5,
    name: 'Dawn',
    path: '/sys_prod/resource/media/audio/alarms/Dawn.ogg'
  },
  {
    id: 6,
    name: 'Flourish',
    path: '/sys_prod/resource/media/audio/alarms/Flourish.ogg'
  },
  {
    id: 7,
    name: 'Flow',
    path: '/sys_prod/resource/media/audio/alarms/Flow.ogg'
  },
  {
    id: 8,
    name: 'Forest Melody',
    path: '/sys_prod/resource/media/audio/alarms/Forest_Melody.ogg'
  },
  {
    id: 9,
    name: 'Hawaii',
    path: '/sys_prod/resource/media/audio/alarms/Hawaii.ogg'
  },
  {
    id: 10,
    name: 'Ingle',
    path: '/sys_prod/resource/media/audio/alarms/Ingle.ogg'
  },
  {
    id: 11,
    name: 'Moment',
    path: '/sys_prod/resource/media/audio/alarms/Moment.ogg'
  },
  {
    id: 12,
    name: 'Morning Light',
    path: '/sys_prod/resource/media/audio/alarms/Morning_Light.ogg'
  },
  {
    id: 13,
    name: 'Morning Mist',
    path: '/sys_prod/resource/media/audio/alarms/Morning_Mist.ogg'
  },
  {
    id: 14,
    name: 'New Day',
    path: '/sys_prod/resource/media/audio/alarms/New_Day.ogg'
  },
  {
    id: 15,
    name: 'Ocean Whisper',
    path: '/sys_prod/resource/media/audio/alarms/Ocean_Whisper.ogg'
  },
  {
    id: 16,
    name: 'Overture',
    path: '/sys_prod/resource/media/audio/alarms/Overture.ogg'
  },
  {
    id: 17,
    name: 'Rays',
    path: '/sys_prod/resource/media/audio/alarms/Rays.ogg'
  },
  {
    id: 18,
    name: 'Ripple',
    path: '/sys_prod/resource/media/audio/alarms/Ripple.ogg'
  },
  {
    id: 19,
    name: 'Sand Sea',
    path: '/sys_prod/resource/media/audio/alarms/Sand_Sea.ogg'
  },
  {
    id: 20,
    name: 'Shimmering',
    path: '/sys_prod/resource/media/audio/alarms/Shimmering.ogg'
  },
  {
    id: 21,
    name: 'Sound of the Sea',
    path: '/sys_prod/resource/media/audio/alarms/Sound of the Sea.ogg'
  },
  {
    id: 22,
    name: 'Star',
    path: '/sys_prod/resource/media/audio/alarms/Star.ogg'
  },
  {
    id: 23,
    name: 'Tap',
    path: '/sys_prod/resource/media/audio/alarms/Tap.ogg'
  },
  {
    id: 24,
    name: 'Timer Beep',
    path: '/sys_prod/resource/media/audio/alarms/Timer_Beep.ogg'
  },
  {
    id: 25,
    name: 'Wonderful Beginning',
    path: '/sys_prod/resource/media/audio/alarms/Wonderful_Beginning.ogg'
  },
  {
    id: 26,
    name: 'Xiaoyi',
    path: '/sys_prod/resource/media/audio/alarms/Xiaoyi.ogg'
  },
  noneRingtone
]

export const recommendedRingtones: number[] = [DEFAULT_RINGTONE_ID, 12, 15]