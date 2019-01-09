//
//  XBVideoPlayerEnum.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2018/12/26.
//  Copyright © 2018 Sky. All rights reserved.
//

import Foundation
import AVFoundation


/// MARK - 播放错误状态编码
public enum XBVideoPlayerErrorStatus: Int, CustomStringConvertible {
    
    ///  未知的错误
    case unknown = 900
    ///  该视频被标记为阻止由于许可限制（地理或装置)
    case videoBlocked = 901
    ///  读取视频流错误
    case fetchStreamError = 902
    ///  找不到视频流资源
    case streamNotFound = 903
    ///  加载资源错误
    case assetLoadError = 904
    ///  加载视频时间错误
    case durationLoadError = 905
    ///  AVPlayer资源加载失败
    case avPlayerFail = 906
    ///  AVPlayerItem资源加载失败
    case avPlayerItemFail = 907
    ///  AVPlayerItem结束失败
    case avPlayerItemEndFail = 908
    
    public var description: String {
        switch self {
        case .unknown:
            return "未知的错误"
        case .videoBlocked:
            return "该视频被标记为阻止由于许可限制（地理或装置）"
        case .fetchStreamError:
            return "读取视频流错误"
        case .streamNotFound:
            return "找不到视频流类型"
        case .assetLoadError:
            return "加载资源错误"
        case .durationLoadError:
            return "加载视频时间错误"
        case .avPlayerFail:
            return "AVPlayer资源加载失败"
        case .avPlayerItemFail:
            return "AVPlayerItem资源加载失败"
        default:
            return "AVPlayerItem结束失败"
        }
    }
}

/// MARK - 超时状态
public enum XBVideoPlayerTimeOutStatus: Int, CustomStringConvertible {
    
    ///  开始加载超时
    case timeOutLoad
    ///  拉进度条的时候缓冲seek超时
    case outSeek
    ///  缓冲超时
    case outBuffer
    
    public var description: String {
        switch self {
        case .timeOutLoad:
            return "开始加载的时候超时"
        case .outSeek:
            return "拉进度条加载的时候超时"
        default:
            return "缓冲超时"
        }
    }
}


///  MARK - 播放状态枚举
public enum XBVideoPlayerStatus: Int, CustomStringConvertible {
    
    ///  未知
    case unknown
    ///  请求StreamURL
    case requestStreamURL
    ///  加载中
    case loading
    ///  准备播放
    case readyToPlay
    ///  播放
    case playing
    ///  暂停播放
    case paused
    ///  暂停卡顿缓冲中
    case buffering
    ///  拖拉进度条seek
    case seeking
    ///  停止播放
    case stopped
    ///  失败
    case error
    
    
    public var description: String {
        switch self {
        case .unknown:
            return "未知"
        case .requestStreamURL:
            return "请求StreamURL"
        case .loading:
            return "加载中"
        case .readyToPlay:
            return "准备播放"
        case .playing:
            return "播放"
        case .paused:
            return "暂停播放"
        case .buffering:
            return "暂停卡顿缓冲中"
        case .seeking:
            return "拖拉进度条seek"
        case .stopped:
            return "停止播放"
        default:
            return "失败"
        }
    }
}


/// MARK - 播放类型
public enum XBVideoPlayerType : Int, CustomStringConvertible {
    
    ///  点播
    case vod
    ///  直播
    case live
    ///  本地
    case local
    
    public var description: String {
        switch self {
        case .vod:
            return "点播"
        case .live:
            return "直播"
        default:
            return "本地播放"
        }
    }
}
