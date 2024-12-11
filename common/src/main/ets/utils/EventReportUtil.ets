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

import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import { LogUtil } from './LogUtil';
// import hiSysEvent from '@ohos.hiSysEvent';
import { BusinessError } from '@ohos.base';
import bundleManager from '@ohos.bundle.bundleManager';

const TAG = 'Common_EventReport';

interface ReportParams {
  PNAMEID: string;
  PVERSIONID: string;
  TIME?: number;
  VALUE?:string;
}

/**
 * Event report util
 *
 * @since 2022-12-15
 */
export class EventReportUtil {
  private static applicationVersion: string;

  static reportEvent(eventName: string, time?: number, value?:string): void {
    if (!EventReportUtil.applicationVersion) {
      EventReportUtil.getApplicationVersion();
    }
    LogUtil.info(TAG, `eventName : ${eventName} `);
    let params: ReportParams = {
      PNAMEID: 'com.ohos.clock',
      PVERSIONID: EventReportUtil.applicationVersion,
      TIME: time,
      VALUE: value
    }
    LogUtil.info(TAG, 'eventName:', eventName, JSON.stringify(params));
    // hiSysEvent.write({
    //   domain: 'CLOCK_UE',
    //   name: eventName,
    //   eventType: eventType,
    //   params: params
    // }).then(
    //   (val) => {
    //     LogUtil.info(TAG, `${eventName}  success.`);
    //   }
    // ).catch(
    //   (err: BusinessError) => {
    //     LogUtil.error(TAG, `${eventName}  error. code: ${err.code} ,message: ${err.message}`);
    //   }
    // )
    return;
  }

  static getApplicationVersion() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
        if (err) {
          LogUtil.error(`${TAG},'getBundleInfoForSelf failed', message: ${err.message}`);
        } else {
          LogUtil.info(`${TAG},'getBundleInfoForSelf successfully', message: ${JSON.stringify(data)}`);
          EventReportUtil.applicationVersion = data?.versionName;
        }
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(`${TAG},'getBundleInfoForSelf failed: %{public}s', message: ${message}`);
    }
  }

  static write(eventName: string, eventType: number, params: Record<string, number | string>): void {
    if (!eventName || !eventType || !params) {
      LogUtil.error(TAG, 'EventReportUtil write failed, params is incorrect');
      return;
    }
    const appEventInfo: hiAppEvent.AppEventInfo = {
      domain: 'clock',
      name: eventName,
      eventType: eventType,
      params: params
    };
    hiAppEvent.write(appEventInfo).then(data => {
      LogUtil.info(TAG, `HiAppEvent success to write event: ${eventName}`);
    }).catch((error: object) => {
      LogUtil.info(TAG, `HiAppEvent failed to write event because ${JSON.stringify(error)}`);
    });
  }
}