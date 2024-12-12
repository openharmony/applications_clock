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

import { Card, CardSize, CommonGrid } from '@hmos/common';
import { WorldClockInfo } from '../../manager/types';
import { WorldClockManager } from '../../manager';

const RESPONSE_REGION_OFFSET = -12;

/**
 * World City Card
 *
 * @since 2022-09-26
 */
@Component
export struct WorldCityCard {
  @Prop isLarge: boolean = false
  @Prop isGrid: boolean = true;
  @Prop isPCView: boolean = false;
  @State cityTimeZoneInfo?: string = '';
  @State hoverBackgroundClose: Resource = $r('app.color.color_hover_disabled');
  private cityName: string = '';
  private cityInfo: WorldClockInfo = {} as WorldClockInfo;
  private onDelete: () => void = () => {
  };

  /**
   * handleButtonHoverEvent
   *
   * @param isHover
   */
  private handleImageHoverEvent(isHover: boolean): Resource {
    if (isHover) {
      return $r('app.color.color_hover');
    } else {
      return $r('app.color.color_hover_disabled');
    }
  };

  async aboutToAppear() {
    this.cityName = WorldClockManager.getDisplayCityName(this.cityInfo.cityIndex);
    this.cityTimeZoneInfo = this.cityInfo.tag;
  }

  @Builder
  buildCardLeftPart() {
    Column() {
      Row() {
        Column() {
          Image($r('app.media.ic_public_drag_handle'))
            .height($r('app.float.appbar_icon_size'))
            .width($r('app.float.appbar_icon_size'))
            .draggable(false)
            .fillColor($r('sys.color.ohos_fa_icon_primary'))
            .responseRegion({
              x: RESPONSE_REGION_OFFSET,
              y: RESPONSE_REGION_OFFSET,
              width: '200%',
              height: '200%',
            })
        }
        .margin({ right: $r('app.float.button_icon_right_padding') })
        .padding($r('app.float.button_icon_hover_padding'))
        .borderRadius($r('app.float.button_shadow_radius'))

        Column() {
          Text(this.cityName)
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .lineHeight($r('app.float.card_title_line_height'))
          Text(this.cityTimeZoneInfo)
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Regular)
            .alignSelf(ItemAlign.Start)
            .margin({ top: $r('app.float.card_title_line_margin') })
            .lineHeight($r('app.float.card_content_line_height'))
        }
      }
    }
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildCardRightPart() {
    Column() {
      Image($r('app.media.ic_public_close_filled'))
        .height($r('app.float.appbar_icon_size'))
        .width($r('app.float.appbar_icon_size'))
        .draggable(false)
        .fillColor($r('sys.color.font_secondary'))
        .responseRegion({ x: RESPONSE_REGION_OFFSET, y: RESPONSE_REGION_OFFSET, width: '200%', height: '200%' })
        .focusable(true)
        .onClick(() => this.onDelete())
    }
    .id('id_closeCity_img')
    .backgroundColor(this.hoverBackgroundClose)
    .padding($r('app.float.card_inner_padding_horizontal'))
    .borderRadius($r('app.float.button_shadow_radius'))
    .margin({
      right: this.isPCView ? $r('app.float.card_inner_margin_horizontal') : ''
    })
    .onHover((isHover: boolean, event: HoverEvent) => {
      if (event && event.stopPropagation) {
        event.stopPropagation();
      }
      this.hoverBackgroundClose = this.handleImageHoverEvent(isHover);
    })
    .onMouse((event: MouseEvent) => {
      if (event && event.stopPropagation) {
        event.stopPropagation();
      }
      if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
        this.hoverBackgroundClose = $r('sys.color.interactive_click');
      } else if (event?.action === MouseAction.Hover) {
        this.hoverBackgroundClose = $r('sys.color.interactive_hover');
      } else if (event?.action === MouseAction.Release) {
        this.hoverBackgroundClose = $r('app.color.color_hover_disabled');
      }
    })
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  buildContent() {
    Column() {
      Card({
        openHoverStatus: this.isLarge,
        openPressStatus: this.isLarge,
        cardSize: this.isLarge ? CardSize.LARGER : CardSize.NORMAL,
        needPressStyle: false,
        isMultipleSubItems: true,
        isHorizontalPaddingLeft: false
      }) {
        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          this.buildCardLeftPart()
          this.buildCardRightPart()
        }
        .height($r('app.float.card_content_height'))
      }
    }
  }

  build() {
    Column() {
      if (this.isGrid) {
        CommonGrid() {
          this.buildContent()
        }
      } else {
        this.buildContent()
      }
    }
  }
}