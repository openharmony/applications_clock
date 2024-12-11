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

import { CommonHwDialog, ActionType } from './CommonHwDialog';
import { CommonUtil } from '../../utils';

@Builder
function dummyFunction() {
};

/**
 * Common Dialog
 *
 * @since 2023-01-10
 */
@CustomDialog
export struct CommonDialog {
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @BuilderParam content: () => void = dummyFunction;
  @Prop firstButtonName: string = '';
  @Prop secondButtonName: string = '';
  private actionType: ActionType = ActionType.TWO_BUTTON_HORIZONTAL;
  private title?: string;
  private firstButtonCallback: () => void = () => {
  };
  private secondButtonCallback: () => void = () => {
  };
  private controller: CustomDialogController = new CustomDialogController({ builder: undefined });
  // This variable must be declared when HwDialog is used. Otherwise, an exception occurs when the dialog is opened.
  @Provide('contentParam') _: number = 0;

  @Builder
  buildDialogForPhone() {
    Column() {
      Column() {
        this.buildDialog()
      }
      .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    }
    .id('id_common_dialog_phone')
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .borderRadius($r('sys.float.corner_radius_level16'))
    .width(this.foldAbleScreen === 1 ? $r('app.float.dilog_width') : '')
    .clip(true)
    .margin({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      bottom: $r('sys.float.padding_level8'),
    })
  }

  @Builder
  buildDialog() {
    CommonHwDialog({
      controller: this.controller,
      title: this.title,
      actionType: this.actionType,
      cancelText: `${this.firstButtonName}`,
      cancelCallback: () => this.firstButtonCallback(),
      confirmText: `${this.secondButtonName}`,
      confirmCallback: () => this.secondButtonCallback(),
      content: () => this.content(),
    })
      .id('id_common_dialog')
      .backgroundColor($r('app.color.component_ultra_thick_dialog'))
  }

  build() {
    if (CommonUtil.isDevicePhone()) {
      this.buildDialogForPhone()
    } else {
      this.buildDialog()
    }
  }
}