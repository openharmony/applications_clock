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

export class WordClockTsUtil {
  public static transHandleScroll(tablet, k, obj, i): void {
    if (k === tablet && !obj[tablet]) {
      obj[tablet] = i;
    }
  }

  public static transIndexerSelect(objs, tablet): number {
    return objs[tablet];
  }
}

export default new WordClockTsUtil();
