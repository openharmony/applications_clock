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

import media from '@ohos.multimedia.media';
import HashMap from '@ohos.util.HashMap';
import fs from '@ohos.file.fs'
import audio from '@ohos.multimedia.audio';
import { LogUtil } from '../utils';
import resmgr from '@ohos.resourceManager';
import { GlobalContext } from '../../../../src/main/ets/utils/index';
import { BusinessError } from '@ohos.base';

const TAG: string = 'ResourceAudioManager';

/**
 * Internal Audio Manager which works with audio resources
 *
 * @since 24-09-2023
 */
interface FileDescriptor {
  fd: string | number,
  offset: string | number,
  length: string | number
}

const TICK_PLAYER = 'TICK_PLAYER';


class ResourceAudioManager {
  private players: HashMap<string, media.AVPlayer> = new HashMap();

  async tickPlayerStateHandle(player: media.AVPlayer) {
    if (!player) {
      return;
    }
    player.on('stateChange', async (state) => {
      switch (state) {
        case 'initialized': {
          player.prepare();
          break;
        }
        case 'prepared': {
          player.loop = false;
          player.play();
          break;
        }
        case 'completed': {
          break;
        }
        case 'stopped': {
          break;
        }

        case 'playing': {
          break;
        }
        case 'paused': {
          break;
        }
        default: {

        }
      }
    })
  }

  async createTickPlayer(resourceFileName = ''): Promise<media.AVPlayer> {
    let tickPlayer = await media.createAVPlayer();
    const resourceManager = (GlobalContext.getContext().getObject('resourceManager') as resmgr.ResourceManager);
    const fileDescriptor = await resourceManager.getRawFd(resourceFileName);
    let avFileDescriptor: media.AVFileDescriptor = {
      fd: fileDescriptor.fd,
      offset: fileDescriptor.offset,
      length: fileDescriptor.length
    };
    tickPlayer.fdSrc = avFileDescriptor;
    return tickPlayer;
  }

  async tickPlayerPlaying(resourceFileName = '') {
    let tickPlayer = this.players.get(TICK_PLAYER);
    if (tickPlayer) {
      if (tickPlayer.state === 'completed') {
        tickPlayer.play();
      }
      return;
    }
    tickPlayer = await this.createTickPlayer(resourceFileName);
    this.addPlayer(TICK_PLAYER, tickPlayer);
    this.tickPlayerStateHandle(tickPlayer);
  }

  async playOnce(resourceFileName = '') {
    LogUtil.info(TAG, 'play once ' + resourceFileName, String(this.players.hasKey(resourceFileName)));
    if (this.players.hasKey(resourceFileName)) {
      let p = this.players.get(resourceFileName);
      if (p) {
        p.play();
      }
      return;
    }
    let player = await this.createPlayer(resourceFileName, false);
    this.addPlayer(resourceFileName, player);

  }

  async playLoop(resourceFileName: string) {
    LogUtil.info(TAG, 'play loop 99' + resourceFileName);
    let player = await this.createPlayer(resourceFileName, true);
    LogUtil.info(TAG, 'play loop 99' + player, JSON.stringify(player));
    this.addPlayer(resourceFileName, player);
  }

  async playFromFileOnce(filePath: string) {
    LogUtil.info(TAG, 'play file at ' + filePath);
    let player = await this.createFilePlayer(filePath, false);
    this.addPlayer(filePath, player);
  }

  async playFromFileLoop(filePath: string) {
    LogUtil.info(TAG, 'play file at ' + filePath);
    let player = await this.createFilePlayer(filePath, true);
    this.addPlayer(filePath, player);
  }

  private addPlayer(resourceFileName: string, player: media.AVPlayer) {
    this.players.set(resourceFileName, player);
  }

  private async createFilePlayer(filePath: string, loop: boolean): Promise<media.AVPlayer> {
    let player = await media.createAVPlayer();

    let fdPath = 'fd://';
    let file = await fs.open(filePath);
    fdPath = fdPath + '' + file.fd;
    LogUtil.info(TAG, 'opening file at ' + fdPath);

    this.setCallback(player, loop, filePath);
    player.url = fdPath;

    return player;
  }

  private async createPlayer(resourceFileName: string, loop: boolean): Promise<media.AVPlayer> {
    let player = await media.createAVPlayer();

    let fileDescriptor: media.AVFileDescriptor = {} as media.AVFileDescriptor;
    await (GlobalContext.getContext()
      .getObject('resourceManager') as resmgr.ResourceManager).getRawFd(resourceFileName).then((value) => {
      fileDescriptor = { fd: value.fd, offset: value.offset, length: value.length }
    })

    this.setCallback(player, loop, resourceFileName);

    player.fdSrc = fileDescriptor;

    return player;
  }

  async pausePlayerFor(resourceFileName: string) {
    let player = await media.createAVPlayer()
    if (this.players.hasKey(resourceFileName)) {
      player = this.players.get(resourceFileName);
    }
    if (player) {
      player.pause();
    }
  }

  async stopPlayerFor(filePath: string) {
    let player: media.AVPlayer | undefined = undefined


    if (this.players.hasKey(filePath)) {
      player = this.players.get(filePath);
    }


    if (player) {
      await this.stopPlayer(player);
      this.players.remove(filePath);

    }
  }

  async stopPlayer(player: media.AVPlayer) {

    if (player) {

      await player.stop();
      player.release();
    }
  }

  release() {
    this.players.forEach((p) => {
      if (p) {
        this.stopPlayer(p);
      }
    })
    this.players.clear();
  }

  setCallback(player: media.AVPlayer, loop: boolean, resourceFileName: string = '') {
    player.on('stateChange', async (state) => {
      LogUtil.info(TAG, 'setCallback stateChange:' + state);
      switch (state) {
        case 'initialized': {
          let audioRendererInfo: audio.AudioRendererInfo = {
            content: audio.ContentType.CONTENT_TYPE_UNKNOWN,
            usage: audio.StreamUsage.STREAM_USAGE_ALARM,
            rendererFlags: 0
          };
          player.audioRendererInfo = audioRendererInfo;
          player.prepare();
          break;
        }
        case 'prepared': {
          player.setVolume(1.0);
          player.loop = loop;
          player.play();
          break;
        }
        case 'completed': {
          player.stop();
          break;
        }
        case 'stopped': {
          player.release();
          break;
        }
      }
    });
    player.on('error', async (error: BusinessError) => {
      LogUtil.error(TAG, 'audio player error:' + JSON.stringify(error));
    });
    player.on('audioInterrupt', async (info: audio.InterruptEvent) => {
      LogUtil.info(TAG, 'audioInterrupt:' + resourceFileName + ' ' + JSON.stringify(info));
      if (info.hintType === audio.InterruptHint.INTERRUPT_HINT_STOP) {
        try {
          this.stopPlayerFor(resourceFileName);
        } catch (error) {
          LogUtil.error(TAG, 'Failed to stopPlayerFor:' + JSON.stringify(error));
        }
      }
    });
  }
}

export default new ResourceAudioManager();