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

import commonEventManager from '@ohos.commonEventManager';
import i18n from '@ohos.i18n';
import Intl from '@ohos.intl';
import router from '@ohos.router';
import emitter from '@ohos.events.emitter';
import {
  AddButton,
  Clock,
  CommonGrid,
  EVENT_ID_CHANGE_WORLD_CLOCK,
  EventName,
  EventReportUtil,
  GlobalContext,
  LogUtil,
  TimeUtil,
  BreakPoint,
  ButtonSize,
  EVENT_ID_WORLDCLOCK_FORPC
} from '@hmos/common';
import { MANAGE_EDIT_WORLD_CLOCK_PC } from '../utils/index'
import { WorldClockCard } from '../components/WorldClockCard';
import { WorldClockInfo } from '../manager/types';
import { WorldClockManager } from '../manager';
// import dataShare from '@ohos.data.dataShare';
import settings from '@ohos.settings';
import { BusinessError } from '@ohos.base';
import deviceInfo from '@ohos.deviceInfo'
// import hiSysEvent from '@ohos.hiSysEvent';

interface ICustomMenuItem extends MenuItemOptions {
  key: string;
}

interface ItemInfo {
  id: number,
  sortOrder: number,
  cityIndex: string,
  timezone: string,
  city: string,
  offset: string,
  tag?: string
}

const TAG = 'WorldClock';
const EDIT_CITIES_PAGE = 'pages/EditCities';
const LONG_PRESS_DURATION = 500;
const TIME_SUBSCRIBE_INFO: CommonEventSubscribeInfo = {
  events: [
    commonEventManager.Support.COMMON_EVENT_TIME_CHANGED,
    commonEventManager.Support.COMMON_EVENT_TIMEZONE_CHANGED,
    commonEventManager.Support.COMMON_EVENT_TIME_TICK,
  ],
};

// This type is not exported from @ohos.commonEvent, so we get it by exported function.
type CommonEventSubscriber = commonEventManager.CommonEventSubscriber;
type CommonEventSubscribeInfo = commonEventManager.CommonEventSubscribeInfo;
const MAX_HEAD_ANGLE: number = 17;
const BODY_HEAD_CRITICAL_ANGLE: number = 12;
const MAX_BODY_ANGLE: number = 10;
const DELETE_SWIPE_HEAD_WIDTH: number = 56;
const DELETE_SWIPE_BODY_WIDTH: number = 123;
const ANGLE_RADIO: number = 10;

/**
 * Main page for world clock
 *
 * @since 2022-09-26
 */
@Component
struct ButtonForAdd {
  @State isLarge: Boolean = false

  @Styles
  normalButtonStyle() {
    .backgroundColor($r('sys.color.ohos_id_container_color_active'))
  }

  @Styles
  pressedButtonStyle() {
    .backgroundColor($r('sys.color.interactive_click'))
  }

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image($r('app.media.ic_add'))
        .width($r('app.float.button_icon_size'))
        .height($r('app.float.button_icon_size'))
        .draggable(false)
    }
    .id('id_add_button')
    .backgroundColor($r('app.color.add_button_color'))
    .width($r('app.float.button_size'))
    .height($r('app.float.button_size'))
    .stateStyles({
      normal: this.normalButtonStyle,
      pressed: this.pressedButtonStyle,
    })
  }

  // .margin({ bottom: $r('app.float.appbar_icon_margin') })


}

