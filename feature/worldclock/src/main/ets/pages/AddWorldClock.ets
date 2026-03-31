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

/*
 *
 *  世界时钟-添加城市
 *
 * */

import { LogUtil, } from '@hmos/common';
import I18n from '@ohos.i18n';
import router from '@ohos.router';
import TimeZoneTaskPoolManager from '../manager/TimeZoneTaskPoolManager';
import taskpool from '@ohos.taskpool';
import deviceInfo from '@ohos.deviceInfo'
import { MyDataSource, TimeZoneUtil, cityInfo, Obj } from './TimeZoneUtil'
import { TsUtilManager } from '@hmos/common'
import { WordClockTsUtil } from '../utils/WorldClockTsUtil';

const TAG = 'World Clock Add City'
const FIRST_LOAD_NUMBER: number = 50; //先计算50条
const TABLE_PAD = 2560;

@Concurrent
function getTimeZoneExtensionInfoAsync(locale: string, isFirstLoading: boolean, firstLoadNum: number): Array<cityInfo> {
  return TimeZoneTaskPoolManager.getTimeZoneInfo(locale, isFirstLoading, firstLoadNum);
}

@Component
export struct AddWorldClock {
  @State pageTitle: Resource = $r('app.string.add_page_title');
  @State num: number = 1;
  @State value: string[] = ['#', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    'V', 'W', 'X', 'Y', 'Z'];
  @State tabletList: string[] = ['A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U',
    'V', 'W', 'X', 'Y', 'Z'];
  @State objs: Obj = {};
  @State @Watch('selectTop') select: string = '';
  @State selectedItem: cityInfo = {
    zoneId: '',
    cityId: '',
    cityDisplayName: '',
    offset: 0,
    zoneDisplayName: '',
    rawOffset: 0
  }
  @State isSelected: boolean = false;
  @State confirmBackground: Resource = $r('sys.color.comp_background_tertiary');
  @State cityList: Array<cityInfo> = []
  @State @Watch('change') scrollDistance?: number = -1;
  @StorageProp('addCityWorldPortrait') isPortraitOrientation: boolean = true;
  @State deviceType: string = deviceInfo.deviceType;
  @State isPC: boolean = false
  @State isHover: boolean = false;
  @StorageProp('currentAbleScreen') foldState: number = -1
  flag: boolean = true;
  flags: boolean = false;
  isFirstLoading: boolean = true;
  scroller: Scroller = new Scroller;
  private data: MyDataSource = new MyDataSource();

  @Styles
  normalStateIconStyles()
  {
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
  }

  @Styles
  pressedSecondStateIconStyles()
  {
    .backgroundColor(null)
    .borderRadius('8vp')
  }

  @Styles
  pressedStateIconStyles()
  {
    .backgroundColor($r('app.color.pressed_state_icon_background_color'))
  }

  @Styles
  normalSecondStateIconStyles()
  {
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
  }

  private portraitLisener() {
    LogUtil.error('isPortraitOrientation ' + (this.isPortraitOrientation))
  }

  private onTouchEvent(event: TouchEvent): void {
    this.isSelected = true
    if (event.type === TouchType.Down || event.type === TouchType.Up) {
      this.isSelected = false;
    }
  }

  private getBackgroundColor(): ResourceColor {
    if (this.isSelected) {
      return $r('app.color.color_hover_shadow');
    }
    return $r('app.color.transparent');
  }

  private updateHover(isHover: boolean): boolean {
    return isHover;
  }

  private onMouseEvent(event: MouseEvent): void {
    if (event.button === MouseButton.Left && event.action === MouseAction.Press) {
      this.isSelected = true;
    } else if (event.button === MouseButton.Left && event.action === MouseAction.Release) {
      this.isSelected = false;
    }
  }

  async aboutToAppear() {
    LogUtil.info(TAG + 'add world city page ~')
    this.deviceType = deviceInfo.deviceType
    if (this.deviceType === '2in1') {
      this.isPC = true
    }
    await this.loadTimeZoneCityList();
  }

