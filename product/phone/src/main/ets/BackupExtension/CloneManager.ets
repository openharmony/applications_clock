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
import contextConstant from '@ohos.app.ability.contextConstant';
import { GlobalContext, LogUtil } from '@hmos/common';
import CloneFSManager from '../DBBackup/CloneFSManager';
import cloneDBManager from '../DBBackup/CloneDBManager';


const TAG: string = 'cloneManager';

interface ICloneManagerManager {
  dbRestore: () => Promise<boolean>;
  cloneHandle: () => Promise<void>;
  cloneAlarmDB: () => Promise<boolean>;
  cloneWorldClockDB: () => Promise<boolean>;
  cloneSingleDB: () => Promise<boolean>;
  judgeDBExist: () => Promise<DoubleDBExist>;
};

interface DoubleDBExist {
  alarmExist: boolean;
  worldClockExist: boolean;
}

function getContext(): Context {
  return GlobalContext.getContext().getObject('clockBackupContext') as Context
}

const cloneManager: ICloneManagerManager = {
  cloneHandle: async () => {
    const existData: DoubleDBExist = await cloneManager.judgeDBExist()
    if (existData.alarmExist) {
      const cloneSuccess = await cloneManager.cloneAlarmDB();
      if (!cloneSuccess) {
        return;
      }
    }
    if (existData.worldClockExist) {
      const cloneSuccess = await cloneManager.cloneWorldClockDB();
      if (!cloneSuccess) {
        return;
      }
    }
    LogUtil.info(TAG, 'Exist:', JSON.stringify(existData));
    await cloneManager.dbRestore();
  },

  dbRestore: async () => {
    LogUtil.info(TAG, 'clone DB migration begin');
    const isSuccess = await cloneDBManager.doubleToSingle();
    if (isSuccess) {
      LogUtil.info(TAG, 'clone DB migration success');
    }
    return isSuccess;
  },
  /**
   * 将克隆得到的闹钟数据库移动到数据库沙箱
   * */
  cloneAlarmDB: async () => {
    const context = getContext();
    context.area = contextConstant.AreaMode.EL1;
    const sourceAlarmFileName = 'alarm.db';
    const sourcePath = '/data/storage/el2/backup/restore/';
    const targetAlarmFilePath = `${context.databaseDir}/rdb/${sourceAlarmFileName}`;
    const sourceAlarmFilePath = `${sourcePath}${sourceAlarmFileName}`;
    LogUtil.info(TAG, 'clone double DB begin' + targetAlarmFilePath);
    const alarmSuccess = await CloneFSManager(getContext()).moveFile(sourceAlarmFilePath, targetAlarmFilePath);
    LogUtil.info(TAG, 'copy double DB end');
    return alarmSuccess;
  },
  /**
   * 将克隆得到的世界时钟数据库移动到数据库沙箱
   * */
  cloneWorldClockDB: async () => {
    const context = getContext();
    context.area = contextConstant.AreaMode.EL1;
    const sourceClockFileName = 'clock.db';
    const sourcePath = '/data/storage/el2/backup/restore/';
    const targetClockFilePath = `${context.databaseDir}/rdb/worldClock.db`
    const sourceClockFilePath = `${sourcePath}${sourceClockFileName}`;
    const clockSuccess = await CloneFSManager(getContext()).moveFile(sourceClockFilePath, targetClockFilePath);
    return clockSuccess;
  },
  /**
   * 单到单克隆数据库替换
   * */
  cloneSingleDB: async () => {
    const context = getContext();
    context.area = contextConstant.AreaMode.EL1;
    const sourceSingleDBName = 'Clock.db';
    const sourceSingleSHMName = 'Clock.db-shm';
    const sourceSingleWALName = 'Clock.db-wal';
    const sourcePath = '/data/storage/el2/backup/restore/data/storage/el1/database/entry/rdb/';
    const targetSingleDBPath = `${context.databaseDir}/rdb/cloneClock.db`;
    const targetSingleSHMPath = `${context.databaseDir}/rdb/cloneClock.db-shm`;
    const targetSingleWALPath = `${context.databaseDir}/rdb/cloneClock.db-wal`;
    const sourceSingleDBPath = `${sourcePath}${sourceSingleDBName}`;
    const sourceSingleSHMPath = `${sourcePath}${sourceSingleSHMName}`;
    const sourceSingleWALPath = `${sourcePath}${sourceSingleWALName}`;
    const dbSuccess = await CloneFSManager(getContext()).moveFile(sourceSingleDBPath, targetSingleDBPath);
    const shmSuccess = await CloneFSManager(getContext()).moveFile(sourceSingleSHMPath, targetSingleSHMPath);
    const walSuccess = await CloneFSManager(getContext()).moveFile(sourceSingleWALPath, targetSingleWALPath);
    const backupSuccess = await cloneDBManager.restoreClock()
    return backupSuccess;
  },
  /**
   * 针对克隆时选择的包为闹钟和世界时钟判断
   * */
  judgeDBExist: async () => {
    const alarmData: string = '/data/storage/el2/backup/restore/alarm.db';
    const worldClockData: string = '/data/storage/el2/backup/restore/clock.db';
    let alarmExist = fs.accessSync(alarmData);
    let worldClockExist = fs.accessSync(worldClockData);
    let resault: DoubleDBExist = { alarmExist: alarmExist, worldClockExist: worldClockExist };
    return resault;
  }
}

export default cloneManager;