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

import { Card } from '../Card';
import {
  DEFAULT_RINGTONE_ID,
  NONE_RINGTONE_ID,
  noneRingtone,
  recommendedRingtones,
  RingtoneItem,
  ringtones
} from './types';
import { ALARM_LAST_SELECTED_RING, APP_CONFIG, ResourceAudioManager, TIMER_SELECTED_RING } from '../../manager';
import preferencesUtil from '@ohos.data.preferences';
import { RingtoneSelectionUtil } from '../../utils/RingtoneSelectionUtil';
import { GlobalContext } from '../../utils'

const TAG = 'RingtoneSelection';

interface PageProps {
  isTimerRingtone: boolean,
  onRingtoneSelected: (path: string) => void,
  selectedPath?: string
}

/**
 * Ringtone Selection page
 *
 * @since 2022-04-10
 */
@Component
export struct RingtoneSelection {
  @Prop pageProps: PageProps = {
    isTimerRingtone: true,
    onRingtoneSelected: (path: string) => '',
    selectedPath: ''
  }
  @State selectedRingtone: RingtoneItem = RingtoneSelectionUtil.getDefaultRingtone();

  async aboutToAppear() {
    this.selectedRingtone = await (this.pageProps.isTimerRingtone ? RingtoneSelectionUtil.getTimerRingtone() :
      this.pageProps.selectedPath ? RingtoneSelectionUtil.getRingtoneByPath(this.pageProps.selectedPath) :
      RingtoneSelectionUtil.getAlarmRingtone());
  }

  async aboutToDisappear() {
    this.pageProps.onRingtoneSelected(this.selectedRingtone.path);
    ResourceAudioManager.stopPlayerFor(this.selectedRingtone.path);
  }

  async onRingtoneSelected(ringtone: RingtoneItem) {
    await ResourceAudioManager.stopPlayerFor(this.selectedRingtone.path);
    const preferences = await preferencesUtil.getPreferences(GlobalContext.getContext()
      .getObject('clockContext') as Context, APP_CONFIG);
    await preferences.put(this.pageProps.isTimerRingtone ? TIMER_SELECTED_RING :
      ALARM_LAST_SELECTED_RING, ringtone.path);
    await preferences.flush();
    this.selectedRingtone = ringtone;
    if (ringtone.path) {
      ResourceAudioManager.playFromFileOnce(ringtone.path);
    }
  }

  @Builder
  buildRingtoneItem(item: RingtoneItem, isDefault?: boolean) {
    Stack({ alignContent: Alignment.Center }) {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Text(item.name + (!this.pageProps.isTimerRingtone && item.id == DEFAULT_RINGTONE_ID ? ' (Default)' : ''))
        Radio({ value: item.name, group: isDefault ? 'default_' : '' + 'ringtones' })
          .height($r('app.float.radio_size'))
          .width($r('app.float.radio_size'))
          .padding(0)
          .checked(this.selectedRingtone && this.selectedRingtone.id == item.id)
      }
      .padding({
        top: $r('app.float.card_inner_padding_horizontal'),
        bottom: $r('app.float.card_inner_padding_horizontal'),
        right: $r('app.float.card_inner_padding_horizontal'),
        left: $r('app.float.card_inner_padding_horizontal'),
      })

      Flex()
        .width('100%')
        .height('100%')
        .onClick(async () => await this.onRingtoneSelected(item))
    }
    .height($r('app.float.ringtone_selection_item_height'))
  }

  @Builder
  buildAlarmSounds() {
    Column() {
      Text('Recommended Ringtones')
        .textCase(TextCase.UpperCase)
        .textAlign(TextAlign.Start)
        .fontSize($r('app.float.ringtone_selection_section_header_size'))
        .margin({
          top: $r('app.float.ringtone_selection_section_header_margin_vertical'),
          bottom: $r('app.float.ringtone_selection_section_header_margin_vertical')
        })
        .padding({
          left: $r('app.float.ringtone_selection_section_header_margin_horizontal'),
          right: $r('app.float.ringtone_selection_section_header_margin_horizontal')
        })
        .width('100%')
      Card({ isMultipleSubItems: true }) {
        ForEach(ringtones.filter((r => recommendedRingtones.some(rr => rr == r.id))),
          (item: RingtoneItem, index: number) => {
            Column() {
              if (index) {
                Divider().color($r('sys.color.comp_divider'))
              }
              this.buildRingtoneItem(item, true)
            }
            .justifyContent(FlexAlign.Center)
            .borderRadius($r('app.float.default_corner_radius_l'))
          })
      }

      Text('Classic Ringtones')
        .textCase(TextCase.UpperCase)
        .textAlign(TextAlign.Start)
        .fontSize($r('app.float.ringtone_selection_section_header_size'))
        .margin({
          top: $r('app.float.ringtone_selection_section_header_margin_vertical'),
          bottom: $r('app.float.ringtone_selection_section_header_margin_vertical')
        })
        .padding({
          left: $r('app.float.ringtone_selection_section_header_margin_horizontal'),
          right: $r('app.float.ringtone_selection_section_header_margin_horizontal')
        })
        .width('100%')
      Card({ isMultipleSubItems: true }) {
        ForEach(ringtones, (item: RingtoneItem, index: number) => {
          if (item.id != NONE_RINGTONE_ID) {
            Column() {
              if (index) {
                Divider().color($r('sys.color.comp_divider'))
              }
              this.buildRingtoneItem(item)
            }
            .justifyContent(FlexAlign.Center)
            .borderRadius($r('app.float.default_corner_radius_l'))
          }
        })
      }
    }
  }

  @Builder
  buildTimerSounds() {
    Column() {
      Text('Preset')
        .textCase(TextCase.UpperCase)
        .textAlign(TextAlign.Start)
        .fontSize($r('app.float.ringtone_selection_section_header_size'))
        .margin({
          top: $r('app.float.ringtone_selection_section_header_margin_vertical'),
          bottom: $r('app.float.ringtone_selection_section_header_margin_vertical')
        })
        .padding({
          left: $r('app.float.ringtone_selection_section_header_margin_horizontal'),
          right: $r('app.float.ringtone_selection_section_header_margin_horizontal')
        })
        .width('100%')
      Card({ isMultipleSubItems: true }) {
        ForEach(ringtones, (item: RingtoneItem, index: number) => {
          if (item.id != NONE_RINGTONE_ID) {
            Column() {
              if (index) {
                Divider().color($r('sys.color.comp_divider'))
              }
              this.buildRingtoneItem(item)
            }
            .justifyContent(FlexAlign.Center)
            .borderRadius($r('app.float.default_corner_radius_l'))
          }
        })
      }
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        if (this.pageProps.isTimerRingtone) {
          this.buildTimerSounds()
        } else {
          this.buildAlarmSounds()
        }
        Card({ isMultipleSubItems: true }) {
          Column() {
            this.buildRingtoneItem(noneRingtone)
          }
          .justifyContent(FlexAlign.Center)
          .borderRadius($r('app.float.default_corner_radius_l'))
        }
      }
    }
    .backgroundColor($r('sys.color.ohos_id_background_secondary'))
    .title(this.pageProps.isTimerRingtone ? 'Notification Sound' : 'Alarm Sound')
  }
}