  change(): void {
    this.scroller?.scrollToIndex(this.scrollDistance);
    this.scrollDistance = -1;
  }

  selectTop() {
    this.num = this.value.indexOf(this.select);
  }

  computeTaskAsync() {
    setTimeout(() => { // 这里使用setTimeout来实现异步延迟运行
      this.loadTimeZoneCityList();
    }, 15)
  }

  async loadTimeZoneCityList(): Promise<void> {
    let locale: string = TimeZoneUtil.getSystemLanguage();
    // 第一次加载 只计算前50条的时间
    let task: taskpool.Task = new taskpool.Task(getTimeZoneExtensionInfoAsync, locale, true, FIRST_LOAD_NUMBER);
    try {
      this.cityList = await taskpool.execute(task, taskpool.Priority.MEDIUM) as Array<cityInfo>;
      this.cityList.forEach((item: cityInfo) => {
        this.data.pushData(item)
      })
    } catch (e) {
      LogUtil.error(TAG, `catch exception when getTimeZoneExtensionInfoAsync [first loading], errmsg: ${JSON.stringify(e)}`);
    }
    if (this.cityList.length < 1) {
      LogUtil.error(TAG, `get timeZoneInfoObject [first loading] failed`);
      return;
    }
    LogUtil.info(TAG, `get timeZoneInfoObject ${JSON.stringify(this.cityList.length)}`);

    if (FIRST_LOAD_NUMBER < this.cityList.length) {
      task = new taskpool.Task(getTimeZoneExtensionInfoAsync, locale, false, FIRST_LOAD_NUMBER);
      try {
        this.cityList = await taskpool.execute(task, taskpool.Priority.MEDIUM) as Array<cityInfo>;
        this.data.refreshData(this.cityList)
      } catch (e) {
        LogUtil.error(TAG, `catch exception when getTimeZoneExtensionInfoAsync [second loading], errmsg: ${JSON.stringify(e)}`);
      }
      if (this.cityList.length < 1) {
        LogUtil.error(TAG, `get timeZoneInfoObject [first loading] failed`);
        return;
      }
    }
  }

  indexerSelect(index: number) {
    if (this.value[index] == '#') {
      this.scrollDistance = 0;
      setTimeout(() => {
        this.select = '#';
      }, 50)
    } else if (this.value[index] === 'A') {
      this.scrollDistance = 0;
    } else if (this.value[index] === 'Z') {
      this.scrollDistance = this.objs?.Z as number;
      setTimeout(() => {
        this.select = 'Z';
      }, 50)
    } else {
      this.tabletList.forEach((tablet) => {
        if (this.value[index] === tablet) {
          this.scrollDistance = WordClockTsUtil.transIndexerSelect(this.objs, tablet)
        }
      })
    }
  }

  handleScroll(start: number) {
    let pinyin = I18n.Transliterator.getInstance('Han-Latin');
    let str = this.cityList[start].cityDisplayName;
    let res = pinyin.transform(str as string);
    let pinyins = I18n.Transliterator.getInstance('Latin-ASCII');
    let res1 = '';
    let obj: Obj = {};
    if (this.flag) {
      this.flag = false;
      for (let i = 0; i < this.cityList.length; i++) {
        let k = '';
        if (this.cityList[i].cityDisplayName === '长春 (中国)' || this.cityList[i].cityDisplayName === '长沙 (中国)') {
          k = 'C';
        } else {
          let head = pinyin.transform(this.cityList[i].cityDisplayName as string);
          let heads = pinyins.transform(head);
          k = heads[0].toLocaleUpperCase();
        }
        this.getTabletDistance(k, obj, i)
      }
      this.objs = obj;
    }
    if (str === '长春 (中国)' || str === '长沙 (中国)') {
      this.select = 'C';
    } else {
      if (this.flags) {
        this.select = res1[0].toLocaleUpperCase();
      } else {
        this.flags = true;
      }
    }
  }

