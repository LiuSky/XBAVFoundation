//
//  AVPlayerItem+.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


// MARK: - AVPlayerItem
public extension AVPlayerItem {
    
    /// 总缓冲
    func totalBuffer() -> Double {
        return self.loadedTimeRanges
            .map({ $0.timeRangeValue })
            .reduce(0, { acc, cur in
                return acc + CMTimeGetSeconds(cur.start) + CMTimeGetSeconds(cur.duration)
            })
    }
    
    /// 当前缓冲
    func currentBuffer() -> Double {
        let currentTime = self.currentTime()
        
        guard let timeRange = self.loadedTimeRanges.map({ $0.timeRangeValue })
            .first(where: { $0.containsTime(currentTime) }) else { return -1 }
        
        return CMTimeGetSeconds(timeRange.end) - currentTime.seconds
    }
    
}
