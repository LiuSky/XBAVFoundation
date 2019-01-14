//
//  XBCameraViewController.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/1/11.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import AVFoundation

/// MARK - 照相机视图控制器
final class XBCameraViewController: UIViewController, XBAudioSessionProtocol {

    /// 照相机控制器
    private lazy var cameraController: XBCameraController = {
        let temCameraController = XBCameraController()
        temCameraController.delegate = self
        return temCameraController
    }()
    
    /// 预览视图
    private lazy var previewView: XBPreviewView = {
        let temPreView = XBPreviewView()
        return temPreView
    }()
    
    /// 照相按钮
    private lazy var captureButton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.setTitle("拍照", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForCapture), for: .touchUpInside)
        return temButton
    }()
    
    /// 视频按钮
    private lazy var videoButton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.setTitle("视频", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForVideo), for: .touchUpInside)
        return temButton
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.title = "照相机"
        self.setCategory(.playAndRecord)
        self.setActive(true)
        
        self.configView()
        
        try? self.cameraController.setupSession()
        self.previewView.session = cameraController.captureSession
        self.cameraController.startSession()
    }
    
    private func configView() {
        
        self.view.addSubview(self.previewView)
        self.previewView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        self.view.addSubview(self.captureButton)
        self.captureButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(-150)
            make.centerX.equalTo(self.view)
            make.size.equalTo(CGSize(width: 100, height: 44))
        }
        
        self.view.addSubview(self.videoButton)
        self.videoButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.captureButton.snp.bottom).offset(12)
            make.centerX.equalTo(self.captureButton.snp.centerX)
            make.size.equalTo(self.captureButton.snp.size)
        }
    }
    
    
    /// 照相
    @objc private func eventForCapture() {
        self.cameraController.captureStillImage()
    }
    
    /// 视频
    @objc private func eventForVideo() {
        if self.cameraController.isRecording == false {
            DispatchQueue(label: "1").async {
                self.cameraController.startRecording()
            }
        } else {
            self.cameraController.stopRecording()
        }
    }
    
    
    deinit {
        
        self.setActive(false)
        debugPrint("释放照相机控制器")
    }
}

extension XBCameraViewController: XBCameraControllerDelegate {
    
    func deviceConfigurationFailed(_ error: NSError) {
        debugPrint(error)
    }
    
    func mediaCaptureFailed(_ error: NSError) {
        debugPrint(error)
    }
    
    func assetLibraryWriteFailed(_ error: NSError) {
        debugPrint(error)
    }
}
