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

import { ManageAlarmClock } from '../../pages/ManageAlarmClock';


interface IPCAlarmFormPopupBuilderProps {
  isPCView: boolean;
  visible: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

/**
 * PC 端 新建闹钟 popup
 *
 * */
@Builder
function PCAlarmFormPopupBuilder(props: IPCAlarmFormPopupBuilderProps) {
  Flex() {
    if (props.visible) {
      ManageAlarmClock({
        isPCView: props.isPCView,
        onConfirmCallback: props.onConfirm,
        onCancelCallback: props.onCancel,
      })
    }
  }
  .size({
    width: $r('app.float.pc_city_popup_builder_flex_width'),
  })
  .padding({
    top: $r('sys.float.padding_level4')
  })
  .backgroundColor($r('app.color.component_ultra_thick_panel'))
}

export {
  PCAlarmFormPopupBuilder
};