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

import audio from '@ohos.multimedia.audio';
import media from '@ohos.multimedia.media';
import { LogUtil, GlobalContext } from '../utils';
import resmgr from '@ohos.resourceManager';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';

const TICK_FILE_NAME_TIME: string = 'timer_tick.ogg';
const TICK_FILE_NAME_STOPWATCH: string = 'stopwatch_tick.ogg';
const TICK_FILR_TIME_PICK: string = 'timepicker.ogg';
const LAP_FILE_NAME_STOPWATCH: string = 'stopwatch_lap.wav';
const TAG = 'soundPoolNew';
let count = 0;
let playTime = 0;

interface Resource {
  page: string,
  file: string,
  soundId: number,
  streamId: number
}

interface PlayParameters {
  loop: number,
  rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
  leftVolume: number,
  rightVolume: number,
  priority: number,
  parallelPlayFlag: boolean
};

export interface IdItems {
  soundId: number,
  streamId: number
}

export const resourceList: Resource[] = [
  { page: 'stopwatch', file: TICK_FILE_NAME_STOPWATCH, soundId: -1, streamId: -1 },
  { page: 'time', file: TICK_FILE_NAME_TIME, soundId: -1, streamId: -1 },
  { page: 'timePick', file: TICK_FILR_TIME_PICK, soundId: -1, streamId: -1 }
];

const idArr: IdItems[] = [
  { soundId: -1, streamId: -1 },
  { soundId: -1, streamId: -1 },
  { soundId: -1, streamId: -1 },
  { soundId: -1, streamId: -1 },
  { soundId: -1, streamId: -1 }
];
const maxStreams: number = 8;

class SoundPool {
  public soundPool: media.SoundPool = {} as media.SoundPool;
  private soundId: number = -1;
  private streamId: number = -1;
  private playTimerClear: number = -1;
  private playStopwatchClear: number = -1;
  private audioRendererInfo: audio.AudioRendererInfo = {
    content: audio.ContentType.CONTENT_TYPE_RINGTONE,
    usage: audio.StreamUsage.STREAM_USAGE_ALARM,
    rendererFlags: 1,
  };
  private playParams: PlayParameters = {
    loop: -1,
    rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
    leftVolume: 1,
    rightVolume: 1,
    priority: 0,
    parallelPlayFlag: true
  };

  async create(tips: string): Promise<void> {
    LogUtil.info(TAG, `create entry tips=${tips}`);
    try {
      this.soundPool = await media.createSoundPool(maxStreams, this.audioRendererInfo);
      this.loadCallback();
      this.finishPlayCallback();
      this.setErrorCallback();
      LogUtil.info(TAG, `create success`);
    } catch (error) {
      LogUtil.error(TAG, `create fail. code: ${error.code}, message: ${error.message}`);
    }
  }

  async openResource(url: string): Promise<resourceManager.RawFileDescriptor> {
    const resourceManager = (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager);
    const fileDescriptor = await resourceManager.getRawFd(url);
    return fileDescriptor;
  }

  async load(fileDescriptor: resourceManager.RawFileDescriptor): Promise<number> {
    let soundId = await this.soundPool.load(fileDescriptor.fd, fileDescriptor.offset, fileDescriptor.length);
    LogUtil.info(TAG, `load success`);
    return soundId;
  }

  async loadResource(step: number, cur: number): Promise<void> {
    LogUtil.info(TAG, `entry loadResource,step=${step},cur=${cur}`);
    try {
      const fileDescriptor1 = await this.openResource(resourceList[0].file);
      resourceList[0].soundId = await this.load(fileDescriptor1);
      const fileDescriptor2 = await this.openResource(resourceList[1].file);
      resourceList[1].soundId = await this.load(fileDescriptor2);
      const fileDescriptor3 = await this.openResource(resourceList[2].file);
      resourceList[2].soundId = await this.load(fileDescriptor3);
      await this.loadRepeat();
    } catch (error) {
      LogUtil.error(TAG, `load fail. code: ${error.code}, message: ${error.message}`);
    }
  }