  handleSelect(city: cityInfo): void {
    if (!city) {
      return
    }
    // LogUtil.info(TAG, 'select city is ' + city.cityDisplayName + '=>' + JSON.stringify(city))
    // AppStorage.SetOrCreate<string>('cityId', city.cityId);
    router.back()
  }

  getTabletDistance(k: string, obj: Obj, i: number): void {
    for (const tablet of this.tabletList) {
      if (k === tablet && !TsUtilManager.getItsProperty(obj, tablet)) {
        WordClockTsUtil.transHandleScroll(tablet, k, obj, i)
      }
    }
  }

  @Builder
  titleBar() {
    Row() {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.ic_back_night'))
            .fillColor($r('sys.color.comp_foreground_primary'))
            .width($r('app.float.dialog_padding_horizontal'))
            .height($r('app.float.dialog_padding_horizontal'))
            .draggable(false);
        }
        .width($r('app.float.header_textHeight'))
        .height($r('app.float.header_textHeight'))
        .hoverEffect(HoverEffect.Highlight)
        .margin({ right: $r('sys.float.padding_level4') })
        .flexGrow(0)
        .flexShrink(0)
        .align(Alignment.Center)
        .onClick(() => {
          router.back();
        });
      }

      Column() {
        Text(this.pageTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .align(Alignment.Start)
    }
    .width('100%')
    .height($r('app.float.add_city_title_height'))
    .padding({
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4'),
    })
    .justifyContent(FlexAlign.Start)
    .margin({
      bottom: $r('app.float.world_edit_bottom_margin'),
    })
  }

