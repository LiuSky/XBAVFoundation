//
//  DispatchQueue.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation


// MARK: - DispatchQueue
public extension DispatchQueue {
    
    /// 主线程执行
    public static func mainThread(execute closure: @escaping () -> Void) {
        
        if Thread.isMainThread {
            closure()
        }
        else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
    /// 延迟执行
    public static func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
