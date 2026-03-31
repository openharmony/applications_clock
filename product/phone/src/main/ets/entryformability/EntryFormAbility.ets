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

import formInfo from '@ohos.app.form.formInfo';
import formBindingData from '@ohos.app.form.formBindingData';
import contextConstant from '@ohos.app.ability.contextConstant';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formProvider from '@ohos.app.form.formProvider';
import { Configuration } from '@ohos.app.ability.Configuration';
import Want from '@ohos.app.ability.Want';
import Base from '@ohos.base';
import { FormManager, LogUtil, GlobalContext, } from '@hmos/common';
import { FormInfo } from '@hmos/common';
import { AlarmCardUtil } from '@hmos/alarmclock';

const TAG: string = 'EntryFormAbility';
const CITY_CLOCK_CARD: string = 'CITY_CLOCK_CARD';

const WORLD_CLOCK_CARD: string = 'WORLD_CLOCK_CARD';

interface formData {
  nextAlarmTime: string,
  noAlarms: boolean,
  isRinging: boolean,
  remainingTime: string,
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    LogUtil.info(TAG, 'onAddForm');
    this.context.area = contextConstant.AreaMode.EL1
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'EntryFormAbility');
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);

    // 使用方创建卡片时触发，提供方需要返回卡片数据绑定类
    let obj: Record<string, Object> = {
      'nextAlarmTime': $r('app.string.fa_alarm_alert'),
      'noAlarms': false,
      'isRinging': false,
      'remainingTime': '',
      'ringingTimestamp': 0
    };
    let formData = formBindingData.createFormBindingData(obj);
    if (want.parameters) {
      const formName = want.parameters['ohos.extra.param.key.form_name'].toString();
      const formId = want.parameters['ohos.extra.param.key.form_identity'].toString();
      this.initAlarmClockCard(formId, formName)
    }
    return formData;


  }

  private async saveFormInfo(formId: string, formName: string, parameters?: string[]): Promise<void> {
    LogUtil.info(TAG, 'SaveFormInfo to Sp -> formId:' + formId + ',formName:' + formName);
    const formInfo: FormInfo = {
      formId: formId,
      formName: formName,
      parameters: parameters,
    };
    LogUtil.info(TAG, 'saveFormInfo formInfo:' + JSON.stringify(formInfo));
    await FormManager.saveFormToSp(formInfo);
  }

  private async initAlarmClockCard(formId: string, formName: string): Promise<void> {
    LogUtil.info(TAG, 'initAlarmClockCard formId:' + formId + formName);
    this.context.area = contextConstant.AreaMode.EL1
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'EntryFormAbility');
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    await this.saveFormInfo(formId, formName);
    AlarmCardUtil.notifyAlarmCardTimeUpdate();
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
    // 使用方将临时卡片转换为常态卡片触发，提供方需要做相应的处理
    LogUtil.info(TAG, `onCastToNormalForm, formId: ${formId}`);
  }

  onUpdateForm(formId: string) {
    // 若卡片支持定时更新/定点更新/卡片使用方主动请求更新功能，则提供方需要重写该方法以支持数据更新
    LogUtil.info(TAG, 'onAcquireFormState:' + formId);
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    // Called when the form provider receives form events from the system.
    // 需要配置formVisibleNotify为true，且为系统应用才会回调
    LogUtil.info(TAG, 'onChangeFormVisibility');
  }

  onFormEvent(formId: string, message: string) {
    // Called when a specified message event defined by the form provider is triggered.
    // 若卡片支持触发事件，则需要重写该方法并实现对事件的触发
    LogUtil.info(TAG, 'onFormEvent');
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
    // 当对应的卡片删除时触发的回调，入参是被删除的卡片ID
    LogUtil.info(TAG, 'EntryFormAbility onRemoveForm:' + formId);
    GlobalContext.getContext().setObject('clockContext', this.context);
    GlobalContext.getContext().setObject('clockContextType', 'EntryFormAbility');
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    this.deleteFromInfo(formId);
  }

  async deleteFromInfo(formId: string): Promise<void> {
    await FormManager.deleteFormToSp(formId);
  }

  onConfigurationUpdate(config: Configuration) {
    // 当系统配置信息更新时触发的回调
    LogUtil.info(TAG, 'onConfigurationUpdate:' + JSON.stringify(config));
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    LogUtil.info(TAG, 'EntryFormAbility onAcquireFormState:');
    // 卡片提供方接收查询卡片状态通知接口，默认返回卡片初始状态。
    return formInfo.FormState.READY;
  }
}
