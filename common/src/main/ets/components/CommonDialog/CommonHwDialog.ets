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

import { CommonUtil } from '../../utils';

export enum ActionType {
  NO_BUTTON = 0,
  SINGE_BUTTON_VERTICAL = 1,
  SINGE_BUTTON_HORIZONTAL = 2,
  TWO_BUTTON_VERTICAL = 3,
  TWO_BUTTON_HORIZONTAL = 4,
  THREE_BUTTON_VERTICAL = 5,
  THREE_BUTTON_HORIZONTAL = 6
}


@Extend(Button)
function dialogButton() {
  .height($r('app.float.dialog_button_height'))
  .fontSize($r('sys.float.Body_L'))
  .flexGrow(1)
}

const TITTLE_TEXT_LEFT_MARGIN_HAS_ICON: number = 12;
const HUNDRED_PERCENT: string = '100%';
const OPACITY_ONE: number = 1;
const OPACITY_OTHER: number = 0.4;
const STROKE_WIDTH: number = 0.5;
const NO_PADDING: number = 0;
const DIALOG_TOP_BOTTOM_PADDING: number = 24;

@Builder
function dummyFunction() {
};

/**
 * CommonHwDialog
 *
 * @since 2023-04-27
 */
@CustomDialog
export struct CommonHwDialog {
  @State title: string = '';
  @BuilderParam content: () => void = dummyFunction;
  @State confirmEnable: boolean = true;
  @State textContent: string = '';
  @State cancelBackground: Resource = $r('app.color.transparent');
  @State confirmBackground: Resource = $r('app.color.transparent');
  @StorageLink('TextInputClose') @Watch('TextInputClose') isTextInputClose: boolean = false;
  private controller: CustomDialogController = new CustomDialogController({ builder: undefined });
  actionType: ActionType = ActionType.NO_BUTTON;
  hasWarning: boolean = false;
  cancelCallback?: () => void;
  confirmCallback?: () => void;
  textInputCallback: (value: string) => void = (input: string) => {
  };
  confirmText?: Resource | string;
  cancelText?: Resource | string;
  confirmTextColor?: ResourceColor;

  private TextInputClose() {
    this.controller.close();
  }

  aboutToAppear(): void {
    if (CommonUtil.isDevicePhone()) {
      this.cancelBackground = $r('app.color.transparent');
      this.confirmBackground = $r('app.color.transparent');
    } else {
      this.cancelBackground = $r('app.color.transparent');
      this.confirmBackground = $r('app.color.transparent');
    }
  }

  /**
   * handleButtonTouchEvent
   *
   * @param event TouchEvent
   *
   */
  private handleButtonTouchEvent(event: TouchEvent): Resource {
    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      if (CommonUtil.isDevicePhone()) {
        return $r('app.color.color_press_text_button');
      } else {
        return $r('app.color.color_press_normal_button');
      }
    } else {
      if (CommonUtil.isDevicePhone()) {
        return $r('app.color.id_color_transparent');
      } else {
        return $r('sys.color.comp_background_tertiary');
      }
    }
  }

  /**
   * handleButtonHoverEvent
   *
   * @param isHover
   */
  private handleButtonHoverEvent(isHover: boolean): Resource {
    if (isHover) {
      if (CommonUtil.isDevicePhone()) {
        return $r('sys.color.interactive_hover');
      } else {
        return $r('app.color.color_hover_normal_button');
      }
    } else {
      return $r('app.color.id_color_transparent');
    }
  }

  @Builder
  buildTitle(): void {
    Flex({ justifyContent: FlexAlign.Start }) {
      Row() {
        Text(this.title)
          .margin({ left: TITTLE_TEXT_LEFT_MARGIN_HAS_ICON })
          .fontSize($r('sys.float.Subtitle_S'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .margin({ left: 0 })
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ maxWidth: HUNDRED_PERCENT })
      .height($r('app.float.float_title_height'))
      .align(Alignment.Start)
      .padding({ left: $r('app.float.float_content_padding'), right: $r('app.float.float_content_padding') })
    }
    .width(HUNDRED_PERCENT)
  }

  @Builder
  buildContent(): void {
    Column() {
      this.content();
    }
    .padding({ left: $r('app.float.float_content_padding'), right: $r('app.float.float_content_padding') })
    .margin({ bottom: $r('app.float.float_content_bottom_margin') })
  }

  @Builder
  buildButtons(): void {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      if (this.cancelCallback) {
        Button(this.cancelText ? this.cancelText : $r('app.string.cancel'))
          .onClick(() => {
            this.controller.close();
            this.cancelCallback ? this.cancelCallback() : undefined;
          })
          .id('id_cancelText_button')
          .dialogButton()
          .fontColor($r('sys.color.ohos_id_icon_color_active'))
          .backgroundColor($r('sys.color.interactive_hover'))
          .onHover((isHover) => {
            this.cancelBackground = this.handleButtonHoverEvent(isHover as boolean);
          })
          .onTouch((event) => {
            this.cancelBackground = this.handleButtonTouchEvent(event as TouchEvent);
          })
      }
      if (this.actionType === ActionType.TWO_BUTTON_HORIZONTAL) {
        if (this.cancelCallback && this.confirmCallback) {
          Divider()
            .vertical(true)
            .strokeWidth(null)
            .color($r('sys.color.comp_divider'))
            .lineCap(LineCapStyle.Round)
            .height($r('app.float.float_divider_height'))
            .padding({ left: $r('app.float.float_divider_padding'), right: $r('app.float.float_divider_padding') })
            .visibility(CommonUtil.isDevicePhone() ? Visibility.Visible : Visibility.Hidden)
        }
        if (this.confirmCallback) {
          Button(this.confirmText ? this.confirmText : $r('app.string.confirm_delete'))
            .onClick(() => {
              this.confirmCallback ? this.confirmCallback() : undefined;
              this.controller.close();
            })
            .id('id_confirmText_button')
            .fontColor(this.hasWarning ? $r('sys.color.warning') : $r('sys.color.ohos_id_icon_color_active'))
            .enabled(this.confirmEnable)
            .opacity(this.confirmEnable ? OPACITY_ONE : OPACITY_OTHER)
            .dialogButton()
            .backgroundColor($r('sys.color.interactive_hover'))
            .onHover((isHover) => {
              this.confirmBackground = this.handleButtonHoverEvent(isHover as boolean);
            })
            .onTouch((event) => {
              this.confirmBackground = this.handleButtonTouchEvent(event as TouchEvent);
            })
        }
      }
    }
    .height($r('app.float.dialog_button_height'))
    .margin({
      bottom: CommonUtil.isDevicePhone() ? $r('app.float.common_text_input_padding_zero') : $r('app.float.confirm_dialog_padding_horizontal')
    })
  }

  @Builder
  buildDialog(): void {
    Column() {
      if (this.title !== '') {
        this.buildTitle();
      }
      this.buildContent();
      this.buildButtons();
    }
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .borderRadius($r('sys.float.corner_radius_level16'))
    .padding({
      left: $r('app.float.confirm_dialog_padding_horizontal'),
      right: $r('app.float.confirm_dialog_padding_horizontal'),
      top: NO_PADDING,
    })
  }

  @Builder
  buildDialogForPhone(): void {
    Column() {
      this.buildDialog();
    }
    .margin({
      bottom: $r('sys.float.padding_level8'),
    })
  }

  build() {
    if (CommonUtil.isDevicePhone()) {
      this.buildDialogForPhone();
    } else {
      this.buildDialog();
    }
  }
}