  async loadRepeat() {
    try {
      const FILDESCRIPTOR_LAP = await this.openResource(LAP_FILE_NAME_STOPWATCH);
      idArr[0].soundId = await this.soundPool.load(FILDESCRIPTOR_LAP.fd, FILDESCRIPTOR_LAP.offset,
        FILDESCRIPTOR_LAP.length);
      idArr[1].soundId = await this.soundPool.load(FILDESCRIPTOR_LAP.fd, FILDESCRIPTOR_LAP.offset,
        FILDESCRIPTOR_LAP.length);
      idArr[2].soundId = await this.soundPool.load(FILDESCRIPTOR_LAP.fd, FILDESCRIPTOR_LAP.offset,
        FILDESCRIPTOR_LAP.length);
      idArr[3].soundId = await this.soundPool.load(FILDESCRIPTOR_LAP.fd, FILDESCRIPTOR_LAP.offset,
        FILDESCRIPTOR_LAP.length);
      idArr[4].soundId = await this.soundPool.load(FILDESCRIPTOR_LAP.fd, FILDESCRIPTOR_LAP.offset,
        FILDESCRIPTOR_LAP.length);
    } catch (error) {
      LogUtil.error(TAG, `loadRepeat fail. code: ${error.code}, message: ${error.message}`);
    }
  }

