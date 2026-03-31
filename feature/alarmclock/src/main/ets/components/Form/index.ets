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

import promptAction from '@ohos.promptAction';
import resmgr from '@ohos.resourceManager';
import {
  ActionType,
  AlarmInfo,
  AlarmInfoProperty,
  AlarmInfoToShow,
  ALARM_NAME_INPUT_LIMIT,
  ALARM_NAME_INPUT_MIN,
  Card,
  CommonDialog,
  CommonTextInputDialog,
  CommonUtil,
  EventName,
  EventReportUtil,
  EventResult,
  GlobalContext,
  PROMPT_TIME,
  ResourceManager,
  LogUtil,
} from '@hmos/common';
import { FLEX_GROW_FILL_FULL, FormField, FormOption, FormValue, InputType, DIALOG_EMITTER_EVENT } from './types';
// import hiSysEvent from '@ohos.hiSysEvent';
import emitter from '@ohos.events.emitter';

const TAG = 'formWeekk';

interface TypeDaysOfWeek {
  daysOfWeekDesc: string;
}

interface IBuildLabelAndValue {
  label: ResourceStr;
  value: ResourceStr;
}

/**
 * Form component that can be configured through template
 *
 * @since 2022-07-16
 */
@Component
export struct Form {
  @StorageProp('currentAbleScreen') foldAbleScreen: number = 0;
  // This parameter is used to transfer form field information.
  // public fields: FormField[] = [];
  @Link fields: FormField[];
  // This parameter is used to transfer form properties.
  // public properties?: TypeDaysOfWeek | AlarmInfoProperty = undefined;
  @Link properties?: AlarmInfoProperty;
  // This parameter is used to pass the custom input builders.
  @StorageProp('repeatType') repeatType: number = 0;
  @StorageProp('repeatModeFields') repeatModeFields: string = '';
  @Prop cancelMargin: boolean = false;
  @BuilderParam buildDiyInput?: (property?: string) => void;
  @State editingField?: FormField = undefined;
  @State dialogSelectChanged: boolean = false;
  @State hoverInfoList: boolean[] = this.fields.map(f => {
    return false;
  });
  @State hoverDialogList: boolean[] = [];
  @State currentPressItem: ResourceStr = '';
  @State currentPressSelectItem: ResourceStr = '';
  @State ringDuration:string = '';
  @State snoozeDuration:string = '';
  private editingValue: FormValue;
  private editingOptions?: FormOption[] = [];
  // The controller of the dialog
  private customControllerOptions: CustomDialogControllerOptions = CommonUtil.getCommonDialogConfig();
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: CommonDialog({
      title: this.getStringFromResourceStr(this.editingField?.label),
      actionType: this.editingField?.inputType === InputType.RADIO
        ? ActionType.SINGE_BUTTON_HORIZONTAL : ActionType.TWO_BUTTON_HORIZONTAL,
      firstButtonName: (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('cancel'),
      firstButtonCallback: () => this.closeInputDialog(false),
      secondButtonName: this.editingField?.inputType === InputType.RADIO
        ? undefined : (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('ok'),
      secondButtonCallback: this.editingField?.inputType === InputType.RADIO
        ? undefined // There's no confirm button for Radio
        : () => this.confirmInput(),
      content: (): void => this.buildDialogContent(),
    }),
    autoCancel: this.customControllerOptions.autoCancel,
    alignment: this.foldAbleScreen === 1 ? DialogAlignment.Center : this.customControllerOptions.alignment,
    customStyle: this.customControllerOptions.customStyle,
  });
  // The controller of the textInputDialogController
  private textInputDialogController: CustomDialogController = new CustomDialogController({
    builder: CommonTextInputDialog({
      title: this.getStringFromResourceStr(this.editingField?.label),
      cancelText: (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('cancel'),
      cancelCallback: () => this.closeInputDialog(false),
      confirmText: this.editingField?.inputType === InputType.RADIO
        ? undefined : (GlobalContext.getContext()
        .getObject('resourceManager') as resmgr.ResourceManager).getStringByNameSync('ok'),
      confirmCallback: this.editingField?.inputType === InputType.RADIO
        ? undefined
        : () => this.confirmInput(),
      textContent: (this.properties as Object as Record<string, string>)[this.editingField!.property],
      textInputCallback: this.textInputCallBack
    }),
    autoCancel: this.customControllerOptions.autoCancel,
    alignment: this.foldAbleScreen === 1 ? DialogAlignment.Center : this.customControllerOptions.alignment,
    customStyle: this.customControllerOptions.customStyle,
  });

  private getValueFromInputDialog(): FormValue {
    if (this.editingField?.inputType === InputType.TEXT) {
      return GlobalContext.getContext().getObject('textInput') as FormValue;
    }
    if (this.editingField?.inputType !== InputType.CHECK_BOX) {
      return this.editingValue;
    }
    if (this.editingOptions) {
      return this.editingOptions!.filter(option => option.isSelected).map(option => option.value);
    }
    return undefined;
  }

  private async confirmInput(): Promise<void> {
    if (this.editingField?.onConfirmDialog) {
      await this.editingField.onConfirmDialog();
      let snoozeDuration = this.properties?.snoozeDuration;
      let snoozeTimes = this.properties?.snoozeTimes;
      this.snoozeDuration = snoozeDuration + '&' + snoozeTimes;
      this.reportEventForDialogConfirm();
      return;
    }
    this.reportEventForDialogConfirm();
    // Callback based on field input parameters
    // Prepare and update the value of the field
    const inputValue: FormValue = this.getValueFromInputDialog();
    this.editingField?.onChange && this.editingField.onChange(inputValue);
    if (this.editingField && this.properties) {
      (this.properties as Object as Record<string, FormValue>)[this.editingField.property] = inputValue;
    }
    this.closeInputDialog(true);
  }

  private reportEventForDialogConfirm() {
    if (this.editingField?.inputType === InputType.CHECK_BOX) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_NEW_CLOCK_REPEAT_CHOICE)
    }
    if (this.editingField?.inputType === InputType.TEXT) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_SET_ALARM_NAME_CONFIRM)
    }
    if (this.editingField?.inputType === InputType.RADIO) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_EDIT_ALARM_RING_DURATION,
      //   0, this.ringDuration)
    }
    if (this.editingField?.inputType === InputType.DIY) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_CONFIRM_SNOOZE_DURATION,
      //   0, this.snoozeDuration)
    }
  }

  private async closeInputDialog(isAuto?: boolean): Promise<void> {
    // Callback based on field input parameters
    this.editingField?.onCloseDialog && await this.editingField.onCloseDialog();
    if (!isAuto) {
      this.reportEventForDialogClose();
    }
    this.editingOptions = undefined;
    this.editingValue = undefined;
    GlobalContext.getContext().setObject('textInput', undefined);
    GlobalContext.getContext().setObject('dialogController', undefined);
  }

  private reportEventForDialogClose() {
    if (this.editingField?.inputType === InputType.CHECK_BOX) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_NEW_CLOCK_REPEAT_CANCEL)
    }
    if (this.editingField?.inputType === InputType.TEXT) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_SET_ALARM_NAME_CANCEL)
    }
    if (this.editingField?.inputType === InputType.RADIO) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_CANCEL_RING_DURATION)
    }
    if (this.editingField?.inputType === InputType.DIY) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_CANCEL_SNOOZE_DURATION)
    }
  }

  private async WEEKopenInputDialog(field: FormField): Promise<void> {
    LogUtil.info(TAG, 'openInputDialog');
    if (field.disabled) {
      return;
    }
    // Callback based on field input parameters
    field.onOpenDialog && await field.onOpenDialog();

    // Prepare Data for Editing
    this.editingField = field;
    this.editingValue = (this.properties as Object as Record<string, FormValue>)[field.property];
    this.hoverDialogList = []
    this.editingOptions = field.options?.map(option => {
      this.hoverDialogList.push(false)
      return { label: option.label,
        value: option.value,
        isSelected: option.isSelected
      } as FormOption;
    });
    GlobalContext.getContext().setObject('dialogController', this.dialogController);
    this.dialogController.open();
    this.reportEventForDialogOpen();
  }

  private async openInputDialog(field: FormField): Promise<void> {
    if (field.disabled) {
      return;
    }

    // Callback based on field input parameters
    field.onOpenDialog && await field.onOpenDialog();

    // Prepare Data for Editing
    this.editingField = field;
    this.editingValue = (this.properties as Object as Record<string, FormValue>)[field.property];
    this.hoverDialogList = []
    this.editingOptions = field.options?.map(option => {
      this.hoverDialogList.push(false)
      return { label: option.label,
        value: option.value,
        isSelected: option.isSelected
      } as FormOption;
    });

    if (this.editingField?.inputType === InputType.TEXT) {
      GlobalContext.getContext()
        .setObject('textInput', (this.properties as Object as Record<string, FormValue>)[field.property]);
      GlobalContext.getContext().setObject('dialogController', this.textInputDialogController);
      this.textInputDialogController.open();
    } else {
      GlobalContext.getContext().setObject('dialogController', this.dialogController);
      this.dialogController.open();
    }
    this.reportEventForDialogOpen();
  }

  private reportEventForDialogOpen() {
    if (this.editingField?.inputType === InputType.CHECK_BOX) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLICK_NEW_CLOCK_REPEAT)
    }
    if (this.editingField?.inputType === InputType.TEXT) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.CLOCK_SET_ALARM_NAME)
    }
    if (this.editingField?.inputType === InputType.RADIO) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.SET_ALARM_RING_DURATION)
    }
    if (this.editingField?.inputType === InputType.DIY) {
      // EventReportUtil.reportEvent(hiSysEvent.EventType.BEHAVIOR, EventName.SET_ALARM_SNOOZE_DURATION)
    }
  }

  private getStringFromResourceStr(resourceStr?: ResourceStr): string {
    if (!resourceStr) {
      return '';
    }
    if (typeof resourceStr === 'string') {
      return resourceStr;
    }
    return (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getStringSync(resourceStr.id);
  }

  async textInputCallBack(value: string): Promise<void> {
    if (value?.length === ALARM_NAME_INPUT_LIMIT) {
      GlobalContext.getContext().setObject('textInput', value);
      const inputLimitTips = await ResourceManager.getStringByIdAsync($r('app.string.strlenght_full_Toast').id);
      promptAction.showToast({ message: inputLimitTips, duration: PROMPT_TIME });
    } else {
      GlobalContext.getContext().setObject('textInput', value);
    }
  }

  @Builder
  buildTextInput() {
    if (this.editingField?.inputType === InputType.TEXT) {
      Flex({ alignItems: ItemAlign.Center, direction: FlexDirection.Column }) {
        TextInput({ text: this.editingValue as ResourceStr || (this.properties as Object as
        Record<string, ResourceStr>)[this.editingField.property] })
          .backgroundColor($r('app.color.transparent'))
          .height($r('app.float.input_height'))
          .maxLength(ALARM_NAME_INPUT_LIMIT)
          .onChange(async (value: string) => {
            if (value?.length === ALARM_NAME_INPUT_LIMIT) {
              const inputLimitTips = await ResourceManager.getStringByIdAsync($r('app.string.strlenght_full_Toast').id);
              promptAction.showToast({ message: inputLimitTips, duration: PROMPT_TIME });
            }
            this.editingValue = value;
            if (value?.length === ALARM_NAME_INPUT_MIN) {
              this.editingValue = (this.properties as Object as Record<string, FormValue>)[this.editingField!.property];
            }
          })
          .padding({
            left: 0,
            right: 0,
          })
      }
      .height($r('app.float.list_item_height'))

      Divider().color($r('sys.color.comp_divider'))
    }
  }

  @Builder
  buildSelectBox(option: FormOption) {
    if (this.editingField?.inputType === InputType.RADIO) {
      Radio({ value: option.label, group: this.editingField.property })
        .height($r('app.float.radio_size'))
        .width($r('app.float.radio_size'))
        .padding(0)
        .checked(option.isSelected as boolean)
        .radioStyle({
          checkedBackgroundColor: $r('sys.color.comp_background_emphasize')
        })
        .hitTestBehavior(HitTestMode.None)
    } else {
      Checkbox()
        .select(option.isSelected as boolean)
        .selectedColor($r('sys.color.comp_background_emphasize'))
        .shape(CheckBoxShape.ROUNDED_SQUARE)
        .height($r('app.float.button_icon_size'))
        .width($r('app.float.button_icon_size'))
        .padding(0)
        .hitTestBehavior(HitTestMode.None)
    }
  }

  @Builder
  buildSelectInputItem(option: FormOption, index: number | undefined) {
    Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.SpaceBetween }) {
      Text(option.label)
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
      Row() {
        this.buildSelectBox(option)
      }
    }
    .id('id_alarmInfo_edit')
    .onClick(() => {
      option.isSelected = !option.isSelected;
      if (this.editingField?.inputType === InputType.RADIO) {
        if (option.isSelected) {
          this.editingValue = option.value;
          this.ringDuration = String(option.value);
          this.confirmInput();
          this.dialogController.close();
        }
      } else {
        this.dialogSelectChanged = !this.dialogSelectChanged;
      }
    })
    .onHover((isHover) => {
      if (typeof index === 'number') {
        if (isHover === true) {
          this.hoverDialogList[index] = true;
        } else {
          this.hoverDialogList[index] = false;
        }
      }
    })
    .backgroundColor(this.currentPressSelectItem === option.label ? $r('sys.color.interactive_click') :
      ((typeof index === 'number' && this.hoverDialogList[index]) ? $r('app.color.color_hover') : $r('app.color.color_hover_disabled')))
    .onMouse((event: MouseEvent) => {
      if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
        this.currentPressSelectItem = option.label;
      } else if (event?.action === MouseAction.Release) {
        this.currentPressSelectItem = '';
      }
    })
    // .backgroundColor((typeof index === 'number' && this.hoverDialogList[index]) ? $r('app.color.color_hover') :
    // $r('app.color.color_hover_disabled'))
    .borderRadius($r('app.float.default_corner_radius_l'))
    .padding({ left: $r('app.float.float_content_padding') })
    .height($r('app.float.list_item_height'))
  }

  @Builder
  buildSelectInput() {
    if (this.editingField?.inputType === InputType.CHECK_BOX || this.editingField?.inputType === InputType.RADIO) {
      ForEach(this.editingOptions || [], (option: FormOption, index: number | undefined) => {
        this.renderDivider(index)
        this.buildSelectInputItem(option, index)
      }, (option: FormOption) => JSON.stringify(option) + this.dialogSelectChanged)
    }
  }

  @Builder
  buildDialogContent() {
    Column() {
      if (this.editingField?.inputType === InputType.DIY && this.buildDiyInput) {
        // The user side uses the builder to implement the input.
        this.buildDiyInput(this.editingField.property)
      } else {
        this.buildSelectInput()
        this.buildTextInput()
      }
    }
  }

  @Builder
  // buildLabelAndValue(label: ResourceStr, value: ResourceStr) {
  buildLabelAndValue($$: IBuildLabelAndValue) {
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text($$.label)
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ right: $r('app.float.card_tag_margin_end') })
        .fontWeight(FontWeight.Medium)
        .width('30%')
      Column() {
        Row() {
          Text($$.value)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Regular)
            .width('90%')
            .textAlign(TextAlign.End)
            .padding({
              top: $r('app.float.card_inner_padding_horizontal'),
              bottom: $r('app.float.card_inner_padding_horizontal'),
            })
        }
      }
      .alignItems(HorizontalAlign.End)
      .flexGrow(FLEX_GROW_FILL_FULL)
    }
    .width('100%')
    .constraintSize({ minHeight: $r('app.float.set_alarm_card_height') })
  }

  @Builder
  renderDivider(index: number | undefined) {
    if (index) {
      // Render divider above items except for the first item with index zero
      Divider().color($r('sys.color.comp_divider'))
    }
  }

  @Builder
  buildFieldItem(field: FormField) {
    Row() {
      this.buildLabelAndValue({ label: field.label, value: (this.properties as Object as
      Record<string, ResourceStr>)[field.property] })
    }
    .onClick(() => this.openInputDialog(field))
  }

  build() {
    Row() {
      Card({ isMultipleSubItems: true, cancelMargin: true, bgColor: $r('sys.color.comp_background_list_card')} ) {
        ForEach(this.fields, (field: FormField, index: number | undefined) => {
          Column() {
            this.renderDivider(index)
            this.buildFieldItem(field)
          }
          .id('id_alarmInfo_item')
          .padding({
            right: $r('app.float.card_inner_padding_horizontal'),
            left: $r('app.float.card_inner_padding_horizontal'),
          })
          .onHover((isHover) => {
            if (typeof index === 'number') {
              if (isHover === true) {
                this.hoverInfoList[index] = true;
              } else {
                this.hoverInfoList[index] = false;
              }
            }
          })
          .backgroundColor(this.currentPressItem === field.property ? $r('sys.color.interactive_click') :
            ((typeof index === 'number' && this.hoverInfoList[index]) ? $r('app.color.color_hover') :
            $r('app.color.color_hover_disabled')))
          .onMouse((event: MouseEvent) => {
            if ((event?.action === MouseAction.Press) && (event?.button === MouseButton.Left)) {
              this.currentPressItem = field.property;
            } else if (event?.action === MouseAction.Release) {
              this.currentPressItem = '';
            }
          })
          .borderRadius($r('app.float.default_corner_radius_l'))
        })
      }
    }
  }
}
