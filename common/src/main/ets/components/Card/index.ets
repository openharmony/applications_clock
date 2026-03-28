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

@Builder
function dummyFunction() {
};

interface ICardBgColorOptions {
  defaultBgColor: ResourceColor;
  hoverBgColor: ResourceColor;
  pressBgColor: ResourceColor;
}

export enum CardSize {
  NORMAL,
  LARGER
}

/**
 * Card Component
 *
 * @since 2022-07-16
 */
@Component
export struct Card {
  @BuilderParam content: () => void = dummyFunction;
  @Prop cancelMargin: boolean = false;
  @Prop restrictAlarmCardMargin: boolean = false;
  @Prop cancelDoubleCardMargin: boolean = false;
  @Prop openHoverStatus: boolean = false;
  @Prop openPressStatus: boolean = false;
  @Prop cardSize: CardSize = CardSize.NORMAL;
  @Prop focusRemoveLRMargin: boolean = false;
  @State bgColorOptions: ICardBgColorOptions = {
    defaultBgColor: $r('sys.color.comp_background_list_card'),
    hoverBgColor: $r('sys.color.interactive_hover'),
    pressBgColor: $r('sys.color.comp_background_list_card'),
  };
  @State bgColor: ResourceColor = this.bgColorOptions.defaultBgColor;
  // Whether a content contains multiple items. default value is 1.
  private isMultipleSubItems: boolean = false;
  private needPressStyle: boolean = true;
  private isHorizontalPaddingLeft: boolean = true;
  bgHoverHandle = (isHover: boolean) => {
    if (!this.openHoverStatus) {
      return;
    }
    if (isHover) {
      this.bgColor = this.bgColorOptions.hoverBgColor;
    } else {
      this.bgColor = this.bgColorOptions.defaultBgColor;
    }
  }
  bgMouseHandle = (event: MouseEvent) => {
    if (!this.openPressStatus) {
      return;
    }
    if ((event.action === MouseAction.Press) && (event.button === MouseButton.Left)) {
      this.bgColor = this.bgColorOptions.pressBgColor;
    } else if (event.action === MouseAction.Hover) {
      this.bgColor = this.bgColorOptions.hoverBgColor;
    } else if (event.action === MouseAction.Release) {
      this.bgColor = this.bgColorOptions.defaultBgColor;
    }
  }

  build() {
    Stack() {
      Column() {
        this.content()
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
      .padding({
        right: this.cardSize === CardSize.LARGER ? 0 : (this.isMultipleSubItems ? 0 : $r('app.float.card_inner_padding_horizontal')),
        left: this.isMultipleSubItems ? 0 : $r('app.float.card_inner_padding_horizontal'),
      })
    }
    .id('id_card')
    .padding({
      top: this.cardSize === CardSize.LARGER ? $r('app.float.card_inner_padding_horizontal') : (this.restrictAlarmCardMargin ? 0 : $r('app.float.card_padding_vertical')),
      right: this.cardSize === CardSize.LARGER ? 0 : $r('app.float.card_padding_horizontal'),
      bottom: this.cardSize === CardSize.LARGER ? $r('app.float.card_inner_padding_horizontal') : (this.restrictAlarmCardMargin ? 0 : $r('app.float.card_padding_vertical')),
      left: this.isHorizontalPaddingLeft ? $r('app.float.card_padding_horizontal') : 0,
    })
    .margin({
      left: (this.cancelMargin || this.cancelDoubleCardMargin || this.focusRemoveLRMargin) ? 0 : $r('app.float.card_margin_start'),
      right: (this.cancelMargin || this.cancelDoubleCardMargin || this.focusRemoveLRMargin) ? 0 : $r('app.float.card_margin_end'),
      top: (this.cancelMargin || this.restrictAlarmCardMargin) ? 0 : $r('app.float.card_margin_top'),
      bottom: this.cancelMargin ? $r('app.float.cancel_bottom_margin') : this.restrictAlarmCardMargin ? 0 : $r('app.float.card_margin_bottom'),
    })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .backgroundColor(this.bgColor)
    .onHover(this.bgHoverHandle)
    .onMouse(this.bgMouseHandle)
  }
}
