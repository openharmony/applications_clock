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

import image from '@ohos.multimedia.image'
import { GlobalContext, LogUtil } from './index';
import resmgr from '@ohos.resourceManager';

const TAG = 'NotificationContentUtil';

export class NotificationContentUtil {
  static async createPixelMap(name: string): Promise<image.PixelMap> {
    const resourceMgr = (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager)
    const fileData = await resourceMgr.getRawFileContent(name + '.svg')
    LogUtil.info(TAG, `${JSON.stringify(resourceMgr)}`)
    const imageSource = image.createImageSource(fileData.buffer as ESObject);
    const pixSize = (name === 'timer_capsule' || name === 'alarm_capsule') ? 63 : 140;
    let decodingOptions: image.DecodingOptions = {
      editable: true,
      desiredPixelFormat: 3,
      desiredSize: {
        width: pixSize,
        height: pixSize
      }
    }
    // 创建pixelMap并进行简单的旋转和缩放
    const pixelMap = await imageSource.createPixelMap(decodingOptions);
    return pixelMap
  }
}