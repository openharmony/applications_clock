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

import BackupExtensionAbility, { BundleVersion } from '@ohos.application.BackupExtensionAbility';
import fs from '@ohos.file.fs';
import { GlobalContext, LogUtil } from '@hmos/common';
import backupManager from './BackupMananger';
import cloneManager from './CloneManager';

const TAG = `ClockBackupExtensionAbility`;

export default class BackupExtension extends BackupExtensionAbility {
  onBackup() {
    LogUtil.info(TAG, `onBackup ok`);
  }

  async onRestore(bundleVersion: BundleVersion) {
    LogUtil.info(TAG, `clockOnRestore 1`);
    GlobalContext.getContext().setObject('clockBackupContext', this.context);
    GlobalContext.getContext().setObject('resourceManager', this.context.resourceManager);
    LogUtil.info(TAG, `clockOnRestore 2`);
    LogUtil.info(TAG, `onRestore ok ${JSON.stringify(bundleVersion)}`);
    await this.judgeBackup(bundleVersion);
    LogUtil.info(TAG, `backup end`);
  }

  async judgeBackup(bundleVersion: BundleVersion) {
    LogUtil.info(TAG, 'judge cloneData or backup');
    const cloneData: string = '/data/storage/el2/backup/restore/cloneBackupData.json';
    try {
      let exist = fs.accessSync(cloneData);
      if (exist) { // 双到单克隆
        LogUtil.info(TAG, 'cloneData exist', cloneData);
        const list = fs.listFileSync('/data/storage/el2/backup/restore/', {
          recursion: true // 递归查目录
        });
        list.map(item => {
          LogUtil.info(TAG, 'read backup file', JSON.stringify(item));
        })
        await cloneManager.cloneHandle();
      } else {
        LogUtil.info(TAG, 'cloneData not found', cloneData);
        if (bundleVersion.name === '0.0.0.0') { // 双升单
          LogUtil.info(TAG, 'start OTA upgrade.');
          await backupManager.restoreHandle();
        } else { // 单到单克隆
          LogUtil.info(TAG, 'start single to single clone');
          const list = fs.listFileSync('/data/storage/el2/backup/restore/', {
            recursion: true // 递归查目录
          });
          list.map(item => {
            LogUtil.info(TAG, 'read backup file', JSON.stringify(item));
          })
          await cloneManager.cloneSingleDB();
        }
      }
    } catch (err) {
      LogUtil.info(TAG, 'accessSync failed with error message: ' + err.message + ', error code: ' + err.code);
    }
  }
}