@Component
export struct WorldClock {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = '';
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  @Link @Watch('refreshTimeInfo') worldClockList: WorldClockInfo[];
  @State isDateTypeClock: boolean = i18n.System.is24HourClock();
  @Consume('pageInfos') pageInfos: NavPathStack;
  @StorageProp('setOrientaion') getOrientaion: number = 0;
  @State itemContextMenuData: Array<ICustomMenuItem> = [{ key: 'del', content: $r('app.string.alarm_tips_del') }, {
    key: 'edit',
    content: $r('app.string.alarm_tips_title')
  }];
  @Prop isPortraitOrientation: boolean = true; //纵向 true 横向 false
  @State isChanged: boolean = false;
  @State isClockHide: boolean = false;
  @State isHourSystemChanged: boolean = false;
  @State clockDiameter: number = 0;
  @State headAngle: number = 0;
  @State bodyAngle: number = 0;
  @State swipeScale: number = 1;
  @State deleteWorldClockId?: string = '';
  @State deviceType: string = deviceInfo.deviceType;
  @Prop isWorldClockVisible: boolean = true;
  private timeSubscriber: CommonEventSubscriber = {} as CommonEventSubscriber;
  @State private currentDateAndWeek: string = '';
  @State private timeZone: string = '';
  @State private keyEvent: string = '';
  @State private worldListLastId: string | undefined = '';
  @State listIndexCache: number = 0;
  @State isAlarm: boolean = false;
  private scrollerForList: Scroller = new Scroller();
  private scrollerForScroll: Scroller = new Scroller();
  // private dataShareHelper: dataShare.DataShareHelper = {} as dataShare.DataShareHelper;
  private uri: string = 'datashare:///com.ohos.settingsdata/entry/settingsdata/SETTINGSDATA?Proxy=true&key=' + settings.date.TIME_FORMAT;
  private isFoldCross: number = 2224;
  private isFoldVertical: number = 2496;
  private isTablePad: string = 'tablet'

  async aboutToAppear(): Promise<void> {
    LogUtil.info(TAG, 'about to appear');
    this.deviceType = deviceInfo.deviceType
    await this.refreshTimeInfo()
    this.subscribeEvents();
    this.subscribeDataBaseShare();
    this.isChanged = !this.isChanged;
    emitter.on({
      eventId: EVENT_ID_WORLDCLOCK_FORPC,
    }, (target) => {
      let arr: WorldClockInfo[] = target.data?.idString !== '' ? this.getArrDiff(target.data?.idString.split(','), this.worldClockList) : [];
      this.worldClockList = arr
    });

  }

  getArrDiff(arr1: number[], arr2: WorldClockInfo[]) {
    let result: WorldClockInfo[] = [];
    for (let i = 0; i < arr1.length; i++) {
      let obj: WorldClockInfo = arr2.filter(item => item.id == arr1[i].toString())[0]
      result.push(obj)
    }
    return result
  }

  async aboutToDisappear(): Promise<void> {
    this.unSubscribeEvents();
    this.unSubscribeDataBaseShare();
  }

  /**
   * refresh Time Info
   */
  async refreshTimeInfo(): Promise<void> {
    const timeZoneId = i18n.getTimeZone().getID();
    const locale = new Intl.Locale(i18n.System.getSystemLanguage());
    this.timeZone = i18n.getTimeZone(timeZoneId).getDisplayName(locale.toString());
    this.currentDateAndWeek = TimeUtil.getCurrentFormattedDateWithWeek();
    this.worldListLastId = this.worldClockList.length > 0 ? this.worldClockList[this.worldClockList.length - 1].id : ''
  }

  /**
   * Subscribe events, used to refresh the page
   */
  private async subscribeEvents(): Promise<void> {
    // Create a subscriber and subscribe to time-change event.
    LogUtil.info(TAG, 'createSubscriber');
    this.timeSubscriber = await commonEventManager.createSubscriber(TIME_SUBSCRIBE_INFO);
    if (!this.timeSubscriber) {
      return;
    }
    commonEventManager.subscribe(this.timeSubscriber, (error, data) => {
      if (error) {
        LogUtil.error(TAG, 'time changed error:' + JSON.stringify(error));
      } else {
        if (data && data.event.indexOf('usual.event.TIME_CHANGED') !== -1) {
          LogUtil.info(TAG, 'data.event: ' + data.event)
          this.isHourSystemChanged = !this.isHourSystemChanged;
          this.refreshTimeInfo()
        } else {
          this.isChanged = !this.isChanged;
          this.refreshTimeInfo()
        }
      }
    });
  }

  /**
   * Unsubscribe events
   */
  private unSubscribeEvents(): void {
    commonEventManager.unsubscribe(this.timeSubscriber, error => {
      if (error) {
        LogUtil.error(TAG, 'Unsubscribe to time-change event failed because: ', error.message);
        return;
      }
      LogUtil.info(TAG, 'Unsubscribe to time-change event successfully!');
    });
  }

