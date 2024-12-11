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
import { TitleBar, LogUtil, FormUtil, FormManager, FormInfo } from '@hmos/common';
import i18n from '@ohos.i18n';
import { FaClockCard } from '../components/FaClockCard'
import { FaCityInfo } from '../manager/types'
import { CityClockCardUtil } from '../utils/CityClockCardUtil'


const TAG: string = 'FaManagerCity';
const CITY_CLOCK_CARD: string = 'CITY_CLOCK_CARD';
const WORLD_CLOCK_CARD: string = 'WORLD_CLOCK_CARD';

@Component
export struct FaManagerCity {
  @State titleName: Resource = {} as Resource;
  @State faCityInfos: FaCityInfo[] = [];
  formInfo: FormInfo = {} as FormInfo;

  async aboutToAppear(): Promise<void> {
    const requestFormId = AppStorage.Get<string>('requestFormId');
    LogUtil.info(TAG, 'requestFormId:' + requestFormId);
    if (requestFormId) {
      this.formInfo = await FormManager.getFromInfoSpById(requestFormId!) as FormInfo;
      LogUtil.info(TAG, 'formInfo:' + JSON.stringify(this.formInfo));
      AppStorage.Delete('requestFormId');
    }
    if (this.formInfo.parameters && this.formInfo.formName === CITY_CLOCK_CARD) {
      const cityDisplayName = i18n.TimeZone.getCityDisplayName(this.formInfo.parameters[0],
        i18n.System.getSystemLanguage());
      const cityClockName = cityDisplayName.substr(0, cityDisplayName.indexOf('(')).trim();
      const faCityInfo: FaCityInfo = {
        cityIndex: this.formInfo.parameters[0],
        cityName: cityClockName,
      }
      this.faCityInfos.push(faCityInfo);
      LogUtil.info(TAG, 'cityClockName:' + JSON.stringify(this.faCityInfos));
      this.titleName = $r('app.string.fa_single_clock_name');
    }
    if (this.formInfo.formName === WORLD_CLOCK_CARD) {
      this.titleName = $r('app.string.fa_three_clock_name');
      if (this.formInfo.parameters) {
        this.formInfo.parameters.forEach((value, index) => {
          const cityDisplayName = i18n.TimeZone.getCityDisplayName(value, i18n.System.getSystemLanguage());
          const cityClockName = cityDisplayName.substr(0, cityDisplayName.indexOf('(')).trim();
          const faCityInfo: FaCityInfo = {
            cityIndex: value,
            cityName: cityClockName,
          }
          this.faCityInfos.push(faCityInfo);
        });
      }
      LogUtil.info(TAG, 'worldClockNames:' + JSON.stringify(this.faCityInfos));
    }

  }

  private async doCancel(): Promise<void> {
    LogUtil.info(TAG, 'doCancel and faCityInfos:' + JSON.stringify(this.faCityInfos))
    let cityIndexs: string[] = [];
    this.faCityInfos.forEach((item, index) => {
      cityIndexs.push(item.cityIndex);
    });
    const changedFormInfo: FormInfo = {
      formId: this.formInfo.formId,
      formName: this.formInfo.formName,
      parameters: cityIndexs,
    };
    await FormManager.saveFormToSp(changedFormInfo);
    if (this.faCityInfos.length === 1) {
      CityClockCardUtil.notifyCityClockCardUpdate(changedFormInfo.formId, cityIndexs[0])
    } else {
      CityClockCardUtil.notifyWorldClockCardUpdate(changedFormInfo.formId, cityIndexs)
    }
    router.back();
  }

  @Builder
  buildTitleBar(): void {
    Row() {
      TitleBar({
        title: '',
        onIconClick: () => this.doCancel(),
        iconResource: $r('app.media.ic_cancel'),
        operationArea: () => {
        },
      })
    }
  }

  @Builder
  buildTitle(): void {
    Row() {
      Text(this.titleName)
        .fontSize($r('app.float.fa_card_title_font_size'))
        .fontColor($r('app.color.fa_card_title_color'))
        .textAlign(TextAlign.Center)
    }
    .margin({ top: $r('app.float.fa_card_title_margin_top') })
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildClockCard(): void {
    Row() {
      FaClockCard({ faCityInfoList: $faCityInfos })
    }
    .margin({ top: $r('app.float.fa_card_margin_top') })
  }

  build() {
    Column() {
      this.buildTitleBar();
      this.buildTitle();
      Row() {
        Text($r('app.string.app_name'))
          .fontSize($r('app.float.fa_card_app_font_size'))
          .fontColor($r('app.color.fa_card_title_color'))
      }
      .margin({ top: $r('app.float.fa_card_margin_top') })
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Row() {
        Text($r('app.string.fa_select_city_title'))
          .fontSize($r('app.float.fa_card_select_font_size'))
          .fontColor($r('app.color.fa_card_title_color'))
          .textAlign(TextAlign.Center)
      }
      .margin({ top: $r('app.float.fa_card_title_margin_top') })
      .padding({ left: $r('app.float.fa_card_title_margin_left') })
      .width('100%')

      this.buildClockCard();
    }
    .height('100%')
  }
}