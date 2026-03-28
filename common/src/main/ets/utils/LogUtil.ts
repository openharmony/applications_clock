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

import hilog from '@ohos.hilog';

const DOMAIN = 0x66EE;
const FORMAT = '%{public}s';
const PREFIX = '[Clock]';
const SEPARATOR = ' ';

/**
 * 日志打印工具类
 *
 * @author XiaHan
 * @since 2022-07-06
 */
export class LogUtil {
  static debug(tag, ...args: string[]): void {
    hilog.debug(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }

  static info(tag, ...args: string[]): void {
    hilog.info(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }

  static warn(tag, ...args: string[]): void {
    hilog.warn(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }

  static error(tag, ...args: string[]): void {
    hilog.error(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }
}