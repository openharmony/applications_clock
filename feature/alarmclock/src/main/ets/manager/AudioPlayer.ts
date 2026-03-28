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

import audio from '@ohos.multimedia.audio';
import fileio from '@ohos.fileio';
import type { BusinessError } from '@ohos.base';
import type resourceManager from '@ohos.resourceManager';
import type common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';
import { GlobalContext } from '../../../../../../common/src/main/ets/utils/GlobalContext';

type RawFileDescriptor = resourceManager.RawFileDescriptor;
type Context = common.Context;

interface AudioStreamInfo {
  samplingRate: number;
  channels: number;
  sampleFormat: number;
  encodingType: number;
}

interface AudioRendererInfo {
  content: number;
  usage: number;
  rendererFlags: number;
}

interface AudioRendererOptions {
  streamInfo: AudioStreamInfo;
  rendererInfo: AudioRendererInfo;
}

const TAG = 'AudioManager';
const DOMAIN = 0x66EE;
const FORMAT = '%{public}s';
const PREFIX = '[Clock]';
const SEPARATOR = ' ';
const RING_FILE_NAME = 'ring.wav';
const FILE_SEPARATOR = '/';
const WRITE_MODE = 'w+';

/**
 * Alarm Audio Manager
 *
 * @since 2022-08-29
 */
export class AudioPlayer {
  private audioStartTime: number = 0;
  private audioEndTime: number = 0;

