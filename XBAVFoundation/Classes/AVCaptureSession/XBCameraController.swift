//
//  XBCameraController.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/1/11.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import AssetsLibrary


/// Context
private var cameraAdjustingExposureContext: Int = 103
private var exposureKeyPath = "adjustingExposure"


/// MARK - 照相机控制器
open class XBCameraController: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    /// 委托
    public weak var delegate: XBCameraControllerDelegate?
    
    /// AVCaptureSession
    private(set) lazy var captureSession: AVCaptureSession = {
        let temCaptureSession = AVCaptureSession()
        temCaptureSession.sessionPreset = AVCaptureSession.Preset.high
        return temCaptureSession
    }()
    
    /// AVCaptureDeviceInput
    private var activeVideoInput: AVCaptureDeviceInput!
    
    /// 设置静态图片输出对象
    private lazy var imageOutput: AVCaptureStillImageOutput = {
        let temImageOutput = AVCaptureStillImageOutput()
        temImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        return temImageOutput
    }()
    
    /// 设置视频文件输出对象
    private lazy var movieOutput: AVCaptureMovieFileOutput = {
        let temMovieOutput = AVCaptureMovieFileOutput()
        return temMovieOutput
    }()
    
    /// 当前活动摄像头
    private var activeCamera: AVCaptureDevice {
        return self.activeVideoInput.device
    }
    
    /// 输出路径
    private var outputURL: URL?
    
    /// 全球队列
    private lazy var globalQueue: DispatchQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
}



// MARK: - public attribute
extension XBCameraController {
    
    /// 相机数量
    public var cameraCount: Int {
        return AVCaptureDevice.devices(for: .video).count
    }
    
    /// 是否支持手电筒
    public var cameraHasTorch: Bool {
        return self.activeCamera.hasTorch
    }
    
    /// 是否支持闪光灯
    public var cameraHasFlash: Bool {
        return self.activeCamera.hasFlash
    }
    
    /// 是否支持自动对焦
    public var cameraSupportsTapToFocus: Bool {
        return self.activeCamera.isFocusPointOfInterestSupported
    }
    
    /// 是否支持曝光点
    public var cameraSupportsTapToExpose: Bool {
        return self.activeCamera.isExposurePointOfInterestSupported
    }
    
    /// 手电筒模式
    public var torchMode: AVCaptureDevice.TorchMode {
        set {
            
            if self.activeCamera.torchMode != torchMode &&
                self.activeCamera.isTorchModeSupported(torchMode) {
                
                do {
                    try self.activeCamera.lockForConfiguration()
                    self.activeCamera.torchMode = torchMode
                    self.activeCamera.unlockForConfiguration()
                } catch let error as NSError {
                    self.delegate?.deviceConfigurationFailed(error)
                }
            }
        }
        get {
            return self.activeCamera.torchMode
        }
    }
    
    
    /// 闪光灯模式
    public var flashMode: AVCaptureDevice.FlashMode {
        set {
            
            if self.activeCamera.flashMode != flashMode &&
                self.activeCamera.isFlashModeSupported(flashMode) {
               
                do {
                    try self.activeCamera.lockForConfiguration()
                    self.activeCamera.flashMode = flashMode
                    self.activeCamera.unlockForConfiguration()
                } catch let error as NSError {
                    self.delegate?.deviceConfigurationFailed(error)
                }
            }
        }
        get {
            return self.activeCamera.flashMode
        }
    }
    
    
    /// 是否正在录音
    public var isRecording: Bool {
        return self.movieOutput.isRecording
    }
    
    
    /// 录音时间
    public var recordedDuration: CMTime {
        return self.movieOutput.recordedDuration
    }
}



// MARK: - public func
extension XBCameraController {
    
