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
import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import fileio from '@ohos.fileio';
import { BusinessError } from '@ohos.base';
import resourceManager from '@ohos.resourceManager';
import { LogUtil, EventReportUtil, EventName, GlobalContext } from '@hmos/common';
import { RING_FILE_NAME, READ_INTERVAL, FILE_SEPARATOR, WRITE_MODE } from './types';

type RawFileDescriptor = resourceManager.RawFileDescriptor;
type AudioRendererOptions = audio.AudioRendererOptions;
type AudioStreamInfo = audio.AudioStreamInfo;
type AudioRendererInfo = audio.AudioRendererInfo;

const TAG = 'AudioManager';

/**
 * Alarm Audio Manager
 *
 * @since 2022-08-29
 */
class AudioManager {
  private audioStartTime: number = 0;
  private audioEndTime: number = 0;

  /**
   * Release audio resources
   */
  async releaseAudioResource(): Promise<void> {
    LogUtil.info(TAG, 'releaseAudioResource');
    const audioRenderer = await this.getAudioRenderer();
    let state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RELEASED || state === audio.AudioState.STATE_NEW) {
      LogUtil.info(TAG, 'renderer already released');
      return;
    }
    await audioRenderer.release();
    state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RELEASED) {
      LogUtil.info(TAG, 'renderer released');
    } else {
      LogUtil.info(TAG, 'renderer release failed');
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
      LogUtil.error(TAG, 'Failed to playAudio');
    }
  }

  /**
   * Stop playing audio
   */
  async stopAudio(): Promise<void> {
    await this.releaseAudioResource();
    this.audioEndTime = new Date().getTime();
    const alarmDuration = this.audioEndTime - this.audioStartTime;
    // EventReportUtil.write(EventName.CLOCK_START_TO_END, hiAppEvent.EventType.BEHAVIOR, {
    //   'duration': alarmDuration });
  }

  private async getAudioRenderer(): Promise<audio.AudioRenderer> {
    if (GlobalContext.getContext().getObject('audioRenderer')) {
      LogUtil.info(TAG, 'no need to createAudioRenderer');
      return GlobalContext.getContext().getObject('audioRenderer') as audio.AudioRenderer;
    }
    LogUtil.info(TAG, 'start createAudioRenderer instance');
    const audioManager = audio.getAudioManager();
    // audioManager.setAudioScene(audio.AudioScene.AUDIO_SCENE_RINGING).then(() => {
    //   LogUtil.info(TAG, 'set audio scene mode successfully');
    // }).catch((err: BusinessError) => {
    //   LogUtil.info(TAG, `failed to set the audio scene mode: ${err}`);
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
      LogUtil.info(TAG, `audioRenderer is interrupted : ${JSON.stringify(interruptEvent)}`);
    });
    LogUtil.info(TAG, 'createAudioRenderer successfully');
    return (GlobalContext.getContext().getObject('audioRenderer') as audio.AudioRenderer);
  }

  private async repeatPlay(ringFilePath?: string): Promise<void> {
    const audioRenderer = await this.getAudioRenderer();
    let state = audioRenderer.state;
    if (state !== audio.AudioState.STATE_PREPARED && state !== audio.AudioState.STATE_PAUSED &&
      state !== audio.AudioState.STATE_STOPPED) {
      LogUtil.info(TAG, `renderer is not in a correct state to start, current state is: ${state}`);
      return;
    }
    try {
      await audioRenderer.start();
    } catch (error) {
      LogUtil.error(TAG, `audioRenderer start failed:  ${JSON.stringify(error)}`);
      return;
    }
    state = audioRenderer.state;
    if (state === audio.AudioState.STATE_RUNNING) {
      LogUtil.info(TAG, 'renderer started');
    } else {
      LogUtil.error(TAG, `renderer start failed, state is ${state}`);
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
      LogUtil.error(TAG, `renderer is not running, do not write, state is ${audioRenderer.state}`);
      return;
    }
    const writtenBytes = await audioRenderer.write(arrayBuffer);
    if (writtenBytes < 0) {
      LogUtil.error(TAG, 'write buffer failed. check the state of renderer');
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
          LogUtil.info(TAG, 'start copy file filed, fd is ' + `${JSON.stringify(rawFileDesc)}`);
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
      LogUtil.error(TAG, `createRingFile failed: ${error}`);
    }
  }
}

export default new AudioManager();