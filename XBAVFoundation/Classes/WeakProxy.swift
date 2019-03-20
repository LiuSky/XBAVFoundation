//
//  WeakProxy.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/3/20.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation

/// MARK - WeakProxy
public class WeakProxy: NSObject {
    
    /// target
    private(set) weak var target: NSObjectProtocol?
    
    /// 初始化
    ///
    /// - Parameter target: <#target description#>
    init(target: NSObjectProtocol) {
        self.target = target
        super.init()
    }
    
    override public func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
    
    deinit {
        debugPrint("释放弱引用代理")
    }
}
