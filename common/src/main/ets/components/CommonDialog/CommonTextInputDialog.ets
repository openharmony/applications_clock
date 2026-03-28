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

import { ALARM_NAME_INPUT_MIN, ALARM_NAME_INPUT_LIMIT } from '../../manager';
import { CommonUtil } from '../../utils';

@Extend(Button)
function inputDialogButton() {
  .height($r('app.float.dialog_button_height'))
  .fontSize($r('sys.float.Body_L'))
  .flexGrow(1)
}

const TITTLE_TEXT_LEFT_MARGIN_HAS_ICON: number = 12;
const HUNDRED_PERCENT: string = '100%';
const OPACITY_ONE: number = 1;
const OPACITY_OTHER: number = 0.4;
const STROKE_WIDTH: number = 0.5;

@Builder
function dummyFunction() {
};

/**
 * CommonTextInputDialog
 *
 * @since 2023-04-27
 */
@CustomDialog
export struct CommonTextInputDialog {
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @State title: string = '';
  @BuilderParam content: () => void = dummyFunction;
  @State confirmEnable: boolean = true;
  @State textContent: string = '';
  @State cancelBackground: Resource = $r('app.color.transparent');
  @State confirmBackground: Resource = $r('app.color.transparent');
  @StorageLink('TextInputClose') @Watch('TextInputClose') isTextInputClose: boolean = false;
  private controller: CustomDialogController = new CustomDialogController({ builder: undefined });
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
      Flex({ alignItems: ItemAlign.Center, direction: FlexDirection.Column }) {
        TextInput({ text: this.textContent })
          .backgroundColor($r('app.color.transparent'))
          .height($r('app.float.input_height'))
          .maxLength(ALARM_NAME_INPUT_LIMIT)
          .onChange(async (value: string) => {
            if (value?.length === ALARM_NAME_INPUT_MIN) {
              this.confirmEnable = false;
              this.textContent = '';
            } else {
              this.confirmEnable = true;
              this.textContent = value;
              await this.textInputCallback(value);
            }
          })
          .padding({
            left: $r('app.float.common_text_input_padding_zero'),
            right: $r('app.float.common_text_input_padding_zero'),
          })
          .defaultFocus(true)
      }
      .height($r('app.float.list_item_height'))

      Divider().color($r('sys.color.comp_divider'))
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
          .inputDialogButton()
          .fontColor($r('sys.color.ohos_id_icon_color_active'))
          .backgroundColor($r('sys.color.interactive_hover'))
          .onHover((isHover) => {
            this.cancelBackground = this.handleButtonHoverEvent(isHover as boolean);
          })
          .onTouch((event) => {
            this.cancelBackground = this.handleButtonTouchEvent(event as TouchEvent);
          })
      }
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
          .enabled(this.confirmEnable)
          .opacity(this.confirmEnable ? OPACITY_ONE : OPACITY_OTHER)
          .inputDialogButton()
          .fontColor($r('sys.color.ohos_id_icon_color_active'))
          .backgroundColor(this.confirmBackground)
          .onHover((isHover) => {
            this.confirmBackground = this.handleButtonHoverEvent(isHover as boolean);
          })
          .onTouch((event) => {
            this.confirmBackground = this.handleButtonTouchEvent(event as TouchEvent);
          })
      }
    }
    .height($r('app.float.dialog_button_height'))
    .margin({
      bottom: $r('app.float.confirm_dialog_padding_horizontal')
    })
  }

  @Builder
  buildDialog(): void {
    Column() {
      this.buildTitle();
      this.buildContent();
      this.buildButtons();
    }
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .borderRadius($r('sys.float.corner_radius_level16'))
    .width(this.foldAbleScreen === 1 ? $r('app.float.dilog_width') : '')
    .padding({
      left: $r('app.float.confirm_dialog_padding_horizontal'),
      right: $r('app.float.confirm_dialog_padding_horizontal'),
    })
  }

  @Builder
  buildDialogForPhone(): void {
    Column() {
      this.buildDialog();
    }
    .margin({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      bottom: $r('sys.float.padding_level6'),
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