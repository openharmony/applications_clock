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

/**
 * Title Bar
 *
 * @since 2022-12-12
 */
import deviceInfo from '@ohos.deviceInfo'
import {
  EventReportUtil,
  EventName
} from '../../utils';
// import hiSysEvent from '@ohos.hiSysEvent';

interface ICancelBgColorOptions {
  defaultBgColor: ResourceColor;
  hoverBgColor: ResourceColor;
  pressBgColor: ResourceColor;
}

const cancelBgColorOptions: ICancelBgColorOptions = {
  defaultBgColor: $r('app.color.color_hover_disabled'),
  hoverBgColor: $r('app.color.color_hover'),
  pressBgColor: $r('app.color.color_hover_disabled'),
}
const pcCancelBgColorOptions: ICancelBgColorOptions = {
  defaultBgColor: $r('sys.color.comp_background_tertiary'),
  hoverBgColor: $r('sys.color.interactive_hover'),
  pressBgColor: $r('sys.color.interactive_click'),
}

@Component
export struct TitleBar {
  @Prop titleFontWeight: FontWeight = FontWeight.Medium;
  @Prop title: string = '';
  @Prop isHoverInfo: boolean = false;
  @Prop isPCView: boolean = false;
  @Prop isFocusAble: boolean = false;
  @Prop isModelBg: boolean = false;
  @Prop modelEditFlag: boolean = false;
  @State hoverBackgroundCancel: ResourceColor = this.getCancelBg();
  @State deviceType: string = deviceInfo.deviceType; // 设备类型
  @BuilderParam operationArea?: () => void; // Operation area on the right of the title

  private isPCLg() {
    return this.deviceType === '2in1'
  }

  private onIconClick?: () => void;
  private iconResource?: Resource;

  private getCancelBg() {
    if (this.isPCView) {
      return pcCancelBgColorOptions.defaultBgColor;
    }
    return pcCancelBgColorOptions.defaultBgColor;
  }
  // 取消修改打点事件
  private cancelEdit(flag:boolean) {
    if (flag) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_ALARM_ABANDON_SETTING)
    } else {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.LONG_PRESS_CANCEL_EDIT_ALARM)
    }
  }

  build() {
    Row() {
      if (this.iconResource) {
        if (this.isHoverInfo) {
          Row() {
            Image(this.iconResource)
              .fillColor($r('sys.color.icon_primary'))
              .width($r('app.float.button_icon_size'))
              .height($r('app.float.button_icon_size'))
              .id('id_title_bar_image')
              .draggable(false)
              .focusable(this.isFocusAble)
          }
          .onClick(() => {
            this.cancelEdit(this.modelEditFlag)
            this.onIconClick?.()
          })
          .margin({
            left: this.isPCView ? 0 : $r('app.float.button_icon_left_padding'),
            right: this.isPCView ? $r('sys.float.padding_level4') : $r('app.float.button_icon_right_padding'),
          })
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.hoverBackgroundCancel)
          .width(this.isPCView ? $r('app.float.pc_button_size') : $r('app.float.pc_button_size'))
          .height(this.isPCView ? $r('app.float.pc_button_size') : $r('app.float.pc_button_size'))
          .borderRadius(this.isPCView ? $r('app.float.pc_button_size') : $r('app.float.pc_button_size'))
          .onMouse((event) => {
            if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
              this.hoverBackgroundCancel = $r('sys.color.interactive_click');
            } else if (event?.action === MouseAction.Release) {
              this.hoverBackgroundCancel = $r('sys.color.interactive_hover');
            }
          })
        } else {
          Image(this.iconResource)
            .fillColor($r('sys.color.ohos_fa_icon_secondary'))
            .id('id_title_bar_image')
            .width($r('app.float.button_icon_size'))
            .height($r('app.float.button_icon_size'))
            .draggable(false)
            .onClick(() => this.onIconClick?.())
            .margin({
              left: this.isPCView ? 0 : $r('sys.float.padding_level8'),
              right: this.isPCView ? $r('sys.float.padding_level4') : $r('sys.float.padding_level8'),
            })
        }
      }
      if (this.iconResource) {
        Text(this.title)
          .fontWeight(this.titleFontWeight)
          .fontSize($r('app.float.header_fontSize_addTitle'))
          .fontColor($r('sys.color.icon_primary'))
          .lineHeight($r('app.float.header_lineHeight_addTitle'))
      } else {
        Text(this.title)
          .fontWeight(this.titleFontWeight)
          .fontSize($r('app.float.header_fontSize'))
          .fontColor($r('sys.color.icon_primary'))
          .lineHeight($r('app.float.header_lineHeight'))
          .height($r('app.float.header_textHeight'))
          .fontWeight(FontWeight.Bold)
          .margin({ top: this.isPCLg() ? $r('app.float.card_margin_top') : '' })
      }

      Blank()
      if (this.operationArea) {
        Row() {
          this.operationArea()
        }
        .margin({ right: this.isPCView ? 0 : $r('app.float.button_operation_right_padding') })
      }
    }
    .backgroundColor(this.isModelBg ? $r('app.color.component_ultra_thick_panel') : $r('sys.color.ohos_id_background_secondary'))
    .id('id_title_bar')
    .height($r('app.float.header_footer_height'))
    .width('100%')
  }
}
