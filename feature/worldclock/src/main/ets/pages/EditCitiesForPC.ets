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
// import hiSysEvent from '@ohos.hiSysEvent';
import resmgr from '@ohos.resourceManager';
import {
  EventName,
  EventReportUtil,
  GlobalContext,
  LogUtil,
  TitleBar,
  BreakPoint,
  CommonGrid,
  EVENT_ID_WORLDCLOCK_FORPC,
  EVENT_ID_CHANGE_WORLD_CLOCK
} from '@hmos/common';
import { WorldCityCard } from '../components/WorldCityCard';
import { WorldClockInfo } from '../manager/types';
import { WorldClockManager } from '../manager';
import { WorldClockUtil } from '../utils/WorldClockUtil';
import curves from '@ohos.curves';
import deviceInfo from '@ohos.deviceInfo'
import emitter from '@ohos.events.emitter';

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
const TITLE_FLEX_SHRINK = 1; // Keep the origin height of title in flex layout


/**
 * Page: Edit world cities
 *
 * @since 2022-09-28
 */
@Component
export struct EditCitiesForPC {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = '';
  @State listPosition: number = 0; // 0代表滚动到List顶部，1代表中间值，2代表滚动到List底部。
  @State worldClockList: WorldClockInfo[] = [];
  @State updateList: WorldClockInfo[] = [];
  @State isDrag: boolean = false;
  @State scaleIndex: string = '';
  @State idString: string = ''
  @State dragItem: string = '';
  @State neighborIndex: string = '';
  @State deviceType: string = deviceInfo.deviceType;
  @Consume('pageInfos') pageInfos: NavPathStack;
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
  @State hoverBackgroundInfo: Resource = $r('sys.color.interactive_hover');
  @State listIndexCache: number = 0;
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
    this.idString = this.updateList.map(item => item.id).toString()
  }

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
    this.idString = this.worldClockList.map(item => item.id).toString()
  }

  onDelete(clockInfo: WorldClockInfo) {
    LogUtil.info(TAG, ' the delete worldClockId:' + clockInfo.id);
    this.deleteList.add(clockInfo);
    this.deleteIdList.add(clockInfo.id as string);
    LogUtil.info(TAG, ' the deleteIdList size:' + this.deleteIdList.size);
    this.worldClockList = this.worldClockList.filter(item =>!this.deleteIdList.has(item.id as string));
    this.idString = this.worldClockList.map(item => item.id).toString()
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
        .fillColor($r('sys.color.icon_primary'))
        .appBarIconBtn()
        .draggable(false)
        .focusable(true)
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
          if (this.deviceType == '2in1') {
            emitter.emit({
              eventId: EVENT_ID_WORLDCLOCK_FORPC,
              priority: emitter.EventPriority.IMMEDIATE,
            }, {
              data: {
                idString: this.idString
              }
            })
            emitter.emit({
              eventId: EVENT_ID_CHANGE_WORLD_CLOCK,
              priority: emitter.EventPriority.IMMEDIATE,
            })
            this.pageInfos.pop();
          } else {
            router.back()
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .borderRadius($r('app.float.dial_shadow_radius'))
    .backgroundColor(this.hoverBackgroundInfo)
    .width($r('app.float.pc_button_size'))
    .height($r('app.float.pc_button_size'))
    .onMouse((event) => {
      if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
        this.hoverBackgroundInfo = $r('sys.color.interactive_click');
      } else if (event?.action === MouseAction.Release) {
        this.hoverBackgroundInfo = $r('sys.color.interactive_hover');
      }
    })
  }

  private doCancel(): void {
    // EventReportUtil.write(EventName.WORLD_CLOCK_EDIT_CANCEL, hiAppEvent.EventType.BEHAVIOR, {
    //   'result': EventResult.WORLD_CLOCK_EDIT_CANCEL });
    if (this.deviceType == '2in1') {
      this.pageInfos.pop();
    } else {
      router.back()
    }

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
          isFocusAble: true,
          operationArea: (): void => this.buildConfirmOperation(),
        })
      }
      .flexShrink(TITLE_FLEX_SHRINK)

      CommonGrid({ lg8: true }) {
        List({ initialIndex: 0, scroller: this.scroller }) {
          ForEach(this.worldClockList, (item: WorldClockInfo) => {
            ListItem() {
              WorldCityCard({
                cityInfo: item,
                onDelete: (): void => this.onDelete(item),
                isLarge: this.deviceType == '2in1' ? true : false,
                isGrid: false,
                isPCView: this.deviceType == '2in1'
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
            .padding({
              left: $r('app.float.world_city_list_item_padding'),
              right: $r('app.float.world_city_list_item_padding')
            })
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
                      const scale = 1 - (-this.offsetY) / (this.ITEM_INTV / 2) / 20;
                      this.neighborScale = scale < 0.94 ? 0.94 : scale
                      LogUtil.info(TAG, 'neighborScaleup:' + this.neighborScale.toString());
                    } else if (this.offsetY > 0 && this.neighborDownIndex != null) {
                      this.neighborIndex = this.neighborDownIndex.cityIndex;
                      const scale = 1 - (this.offsetY) / (this.ITEM_INTV / 2) / 20;
                      this.neighborScale = scale < 0.94 ? 0.94 : scale
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
            .onKeyEvent((e: KeyEvent) => {
              if (e.keyText === 'KEYCODE_TAB' || e.keyText === 'KEYCODE_DPAD_DOWN' || e.keyText === 'KEYCODE_DPAD_UP') {
                const listIndex = this.worldClockList.findIndex(i => item.id === i.id)
                if (listIndex !== this.listIndexCache) {
                  this.listIndexCache = listIndex
                  // 48 视口区最后显示一半的列表向上滚动的距离，94.2每条item滚动高度
                  this.scroller.scrollTo({
                    xOffset: 0,
                    yOffset: listIndex > 5 ? (listIndex - 6) * 92 + 48 : 0,
                    animation: { duration: 100, curve: Curve.Linear }
                  });
                }
              }
            })
          }, (item: WorldClockInfo) => JSON.stringify(item))
        }
        .padding(this.currentBreakpoint === BreakPoint.MD ? {
          left: $r('app.float.word_padding_left'),
          right: $r('app.float.word_padding_right')
        } : {})
        .height('100%')
        .backgroundColor($r('sys.color.background_secondary'))
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
            } else if (event.touches[0].y > 565) {
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
    .backgroundColor($r('sys.color.ohos_id_background_secondary'))
  }

  build() {
    if (this.deviceType == '2in1') {
      NavDestination() {
        this.buildPage()
      }
      .hideTitleBar(true)
      .backgroundColor(Color.Transparent)
      .margin({ bottom: $r('app.float.world_edit_bottom_margin') })
      .constraintSize({
        maxHeight: '90%'
      })
    } else {
      this.buildPage()
    }

  }
}