  async playForRepeat(): Promise<void> {
    try {
      const soundId = idArr[count].soundId;
      LogUtil.info(TAG, 'play', String(count), String(soundId));
      this.soundPool.play(soundId, {
        loop: 0,
        rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
        leftVolume: 1,
        rightVolume: 1,
        priority: 0
      }, (error: BusinessError, streamId: number) => {
        if (error) {
          console.info(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
        } else {
          // streamID = streamId;
          console.info('play success soundid:' + streamId);
        }
      });
      count++;
      if (count >= 5) {
        count = 0;
      }
      LogUtil.info(TAG, 'play success');
    } catch (error) {
      LogUtil.error(TAG, `playForRepeat fail. code: ${error.code}, message: ${error.message}`);
    }
  }

  playStopwatchForDelay() {
    this.playStopwatchClear !== -1 && clearTimeout(this.playStopwatchClear);
    this.playStopwatchClear = setTimeout(() => {
      this.soundPool.play(resourceList[0].soundId, this.playParams).then((streamid) => {
        resourceList[0].streamId = streamid;
      }).catch((err: BusinessError) => {
        LogUtil.info(TAG, `playStopwatchForDelay failed,code=${err.code},msg=${err.message}`);
      })
    }, 200);
  }

  playTimeForDelay() {
    this.playTimerClear !== -1 && clearTimeout(this.playTimerClear);
    this.playTimerClear = setTimeout(() => {
      this.soundPool.play(resourceList[1].soundId, this.playParams).then((streamid) => {
        resourceList[1].streamId = streamid;
      }).catch((err: BusinessError) => {
        LogUtil.info(TAG, `playTimeForDelay failed,code=${err.code},msg=${err.message}`);
      })
    }, 200);
  }

  async playSoundPool(page: string): Promise<void> {
    LogUtil.info(TAG, `playSoundPool entry`);
    switch (page) {
      case 'stopwatch':
        try {
          let streamId = await this.soundPool.play(resourceList[0].soundId, this.playParams);
          resourceList[0].streamId = streamId;
          LogUtil.info(TAG, `play success for stopwatch`);
        } catch (error) {
          LogUtil.error(TAG, `play failed for stopwatch,code=${error.code},msg=${error.message}`);
        }
        break;
      case 'time':
        try {
          LogUtil.info(TAG, `playTime entry resourceList[1].soundId=${resourceList[1].soundId}`);
          let streamId: number = await this.soundPool.play(resourceList[1].soundId, this.playParams);
          resourceList[1].streamId = streamId
          LogUtil.info(TAG, `play success for time`);
        } catch (error) {
          LogUtil.error(TAG, `play failed for time,code=${error.code},msg=${error.message}`);
        }
        break;
      case 'timePick':
        try {
          this.soundPool.play(resourceList[2].soundId, {
            loop: 0,
            rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
            leftVolume: 1,
            rightVolume: 1,
            priority: 0
          }, (error: BusinessError, streamId: number) => {
            if (error) {
              console.info(`play sound Error: errCode is ${error.code}, errMessage is ${error.message}`)
            } else {
              // streamID = streamId;
              resourceList[2].streamId = streamId;
              console.info('play success soundid:' + streamId);
            }
          });
          LogUtil.info(TAG, `play timePick success`);
        } catch {
          LogUtil.error(TAG, `play timePick failed`);
        }
        break;
      default:
        break;
    }
  }

  async stopForPageHide(page: string): Promise<void> {
    switch (page) {
      case 'stopwatch':
        try {
          resourceList[0].streamId !== -1 && await this.soundPool.stop(resourceList[0].streamId);
          this.setErrorCallback();
          if (this.playStopwatchClear !== -1) {
            clearTimeout(this.playStopwatchClear);
            this.playStopwatchClear = -1;
          }
          LogUtil.info(TAG, `stopForPageHide stopwatch success`);
        } catch {
          LogUtil.error(TAG, `stopForPageHide stopwatch failed`);
        }
        break;
      case 'time':
        try {
          resourceList[1].streamId !== -1 && await this.soundPool.stop(resourceList[1].streamId);
          this.setErrorCallback();
          if (this.playTimerClear !== -1) {
            clearTimeout(this.playTimerClear);
            this.playTimerClear = -1;
          }
          LogUtil.info(TAG, `stopForPageHide time success`);
        } catch {
          LogUtil.error(TAG, `stopForPageHide time failed`);
        }
        break;
      case 'timePick':
        try {
          LogUtil.info(TAG, `stopForPageHide resourceList[2].streamId=${resourceList[2].streamId}`);
          resourceList[2].streamId !== -1 && await this.soundPool.stop(resourceList[2].streamId);
          this.setErrorCallback();
          LogUtil.info(TAG, `stopForPageHide timePick success`);
        } catch {
          LogUtil.error(TAG, `stopForPageHide timePick failed`);
        }
        break;
      default:
        break;
    }
  }

  async stopForRepeat(): Promise<void> {
    try {
      idArr[0].streamId !== -1 && await this.soundPool.stop(idArr[0].streamId);
      idArr[1].streamId !== -1 && await this.soundPool.stop(idArr[1].streamId);
      idArr[2].streamId !== -1 && await this.soundPool.stop(idArr[2].streamId);
      idArr[3].streamId !== -1 && await this.soundPool.stop(idArr[3].streamId);
      idArr[4].streamId !== -1 && await this.soundPool.stop(idArr[4].streamId);
    } catch {
      LogUtil.info(TAG, `stopForRepeat failed`);
    }
  }

  async stopAllSoundPool(): Promise<void> {
    try {
      resourceList[0].streamId !== -1 && await this.soundPool.stop(resourceList[0].streamId);
      resourceList[1].streamId !== -1 && await this.soundPool.stop(resourceList[1].streamId);
      resourceList[2].streamId !== -1 && await this.soundPool.stop(resourceList[2].streamId);
      if (this.playStopwatchClear !== -1) {
        clearTimeout(this.playStopwatchClear);
        this.playStopwatchClear = -1;
      }
      if (this.playTimerClear !== -1) {
        clearTimeout(this.playTimerClear);
        this.playTimerClear = -1;
      }
    } catch {
      LogUtil.info(TAG, `stop all failed`);
    }
  }

  async unloadForRepeat(): Promise<void> {
    try {
      idArr[0].soundId != -1 && idArr[0].streamId != -1 && await this.soundPool.unload(idArr[0].soundId);
      idArr[1].soundId != -1 && idArr[1].streamId != -1 && await this.soundPool.unload(idArr[1].soundId);
      idArr[2].soundId != -1 && idArr[2].streamId != -1 && await this.soundPool.unload(idArr[2].soundId);
      idArr[3].soundId != -1 && idArr[3].streamId != -1 && await this.soundPool.unload(idArr[3].soundId);
      idArr[4].soundId != -1 && idArr[4].streamId != -1 && await this.soundPool.unload(idArr[4].soundId);
      LogUtil.info(TAG, `unloadForRepeat success`);
    } catch (err) {
      LogUtil.error(TAG, `unloadForRepeat failed,code=${err.code},msg=${err.message}`);
    }
  }

  async unloadAllSoundPool(): Promise<void> {
    try {
      resourceList[0].soundId != -1 && resourceList[0].streamId != -1 &&
        await this.soundPool.unload(resourceList[0].soundId);
      LogUtil.info(TAG, `unload stopwatch success`);
    } catch (err) {
      LogUtil.error(TAG, `unload stopwatch failed,code=${err.code},msg=${err.message}`);
    }
    try {
      resourceList[1].soundId != -1 && resourceList[1].streamId != -1 &&
        await this.soundPool.unload(resourceList[1].soundId);
      LogUtil.info(TAG, `unload time success`);
    } catch (err) {
      LogUtil.error(TAG, `unload time failed,code=${err.code},msg=${err.message}`);
    }
    try {
      resourceList[2].soundId != -1 && resourceList[2].streamId != -1 &&
        await this.soundPool.unload(resourceList[2].soundId);
      LogUtil.info(TAG, `unload timePick success`);
    } catch (err) {
      LogUtil.error(TAG, `unload timePick failed,code=${err.code},msg=${err.message}`);
    }
  }

  async releaseAll(): Promise<void> {
    try {
      await this.stopAllSoundPool();
      await this.stopForRepeat();
      await this.unloadAllSoundPool();
      await this.unloadForRepeat();
      LogUtil.info(TAG, `unloadAll success`);
      this.setOffCallback();
    } catch (err) {
      LogUtil.info(TAG, `unloadAll all failed,code=${err.code},msg=${err.message}`);
    }
  }

  async release(): Promise<void> {
    this.soundPool.stop(this.streamId);
    await this.soundPool.unload(this.soundId);
    this.setOffCallback();
    await this.soundPool.release();
  }

  async setPlayParams(streamId: number, loop: number, volume?: number) {
    // 设置循环播放次数
    this.soundPool && await this.soundPool.setLoop(streamId, loop); // 循环
    // 设置对应流的优先级
    this.soundPool && await this.soundPool.setPriority(streamId, 0);
    // 设置播放倍速
    this.soundPool && await this.soundPool.setRate(streamId, audio.AudioRendererRate.RENDER_RATE_NORMAL); // 半倍速播放
    // 设置音量
    this.soundPool && await this.soundPool.setVolume(streamId, volume || 1, volume || 1);
  }

  //关闭监听
  setOffCallback() {
    this.soundPool.off('loadComplete');
    this.soundPool.off('playFinished');
    this.soundPool.off('error');
  }

  async loadCallback(): Promise<void> {
    // 加载完成回调
    this.soundPool.on('loadComplete', (soundId_: number) => {
      LogUtil.info(TAG, `loadComplete message`);
    });
  }

  //设置播放完成监听
  async finishPlayCallback(): Promise<void> {
    // 播放完成回调
    this.soundPool.on('playFinished', async () => {
      LogUtil.info(TAG, `recive play finished message`);
    });
  }

  //设置错误类型监听
  setErrorCallback(): void {
    this.soundPool.on('error', (error) => {
      LogUtil.info(TAG, `error happened,message is: ${error.message},code=${error.code},name=${error.name}`);
    });
  }
}

export default new SoundPool();