  @Builder
  LazyForEachContent() {
    LazyForEach(this.data, (item: cityInfo) => {
      ListItem() {
        Column() {
          Text(item.cityDisplayName)
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: '2vp' })
          Text(item.settingSummary)
            .fontColor($r('sys.color.font_primary'))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Regular)
            .margin({
              top: $r('app.float.card_title_line_margin')
            })
            .width('100%')
          Divider().margin({ top: 10 })
        }
        .onTouch((event?: TouchEvent): void => {
          event && this.onTouchEvent(event);
        })
        .onHover((isHover) => {
          isHover = isHover ? true : false;
          this.isHover = this.updateHover(isHover);
        })
        .onMouse((event?: MouseEvent): void => {
          event && this.onMouseEvent(event);
        })
        .onClick(() => {
          this.handleSelect(item)
        })
        .borderRadius($r('app.float.swipe_image_height_and_width'))
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Start)
        .hoverEffect(HoverEffect.Highlight)
        .padding({
          top: $r('app.float.card_content_text_margin_top_11'),
          left: $r('app.float.card_content_text_margin_top_8'),
          right: $r('app.float.card_content_text_margin_top_8')
        })
      }
      .width('100%')
      .borderRadius($r('app.float.swipe_image_height_and_width'))
    }, (item: cityInfo) => {
      return `${item.cityDisplayName?.toString()} + ${item.settingSummary?.toString()}`;
    })
  }

  @Builder
  WhiteCardForPC() {
    Column() {
      List({ initialIndex: 0, scroller: this.scroller }) {
        this.LazyForEachContent()
      }
      .cachedCount(5)
      .width('100%')
      .height('100%')
      .padding($r('app.float.white_card_padding'))
      .scrollBar(BarState.Off)
      .onScrollIndex((start: number, end: number) => {
        this.handleScroll(start)
      })

    }
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .height('90%')
    .borderRadius(20)
    .margin({
      left: $r('app.float.appbar_icon_margin'),
      right: $r('sys.float.padding_level12')
    })
  }

  @Builder
  WhiteCard() {
    Column() {
      List({ initialIndex: 0, scroller: this.scroller }) {
        LazyForEach(this.data, (item: cityInfo) => {
          ListItem() {
            Column() {
              Text(item.cityDisplayName)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .fontSize($r('sys.float.ohos_id_text_size_body1'))
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: '2vp' })
              Text(item.settingSummary)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Regular)
                .margin({
                  top: $r('app.float.card_title_line_margin')
                })
                .width('100%')
              Divider().margin({ top: 10 })
            }
            .onTouch((event?: TouchEvent): void => {
              if (event) {
                this.onTouchEvent(event);
              }
            })
            .onHover((isHover) => {
              isHover = isHover ? true : false;
              this.isHover = this.updateHover(isHover);
            })
            .onMouse((event?: MouseEvent): void => {
              if (event) {
                this.onMouseEvent(event);
              }
            })
            .onClick(() => {
              LogUtil.info(TAG, 'select city is ' + item.cityDisplayName + '=>' + JSON.stringify(item))
              AppStorage.SetOrCreate<string>('cityId', item.cityId);
              router.back()
            })
            .borderRadius($r('app.float.swipe_image_height_and_width'))
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Start)
            .backgroundColor(this.getBackgroundColor())
            .hoverEffect(HoverEffect.Highlight)
            .stateStyles({
              normal: this.normalStateIconStyles,
              pressed: this.pressedStateIconStyles,
            })
            .padding({
              top: $r('app.float.card_content_text_margin_top_11'),
              left: $r('app.float.card_content_text_margin_top_8'),
              right: $r('app.float.card_content_text_margin_top_8')
            })
          }
          .width('100%')
          .borderRadius($r('app.float.swipe_image_height_and_width'))

        }, (item: cityInfo) => {
          return `${item.cityDisplayName?.toString()} + ${item.settingSummary?.toString()}`;
        })
      }
      .cachedCount(5)
      .width('100%')
      .height('100%')
      .padding($r('app.float.white_card_padding'))
      .scrollBar(BarState.Off)
      .onScrollIndex((start: number, end: number) => {
        this.handleScroll(start)
      })

    }
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .height('90%')
    .borderRadius(20)
    .margin({
      left: $r('app.float.appbar_icon_margin'),
      right: $r('sys.float.padding_level12')
    })
  }

  @Builder
  IndexBar() {
    Column() {
      AlphabetIndexer({ arrayValue: this.value, selected: this.num })
        .popupPosition({
          x: 60,
          y: 196
        })
        .alignSelf(ItemAlign.Start)
        .selectedColor($r('sys.color.font_emphasize'))// 选中项文本颜色
        .popupColor($r('sys.color.font_emphasize'))// 弹出框文本颜色
        .selectedBackgroundColor($r('sys.color.comp_emphasize_secondary'))// 选中项背景颜色
        .popupBackground(0xFFFFFFFF)// 弹出框背景颜色
        .usingPopup(true)// 是否显示弹出框
        .selectedFont({ size: $r('sys.float.Body_S'), weight: FontWeight.Medium })// 选中项字体样式
        .font({ size: $r('sys.float.Body_S'), weight: FontWeight.Medium })
        .popupFont({ size: $r('sys.float.Subtitle_M'), weight: FontWeight.Medium })// 弹出框内容的字体样式
        .itemSize(16)// 每一项的尺寸大小
        .alignStyle(IndexerAlign.Right)// 弹出框在索引条左侧弹出
        .onSelect((index: number) => {
          this.indexerSelect(index)
        })
        .onRequestPopupData((index: number) => {
          return [];
        })
    }
    .width($r('sys.float.padding_level12'))

  }

  build() {
    if (!this.isPC) {
      Column() {
        this.titleBar()
        Row() {
          Stack({ alignContent: Alignment.TopEnd }) {
            this.WhiteCard()
            this.IndexBar()
          }

        }
        .width('100%')
      }
      .width('100%')
      .height('100%')

    } else {
      Column() {
        this.titleBar()
        Row() {
          Stack({ alignContent: Alignment.TopEnd }) {
            this.WhiteCardForPC()
            this.IndexBar()
          }

        }
        .width('100%')
      }
      .width('60%')
      .height('100%')
    }

  }
}

