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

import fs from '@ohos.file.fs';
import { LogUtil } from '@hmos/common';
import { Context } from '@ohos.abilityAccessCtrl';

const TAG = `CloneFSManager`;


interface ICloneFSManager {
  context: Context;

  moveFile(sourceFilePath: string, targetFilePath: string): Promise<boolean>;
}


class CloneFSManager implements ICloneFSManager {
  public context = {} as Context;

  constructor(context: Context) {
    this.context = context;
  }

  async moveFile(sourceFilePath: string, targetFilePath: string): Promise<boolean> {
    try {
      const exist = fs.accessSync(sourceFilePath);
      LogUtil.info(TAG, 'sourceFilePath exist', JSON.stringify(exist));
      if (!exist) {
        LogUtil.info(TAG, 'sourceFilePath not found', sourceFilePath);
        return false;
      }
      const targetPath = targetFilePath.substring(0, targetFilePath.lastIndexOf('/'));
      const existTargetFilePath = await fs.access(targetPath);
      if (!existTargetFilePath) {
        LogUtil.info(TAG, 'targetPath not found', targetPath);
        fs.mkdirSync(targetPath);
        LogUtil.info(TAG, 'create targetPath success', targetPath);
      }
      LogUtil.info(TAG, 'sourceFilePath exist', sourceFilePath);
      const cpSuccess = await fs.copyFile(sourceFilePath, targetFilePath).then(() => true);
      if (cpSuccess) {
        LogUtil.info(TAG, 'copy file success');
        const list = fs.listFileSync(this.context.databaseDir, {
          recursion: true // 递归查目录
        });
        list.map(item => {
          LogUtil.info(TAG, 'read context.databaseDir file', JSON.stringify(item));
        })
        return true;
      }
      LogUtil.info(TAG, 'copy file fail');
      return false;

    } catch (error) {
      LogUtil.error(TAG, JSON.stringify(error));
    }
    return false;
  }
}

export default function (context: Context): CloneFSManager {
  return new CloneFSManager(context);
}
