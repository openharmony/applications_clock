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

import { buttonColorSchemes, FloatingActionButtonColor, ButtonColorScheme, IButtonCustomStyle } from './types';

/**
 * Floating Action Button Component
 *
 * @since 2023-09-14
 */
@Component
export struct FloatingActionButton {
  @Prop src: Resource = {} as Resource;
  @Prop colorSchemeName: FloatingActionButtonColor = FloatingActionButtonColor.BLUE;
  @Prop isEnabled: boolean = true;
  @Prop playButton: boolean = false;
  @Prop idx: string | number = 0;
  @Prop customStyle: IButtonCustomStyle = {} as IButtonCustomStyle;
  @State noDraggable: boolean = false;
  onButtonClick?: () => void;
  private colorScheme = buttonColorSchemes.find(s => s.schemeName === this.colorSchemeName);

  @Styles
  normalButtonStyle()
   {
    .backgroundColor(this.isEnabled ? this.colorScheme!.backgroundColor : (this.customStyle.buttonDefaultBgc ||
    this.colorScheme!.backgroundColor))
  }

  @Styles
  pressedButtonStyle()
   {
    .backgroundColor(this.colorScheme!.backgroundColorPressed)
  }

  @Styles
  disabledButtonStyle()
   {
    .backgroundColor($r('app.color.dialog_background_color'))
  }

  @Builder
  buildButtonShadow() {
    Column()
      .width($r('app.float.button_size'))
      .height($r('app.float.button_size'))
      .borderRadius($r('app.float.button_size'))
      .shadow({
        radius: $r('app.float.button_shadow_radius'),
        color: $r('app.color.color_fab_shadow'),
        offsetX: $r('app.float.button_shadow_x'),
        offsetY: $r('app.float.button_shadow_y'),
      })
  }

  build() {
    Stack() {
      if (this.colorSchemeName == FloatingActionButtonColor.BLUE && this.isEnabled) {
        this.buildButtonShadow()
      }
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image(this.src)
          .width(this.playButton ? $r('app.float.button_icon_on') : $r('app.float.button_icon_size'))
          .height(this.playButton ? $r('app.float.button_icon_on') : $r('app.float.button_icon_size'))
          .fillColor(this.isEnabled ? (this.customStyle.iconPlayColor || this.colorScheme!.iconColor)
            : (this.customStyle.iconDefaultColor || this.colorScheme!.iconColorDisabled))
          .draggable(this.noDraggable)
          .focusable(true)
      }
      .id('id_fab_button' + this.idx)
      .backgroundColor(this.colorScheme!.backgroundColor)
      .width(this.playButton ? $r('app.float.button_back') : $r('app.float.button_size'))
      .height(this.playButton ? $r('app.float.button_back') : $r('app.float.button_size'))
      .margin(this.playButton ? { top: '2vp', bottom: '2vp' } : 0)
      .stateStyles({
        normal: this.normalButtonStyle,
        pressed: this.pressedButtonStyle,
        disabled: this.disabledButtonStyle,
      })
      // .enabled(this.isEnabled)
      .onClick(() => this.onButtonClick && this.onButtonClick())
    }
    .enabled(this.isEnabled)
  }
}