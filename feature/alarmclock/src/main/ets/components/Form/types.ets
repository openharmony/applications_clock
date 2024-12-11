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

export enum InputType {
  TEXT,
  RADIO,
  CHECK_BOX,
  DIY, // The user side uses the builder to implement the input.
}

export interface FormOption {
  label: string;
  value: number;
  isSelected?: boolean;
}

export interface FormField {
  label: ResourceStr;
  property: string;
  inputType: InputType;
  options?: FormOption[]; // Mandatory for radio or check box
  onChange?: (value?: FormValue) => void;
  onOpenDialog?: () => void; // Callback when the input dialog is opened
  onCloseDialog?: () => void; // Callback when the input dialog is closed
  onConfirmDialog?: () => void; // Callback when the input dialog is confirmed
  disabled?: boolean;
}

export interface WeekListField {
  label: string;
  value: number,
  selected: boolean;
}

export interface FormDiyCallbackInfo {
  onOpenDialog: () => void;
  onCloseDialog: () => void;
  onConfirmDialog: () => void;
}

export const FLEX_GROW_FILL_FULL = 1;

export type FormValue = ResourceStr | number | number[] | undefined;

export const DIALOG_EMITTER_EVENT = 99999;