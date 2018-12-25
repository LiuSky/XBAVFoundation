////
////  XBAudioRecorderHelper.swift
////  XBAVFoundation
////
////  Created by xiaobin liu on 2018/12/25.
////  Copyright © 2018 Sky. All rights reserved.
////
//
//import UIKit
//import Foundation
//import AVFoundation
//
//
//
///// MARK - 录音帮助类
//public class XBAudioRecorderHelper: NSObject, XBAudioSessionProtocol {
//
//    /// 准备录音
//    public typealias PrepareRecorderCompletion = () -> Bool
//
//    /// 开始录音
//    public typealias StartRecorderCompletion = () -> Void
//
//    /// 停止录音
//    public typealias StopRecorderCompletion = () -> Void
//
//    /// 暂停录音
//    public typealias PauseRecorderCompletion = () -> Void
//
//    /// 录音完成
//    public typealias ResumeRecorderCompletion = () -> Void
//
//    /// 取消录音并删除文件
//    public typealias CancellRecorderDeleteFileCompletion = () -> Void
//
//    /// 录音进度
//    public typealias RecordProgress = (Float) -> Void
//
//    /// 音量分贝变化
//    public typealias PeakPowerForChannel = (Float) -> Void
//
//    /// 倒计时
//    public typealias CountdownTimer = (Int) -> Void
//
//    /// 录音进度属性回调
//    public var recordProgress: RecordProgress?
//
//    /// 倒计时属性回调
//    public var countdownTimer: CountdownTimer?
//
//    /// 音量分贝进度
//    public var peakPowerForChannel: PeakPowerForChannel?
//
//    /// 最大录音秒数停止录音属性回调
//    public var maxTimeStopRecorderCompletion: StopRecorderCompletion?
//
//    /// 最大录音时长(默认60)
//    public var maxRecordTime: Float = 60.0
//
//    /// 记录路径
//    private(set) var recordPath: String?
//
//    /// 记录时间(字符串)
//    private(set) var recordDuration: String = "0"
//
//    /// 当前录音时长间隔
//    private(set) var currentTimeInterval: TimeInterval?
//
//    /// 录音机
//    private var recorder: AVAudioRecorder?
//
//    /// 后台任务
//    private var backgroundIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
//
//    /// 计时器
//    private var timer: Timer?
//
//    /// 是否暂停(默认false)
//    private var isPause: Bool = false
//
//    /// 队列
//    private lazy var queue: DispatchQueue = {
//        return DispatchQueue(label: "com.mike.XBAudioRecorderHelper.queue")
//    }()
//
//    public override init() {}
//}
//
//
//// MARK: - public func
//extension XBAudioRecorderHelper {
//
//    /**
//     *  准备记录
//     *
//     *  @param path                      路径
//     *  @param prepareRecorderCompletion 回调
//     */
//    public func prepareRecording(withPath path: String, prepareRecorderCompletion: @escaping PrepareRecorderCompletion) {
//
//        queue.async { in
//
////            guard let self = self else { return }
//
//            self.isPause = false
//            self.setCategory(.playAndRecord)
//            self.setActive(true)
//
//            let setting: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC,
//             AVSampleRateKey: 16000.0,
//             AVNumberOfChannelsKey: 1,
//             AVEncoderBitDepthHintKey: 16,
//             AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue]
//
//            self.recordPath = path
//
//            if self.recorder == nil {
//
//                self.cancelRecording()
//            } else {
//
//                guard let temRecorder = try? AVAudioRecorder(url: URL(fileURLWithPath: path), settings: setting) else {
//                    debugPrint("创建AVAudioRecorder失败")
//                    return
//                }
//
//                temRecorder.delegate = self
//                temRecorder.isMeteringEnabled = true
//                temRecorder.prepareToRecord()
//                temRecorder.record(forDuration: 60)
//                self.recorder = temRecorder
//                self.startBackgroundTask()
//            }
//
//            DispatchQueue.main.async {
//
//                if prepareRecorderCompletion() == false {
//                    // do thing
//                    self.cancelledDelete(with: {
//
//                    })
//                }
//            }
//        }
//    }
//
//    /// 开始录音
//    public func startRecording(with startRecorderCompletion: @escaping StartRecorderCompletion) {
//
//        if self.recorder?.record() ?? false {
//
//            self.resetTimer()
//            self.timer = Timer(timeInterval: 0.05, target: self, selector: #selector(updateMeters), userInfo: nil, repeats: true)
//            RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)
//
//            DispatchQueue.main.async {
//                startRecorderCompletion()
//            }
//        }
//    }
//
//    /// 录音完成
//    public func resumeRecording(with resumeRecorderCompletion: @escaping ResumeRecorderCompletion) {
//
//        self.isPause = false
//        guard let temRecorder = self.recorder else {
//            return
//        }
//
//        if temRecorder.record() {
//            DispatchQueue.main.async {
//                resumeRecorderCompletion()
//            }
//        }
//    }
//
//    /// 暂停记录器
//    public func pauseRecording(with pauseRecorderCompletion: @escaping PauseRecorderCompletion) {
//        self.isPause = true
//
//        guard let temRecorder = self.recorder else {
//            return
//        }
//
//        temRecorder.pause()
//        if temRecorder.isRecording == false {
//            DispatchQueue.main.async {
//                pauseRecorderCompletion()
//            }
//        }
//    }
//
//    /// 停止录音
//    public func stopRecording(with stopRecorderCompletion: @escaping StopRecorderCompletion) {
//        self.isPause = false
//        self.stopBackgroundTask()
//        self.stopRecord()
//            DispatchQueue.main.async {
//                stopRecorderCompletion()
//        }
//    }
//
//    /// MARK - 取消删除文件
//    public func cancelledDelete(with cancelledDeleteCompletion: @escaping CancellRecorderDeleteFileCompletion) {
//
//        self.isPause = false
//        self.stopBackgroundTask()
//        self.stopRecord()
//
//        if let temRecordPath = self.recordPath {
//
//            let fileManeger = FileManager.default
//            if fileManeger.fileExists(atPath: temRecordPath) {
//
//                try? fileManeger.removeItem(atPath: temRecordPath)
//                DispatchQueue.main.async {
//                    cancelledDeleteCompletion()
//                }
//            } else {
//                DispatchQueue.main.async {
//                    cancelledDeleteCompletion()
//                }
//            }
//            // do thing
//            DispatchQueue.main.async {
//                cancelledDeleteCompletion()
//            }
//        } else {
//            DispatchQueue.main.async {
//               cancelledDeleteCompletion()
//            }
//        }
//    }
//
//
//}
//
//
//
//// MARK: - class func
//extension XBAudioRecorderHelper {
//
//
//    /// MARK - 检查是否有麦克风访问权限
//    ///
//    /// - Returns: 是否允许
//    open class func checkMicPermission() -> Bool {
//
//        var permissionCheck: Bool = true
//        switch AVAudioSession.sharedInstance().recordPermission {
//        case AVAudioSession.RecordPermission.granted:
//            permissionCheck = true
//        case AVAudioSession.RecordPermission.denied:
//            permissionCheck = false
//        case AVAudioSession.RecordPermission.undetermined:
//            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
//                if granted {
//                    permissionCheck = true
//                } else {
//                    permissionCheck = false
//                }
//            })
//        default:
//            break
//        }
//
//        return permissionCheck
//    }
//}
//
///// MARK - private func
//extension XBAudioRecorderHelper {
//
//    /// 开始后台任务
//    private func startBackgroundTask() {
//        self.stopBackgroundTask()
//        self.backgroundIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
//            self.stopBackgroundTask()
//        })
//    }
//
//    /// 停止后台任务
//    private func stopBackgroundTask() {
//
//        if self.backgroundIdentifier != UIBackgroundTaskIdentifier.invalid {
//            UIApplication.shared.endBackgroundTask(self.backgroundIdentifier)
//            self.backgroundIdentifier = UIBackgroundTaskIdentifier.invalid
//        }
//    }
//
//    /// 重制计时器
//    private func resetTimer() {
//
//        guard let temTimer = self.timer else {
//            return
//        }
//
//        temTimer.invalidate()
//        self.timer = nil
//    }
//
//    /// 取消录音
//    private func cancelRecording() {
//
//        guard let temRecorder = self.recorder else {
//            return
//        }
//
//        if temRecorder.isRecording {
//            temRecorder.stop()
//        }
//        self.recordDuration = "\(temRecorder.currentTime)"
//        self.recorder = nil
//    }
//
//    /// 停止录音
//    private func stopRecord() {
//
//        self.cancelRecording()
//        self.resetTimer()
//    }
//
//    /// 刷新分贝
//    @objc private func updateMeters() {
//
//        guard let temRecorder = self.recorder else {
//            return
//        }
//
//        queue.async {
//
//            temRecorder.updateMeters()
//            self.currentTimeInterval = temRecorder.currentTime
//
//            if self.isPause == false {
//
//                let progress: Float = Float(temRecorder.currentTime) / self.maxRecordTime * 1.0
//                DispatchQueue.main.async {
//
//                    self.recordProgress?(progress)
//                    let recordInt: Int = Int(self.maxRecordTime - Float(self.currentTimeInterval ?? 0))
//                    if recordInt <= 11 {
//                        self.countdownTimer?(recordInt)
//                    }
//                }
//            }
//
//
//            let peakPower: Double = Double(temRecorder.averagePower(forChannel: 0))
//            let alpha = 0.015
//            let peakPowerForChannel = pow(10, (alpha * peakPower))
//            DispatchQueue.main.async {
//
//                self.peakPowerForChannel?(Float(peakPowerForChannel))
//            }
//
//            if Float(self.currentTimeInterval ?? 0) > self.maxRecordTime {
//                self.stopRecord()
//                DispatchQueue.main.async {
//                    self.maxTimeStopRecorderCompletion?()
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - <#AVAudioRecorderDelegate#>
//extension XBAudioRecorderHelper: AVAudioRecorderDelegate {
//
//    /// 录音结束
//    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
//        self.setActive(false)
//    }
//}
//