    /// MARK - 设置会话
    public func setupSession() throws {
        
        /// 设置默认的摄像设备
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            /// 后续处理
            throw NSError(domain: "123213", code: 0, userInfo: nil)
        }

        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
            self.activeVideoInput = videoInput
        }

        
        /// 设置默认麦克风
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
               throw NSError(domain: "com.mike.camera", code: 1, userInfo: nil)
        }
        
        if self.captureSession.canAddInput(audioInput) {
            self.captureSession.addInput(audioInput)
        }
        
        
        /// 设置静态图像输出
        if self.captureSession.canAddOutput(self.imageOutput) {
           self.captureSession.addOutput(self.imageOutput)
        }
        
        /// 设置电影文件输出
        if self.captureSession.canAddOutput(self.movieOutput) {
            self.captureSession.addOutput(self.movieOutput)
        }
    }
    
    
    /// MARK - 开始会话
    public func startSession() {
        
        if self.captureSession.isRunning == false {
            self.globalQueue.async {
                self.captureSession.startRunning()
            }
        }
    }
    
    
    /// MARK - 停止会话
    public func stopSession() {
        if self.captureSession.isRunning {
            self.globalQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    
    
    /// 切换摄像头
    ///
    /// - Returns: 切换成功or失败
    public func switchCameras() -> Bool {
        
        if !self.canSwitchCameras() {
            return false
        }
        
        guard let viedeoDevice = self.inactiveCamera(),
              let videoInput = try? AVCaptureDeviceInput(device: viedeoDevice) else {
            // 回调
            return false
        }
        
        self.captureSession.beginConfiguration()
        self.captureSession.removeInput(self.activeVideoInput)
        
        if self.captureSession.canAddInput(videoInput) {
            self.captureSession.addInput(videoInput)
            self.activeVideoInput = videoInput
        } else {
            self.captureSession.addInput(self.activeVideoInput)
        }
        self.captureSession.commitConfiguration()
        return true
    }
    
    
    /// 是否支持切换摄像头
    ///
    /// - Returns: true or false
    public func canSwitchCameras() -> Bool {
        return self.cameraCount > 1
    }
    
    
    /// 设置对焦
    ///
    /// - Parameter point: 位置
    public func focus(at point: CGPoint) {

        /// 记得修改错误为其他的方式
        let device: AVCaptureDevice = self.activeCamera
        if device.isFocusPointOfInterestSupported &&
            device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
            
            do {
                try device.lockForConfiguration()
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch let error as NSError {
                self.delegate?.deviceConfigurationFailed(error)
            }
        }
    }
    
    
    /// 设置曝光点
    ///
    /// - Parameter point: 位置
    public func expose(at point: CGPoint) {
        
        let devide = self.activeCamera
        
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        
        if devide.isExposurePointOfInterestSupported &&
           devide.isExposureModeSupported(exposureMode) {
            
            do {
                
                try devide.lockForConfiguration()
                devide.exposurePointOfInterest = point
                devide.exposureMode = exposureMode
                if devide.isExposureModeSupported(AVCaptureDevice.ExposureMode.locked) {
                    devide.addObserver(self,
                                       forKeyPath: exposureKeyPath,
                                       options: NSKeyValueObservingOptions.new,
                                       context: &cameraAdjustingExposureContext)
                }
                devide.unlockForConfiguration()
                
            } catch let error as NSError {
                self.delegate?.deviceConfigurationFailed(error)
            }
        }
    }
    
    
    /// 监听
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - object: <#object description#>
    ///   - change: <#change description#>
    ///   - context: <#context description#>
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if context == &cameraAdjustingExposureContext {
            
            let device: AVCaptureDevice = object as! AVCaptureDevice
            if !device.isAdjustingExposure &&
                device.isExposureModeSupported(AVCaptureDevice.ExposureMode.locked) {
                
                device.removeObserver(self,
                                      forKeyPath: exposureKeyPath,
                                      context: &cameraAdjustingExposureContext)
                DispatchQueue.main.async {
                    do {
                        try device.lockForConfiguration()
                        device.exposureMode = AVCaptureDevice.ExposureMode.locked
                        device.unlockForConfiguration()
                    } catch let error as NSError {
                        self.delegate?.deviceConfigurationFailed(error)
                    }
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    /// 重置曝光点和闪光灯
    public func resetFocusAndExposureModes() {
        
        let device = self.activeCamera
        let exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
        let focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
        
        let canResetFocus = device.isFocusPointOfInterestSupported
            && device.isFocusModeSupported(focusMode)
        
        let canResetExposure = device.isExposurePointOfInterestSupported &&
            device.isExposureModeSupported(exposureMode)
        
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        
        do {
            
            try device.lockForConfiguration()
            if canResetFocus {
                device.focusMode = focusMode
                device.focusPointOfInterest = centerPoint
            }
            
            if canResetExposure {
                device.exposureMode = exposureMode
                device.exposurePointOfInterest = centerPoint
            }
            
            device.unlockForConfiguration()
        } catch let error as NSError {
            self.delegate?.deviceConfigurationFailed(error)
        }
    }
    
    
    /// 静态图片捕捉方法
    public func captureStillImage() {
        
        guard let connection = self.imageOutput.connection(with: AVMediaType.video) else {
            debugPrint("失败")
            return
        }
        
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = self.currentVideoOrientation()
        }
        
        
        self.imageOutput.captureStillImageAsynchronously(from: connection) { (sampleBuffer, error) in
            if let temSampleBuffer = sampleBuffer,
               let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(temSampleBuffer),
               let image = UIImage(data: imageData)  {
                self.writeImage(toPhotoLibrary: image)
            } else {
                debugPrint("NUll sampleBuffer \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    
    /// 开始录音
    public func startRecording() {

        if !self.isRecording {

            guard let videoConnection = self.movieOutput.connection(with: .video) else {
                debugPrint("失败")
                return
            }

            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = self.currentVideoOrientation()
            }

            /// 会导致屏幕一闪
            if videoConnection.isVideoStabilizationSupported {
                videoConnection.enablesVideoStabilizationWhenAvailable = true
                //preferredVideoStabilizationMode = .auto
            }
            
            
        
            let device = self.activeCamera
            if device.isSmoothAutoFocusSupported {

                do {

                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()

                } catch let error as NSError {
                    self.delegate?.deviceConfigurationFailed(error)
                }
            }


            self.outputURL = self.uniqueURL()
            self.movieOutput.startRecording(to: self.outputURL!, recordingDelegate: self)
        }
    }
    
    
    /// 停止录音
    public func stopRecording() {
        
        if self.isRecording {
            self.movieOutput.stopRecording()
        }
    }
    
    
    /// 录制视频完成时
    ///
    /// - Parameters:
    ///   - output: 捕捉文件输出
    ///   - outputFileURL: 文件输出路径
    ///   - connections: 连接
    ///   - error: 错误
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let temError = error {
            self.delegate?.mediaCaptureFailed(temError as NSError)
        } else {
            self.writeVideo(toAssetsLibrary: outputFileURL)
        }
        self.outputURL = nil
    }
}


// MARK: - private func
extension XBCameraController {
    
    
    /// 遍历可用的视频设备
    ///
    /// - Parameter position: 位置(前置摄像头,后置摄像头)
    /// - Returns: 捕捉设备
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        for device: AVCaptureDevice in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    
    /// 获取未激活的摄像头
    ///
    /// - Returns: 捕捉设备
    private func inactiveCamera() -> AVCaptureDevice? {
        
        var device: AVCaptureDevice? = nil
        if cameraCount > 1 {
            if self.activeCamera.position == .back {
                device = camera(with: AVCaptureDevice.Position.front)
            } else {
                device = camera(with: AVCaptureDevice.Position.back)
            }
        }
        return device
    }
    
    
    
    /// 写入图片到照片库
    ///
    /// - Parameter image: <#image description#>
    private func writeImage(toPhotoLibrary image: UIImage) {
        
        let library = ALAssetsLibrary()
        library.writeImage(toSavedPhotosAlbum: image.cgImage!, orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue) ?? ALAssetOrientation.up) { (url, error) in
            if let error = error {
                debugPrint("保存失败")
            } else {
                debugPrint("通知")
                self.postThumbnailNotifification(image)
            }
        }
    }
    
    
    /// 发送通知
    private func postThumbnailNotifification(_ image: UIImage) {
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.ThumbnailCreated, object: image)
        }
    }
    
    
    
    /// 创建一个唯一的临时文件路径
    ///
    /// - Returns: 路径
    private func uniqueURL() -> URL {
        
        let directory = NSTemporaryDirectory()
        let fileName = NSUUID().uuidString
        let dirPath = NSURL.fileURL(withPathComponents: [directory, "\(fileName).mov"])
        return dirPath!
    }
    
    
    
    /// 视频写入相册
    ///
    /// - Parameter videoURL: 视频路径
    private func writeVideo(toAssetsLibrary videoURL: URL) {
        
        let library = ALAssetsLibrary()
        
        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: videoURL) {
            
            library.writeVideoAtPath(toSavedPhotosAlbum: videoURL) { (url, error) in
                
                if let temError = error {
                    self.delegate?.assetLibraryWriteFailed(temError as NSError)
                } else {
                    debugPrint("录制写入成功")
                    self.generateThumbnailForVideo(at: videoURL)
                }
                
            }
        }
    }
    
    
    /// 生成视频缩略图
    ///
    /// - Parameter videoURL: 路径
    private func generateThumbnailForVideo(at videoURL: URL) {
        
        self.globalQueue.async {
            
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.maximumSize = CGSize(width: 100, height: 0)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let imageRef = try! imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            DispatchQueue.main.async {
                self.postThumbnailNotifification(image)
            }
        }
    }
    
    
    /// 当前设方向
    ///
    /// - Returns: AVCaptureVideoOrientation
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        
        var orientation: AVCaptureVideoOrientation?
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .landscapeRight
        }
        
        return orientation!
    }
}
