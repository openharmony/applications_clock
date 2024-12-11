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

import router from '@ohos.router';
import resmgr from '@ohos.resourceManager';
// import hiSysEvent from '@ohos.hiSysEvent';
import {
  EventName,
  EventReportUtil,
  GlobalContext,
  LogUtil,
  TitleBar,
  BreakPoint,
} from '@hmos/common';
import { WorldCityCard } from '../components/WorldCityCard';
import { WorldClockInfo } from '../manager/types';
import { WorldClockManager } from '../manager';
import { WorldClockUtil } from '../utils/WorldClockUtil';
import curves from '@ohos.curves';
import deviceInfo from '@ohos.deviceInfo'

interface DragParam {
  selectedIndex: number;
  insertIndex: number;
}

interface idInfo {
  id: number | string
}

@Extend(Image)
function appBarIconBtn() {
  .width($r('app.float.appbar_icon_size'))
  .height($r('app.float.appbar_icon_size'))
  .responseRegion({
    width: $r('app.float.response_region_size'),
    height: $r('app.float.response_region_size'),
  })
}

const TAG = 'EditCities';
const DEFAULT_SORT_ORDER = 9999;
const DRAG_LEAVE_TOP_INDEX = 0;
const DRAG_EXTRA_SPACE_RATE = '20%';
const HEIGHT_WITH_DRAG_EXTRA_SPACE = '140%';
const TITLE_FLEX_SHRINK = 1; // Keep the origin height of title in flex layout
const CONTENT_FLEX_GROW = 1; // Extend the content area as much as possible in flex layout
const topMargin: number = 30;

/**
 * Page: Edit world cities
 *
 * @since 2022-09-28
 */
@Component
export struct EditCities {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = '';
  @State listPosition: number = 0; // 0代表滚动到List顶部，1代表中间值，2代表滚动到List底部。
  @State worldClockList: WorldClockInfo[] = [];
  @State updateList: WorldClockInfo[] = [];
  @State isDrag: boolean = false;
  @State scaleIndex: string = '';
  @State dragItem: string = '';
  @State neighborIndex: string = '';
  @State deviceType: string = deviceInfo.deviceType;
  @State neighborUpIndex: WorldClockInfo = {
    sortOrder: DEFAULT_SORT_ORDER,
    cityIndex: '',
    timezone: '',
    city: '',
    offset: 0
  };
  @State neighborDownIndex: WorldClockInfo = {
    sortOrder: DEFAULT_SORT_ORDER,
    cityIndex: '',
    timezone: '',
    city: '',
    offset: 0
  };
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State neighborScale: number = -1;
  @State dragCityInfo: WorldClockInfo = {
    sortOrder: DEFAULT_SORT_ORDER,
    cityIndex: '',
    timezone: '',
    city: '',
    offset: 0
  };
  @State hoverBackgroundInfo: Resource = $r('app.color.color_hover_disabled');
  private ITEM_INTV: number = 80;
  private dragRefOffset: number = 0;
  private deleteList: Set<WorldClockInfo> = new Set();
  private deleteIdList: Set<String> = new Set();
  private isChanged: boolean = false;
  //private scrollUp: boolean = true;
  private scroller: Scroller = new Scroller();

  // private isDragToBottom: boolean = false;

  /**
   * handleButtonHoverEvent
   *
   * @param isHover
   */

  scaleSelect(item: string): number {
    if (this.scaleIndex == item) {
      return 1.05;
    } else if (this.neighborIndex == item) {
      return this.neighborScale;
    } else {
      return 1;
    }
  }

  itemMove(index: number, newIndex: number): void {
    let tmp = this.worldClockList.splice(index, 1);
    this.worldClockList.splice(newIndex, 0, tmp[0]);
    this.updateList = this.worldClockList.map((item, index) => {
      let worldClockInfo: WorldClockInfo = {
        sortOrder: index,
        id: item.id,
        cityIndex: item.cityIndex,
        timezone: item.timezone,
        city: item.city,
        offset: item.offset,
        tag: item.tag,
      }
      return worldClockInfo;
    });
  }