  logInfo(tag, ...args: string[]): void {
    hilog.info(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }

  logError(tag, ...args: string[]): void {
    hilog.error(DOMAIN, PREFIX, FORMAT, `tag: ${tag} --> ${args.join(SEPARATOR)}`);
  }

  /**
   * Release audio resources
   */
  async releaseAudioResource(): Promise<void> {
    this.logInfo(TAG, 'releaseAudioResource');
    const audioRenderer = await this.getAudioRenderer();
    let state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RELEASED || state === audio.AudioState.STATE_NEW) {
      this.logInfo(TAG, 'renderer already released');
      return;
    }
    await audioRenderer.release();
    state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RELEASED) {
      this.logInfo(TAG, 'renderer released');
    } else {
      this.logInfo(TAG, 'renderer release failed');
    }
    GlobalContext.getContext().setObject('audioRenderer', undefined);
  }

  /**
   * Start playing audio
   */
  async playAudio(ringFilePath?: string): Promise<void> {
    try {
      this.audioStartTime = new Date().getTime();
      await this.repeatPlay(ringFilePath);
    } catch {
      this.logError(TAG, 'Failed to playAudio');
    }
  }

  /**
   * Stop playing audio
   */
  async stopAudio(): Promise<void> {
    await this.releaseAudioResource();
    this.audioEndTime = new Date().getTime();
    const alarmDuration = this.audioEndTime - this.audioStartTime;
  }

  private async getAudioRenderer(): Promise<audio.AudioRenderer> {
    if (GlobalContext.getContext().getObject('audioRenderer')) {
      this.logInfo(TAG, 'no need to createAudioRenderer');
      return GlobalContext.getContext().getObject('audioRenderer') as audio.AudioRenderer;
    }
    this.logInfo(TAG, 'start createAudioRenderer instance');
    const audioManager = audio.getAudioManager();
    this.logInfo(TAG, 'set audio scene mode successfully');
    // audioManager.setAudioScene(audio.AudioScene.AUDIO_SCENE_RINGING).then(() => {
    //   this.logInfo(TAG, 'set audio scene mode successfully');
    // }).catch((err: BusinessError) => {
    //   this.logInfo(TAG, `failed to set the audio scene mode: ${err}`);
    // });
    const audioStreamInfo: AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_2,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
    };
    const audioRendererInfo: AudioRendererInfo = {
      content: audio.ContentType.CONTENT_TYPE_MUSIC,
      usage: audio.StreamUsage.STREAM_USAGE_ALARM,
      rendererFlags: 0,
    };
    const audioRendererOptions: AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo,
    };
    GlobalContext.getContext().setObject('audioRenderer', await audio.createAudioRenderer(audioRendererOptions));
    const interruptMode: audio.InterruptMode = audio.InterruptMode.INDEPENDENT_MODE;
    await (GlobalContext.getContext()
      .getObject('audioRenderer') as audio.AudioRenderer).setInterruptMode(interruptMode);
    (GlobalContext.getContext()
      .getObject('audioRenderer') as audio.AudioRenderer).on('audioInterrupt', async (interruptEvent) => {
      this.logInfo(TAG, `audioRenderer is interrupted : ${JSON.stringify(interruptEvent)}`);
    });
    this.logInfo(TAG, 'createAudioRenderer successfully');
    return (GlobalContext.getContext().getObject('audioRenderer') as audio.AudioRenderer);
  }

  private async repeatPlay(ringFilePath?: string): Promise<void> {
    const audioRenderer = await this.getAudioRenderer();
    let state = audioRenderer.state;
    if (state !== audio.AudioState.STATE_PREPARED && state !== audio.AudioState.STATE_PAUSED &&
      state !== audio.AudioState.STATE_STOPPED) {
      this.logInfo(TAG, `renderer is not in a correct state to start, current state is: ${state}`);
      return;
    }
    try {
      await audioRenderer.start();
    } catch (error) {
      this.logError(TAG, `audioRenderer start failed:  ${JSON.stringify(error)}`);
      return;
    }
    state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RUNNING) {
      this.logInfo(TAG, 'renderer started');
    } else {
      this.logError(TAG, `renderer start failed, state is ${state}`);
    }
    let readLength = 0;
    const bufferSize: number = await audioRenderer.getBufferSize();
    const fileStream = fileio.createStreamSync(ringFilePath!, 'r');
    const totalSize = fileio.statSync(ringFilePath!).size;
    const discardHeader = new ArrayBuffer(bufferSize);
    fileStream.readSync(discardHeader);
    readLength += bufferSize;
    while (readLength < totalSize) {
      if (audioRenderer.state === audio.AudioState.STATE_RELEASED) {
        await this.stopRenderer(fileStream, audioRenderer);
        break;
      }
      if (audioRenderer.state === audio.AudioState.STATE_RUNNING) {
        let arrayBuffer = new ArrayBuffer(bufferSize);
        readLength += fileStream.readSync(arrayBuffer);
        await this.writeBuf(audioRenderer, arrayBuffer);
      }
    }
    if (readLength >= totalSize) {
      await this.stopRenderer(fileStream, audioRenderer);
      this.repeatPlay(ringFilePath);
    }
  }

  private async stopRenderer(fileStream: fileio.Stream, audioRenderer: audio.AudioRenderer): Promise<void> {
    fileStream.closeSync();
    if (audioRenderer.state !== audio.AudioState.STATE_RELEASED) {
      await audioRenderer.stop();
    }
  }

  private async writeBuf(audioRenderer: audio.AudioRenderer, arrayBuffer: ArrayBuffer): Promise<void> {
    if (audioRenderer.state !== audio.AudioState.STATE_RUNNING) {
      this.logError(TAG, `renderer is not running, do not write, state is ${audioRenderer.state}`);
      return;
    }
    const writtenBytes = await audioRenderer.write(arrayBuffer);
    if (writtenBytes < 0) {
      this.logError(TAG, 'write buffer failed. check the state of renderer');
    }
  }

  public async createRingFileIfNotExist(): Promise<void> {
    try {
      const filePath = (GlobalContext.getContext()
        .getObject('clockContext') as Context).filesDir + FILE_SEPARATOR + RING_FILE_NAME;
      let isFileExist = false;
      await fileio.access(filePath, 0).then(() => {
        isFileExist = true;
      }).catch(() => {
        isFileExist = false;
      });
      if (!isFileExist) {
        const rawFileDesc: RawFileDescriptor = await (GlobalContext.getContext()
          .getObject('clockContext') as Context).resourceManager.getRawFileDescriptor(RING_FILE_NAME);
        if (!rawFileDesc?.fd) {
          this.logInfo(TAG, 'start copy file filed, fd is ' + `${JSON.stringify(rawFileDesc)}`);
          return;
        }
        const descLength: number = rawFileDesc.length;
        const buffer = new ArrayBuffer(descLength);
        fileio.readSync(rawFileDesc.fd, buffer, {
          length: rawFileDesc.length,
          position: rawFileDesc.offset,
        });
        const streamOutput = fileio.createStreamSync(filePath, WRITE_MODE);
        streamOutput.writeSync(buffer);
        streamOutput.closeSync();
      }
    } catch (error) {
      this.logError(TAG, `createRingFile failed: ${error}`);
    }
  }
}

export default new AudioPlayer();