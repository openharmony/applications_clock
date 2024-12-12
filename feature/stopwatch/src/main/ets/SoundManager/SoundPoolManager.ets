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

import media from '@ohos.multimedia.media';
import audio from '@ohos.multimedia.audio';
import fs from '@ohos.file.fs';
import { LogUtil, GlobalContext } from '@hmos/common';
import resourceManager from '@ohos.resourceManager';

const TAG: string = 'SoundPoolManager';

interface ISoundPoolManager {
  create: (options: ICreateOptions) => Promise<media.SoundPool>;
  openFile: (filePath: string, openMode: number) => Promise<fs.File>;
  openResourceFile: (resourceName: string, context: Context) => Promise<resourceManager.RawFileDescriptor>;
  loadFile: (rawFileDescriptor: resourceManager.RawFileDescriptor, soundPool: media.SoundPool) => Promise<number>;
  play: (soundId: number, mediaOptions: media.PlayParameters, soundPool: media.SoundPool) => Promise<void>
}

interface ICreateOptions {
  maxStreams: number; // soundPool实例的最大播放的流数
  audioRenderInfo: audio.AudioRendererInfo; // 音频播放参数信息

}

function getContext(): Context {
  return GlobalContext.getContext().getObject('clockContext') as Context;
}

const soundPoolManager: ISoundPoolManager = {
  async create(options) {
    let soundPool = {} as media.SoundPool;
    try {
      soundPool = await media.createSoundPool(options.maxStreams, options.audioRenderInfo);
      LogUtil.info(TAG, `createSoundPool success.`);
      return soundPool;
    } catch (error) {
      LogUtil.error(TAG, `create fail. code: ${error.code}, message: ${error.message}`);
    }
    return soundPool;
  },
  async openResourceFile(resourceName, context) {
    let rawFileDescriptor = {} as resourceManager.RawFileDescriptor;
    try {
      const resourceManagerInstance = context.resourceManager;
      rawFileDescriptor = await resourceManagerInstance.getRawFd(resourceName);
      LogUtil.info(TAG, `openResourceFile success.`, String(rawFileDescriptor.fd), String(rawFileDescriptor.offset), String(rawFileDescriptor.length));
      return rawFileDescriptor;
    } catch (error) {
      LogUtil.error(TAG, `openResourceFile fail. code: ${error.code}, message: ${error.message}`);
    }
    return rawFileDescriptor;
  },
  async openFile(filePath, openMode) {
    let file = {} as fs.File;
    // 获取文件
    try {
      file = await fs.open(filePath, openMode);
      LogUtil.info(TAG, `open file success. filePath: ${filePath}`);
      return file;
    } catch (error) {
      LogUtil.error(TAG, `open file fail. code: ${error.code}, message: ${error.message}, filePath: ${filePath}`);
    }
    return file;
  },
  async loadFile(rawFileDescriptor, soundPool) {
    let soundId: number = -1;
    try {
      const soundId: number = await soundPool.load(rawFileDescriptor.fd,
        rawFileDescriptor.offset, rawFileDescriptor.length);
      LogUtil.info(TAG, `loadFile success.`, String(soundId));
      return soundId;
    } catch (error) {
      LogUtil.error(TAG, `loadFile fail. code: ${error.code}, message: ${error.message}`);
    }
    return soundId;
  },
  async play(soundId, mediaOptions, soundPool) {

    try {
      const streamId = await soundPool.play(soundId, mediaOptions);
      LogUtil.info(TAG, `play success.`);
    } catch (error) {
      LogUtil.error(TAG, `play fail. code: ${error.code}, message: ${error.message}`);
    }
  }
}

const MAX_STREAMS = 5;
const createOptions: ICreateOptions = {
  maxStreams: MAX_STREAMS,
  audioRenderInfo: {
    usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
    rendererFlags: 1
  }
};
const mediaPlayOptions: media.PlayParameters = {
  loop: 0, // 循环0次
  rate: audio.AudioRendererRate.RENDER_RATE_NORMAL, // 正常倍速
  leftVolume: 0.5,
  rightVolume: 0.5,
  priority: 0, // 最低优先级
  parallelPlayFlag: false // 不和其它正在播放的音频并行播放
};
let soundPool: media.SoundPool;
let soundIdArr: number[] = [];
const resourceName = 'stopwatch_lap.wav';
let count = 0;

export async function soundPoolInit() {
  const context = getContext();
  if (!soundPool) {
    soundPool = await soundPoolManager.create(createOptions);

    soundPool.on('loadComplete', (soundId: number) => {
      LogUtil.info(TAG, 'loadComplete success，soundId：' + soundId);
    })
    soundPool.on('playFinished', () => {
      LogUtil.info(TAG, 'playFinished success');
    })
  }
  const rawFileDescriptor = await soundPoolManager.openResourceFile(resourceName, context);
  const s1 = await soundPoolManager.loadFile(rawFileDescriptor, soundPool);
  const s2 = await soundPoolManager.loadFile(rawFileDescriptor, soundPool);
  const s3 = await soundPoolManager.loadFile(rawFileDescriptor, soundPool);
  const s4 = await soundPoolManager.loadFile(rawFileDescriptor, soundPool);
  const s5 = await soundPoolManager.loadFile(rawFileDescriptor, soundPool);
  soundIdArr.push(s1);
  soundIdArr.push(s2);
  soundIdArr.push(s3);
  soundIdArr.push(s4);
  soundIdArr.push(s5);
}

export async function stopWatchTickHandle() {
  if (soundPool) {
    const soundId = soundIdArr[count];
    LogUtil.info(TAG, 'play', String(count), String(soundId));
    await soundPoolManager.play(soundId, mediaPlayOptions, soundPool);
    count++;
    if (count >= MAX_STREAMS) {
      count = 0;
    }
  }
}

export default soundPoolManager;