  private handleImageHoverEvent(isHover: boolean): Resource {
    if (isHover) {
      return $r('app.color.color_hover');
    } else {
      return $r('app.color.color_hover_disabled');
    }
  };

  async aboutToAppear() {
    LogUtil.info(TAG, 'aboutToAppear: EditCities.');
    this.deviceType = deviceInfo.deviceType
    this.isChanged = false;
    let worldClockList = await WorldClockManager.getAllWorldClock();
    for (let worldClock of worldClockList) {
      worldClock.tag = await WorldClockUtil.updateTimeZoneInfo(worldClock.offset, worldClock.timezone,
        worldClock.cityIndex);
    }
    this.worldClockList = worldClockList;
  }

  onDelete(clockInfo: WorldClockInfo) {
    LogUtil.info(TAG, ' the delete worldClockId:' + clockInfo.id);
    this.deleteList.add(clockInfo);
    this.deleteIdList.add(clockInfo.id as string);
    LogUtil.info(TAG, ' the deleteIdList size:' + this.deleteIdList.size);
    this.worldClockList = this.worldClockList.filter(item =>!this.deleteIdList.has(item.id as string));
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_CITY_DEL)
  }

  @Builder
  pixelMapBuilder(cityInfo: WorldClockInfo) {
    Column() {
      WorldCityCard({
        cityInfo: cityInfo,
      })
    }
  }

  @Builder
  buildConfirmOperation() {
    Row() {
      Image($r('app.media.ic_confirm'))
        .id('id_cityConfirm_img')
        .fillColor($r('sys.color.icon_primary'))
        .appBarIconBtn()
        .draggable(false)
        .onClick(async () => {
          let delList = Array.from(this.deleteList)
          if (this.isChanged) {
            for (let item of this.updateList) {
              await WorldClockManager.updateWorldClock(item);
            }
          }
          for (let item of delList) {
            await WorldClockManager.removeWorldClock(item);
          }
          // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_EDIT_CONFIRM)
          router.back();
        })
    }
    .justifyContent(FlexAlign.Center)
    // .padding($r('app.float.button_icon_hover_padding'))
    .borderRadius($r('app.float.new_button_size'))
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .width($r('app.float.new_button_size'))
    .height($r('app.float.new_button_size'))
    .onHover((isHover) => {
      this.hoverBackgroundInfo = this.handleImageHoverEvent(isHover as boolean);
    })
  }

  private doCancel(): void {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_EDIT_CANCEL)
    router.back();
  }

  @Builder
  buildPage() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        TitleBar({
          title: (GlobalContext.getContext()
            .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('sort_city_title_new'),
          onIconClick: () => this.doCancel(),
          iconResource: $r('app.media.ic_cancel'),
          isHoverInfo: true,
          operationArea: (): void => this.buildConfirmOperation(),
        })
      }
      .flexShrink(TITLE_FLEX_SHRINK)

      List({ initialIndex: 0, scroller: this.scroller }) {
        ForEach(this.worldClockList, (item: WorldClockInfo) => {
          ListItem() {
            WorldCityCard({
              cityInfo: item,
              onDelete: (): void => this.onDelete(item),
            })
              .animation({ curve: Curve.Sharp, duration: 100 })
          }
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.IDENTITY,
              TransitionEffect.scale({ x: 1, y: 1 })
                .animation({ curve: Curve.Friction, duration: 100 })
                .combine(
                  TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 100 })
                )
            )
          )
          .scale({ x: this.scaleSelect(item.cityIndex), y: this.scaleSelect(item.cityIndex) })
          .zIndex(this.dragItem == item.cityIndex ? 1 : 0)
          .translate(this.dragItem == item.cityIndex ? { y: this.offsetY } : { y: 0 })
          .editable(true)
          .gesture(
            // 以下组合手势为顺序识别，当长按手势事件未正常触发时则不会触发拖动手势事件
            GestureGroup(GestureMode.Sequence,
              LongPressGesture({ repeat: true })
                .onAction((event?: GestureEvent) => {
                  animateTo({ curve: Curve.Friction, duration: 300 }, () => {
                    this.scaleIndex = item.cityIndex;
                  })
                })
                .onActionEnd(() => {
                  animateTo({ curve: Curve.Friction, duration: 300 }, () => {
                    this.scaleIndex = null;
                  })
                }),
              PanGesture()
                .onActionStart(() => {
                  this.dragItem = item.cityIndex;
                  this.dragRefOffset = 0;
                })
                .onActionUpdate((event: GestureEvent) => {
                  this.offsetY = event.offsetY - this.dragRefOffset;
                  LogUtil.info(TAG, 'Y:' + this.offsetY.toString());
                  this.neighborIndex = null;
                  let info = this.worldClockList.indexOf(item);
                  this.neighborUpIndex = this.worldClockList[info - 1];
                  this.neighborDownIndex = this.worldClockList[info + 1];
                  if (this.offsetY < 0 && this.neighborUpIndex != null) {
                    this.neighborIndex = this.neighborUpIndex.cityIndex;
                    this.neighborScale = 1 - (-this.offsetY) / (this.ITEM_INTV / 2) / 20;
                    LogUtil.info(TAG, 'neighborScaleup:' + this.neighborScale.toString());
                  } else if (this.offsetY > 0 && this.neighborDownIndex != null) {
                    this.neighborIndex = this.neighborDownIndex.cityIndex;
                    this.neighborScale = 1 - (this.offsetY) / (this.ITEM_INTV / 2) / 20;
                    LogUtil.info(TAG, 'neighborScaledown:' + this.neighborScale.toString());
                  }
                  if (this.offsetY > this.ITEM_INTV && this.neighborDownIndex != null) {
                    this.offsetY -= this.ITEM_INTV;
                    this.dragRefOffset += this.ITEM_INTV;
                    this.isChanged = true
                    this.itemMove(info, info + 1);
                  } else if (this.offsetY < -this.ITEM_INTV && this.neighborUpIndex != null) {
                    this.offsetY += this.ITEM_INTV;
                    this.dragRefOffset -= this.ITEM_INTV;
                    this.isChanged = true
                    this.itemMove(info, info - 1);
                  }
                })
                .onActionEnd((event: GestureEvent) => {
                  animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
                    this.dragItem = '';
                  })
                  animateTo({
                    curve: curves.interpolatingSpring(14, 1, 170, 17), delay: 150
                  }, () => {
                    this.scaleIndex = null;
                  })
                  animateTo({
                    curve: Curve.Sharp, duration: 300
                  }, () => {
                    this.neighborIndex = null;
                  })
                })
            )
              .onCancel(() => {
                animateTo({ curve: curves.interpolatingSpring(0, 1, 400, 38) }, () => {
                  this.dragItem = '';
                })
                animateTo({
                  curve: curves.interpolatingSpring(14, 1, 170, 17), delay: 150
                }, () => {
                  this.scaleIndex = '';
                })
              })
          )
        }, (item: WorldClockInfo) => JSON.stringify(item))
      }
      .padding(this.currentBreakpoint === BreakPoint.MD ? {
        left: $r('app.float.word_padding_left'),
        right: $r('app.float.word_padding_right')
      } : {})
      .height('100%')
      .backgroundColor($r('sys.color.ohos_id_background_secondary'))
      .onScroll((offset: number) => {
        this.dragRefOffset -= offset;
        this.offsetY += offset;
      })
      .onTouch((event: TouchEvent) => {
        if (event.type == TouchType.Move) {
          LogUtil.info(TAG, 'y:' + event.touches[0].y.toString());
          if (event.touches[0].y < 66) {
            this.scroller.scrollTo({
              xOffset: 0,
              yOffset: 0,
              animation: { duration: 2000, curve: Curve.Linear }
            });
          } else if (event.touches[0].y > 645) {
            this.scroller.scrollTo({
              xOffset: 0,
              yOffset: this.worldClockList.length * this.ITEM_INTV,
              animation: { duration: 3000, curve: Curve.Linear }
            });
          }
        }
      })
    }

  }

  build() {
    if (this.deviceType == '2in1') {
      NavDestination() {
        this.buildPage()
      }
      .hideTitleBar(true)
      .backgroundColor(Color.Transparent)
      .height($r('app.float.nav_destination_height'))
      .constraintSize({
        maxHeight: '90%'
      })
    } else {
      this.buildPage()
    }

  }
}