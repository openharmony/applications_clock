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

import router from '@ohos.router';
import {
  EventReportUtil,
  EventName,
  CommonUtil
} from '../../utils';
// import hiSysEvent from '@ohos.hiSysEvent';
/**
 * Add-Button Component
 *
 * @since 2022-09-26
 */
export enum ButtonSize {
  NORMAL,
  LARGER
}

@Component
export struct AddButton {
  @Prop buttonSize: ButtonSize = ButtonSize.NORMAL;
  @Prop alarmFlag: boolean = true;
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  onButtonClick?: () => void;

  @Styles
  normalButtonStyle()
   {
    .backgroundColor($r('sys.color.ohos_id_container_color_active'))
  }

  @Styles
  pressedButtonStyle()
   {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  private getButtonSize(): ResourceStr {
    if (this.buttonSize === ButtonSize.NORMAL) {
      return $r('app.float.button_size');
    } else if (this.buttonSize === ButtonSize.LARGER) {
      return $r('app.float.pc_add_button_size');
    }
    return $r('app.float.button_size');
  }

  private addDottingEvent(flag: boolean): void {
    if (flag) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_ALARM_CLOCK_ADD)
    } else {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_ADD_CITY)
    }
  }

  @Builder
  buildAddButtonShadow() {
    Column()
      .width($r('app.float.pc_add_button_size'))
      .height($r('app.float.pc_add_button_size'))
      .borderRadius($r('app.float.button_size'))
      .shadow({
        radius: $r('app.float.button_shadow_radius'),
        color: $r('sys.color.ohos_id_icon_color_active_secondary'),
        offsetX: $r('app.float.button_shadow_x'),
        offsetY: $r('app.float.button_shadow_y'),
      })
  }

  build() {
    Stack() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.ic_add'))
          .fillColor($r('sys.color.icon_on_primary'))
          .width($r('app.float.button_icon_size'))
          .height($r('app.float.button_icon_size'))
          .draggable(false)
          .focusable(true)
      }
      .id('id_add_button')
      .backgroundColor($r('sys.color.ohos_id_container_color_active'))
      .width($r('app.float.pc_add_button_size'))
      .height($r('app.float.pc_add_button_size'))
      .stateStyles({
        pressed: this.pressedButtonStyle,
      })
      .shadow({
        radius: $r('app.float.button_shadow_radius'),
        color: CommonUtil.changeShadowColor($r('sys.color.ohos_id_container_color_active')),
        offsetX: 0,
        offsetY: $r('app.float.button_shadow_y2'),
      })
      .onClick(() => {
        this.onButtonClick && this.onButtonClick()
        this.addDottingEvent(this.alarmFlag)
      })
    }
    .margin({ bottom: this.buttonSize === ButtonSize.LARGER ? 0 : $r('app.float.appbar_fold_icon_margin') })
  }
}