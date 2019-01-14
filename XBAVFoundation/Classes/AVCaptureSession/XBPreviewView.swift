//
//  XBPreviewView.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/1/14.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import AVFoundation

/// MARK - 预览视图
final class XBPreviewView: UIView {

    /// 设置捕捉会话
    public var session: AVCaptureSession {
        set {
            (self.layer as! AVCaptureVideoPreviewLayer).session = newValue
        }
        get {
            return (self.layer as! AVCaptureVideoPreviewLayer).session!
        }
    }
    
    
    /// 重写layerClass类方法返回一个AVPlayerLayer类
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.black
        self.setupView()
    }
    
    
    /// 设置View
    private func setupView() {
        (self.layer as! AVCaptureVideoPreviewLayer).videoGravity = .resizeAspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
