//
//  XBCameraControllerDelegate.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/1/11.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


/// MARK - 照相机控制器委托
public protocol XBCameraControllerDelegate: NSObjectProtocol {
    
    
    /// 设备配置失败方法
    ///
    /// - Throws: 错误原因
    func deviceConfigurationFailed(_ error: NSError)
    
    
    /// 媒体捕捉失败方法
    ///
    /// - Throws: 错误原因
    func mediaCaptureFailed(_ error: NSError)
    
    
    /// 资源写入失败方法
    ///
    /// - Throws: 错误原因
    func assetLibraryWriteFailed(_ error: NSError)
}


// MARK: - 通知名称
public extension Notification {
    
    
    /// 图片保存到相册通知
    static let ThumbnailCreated = Notification.Name(rawValue: "com.mike.camera.notification.name.thumbnailCreated")
}