  /**
   * Subscribe DataBaseShare, used to refresh the page
   */
  private async subscribeDataBaseShare(): Promise<void> {
    LogUtil.info(TAG, 'subscribeDataBaseShare');
    // try {
    //   dataShare.createDataShareHelper((GlobalContext.getContext().getObject('clockContext') as Context), this.uri)
    //     .then((data: dataShare.DataShareHelper) => {
    //       LogUtil.info(TAG, 'createDataShareHelper succeed');
    //       this.dataShareHelper = data;
    //       this.dataShareHelper.on('dataChange', this.uri, () => {
    //         this.isDateTypeClock = !this.isDateTypeClock
    //         this.isHourSystemChanged = !this.isHourSystemChanged;
    //       });
    //     })
    //     .catch((err: BusinessError) => {
    //       LogUtil.error(TAG, `createDataShareHelper error: code: ${err.code}, message: ${err.message} `);
    //     });
    // } catch (err) {
    //   LogUtil.error(TAG, `createDataShareHelper error: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message} `);
    // }
  }

  /**
   * Unsubscribe DataBaseShare
   */
  private unSubscribeDataBaseShare(): void {
    // this.dataShareHelper.off('dataChange', this.uri, () => {
      LogUtil.info(TAG, 'unSubscribeDataBaseShare');
    // });
  }

