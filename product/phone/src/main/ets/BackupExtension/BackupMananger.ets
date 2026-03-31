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

import { GlobalContext, LogUtil } from '@hmos/common';
import fsManager from '../DBBackup/FSMananger';
import DBManager from '../DBBackup/DBManager';
import contextConstant from '@ohos.app.ability.contextConstant';


const TAG: string = 'BackupManager';

interface IBackupManager {
  restoreHandle: () => Promise<void>;
  dbRestore: () => Promise<boolean>;
  copyDoubleDB: () => Promise<boolean>;
}

function getContext(): Context {
  return GlobalContext.getContext().getObject('clockBackupContext') as Context
}

const backupManager: IBackupManager = {
  restoreHandle: async () => {
    LogUtil.info(TAG, `clockOnRestore BackupManager.copyDoubleDB`);
    const cpSuccess = await backupManager.copyDoubleDB();
    if (!cpSuccess) {
      return;
    }
    LogUtil.info(TAG, `clockOnRestore BackupManager.dbRestore()`);
    LogUtil.info(TAG, `clockOnRestore dbRestore`);
    await backupManager.dbRestore();
  },
  dbRestore: async () => {
    LogUtil.info(TAG, 'DB migration begin')
    const isSuccess = await DBManager.doubleToSingle();
    if (isSuccess) {
      LogUtil.info(TAG, 'double to single DB migration success')
    }
    return isSuccess;
  },
  copyDoubleDB: async () => {
    const context = getContext();
    const doubleDBFilename = 'alarms.db';
    // backup 沙箱路径
    const sourcePath = '/data/storage/el1/backup/restore/com.huawei.deskclock/de/databases';
    context.area = contextConstant.AreaMode.EL1;
    const targetFilePath = `${context.databaseDir}/rdb/${doubleDBFilename}`;
    const sourceFilePath = `${sourcePath}/${doubleDBFilename}`;

    LogUtil.info(TAG, 'move double DB begin');
    const r = await fsManager(getContext()).moveFile(sourceFilePath, targetFilePath);
    LogUtil.info(TAG, 'move double DB end', String(r));
    return r;
  }
}

export default backupManager;