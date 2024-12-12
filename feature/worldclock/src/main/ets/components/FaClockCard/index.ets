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

import { LogUtil, Card } from '@hmos/common';
import { FaCityInfo } from '../../manager/types'

const RESPONSE_REGION_OFFSET: number = -12;
const FLEX_GROW_FILL_FULL: number = 1;
const CITY_COUNT_ONE: number = 1;
const TAG: string = 'FaClockCard';

interface DragParam {
  selectedIndex: number;
  insertIndex: number;
}

@Component
export struct FaClockCard {
  @Link faCityInfoList: FaCityInfo[];
  @State isDrag: boolean = false;
  @State dragFaCityInfo: FaCityInfo = {
    cityIndex: '',
    cityName: '',
  };
  private dragIndex?: number;
  private isChanged: boolean = false;

  private dealWithDragResult(dragParam: DragParam): void {
    if (!this.isDrag) {
      return;
    }
    if (dragParam.insertIndex) {
      if (dragParam.selectedIndex !== dragParam.insertIndex) {
        this.isChanged = true;
      }
    }

    LogUtil.info(TAG, 'this.cityNameList:' + JSON.stringify(this.faCityInfoList));
    LogUtil.info(TAG, 'this.dragFaCityInfo:' + JSON.stringify(this.dragFaCityInfo));

    if (dragParam.insertIndex) {
      this.faCityInfoList.splice(dragParam.insertIndex, 0, this.dragFaCityInfo);
    }
    LogUtil.info(TAG, 'this.cityNameList:' + JSON.stringify(this.faCityInfoList));
    this.isDrag = false;
  }

  @Builder
  renderDivider(index?: number): void {
    if (index) {
      // Render divider above items except for the first item with index zero
      Divider().color($r('sys.color.comp_divider'))
    }
  }

  @Builder
  buildLeftPart(index?: number): void {
    Row() {
      if (this.faCityInfoList.length > CITY_COUNT_ONE) {
        Image($r('app.media.ic_public_drag_handle'))
          .height($r('app.float.appbar_icon_size'))
          .width($r('app.float.appbar_icon_size'))
          .margin({ right: $r('app.float.card_margin_start') })
          .draggable(false)
          .responseRegion({
            x: RESPONSE_REGION_OFFSET,
            y: RESPONSE_REGION_OFFSET,
            width: '200%',
            height: '200%',
          })
      }
      Text($r('app.string.fa_select_city'))
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ right: $r('app.float.card_tag_margin_end') })
        .fontWeight(FontWeight.Medium)
        .width('50%')
    }
  }

  @Builder
  buildRightPart(item: string): void {
    Column() {
      Row() {
        Text(item)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Regular)
          .width('80%')
          .textAlign(TextAlign.End)
      }
    }
    .alignItems(HorizontalAlign.End)
    .flexGrow(FLEX_GROW_FILL_FULL)
  }

  @Builder
  cardContent(item: string, index?: number): void {
    Column() {
      Row() {
        this.renderDivider(index);
      }
      .width('100%')

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        this.buildLeftPart(index);
        this.buildRightPart(item);
      }
      .width('100%')
      .height($r('app.float.fa_card_height'))
    }
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  @Builder
  pixelMapBuilder(item: string, index?: number): void {
    Card({ needPressStyle: false }) {
      this.cardContent(item, index);
    }
  }

  @Builder
  buildCityClockSelectContent(): void {
    if (this.faCityInfoList.length === CITY_COUNT_ONE) {
      Card({ needPressStyle: false }) {
        this.cardContent(this.faCityInfoList[0].cityName, 0);
      }
    } else {
      Card({ needPressStyle: false }) {
        List() {
          ForEach(this.faCityInfoList, (item: FaCityInfo, index) => {
            ListItem() {
              this.cardContent(item.cityName, index);
            }
            .transition(
              TransitionEffect.asymmetric(
                TransitionEffect.IDENTITY,
                TransitionEffect.scale({ x: 1, y: 1 })
                  .animation({ curve: Curve.Friction, duration: 0 })
                  .combine(
                    TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
                  )
              )
            )
            .editable(false)
            .onDragStart(() => {
              this.dragFaCityInfo = item;
              if (this.dragIndex) {
                this.dragIndex = index;
              }
              this.isDrag = true;
              this.faCityInfoList = this.faCityInfoList.filter(faCityInfo => faCityInfo.cityName !== item.cityName);
              return this.pixelMapBuilder(item.cityName, index);
            })
          })
        }
        .onDragLeave((event?: DragEvent, extraParams?: string) => {
          if (event && extraParams) {
            LogUtil.info(TAG, 'List onDragLeave, ' + extraParams + 'X:' + event.getX() + 'Y:' + event.getY());
            const dragParam: DragParam = JSON.parse(extraParams);
            if (this.dragIndex) {
              LogUtil.info(TAG, 'List onDragLeave dragIndex:' + this.dragIndex);
              if (dragParam.insertIndex) {
                dragParam.insertIndex = this.dragIndex;
              }
            }
            dragParam && this.dealWithDragResult(dragParam);
          }
        })
        .onDrop((event?: DragEvent, extraParams?: string) => {
          if (extraParams) {
            if (event) {
              LogUtil.info(TAG, 'List onDrop, ' + extraParams + 'X:' + event.getX() + 'Y:' + event.getY());
            }
            const dragParam: DragParam = JSON.parse(extraParams);
            dragParam && this.dealWithDragResult(dragParam);
          }
        })
      }
    }
  }

  build() {
    Column() {
      this.buildCityClockSelectContent()
    }
    .margin({ left: $r('app.float.fa_card_left_margin'), right: $r('app.float.fa_card_right_margin') })
  }
}