  @Builder
  buildClock(): void {
    Row() {
      Clock({
        getOrientaion: this.getOrientaion,
        isPortraitOrientation: this.isPortraitOrientation,
        showBoth: this.deviceType == '2in1' ? true : false
      })
    }
    .transition(TransitionEffect.opacity(1))
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .margin({
      top: this.deviceType == '2in1' ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? $r('app.float.clock_shadow_above_space_32') : '10vp'),
      bottom: this.deviceType == '2in1' ? '' : (this.isPortraitOrientation || this.foldAbleScreen === 1 ? $r('app.float.clock_margin_vertical') : $r('app.float.clock_landscape_no_height')),
    })
  }

  @Builder
  buildTimeInfo(): void {
    Column() {
      if (this.deviceType == '2in1') {
        Row() {
          if (this.worldClockList.length === 0) {
            Text(this.timeZone)
              .fontColor($r('sys.color.icon_secondary'))
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)
              .margin({ right: 10 })
            Text(this.currentDateAndWeek)
              .fontColor($r('sys.color.icon_secondary'))
              .fontSize($r('sys.float.Body_M'))
              .fontWeight(FontWeight.Regular)
          } else {
            Column() {
              Text(this.timeZone)
                .fontColor($r('sys.color.icon_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Regular)
                .margin({ right: 10, bottom: 5 })
              Text(this.currentDateAndWeek)
                .fontColor($r('sys.color.icon_secondary'))
                .fontSize($r('sys.float.Body_M'))
                .fontWeight(FontWeight.Regular)
            }
          }
        }
      } else {
        Row() {
          Text(this.timeZone)
            .fontColor($r('sys.color.ohos_id_color_primary'))
            .fontSize($r('app.float.text_20'))
            .fontWeight(FontWeight.Medium)
        }
        .margin({ bottom: $r('app.float.timezone_margin_bottom') })

        Row() {
          Text(this.currentDateAndWeek)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .fontSize($r('sys.float.ohos_id_text_size_body2'))
            .fontWeight(FontWeight.Regular)
        }
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
    })
    .margin({ bottom: $r('app.float.date_info_margin_bottom') })
  }

  private async dealWorldClockDelete(worldClockInfo: WorldClockInfo): Promise<void> {
    LogUtil.info(TAG, 'start to dealWorldClockDelete id :' + worldClockInfo.id);
    let delIndex = -1;
    this.worldClockList.forEach((item: WorldClockInfo, index: number) => {
      LogUtil.info(TAG, 'worldClockList-' + JSON.stringify(item));
      if (item.id === worldClockInfo.id) {
        delIndex = index;
      }
    })
    LogUtil.info(TAG, 'dealWorldClockDelete for delIndex:' + delIndex);
    if (delIndex !== -1) {
      this.worldClockList.splice(delIndex, 1);
    }
    LogUtil.info(TAG, 'dealWorldClockDelete end');
    WorldClockManager.removeWorldClock(worldClockInfo).then((data) => {
      emitter.emit({
        eventId: EVENT_ID_CHANGE_WORLD_CLOCK,
        priority: emitter.EventPriority.IMMEDIATE,
      })
    });
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CITY_SWIPE_LEFT_DEL)
  }

  @Styles
  buttonStyle() {
    .borderRadius($r('app.float.swipe_image_height_and_width'))
    .height($r('app.float.swipe_button_height_and_width'))
    .width($r('app.float.swipe_button_height_and_width'))
    .margin($r('app.float.swipe_margin_size'))
  }

  @Builder
  renderSwipeAction(worldClockInfo: WorldClockInfo): void {
    Row() {
      Stack() {
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Image($r('app.media.ic_delete_grey'))
            .width($r('app.float.swipe_delete_head_width'))
            .draggable(false)
            .rotate({
              x: 0,
              y: 0,
              z: 1,
              centerX: '100%',
              centerY: '100%',
              angle: this.headAngle,
            })
        }
        .width($r('app.float.swipe_button_height_and_width'))
        .height($r('app.float.swipe_button_height_and_width'))
      }
      .buttonStyle()
      .scale({ x: this.swipeScale, y: this.swipeScale })
      .backgroundColor($r('sys.color.ohos_id_color_warning'))
      .onClick(() => {
        setTimeout(() => {
          if (worldClockInfo.id) {
            this.deleteWorldClockId = worldClockInfo.id;
          }
          if (this.worldClockList.length > 3 && this.foldAbleScreen === 1) {
            this.dealWorldClockDelete(worldClockInfo);
          } else {
            animateTo({
              duration: 350,
              curve: Curve.Friction,
            }, () => {
              this.dealWorldClockDelete(worldClockInfo);
            })
          }
        }, 150)
      })
    }
    .id('id_deleteCity_img')
    .padding(this.foldAbleScreen === 1 && this.worldClockList.length < 4 ? {
      left: 0,
      top: $r('app.float.swipe_margin_size'),
      right: $r('app.float.swipe_padding_size'),
      bottom: $r('app.float.swipe_margin_size')
    } : $r('app.float.swipe_margin_size'))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      let wid = newValue.width;
      this.headAngle = (Number(wid) - DELETE_SWIPE_HEAD_WIDTH) / DELETE_SWIPE_HEAD_WIDTH * ANGLE_RADIO;
      if (this.headAngle <= 0) {
        this.headAngle = 0;
      }
      if (this.headAngle >= MAX_HEAD_ANGLE) {
        this.headAngle = MAX_HEAD_ANGLE;
      }
      if (this.headAngle > BODY_HEAD_CRITICAL_ANGLE) {
        this.swipeScale = 1.05;
        this.bodyAngle = (Number(wid) - DELETE_SWIPE_BODY_WIDTH) / DELETE_SWIPE_BODY_WIDTH * ANGLE_RADIO;
      } else {
        this.bodyAngle = 0;
        this.swipeScale = 1;
      }
      if (this.bodyAngle > MAX_BODY_ANGLE) {
        this.bodyAngle = MAX_BODY_ANGLE;
        this.swipeScale = 1.05;
      }
      this.bodyAngle = (-1) * this.bodyAngle;
    })
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  pcRightControlMenuClickHandle(menuItem: ICustomMenuItem, worldItem: WorldClockInfo) {
    // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.ENTER_ALARM_EDIT_PAGE)
    menuItem.key == 'del' && this.dealWorldClockDelete(worldItem);
    menuItem.key == 'edit' && this.pageInfos.pushPath(new NavPathInfo(MANAGE_EDIT_WORLD_CLOCK_PC, 'unknow'));
  }

  private onScrollParent(yOffset: number): void {
    if (yOffset === 0 || yOffset > 0 && this.isClockHide || yOffset < 0 && !this.isClockHide) {
      return;
    }
    const offset = this.scrollerForScroll.currentOffset();
    LogUtil.info(TAG, `yOffset=${yOffset}  current=${offset.yOffset}`);
    if (yOffset > 0) {
      this.isClockHide = true;
    } else {
      this.isClockHide = false;
    }
  }

  private onScrollStopParent(): void {
    const offset = this.scrollerForScroll.currentOffset();
    LogUtil.info(TAG, `onScrollStop  current=${offset.yOffset} ${this.isClockHide}`);
    if (this.isClockHide) {
      this.scrollerForScroll.scrollEdge(Edge.End);
    } else {
      this.scrollerForScroll.scrollEdge(Edge.Start);
    }
  }

  @Builder
  pcRightControlMenuBuilder(worldItem: WorldClockInfo) {
    Menu() {
      ForEach(this.itemContextMenuData, (item: ICustomMenuItem) => {
        MenuItem({ content: item.content })
          .contentFont({
            size: $r('sys.float.Body_L')
          })
          .onClick(() => this.pcRightControlMenuClickHandle(item, worldItem))
          .borderRadius($r('sys.float.corner_radius_level4'))
      }, (item: MenuItemOptions, index: number) => String(index))
    }
    .width('16.6%')
    .shadow(ShadowStyle.OUTER_DEFAULT_MD)
  }

  @Builder
  listWold(): void {
    ForEach(this.worldClockList, (item: WorldClockInfo) => {
      ListItem() {
        WorldClockCard({
          cityInfo: item,
          isChanged: this.isChanged,
          isHourSystemChanged: this.isHourSystemChanged,
          isLarge: this.deviceType == '2in1' ? true : false,
          cancelDoubleCardMargin: this.foldAbleScreen === 1 && this.worldClockList.length > 3
        })
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
      .margin({
        bottom: (this.deviceType === '2in1' && item.id === this.worldListLastId) || this.worldClockList.length === 1 ? 0 : $r('app.float.card_list_margin')
      })
      .clip(this.deviceType === '2in1' ? false : true)
      .bindContextMenu(this.pcRightControlMenuBuilder(item), ResponseType.RightClick)
      .zIndex(this.deleteWorldClockId === item.id ? 0 : 1)
      .swipeAction(
        {
          edgeEffect: SwipeEdgeEffect.None,
          end: {
            builder: (): void => this.renderSwipeAction(item),
            onAction: () => {
              setTimeout(() => {
                this.deleteWorldClockId = item.id;
                if (this.worldClockList.length > 3 && this.foldAbleScreen === 1) {
                  this.dealWorldClockDelete(item);
                } else {
                  animateTo({
                    duration: 350,
                    curve: Curve.Friction,
                  }, () => {
                    this.dealWorldClockDelete(item);
                  })
                }
              }, 350);
            },
            onEnterActionArea: () => {
              LogUtil.info(TAG, 'List Swipe EnterDeleteArea');
            },
            onExitActionArea: () => {
              LogUtil.info(TAG, 'List Swipe ExitDeleteArea');
            }
          },
        }
      )

      .editable(true)
      .gesture(LongPressGesture({ duration: LONG_PRESS_DURATION })
        .onAction(() => {
          if (this.deviceType !== '2in1') {
            router.pushUrl({ url: EDIT_CITIES_PAGE });
            // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_LONG_PRESS_EDIT)
          }
        })
      )
      .onKeyEvent((e: KeyEvent) => {
        this.keyEvent = e.keyText === 'KEYCODE_ENTER' || e.keyText === 'KEYCODE_SPACE' ? 'enter' : '';
        setTimeout(() => {
          this.keyEvent = ''
        })

        if (e.keyText === 'KEYCODE_TAB' || e.keyText === 'KEYCODE_DPAD_DOWN' || e.keyText === 'KEYCODE_DPAD_UP') {
          const listIndex = this.worldClockList.findIndex(i => item.id === i.id)
          if (listIndex !== this.listIndexCache) {
            this.listIndexCache = listIndex
            // 34=38-4 视口区最后显示一半的列表向上滚动的距离，93每条item滚动高度
            this.scrollerForScroll.scrollTo({
              xOffset: 0,
              yOffset: listIndex > 3 ? (listIndex - 4) * 93 + 33 : 0,
              animation: { duration: 100, curve: Curve.Linear }
            });
          }
        }
      })
      .onClick(() => {
        if (this.keyEvent === 'enter') {
          this.pageInfos.pushPath(new NavPathInfo(MANAGE_EDIT_WORLD_CLOCK_PC, 'unknow'))
          // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.WORLD_CLOCK_LONG_PRESS_EDIT)
        }
      })

    }, (item: WorldClockInfo) => JSON.stringify(item))

    if (this.deviceType !== '2in1') {
      ListItem() {
      }.height($r('app.float.empty_world_list_alarm'))
    }
    if (this.worldClockList.length > 3 && this.foldAbleScreen !== 1 && this.deviceType !== '2in1') {
      ListItem() {
      }.transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY,
          TransitionEffect.scale({ x: 1, y: 1 }).animation({ curve: Curve.Friction, duration: 0 })
            .combine(
              TransitionEffect.OPACITY.animation({ curve: Curve.Sharp, duration: 0 })
            )
        )
      )
    }
  }

  @Builder
  buildWorldClockList(): void {
    List({ initialIndex: 0, scroller: this.scrollerForList }) {
      this.listWold()
    }
    .padding(this.foldAbleScreen === 1 ? {
      left: $r('app.float.word_padding_left'),
      right: $r('app.float.word_padding_right')
    } : {})
    .lanes(this.worldClockList.length > 3 && this.foldAbleScreen === 1 ? 2 : 1, $r('app.float.lans_list_item_10'))
    .listDirection(Axis.Vertical)
    .margin({
      left: $r('app.float.card_margin_start'),
      right: $r('app.float.card_margin_start')
    })
    .clip(false)
    .edgeEffect(EdgeEffect.Spring)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })

  }

  @Builder
  buildWorldClockPcList(): void {
    List({ initialIndex: 0, scroller: this.scrollerForList }) {
      this.listWold()
    }
    .height(this.worldClockList.length >= 5 ? '100%' : '')
    .padding(this.deviceType == '2in1' ? {
      right: $r('app.float.card_margin_start')
    } : (this.currentBreakpoint === BreakPoint.MD ? this.isPortraitOrientation ? {
      left: $r('app.float.word_padding_left'),
      right: $r('app.float.word_padding_right')
    } : this.foldAbleScreen === 1 ?
      this.getOrientaion === this.isFoldCross ? {
        left: $r('app.float.word_padding_left'),
        right: $r('app.float.word_padding_right')
      } :
        {
          left: $r('app.float.fold_cross_padding'),
          right: $r('app.float.fold_cross_padding'),
        } : {} : {}))
    .listDirection(Axis.Vertical)
    .margin(this.deviceType == '2in1' ? { left: $r('app.float.card_margin_start'),
      right: 0 } : {
      left: $r('app.float.card_margin_start'),
      right: $r('app.float.card_margin_start')
    })
    .clip(false)
  }

  @Builder
  buildTimeInfoAndWorldClockList(): void {
    Stack({ alignContent: Alignment.Start }) {
      Flex({ direction: FlexDirection.Column }) {
        this.buildTimeInfo();
      }

      Flex({ direction: FlexDirection.Column }) {
        CommonGrid() {
          this.buildWorldClockList();
        }
      }
      .clip(true)
      .margin({ top: $r('app.float.empty_world_list_alarm') })
    }
    .width('100%')
    .height('97%')
  }

  @Builder
  buildPortrait() { // 纵向
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scrollerForScroll) {
        Column() {
          this.buildClock();
          if (this.worldClockList.length === 0) {
            this.buildTimeInfo();
          } else {
            this.buildTimeInfoAndWorldClockList();
          }
        }
      }
      .scrollBar(BarState.Off)
      .onScroll((_: number, yOffset: number) => this.onScrollParent(yOffset))
      .onScrollStop(() => this.onScrollStopParent())
      .align(Alignment.Top)
      .height('100%')
      .width('100%')

      // AddButton({
      //   alarmFlag: this.isAlarm,
      //   onButtonClick: () => router.pushUrl({ url: 'pages/AddCityNew' })
      //
      // })
      //   .transition(TransitionEffect.opacity(1))
      //   .visibility(this.isWorldClockVisible ? Visibility.Visible : Visibility.Hidden)
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  buildLandscape() { // 横向
    if (this.deviceType == '2in1') {
      Row() {
        Column() {
          this.buildClock();
          this.buildTimeInfo();
        }
        .width(this.worldClockList.length == 0 ? 'calc(100% - 172vp)' : '40%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        Column() {
          Flex({ justifyContent: FlexAlign.Center,
            alignItems: ItemAlign.Center }) {
            if (this.worldClockList.length != 0) {
              Row() {
                Scroll(this.scrollerForScroll) {
                  this.buildWorldClockList();
                }
                .height('100%')
                .edgeEffect(EdgeEffect.Spring)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
              }
            }
            Row() {
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Image($r('app.media.ic_add'))
                  .width($r('app.float.button_icon_size'))
                  .height($r('app.float.button_icon_size'))
                  .draggable(false)
              }
              .id('id_add_button')
              .backgroundColor($r('app.color.color_fab_bg'))
              .width($r('app.float.large_btn_width'))
              .height($r('app.float.large_btn_height'))
              .transition(TransitionEffect.opacity(1))
              .stateStyles({
                // pressed: this.pressedButtonStyle,
              })
              .onClick(() => {
                router.pushUrl({ url: 'pages/AddCityNew' });
              })
            }
            .width($r('app.float.large_btn_wrapper_width'))
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .height('100%')
        }
        .width(this.worldClockList.length == 0 ? $r('app.float.large_btn_wrapper_width') : '60%')
        .height('100%')
      }
      // .width('calc(100% - 96vp)')
      .margin({ left: $r('app.float.large_row_margin_left') })

    } else if (this.deviceType === this.isTablePad) {
      Row() {
        Column() {
          this.buildClock();
          this.buildTimeInfo();
        }
        .width('40%')

        Rect()
          .fill($r('sys.color.comp_divider'))
          .width('1px')
          .height($r('app.float.line_height'))
          .margin({ left: $r('app.float.rect_pad_margin_left') })

        Stack({ alignContent: Alignment.Bottom }) {
          Scroll(this.scrollerForScroll) {
            this.buildWorldClockList();
          }
          .height('100%')
          .edgeEffect(EdgeEffect.Spring)
          .align(Alignment.Top)

          AddButton({
            alarmFlag: this.isAlarm,
            onButtonClick: () => router.pushUrl({ url: 'pages/AddCityNew' })
          })
            .transition(TransitionEffect.opacity(1))
            .visibility(this.isWorldClockVisible ? Visibility.Visible : Visibility.Hidden)
        }
        .width('calc(60% - 19vp)')
      }
      .width('100%')
    } else {
      Row() {
        Column() {
          this.buildClock();
          this.buildTimeInfo();
        }
        .width('40%')

        Rect()
          .fill($r('sys.color.ohos_id_color_list_separator'))
          .width('1px')
          .height($r('app.float.line_height'))
          .margin({ left: $r('app.float.rect_margin_left') })

        Stack({ alignContent: Alignment.Bottom }) {
          Scroll(this.scrollerForScroll) {
            this.buildWorldClockList();
          }
          .height('100%')
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .align(Alignment.Top)

          AddButton({
            alarmFlag: this.isAlarm,
            onButtonClick: () => router.pushUrl({ url: 'pages/AddCityNew' })
          })
            .transition(TransitionEffect.opacity(1))
            .visibility(this.isWorldClockVisible ? Visibility.Visible : Visibility.Hidden)
        }
        .width('60%')
      }
      .width('100%')
    }
  }

  @Builder
  buildPortraitForPC() {
    Row() {
      Column() {
        this.buildClock();
        this.buildTimeInfo()
      }
      .width(this.worldClockList.length === 0 ? '86%' : '40%')
      .padding({
        left: this.worldClockList.length === 0 ? $r('app.float.tool_bar_width_1') : $r('app.float.tool_bar_width'),
      })

      Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
        if (this.worldClockList.length != 0) {
          Scroll(this.scrollerForScroll) {
            this.buildWorldClockPcList();
          }
          .height(this.deviceType == '2in1' ? '76%' : '100%')
          .align(this.deviceType == '2in1' ? Alignment.Center : Alignment.Top)
          .edgeEffect(EdgeEffect.Spring)
          .flexBasis(50)
          .flexGrow(10)
          .padding({
            top: $r('app.float.pc_list_scroll_padding'),
            bottom: $r('app.float.pc_list_scroll_padding')
          })
        }
        Flex({ alignItems: ItemAlign.Center, direction: FlexDirection.Row, justifyContent: FlexAlign.Center }) {
          AddButton({
            alarmFlag: this.isAlarm,
            buttonSize: ButtonSize.LARGER,
            onButtonClick: (): void => {
              router.push({ url: 'pages/AddCityNew' });
            },
          })
            .transition(TransitionEffect.opacity(1))
            .visibility(this.isWorldClockVisible ? Visibility.Visible : Visibility.Hidden)
        }
        .flexBasis(50)
        .flexGrow(1)
        .padding({
          left: $r('app.float.pc_padding'),
          right: $r('app.float.pc_padding')
        })
      }
      .width(this.worldClockList.length === 0 ? '14%' : '60%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.deviceType == '2in1') {
      this.buildPortraitForPC()

    } else {
      if (this.isPortraitOrientation || this.foldAbleScreen === 1) {
        this.buildPortrait()
      } else {
        this.buildLandscape();
      }
    }

  }
}

