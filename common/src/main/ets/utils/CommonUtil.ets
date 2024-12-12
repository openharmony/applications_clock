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

import i18n from '@ohos.i18n';
import deviceInfo from '@ohos.deviceInfo';
import resmgr from '@ohos.resourceManager';
import util from '@ohos.util';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import common from '@ohos.app.ability.common';

import { GlobalContext, LogUtil, SettingUtil } from '.';
import wallpaper from '@ohos.wallpaper';
import image from '@ohos.multimedia.image';
import { AlarmStateManager } from '../manager';
import SnoozeManager from '../manager/SnoozeManager';
import notificationManager from '@ohos.notificationManager';
import { BusinessError } from '@ohos.base';

const DEVICE_TYPE_PHONE = 'phone';
const NAME = 'nearestAlarmingTime';
const TAG = 'CommonUtil';
// type ServiceExtensionContext = common.ServiceExtensionContext;
const UNICODE: string = 'utf-8';

/**
 * Common Util
 *
 * @since 2023-01-10
 */
export class CommonUtil {
  /**
   * Check whether the current device is a mobile phone.
   *
   * @return Whether the current device is a mobile phone.
   */
  static isDevicePhone(): boolean {
    return deviceInfo.deviceType === DEVICE_TYPE_PHONE;
  }

  /**
   * Set button shadow color.
   *
   * @return button shadow color.
   */
  static changeShadowColor(resource: Resource): string | undefined {
    let context = GlobalContext.getContext().getObject('clockContext') as Context;
    if (context) {
      let backgroundColor: string = context.resourceManager.getColorSync(resource).toString(16);
      let colorSize = 6;
      let shadowColor = '#' + '4d' + backgroundColor.substring(backgroundColor.length - colorSize);
      LogUtil.info('changeShadowColor' + shadowColor);
      return shadowColor;
    }
    return;
  }

  /**
   * Get common dialog controller configurations
   *
   * @return Common dialog controller configurations
   */
  static getCommonDialogConfig(): CustomDialogControllerOptions {
    return {
      builder: undefined,
      autoCancel: true,
      alignment: CommonUtil.isDevicePhone() ? DialogAlignment.Bottom : undefined,
      customStyle: CommonUtil.isDevicePhone(),
    };
  }

  /**
   * Query which day of the week by given the date.
   *
   * @param date Date
   * @return The description of the queried day of a week in the corresponding language.
   */
  static getDayOfWeekByDateNotHO(date: Date): string {
    if (!date) {
      return '';
    }
    const options: Intl.DateTimeFormatOptions = { weekday: 'short' };
    return new Date(date.getFullYear(), date.getMonth(),
      date.getDate()).toLocaleDateString(i18n.getSystemLanguage(), options);
  }

  public static refreshNearestAlarmTime(timeStamp: number): boolean {
    const oldData: string = SettingUtil.getValueSync(NAME, '-1');
    const insertData = (timeStamp >= 0 ? timeStamp.toString() : '0');
    if (oldData === '-1' || oldData !== insertData) {
      let isSuccess = SettingUtil.setValueSync(NAME, insertData);
      LogUtil.info(TAG, 'nearestAlarmingTime refresh timestamp=' + insertData + ' isSuccess=' + isSuccess);
      return isSuccess;
    } else {
      LogUtil.info(TAG, 'nearestAlarmingTime same timestamp=' + insertData);
      return true;
    }
  }

  public static getNearestAlarmTime(): string {
    return SettingUtil.getValueSync(NAME, '-1');
  }

  public static requestTimerResources(): void {
    try {
      // backgroundTaskManager.resetAllEfficiencyResources();
      // let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      //   resourceTypes: backgroundTaskManager.ResourceType.TIMER,
      //   isApply: true, // 申请资源
      //   timeOut: 0,
      //   reason: 'apply',
      //   isPersist: true,
      //   isProcess: false,
      // };
      // backgroundTaskManager.applyEfficiencyResources(request);
      LogUtil.info(TAG, 'Succeeded in invoking requestTimerResources.');
    } catch (err) {
      LogUtil.error(TAG, `requestTimerResources Failed: ${JSON.stringify(err as BusinessError)}`)
    }
  }

  public static requestCPUResources(): void {
    try {
      // let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      //   resourceTypes: backgroundTaskManager.ResourceType.CPU,
      //   isApply: true, // 申请资源
      //   timeOut: 0,
      //   reason: 'apply',
      //   isPersist: true,
      //   isProcess: false,
      // };
      // backgroundTaskManager.applyEfficiencyResources(request);
      LogUtil.info(TAG, 'Succeeded in requestCPUResources.');
    } catch (err) {
      LogUtil.error(TAG, `requestCPUResources Failed: ${JSON.stringify(err as BusinessError)}`)
    }
  }

