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
import resmgr from '@ohos.resourceManager';
import { BusinessError } from '@ohos.base';
import { GlobalContext, LogUtil } from '../utils';

const TAG = 'ResourceManager';

/**
 * 资源相关工具类
 *
 * @author XiaHan
 * @since 2022-07-06
 */
class ResourceManager {
  // 缓存资源信息，对于字符串资源，key 是 语言编码 + 资源 ID，value 是语言和资源对应的字符串
  private resourceCache: Map<string, string> = new Map<string, string>();

  /**
   * 读取字符串资源，放入缓存中
   * 与 getStringById 配合使用，通过提前加载字符串资源，做到在同步方法中使用字符串资源
   *
   * @param resourceIds 需要预加载的字符串资源的 ID
   */
  async preloadStringResources(resourceIds: number[]): Promise<void> {
    this.resourceCache = this.resourceCache || new Map<string, string>();
    LogUtil.info(TAG, `resourceCache==> ${this.resourceCache}`);
    for (const id of resourceIds) {
      const stringKey = `${i18n.getSystemLocale()}_${id}`;
      if (!this.resourceCache.has(stringKey)) {
        await this.getStringByIdAsync(id);
      }
    }
  }

  preloadStringResourcesSync(resourceIds: number[]): void {
    this.resourceCache = this.resourceCache || new Map<string, string>();
    for (const id of resourceIds) {
      const stringKey = `${i18n.getSystemLocale()}_${id}`;
      if (!this.resourceCache.has(stringKey)) {
        this.getStringByIdSync(id);
      }
    }
  }

  getStringByIdSync(id: number): string {
    const stringKey = `${i18n.getSystemLocale()}_${id}`;
    if (this.resourceCache.has(stringKey)) {
      return this.getStringById(id);
    }
    let result = '';
    try {
      result = (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager).getStringSync(id);
      const stringKey = `${i18n.getSystemLocale()}_${id}`;
      this.resourceCache.set(stringKey, result);
      LogUtil.info(TAG, 'getString successfully!');
    } catch (error) {
      LogUtil.error(TAG, 'getString error:', (error as BusinessError).message);
    }
    return result;
  }

  /**
   * 获取字符串资源的同步方法
   * 使用前需要通过 preloadStringResources 预加载相关资源
   *
   * @param id 字符串资源的 ID
   * @return 资源 ID 对应的当前语言下的字符串
   */
  getStringById(id: number): string {
    LogUtil.info(TAG, `getStringById  ID==> ${id}`);
    const stringKey = `${i18n.getSystemLocale()}_${id}`;
    LogUtil.info(TAG, `stringKey==> ${stringKey}`);
    return this.resourceCache.get(stringKey) as string;
  }

  /**
   * 获取字符串资源的异步方法
   * 如果缓存中存在对应资源，则直接返回，否则通过资源管理器获取相关资源，并存入缓存
   *
   * @param id 字符串资源的 ID
   * @return 资源 ID 对应的当前语言下的字符串
   */
  async getStringByIdAsync(id: number): Promise<string> {
    const stringKey = `${i18n.getSystemLocale()}_${id}`;
    if (this.resourceCache.has(stringKey)) {
      LogUtil.info(TAG, `getStringByIdAsync  ID==> ${id}`);
      return this.getStringById(id);
    }
    let result = '';
    try {
      result = await (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager).getString(id);
      LogUtil.info(TAG, `stringKey=> ${stringKey}`, `result=> ${result}`);
      this.resourceCache.set(stringKey, result);
      LogUtil.info(TAG, 'getString successfully!');
    } catch (error) {
      LogUtil.error(TAG, 'getString error:', (error as BusinessError).message);
    }
    LogUtil.info(TAG, `result===> ${result}`);
    return result;
  }

  /**
   * 获取区分单复数的字符串资源的异步方法
   * 此处直接透传 resourceManager 的 getPluralString 方法
   * 暂不做任何【缓存处理】 和 对【同步引用方式】的适配
   *
   * @param id 字符串资源的 ID
   * @param num 数量
   * @return 资源 ID 和 对应数量，在当前语言下组合后的字符串
   */
  async getPluralStringAsync(id: number, num: number): Promise<string> {
    return await (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getPluralString(id, num);
  }

  /**
   * 获取string资源值
   * @param resource Resource资源类
   */
  getStringSync(resource: ResourceStr | undefined): string {
    if (!resource) {
      LogUtil.error(TAG, 'resource is null');
      return '';
    }
    if (typeof resource === 'string') {
      return resource;
    }
    let resourceManager = GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager;
    if (!resourceManager) {
      return '';
    }
    return resourceManager.getStringSync(resource.id);
  }
}

export default new ResourceManager();