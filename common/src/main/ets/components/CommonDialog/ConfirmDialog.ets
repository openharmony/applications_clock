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

import resmgr from '@ohos.resourceManager';
import { ActionType, CommonHwDialog } from './CommonHwDialog';
import { CommonUtil, GlobalContext } from '../../utils';

/**
 * ConfirmDialog
 *
 * @since 2022-12-10
 */
@CustomDialog
export struct ConfirmDialog {
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  private confirmMessage: ResourceStr = '';
  private controller: CustomDialogController = new CustomDialogController({ builder: undefined });
  private cancel?: () => void;
  private confirm?: () => void;
  private confirmText?: ResourceStr;
  private cancelText?: ResourceStr
  private hasWarning: boolean = false;
  // This variable must be declared when HwDialog is used. Otherwise, an exception occurs when the dialog is opened.
  @Provide('contentParam') _: number = 0;

  private getStrFromResource(resourceStr: ResourceStr): string {
    if (typeof resourceStr === 'string') {
      return resourceStr;
    }
    return (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringSync(resourceStr.id);
  }

  @Builder
  buildContent(): void {
    Column() {
      Text(this.confirmMessage)
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Regular)
    }
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .padding({
      top: $r('app.float.confirm_dialog_content_padding_top'),
      bottom: $r('app.float.confirm_dialog_content_padding_bottom'),
    })
  }

  @Builder
  buildDialogForPhone() {
    Column() {
      Column() {
        this.buildDialog()
      }
      .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    }
    .backgroundColor($r('app.color.component_ultra_thick_dialog'))
    .borderRadius($r('sys.float.corner_radius_level16'))
    .clip(true)
    .width(this.foldAbleScreen === 1 ? $r('app.float.dilog_width') : '')
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
      hasWarning: this.hasWarning,
      actionType: ActionType.TWO_BUTTON_HORIZONTAL,
      cancelText: this.cancelText ? this.getStrFromResource(this.cancelText) : (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('cancel'),
      cancelCallback: () => this.cancel ? this.cancel() : undefined,
      confirmText: this.confirmText ? this.getStrFromResource(this.confirmText) : (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('confirm_delete'),
      confirmCallback: () => this.confirm ? this.confirm() : undefined,
      content: () => this.buildContent(),
    })
  }

  build() {
    if (CommonUtil.isDevicePhone()) {
      this.buildDialogForPhone()
    } else {
      this.buildDialog()
    }
  }
}