  public static releaseCPUResources(): void {
    try {
      // let request: backgroundTaskManager.EfficiencyResourcesRequest = {
      //   resourceTypes: backgroundTaskManager.ResourceType.CPU,
      //   isApply: false, // 释放资源
      //   timeOut: 0,
      //   reason: 'apply',
      //   isPersist: true,
      //   isProcess: false,
      // };
      // backgroundTaskManager.applyEfficiencyResources(request);
      LogUtil.info(TAG, 'Succeeded in releaseCPUResources.');
    } catch (err) {
      LogUtil.error(TAG, `releaseCPUResources Failed: ${JSON.stringify(err as BusinessError)}`)
    }
  }

  public static async terminateAlarmService(): Promise<void> {
    try {
      const isFiring = await AlarmStateManager.isFiring();
      const snoozeIds = await SnoozeManager.getSnoozedAlarmId();
      const notificationCnt = await notificationManager.getActiveNotificationCount();
      LogUtil.info(TAG, `terminateAlarmService isFiring:${isFiring} cnt:${notificationCnt} snoozeIds:${JSON.stringify(snoozeIds)} `);
      if (!isFiring && snoozeIds.length === 0) {
        LogUtil.info(TAG, `terminateAlarmService begin`);
        // await (GlobalContext.getContext().getObject('AlarmServiceContext') as ServiceExtensionContext).terminateSelf();
      }
    } catch (err) {
      LogUtil.error(TAG, `terminateAlarmService Failed: ${JSON.stringify(err as BusinessError)}`)
    }
  }

  public static terminateFullScreenAbility(): void {
    try {
      const isTerminated: boolean = GlobalContext.getContext()
        .getObject('terminateFullScreenAbilityContext') as boolean;
      LogUtil.info(TAG, 'terminateFullScreenAbility isTerminated=' + isTerminated);
      if (!isTerminated) {
        LogUtil.info(TAG, 'terminateFullScreenAbility begin');
        GlobalContext.getContext().setObject('terminateFullScreenAbilityContext', true);
        // (GlobalContext.getContext()
        //   .getObject('FullScreenAbilityContext') as ServiceExtensionContext).terminateSelf((error: object) => {
        //   LogUtil.info(TAG, `terminateFullScreenAbility finish error: ${JSON.stringify(error)}`);
        // });
        GlobalContext.getContext().setObject('FullScreenAbilityContext', undefined);
      }
    } catch (err) {
      LogUtil.error(TAG, `terminateFullScreenAbility Failed: ${JSON.stringify(err as BusinessError)}`)
    }
  }

  public static async getWallpaper(): Promise<void> {
    try {
      LogUtil.info(TAG, `getWallpaper begin`);
      // let wallpaperImage: image.PixelMap = await wallpaper.getImage(wallpaper.WallpaperType.WALLPAPER_LOCKSCREEN);
      // GlobalContext.getContext().setObject('wallpaperImage', wallpaperImage);
      // LogUtil.info(TAG, `getWallpaper: ${wallpaperImage}`);
    } catch (err) {
      LogUtil.error(TAG, `getWallpaper Failed: ${JSON.stringify(err as BusinessError)}`);
    }
  }

  /**
   * 获取指定JSON文件的对象
   * @param context 上下文
   */
  public static getStringByFile(resourceManager: resmgr.ResourceManager | undefined,
                                fileName: string): Promise<string> {
    return new Promise((resolve, reject) => {
      LogUtil.info(TAG, `getFileContent. fileName: ${fileName}`);
      if (!resourceManager || !fileName) {
        LogUtil.error(TAG, `getFileContent failed. resourceManager or fileName is null. fileName:${fileName}`);
        reject();
        return;
      }
      try {
        resourceManager.getRawFileContent(fileName).then((value) => {
          let content = util.TextDecoder.create(UNICODE).decodeWithStream(value);
          resolve(content);
        }).catch((err: BusinessError) => {
          LogUtil.error(TAG, `getFileContent of ${fileName} failed. ${err?.code} ${err?.message}`);
          reject(err);
        });
      } catch (jsonError) {
        LogUtil.error(TAG, `JSON parse error:${jsonError?.code} ${jsonError?.message}`);
        reject();
      }
    });
  }
}