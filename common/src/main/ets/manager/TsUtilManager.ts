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

interface FormInfo {
  formId: string;
  formName: string;
  parameters?: string[];
}

/**
 * TsUtil
 *
 * @since 2023-09-21
 */
export class TsUtilManager {
  /**
   * 将object类型的数据转化为fromInfo类型
   *
   * @return fromInfo[]
   */
  public static transferObjectToFormInfo(data): FormInfo[] {
    let result: FormInfo[] = [];
    Object.keys(data).forEach((value, index) => {
      let formInfo = JSON.parse(data[value]);
      result.push(formInfo);
    });
    return result;
  }

  public static hasItsProperty(data, value): boolean {
    if (data && value) {
      return Object.prototype.hasOwnProperty.call(data, value);
    } else {
      return false;
    }
  }

  public static getItsProperty(data, value): string {
    if (TsUtilManager.hasItsProperty(data, value)) {
      return data[value];
    } else {
      return '';
    }
  }
}

export default new TsUtilManager();
