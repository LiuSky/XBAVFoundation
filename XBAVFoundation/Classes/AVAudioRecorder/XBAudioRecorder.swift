//
//  XBAudioRecorder.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/24.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 录音类
open class XBAudioRecorder: NSObject, XBAudioSessionProtocol {
    
    /// 停止播放
    public typealias StopCompletionHandler = (_ complete: Bool, _ pathUrl: URL) -> Void
    
    /// 时间类型别名
    public typealias TimerHandler = (_ currentTime: TimeInterval) -> Void
    
    /// 录音分贝更新类型别名
    public typealias MetersHandler = (_ meters: Float) -> Void
    
    /// 时间计时器回调
    public var timerHandler: TimerHandler?
    
    /// 分贝回调
    public var updateMeters: MetersHandler?
    
    /// 音频录音
    private(set) var recorder: AVAudioRecorder?
    
    /// 录音时间计时器
    private var timer: Timer?
    
    /// CADisplayLink与Timer的作用类似,不过它可以与现实刷新率自动同步
    private var displayLink: CADisplayLink?
    
    /// 停止录音完成事件
    private var stopCompletionHandler: StopCompletionHandler?
    
    /// MARK - 录音选项配置
    /// 1.音频格式(AVFormatIDKey): kAudioFormatMPEG4AAC 默认
    /// 2.采样率(AVSampleRateKey): 8000, 16000, 220505, 44100 默认16.0kHz
    /// 3.通道数(AVNumberOfChannelsKey): 1单声道 2 立体声录制 默认1
    /// 4.编码器位深(AVEncoderBitDepthHintKey): 8-32 默认16
    /// 5.编码音频质量(AVEncoderAudioQualityKey):  min, low, medium, high, max 默认AVAudioQuality.medium
    init(settings: [String : Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                      AVSampleRateKey: 22050.0,
                                      AVNumberOfChannelsKey: 1,
                                      AVEncoderBitDepthHintKey: 16,
                                      AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue]) {
        super.init()
    
        do {
            self.recorder = try AVAudioRecorder(url: self.getRecorderTemPath(), settings: settings)
            self.recorder?.delegate = self
            self.recorder?.isMeteringEnabled = true
        } catch (let e) {
            assertionFailure(e.localizedDescription)
        }
    }
}


// MARK: - public func
extension XBAudioRecorder {
    
    /// 准备播放
    public func prepareToRecord() {
        
        self.setActive(true)
        self.setCategory(.playAndRecord)
        self.recorder?.prepareToRecord()
    }
    
    /// 开始录音
    @discardableResult
    public func record() -> Bool {
        self.startTimer()
        self.startMeteTimer()
        return self.recorder?.record() ?? false
    }
    
    /// 暂停录音
    public func pause() {
        self.recorder?.pause()
    }
    
    /// 停止录音
    public func stop(completionHandler: @escaping StopCompletionHandler) {
        self.stopCompletionHandler = completionHandler
        self.recorder?.stop()
        self.stopTimer()
        self.stopMeteTimer()
    }
}


// MARK: - class func
extension XBAudioRecorder {
    
    
    /// MARK - 检查是否有麦克风访问权限
    ///
    /// - Returns: 是否允许
    open class func checkMicPermission() -> Bool {
        
        var permissionCheck: Bool = true
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            permissionCheck = true
        case AVAudioSession.RecordPermission.denied:
            permissionCheck = false
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                } else {
                    permissionCheck = false
                }
            })
        default:
            break
        }
        
        return permissionCheck
    }
}


// MARK - private func
extension XBAudioRecorder {
    
    /// 获取录音临时路径
    private func getRecorderTemPath() -> URL {
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        let tmpDir = NSTemporaryDirectory() as NSString
        return URL(fileURLWithPath: tmpDir.appendingPathComponent("\(dateFormatter.string(from: now)).m4a"))
    }
    
    /// 开始录音时长计时器
    private func startTimer() {
        
        self.timer?.invalidate()
        self.timer = Timer(timeInterval: 0.5, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    /// 停止录音时长计时器
    private func stopTimer() {
        self.updateTime()
        self.timer?.invalidate()
        self.timer = nil
    }
    
    /// 更新时间显示
    @objc private func updateTime() {
        
        self.timerHandler?(self.recorder?.currentTime ?? 0)
    }
    
    /// 开始计时录音分贝
    private func startMeteTimer() {
        self.displayLink?.invalidate()
        self.displayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        self.displayLink?.frameInterval = 5
        self.displayLink?.add(to: RunLoop.current, forMode: .common)
    }
    
    /// 停止计时录音分贝
    private func stopMeteTimer() {
        self.updateMeters?(0)
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    /// 刷新分贝
    @objc private func updateMeter() {
        
        let queue = DispatchQueue(label: "com.mike.XBAudioRecoder.meter")
        queue.async {
           
            self.recorder?.updateMeters()
            let peakPower: Double = Double(self.recorder?.averagePower(forChannel: 0) ?? 0)
            let alpha = 0.015
            let peakPowerForChannel = pow(10, (alpha * peakPower))
            DispatchQueue.main.async {
               self.updateMeters?(Float(peakPowerForChannel))
            }
        }
    }
}


// MARK: - <#AVAudioRecorderDelegate#>
extension XBAudioRecorder: AVAudioRecorderDelegate {
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self.stopCompletionHandler?(flag, recorder.url)
        self.setActive(false)
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        debugPrint("错误")
        self.setActive(false)
    }
}
