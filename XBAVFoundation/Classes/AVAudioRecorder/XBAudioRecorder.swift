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
    
    /// 准备完成
    public typealias PrepareCompletionHandler = (_ complete: Bool) -> Void
    
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
    
    /// 最大录音时长(默认60,如果等于于0就是不限制)
    public var maxRecordTime: TimeInterval = 60.0
    
    /// 音频录音
    private(set) var recorder: AVAudioRecorder?
    
    /// CADisplayLink与Timer的作用类似,不过它可以与现实刷新率自动同步
    private var displayLink: CADisplayLink?
    
    /// 停止录音完成事件
    private var stopCompletionHandler: StopCompletionHandler?
    
    /// 准备完成处理
    private var prepareCompletionHandler: PrepareCompletionHandler?
    
    /// 队列
    private lazy var queue: DispatchQueue = {
        return DispatchQueue(label: "com.mike.XBAudioRecorder.queue")
    }()
    

    ///  MARK - 初始化录音播放器
    ///
    /// - Parameters:
    ///   - settings: 录音配置项
    ///   - AVSampleRateKey: 1.音频格式(AVFormatIDKey): kAudioFormatMPEG4AAC 默认
    ///   - AVNumberOfChannelsKey: 2.采样率(AVSampleRateKey): 8000, 16000, 220505, 44100 默认16.0kHz
    ///   - AVEncoderBitDepthHintKey: 3.通道数(AVNumberOfChannelsKey): 1单声道 2 立体声录制 默认1
    ///   - AVEncoderAudioQualityKey: 5.编码音频质量(AVEncoderAudioQualityKey):  min, low, medium, high, max 默认AVAudioQuality.medium
    ///   - url: 录音保存地址
    init(settings: [String : Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                      AVSampleRateKey: 22050.0,
                                      AVNumberOfChannelsKey: 1,
                                      AVEncoderBitDepthHintKey: 16,
                                      AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue],
         url: URL = getRecorderTemPath()) {
        
        super.init()
        do {
            self.recorder = try AVAudioRecorder(url: url, settings: settings)
            self.recorder?.delegate = self
            self.recorder?.isMeteringEnabled = true
        } catch (let e) {
            assertionFailure(e.localizedDescription)
        }
    }
}


// MARK: - public func
extension XBAudioRecorder {
    
    /// 准备播放(因为有时候其他的音乐正在播放,这时候就需要一个准备过程)
    public func prepareToRecord(completionHandler: @escaping PrepareCompletionHandler)  {
        
        queue.async {
           
            self.prepareCompletionHandler = completionHandler
            /// 判断是否有其他的音乐正在播放
            if AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint {
                self.addNotification()
                self.setCategory(.playAndRecord)
                self.setActive(true)
            } else {
                self.setCategory(.playAndRecord)
                self.setActive(true)
                self.prepareToRecord()
            }
        }
    }
    
    /// 开始录音
    @discardableResult
    public func record() -> Bool {
        self.startMeteTimer()
        return self.recorder?.record() ?? false
    }
    
    /// 暂停录音
    public func pause() {
        
        if maxRecordTime > 0 {
           self.recorder?.record(forDuration: maxRecordTime)
        }
        self.recorder?.pause()
    }
    
    
    /// 取消录音
    public func cancel() {
        
        self.stop { (is, url) in
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// 停止录音
    public func stop(completionHandler: @escaping StopCompletionHandler) {
        self.stopCompletionHandler = completionHandler
        self.recorder?.stop()
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
    private static func getRecorderTemPath() -> URL {
        
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        let tmpDir = NSTemporaryDirectory() as NSString
        return URL(fileURLWithPath: tmpDir.appendingPathComponent("\(dateFormatter.string(from: now)).m4a"))
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
        
        queue.async {
            
            self.recorder?.updateMeters()
            let peakPower: Double = Double(self.recorder?.averagePower(forChannel: 0) ?? 0)
            let alpha = 0.015
            let peakPowerForChannel = pow(10, (alpha * peakPower))
            DispatchQueue.main.async {
               self.updateTime()
               self.updateMeters?(Float(peakPowerForChannel))
            }
        }
    }
    
    /// 添加静音二级音频提示通知
    private func addNotification() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSecondaryAudio(notification:)), name: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil)
    }
    
    /// 移除静音二级音频提示通知
    private func removeNotification() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil)
    }
    
    
    /// MARK - 处理辅助音频通知
    @objc func handleSecondaryAudio(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
            let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: typeValue) else {
                return
        }
        
        if type == .begin {
            debugPrint("其他应用音频开始播放-静音辅助音频")
        } else {
            self.prepareToRecord()
        }
    }
    
    /// 准备录音
    private func prepareToRecord() {
        
        DispatchQueue.main.async {
           self.prepareCompletionHandler?(self.recorder?.prepareToRecord() ?? false)
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
