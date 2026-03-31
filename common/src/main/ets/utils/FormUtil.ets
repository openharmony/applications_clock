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

import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import { FormManager } from '../manager';
import { FormInfo } from '../manager/types';
import { LogUtil } from './LogUtil';
import { GlobalContext } from './GlobalContext';

const TAG: string = 'FormUtil';

/**
 * 卡片工具类
 *
 * @since 2023-06-08
 */
export class FormUtil {
  /**
   * notify FormData Changed
   *
   * @param formId formId
   * @param formData formData
   */
  public static async notifyFormDataChanged(formId: string, formData: Object): Promise<void> {
    try {
      let bindData = formBindingData.createFormBindingData(formData);
      LogUtil.info(TAG, `notifyFormDataChanged --> formId: ${formId}, formData = ${JSON.stringify(bindData)}`);
      formProvider.updateForm(formId, bindData);
    } catch (error) {
      LogUtil.error(TAG, `notifyFormDataChanged error: ${error}`);
    }
  }

  /**
   * notify FormBindData Changed
   *
   * @param formId formId
   * @param formBindData formBindData
   */
  public static async notifyFormBindDataChanged(formId: string, formBindData: formBindingData.FormBindingData):
    Promise<void> {
    try {
      LogUtil.info(TAG, `notifyFormBindDataChanged --> formId: ${formId}, formBindData = ${JSON.stringify(formBindData)}`);
      formProvider.updateForm(formId, formBindData);
    } catch (error) {
      LogUtil.error(TAG, `notifyFormBindDataChanged error: ${error}`);
    }
  }

  /**
   * Notify All Alarm Card Changed
   *
   */
  public static async notifyClockCardChanged(formData: Object, formName: string): Promise<void> {
    try {
      let bindData = formBindingData.createFormBindingData(formData);
      const formList: FormInfo[] = await FormManager.fetchAllFormsFromSp();
      LogUtil.info(TAG, 'notifyClockCardChanged formList=' + JSON.stringify(formList))
      formList.forEach((value, index) => {
        if (value.formName === formName) {
          FormUtil.notifyFormBindDataChanged(value.formId, bindData);
        }
      });
    } catch (error) {
      LogUtil.error(TAG, `notifyClockCardChanged error: ${error}`);
    }
  }
}