/**
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
import { CountdownState } from '../controller/CountdownController'
import { ConfigData } from '@ohos/common'

@Component
export struct CountdownView {
  private viewSize: number = 40
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true })
  @Prop totalTime: number
  @Prop currentTime: number
  @State state: CountdownState = CountdownState.IDLE
  private normalColor: string = '#007DFF'
  private originRadius: number = 8
  private shadowOffset: number = 2.5
  private shadowColor: string = '#1400001E'
  private scaleWidth: number = 2.5
  private scaleHeight: number = 16
  private scalePadding: number = 10.5
  private pointerOffset: number = 13.5

  /**
   * Draw CountdownView.
   */
  private draw(): void{
    this.context.clearRect(0, 0, this.viewSize, this.viewSize)

    this.drawDials()
    this.drawPointer(this.totalTime, this.currentTime)
  }

  /**
   * Draw origin circle and tick marks.
   */
  private drawDials(): void{
    this.context.save()
    this.context.beginPath()
    this.context.fillStyle = this.normalColor
    this.context.arc(this.viewSize / 2, this.viewSize / 2, this.originRadius, 0, Math.PI * 2)
    this.context.fill()
    this.context.shadowBlur = this.originRadius * 2 + this.shadowOffset
    this.context.shadowColor = this.shadowColor
    this.context.restore()

    for (let n = 0; n < ConfigData.SCALE_NUM; n++) {
      var theta = n * (Math.PI * 2) / ConfigData.SCALE_NUM
      this.context.save()
      this.context.lineWidth = this.scaleWidth
      this.context.beginPath()
      var x_move = (this.viewSize / 2 - this.scalePadding) * Math.sin(theta) + this.viewSize / 2
      var y_move = -(this.viewSize / 2 - this.scalePadding) * Math.cos(theta) + this.viewSize / 2
      var x_to = (this.viewSize / 2 - (this.scalePadding + this.scaleHeight)) * Math.sin(theta) + this.viewSize / 2
      var y_to = -(this.viewSize / 2 - (this.scalePadding + this.scaleHeight)) * Math.cos(theta) + this.viewSize / 2
      this.context.strokeStyle =
        (this.state == CountdownState.RUNNING || this.state == CountdownState.PAUSED) &&
        (this.currentTime / this.totalTime > n / ConfigData.SCALE_NUM) && n ?
        'rgb(' + Math.ceil(ConfigData.COLOR_R - (ConfigData.COLOR_R / ConfigData.SCALE_NUM * n)) + ','
        + Math.ceil(ConfigData.COLOR_G_START - (ConfigData.COLOR_G_START - ConfigData.COLOR_G_END) / ConfigData.SCALE_NUM * n) + ',' + ConfigData.COLOR_B + ')' :
        '#66182431'
      this.context.moveTo(x_move, y_move)
      this.context.lineTo(x_to, y_to)
      this.context.stroke()
      this.context.restore()
    }
  }

  /**
   * Draw pointer.
   */
  private drawPointer(totalTime: number, currentTime: number): void{
    this.context.save()
    this.context.strokeStyle = this.normalColor
    this.context.shadowBlur = this.scaleWidth + this.shadowOffset
    this.context.shadowColor = this.shadowColor
    var theta = totalTime ? currentTime / totalTime * Math.PI * 2 : 0
    this.context.beginPath()
    this.context.lineWidth = this.scaleWidth
    var x_move = (this.viewSize / 2 - this.scalePadding) * Math.sin(theta) + this.viewSize / 2
    var y_move = -(this.viewSize / 2 - this.scalePadding) * Math.cos(theta) + this.viewSize / 2
    var x_to = -(this.originRadius + this.pointerOffset) * Math.sin(theta) + this.viewSize / 2
    var y_to = (this.originRadius + this.pointerOffset) * Math.cos(theta) + this.viewSize / 2
    this.context.moveTo(x_move, y_move)
    this.context.lineTo(x_to, y_to)
    this.context.stroke()
    this.context.restore()
  }

  build() {
    Canvas(this.context)
      .width(this.viewSize)
      .height(this.viewSize)
      .backgroundColor($r("app.color.background_color_white"))
      .border({ radius: this.viewSize })
      .shadow({ radius: $r("app.float.radius_value_26_5"), color: this.shadowColor })
      .onReady(() => {
        this.draw()
      })
  }
}