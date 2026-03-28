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

export enum FloatingActionButtonColor {
  BLUE,
  WHITE
}

export interface ButtonColorScheme {
  schemeName: FloatingActionButtonColor;
  backgroundColor: Resource;
  backgroundColorPressed: Resource;
  backgroundColorDisabled: Resource;
  iconColor: Resource;
  iconColorDisabled: Resource;
}

export interface IButtonCustomStyle {
  iconDefaultColor: string | Resource;
  iconPlayColor: string | Resource;
  buttonDefaultBgc: string | Resource;
  buttonPlayBgc: string | Resource;
}

export const buttonColorSchemes: ButtonColorScheme[] = [
  {
    schemeName: FloatingActionButtonColor.BLUE,
    backgroundColor: $r('sys.color.ohos_id_icon_color_active'),
    backgroundColorPressed: $r('sys.color.ohos_id_icon_color_active'),
    backgroundColorDisabled: $r('app.color.color_fab_bg_disabled'),
    iconColor: $r('app.color.play_btn'),
    iconColorDisabled: $r('sys.color.ohos_id_icon_color_active')
  },
  {
    schemeName: FloatingActionButtonColor.WHITE,
    backgroundColor: $r('app.color.color_white'),
    backgroundColorPressed: $r('app.color.color_fab_bg_white_pressed'),
    backgroundColorDisabled: $r('app.color.color_fab_bg_white_disabled'),
    iconColor: $r('app.color.color_black'),
    iconColorDisabled: $r('app.color.color_fab_icon_white_disabled')
  }
];