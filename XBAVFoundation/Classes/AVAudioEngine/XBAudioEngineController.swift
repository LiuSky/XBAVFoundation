//
//  AVAudioEngineController.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/3/18.
//  Copyright © 2019 Sky. All rights reserved.
//  reference https://github.com/potato04/AudioSpectrum, https://juejin.im/post/5c1bbec66fb9a049cb18b64c

import UIKit
import SnapKit
import AVFoundation


/// MARK - XBAudioEngineController
final class XBAudioEngineController: UIViewController {
    
    /// 光谱视图
    private lazy var spectrumView: SpectrumView = {
        let temSpectrumView = SpectrumView()
        temSpectrumView.backgroundColor = UIColor.black
        let barSpace = self.view.frame.width / CGFloat(player.analyzer.frequencyBands * 3 - 1)
        temSpectrumView.barWidth = barSpace * 2
        temSpectrumView.space = barSpace
        return temSpectrumView
    }()
    
    /// 列表
    private lazy var tableView: UITableView = {
        let temTableView = UITableView()
        temTableView.rowHeight = 50
        temTableView.dataSource = self
        temTableView.delegate = self
        temTableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return temTableView
    }()
    
    /// 播放
    private lazy var player: AudioSpectrumPlayer = {
        let temPlayer = AudioSpectrumPlayer()
        temPlayer.delegate = self
        return temPlayer
    }()
    
    /// 数据源
    private lazy var trackPaths: [String] = {
        var paths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        paths.sort()
        return paths.map { $0.components(separatedBy: "/").last! }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        configView()
        configLocation()
    }
    
    private func configView() {
        view.addSubview(spectrumView)
        view.addSubview(tableView)
    }
    
    private func configLocation() {
        
        self.spectrumView.snp.makeConstraints { (make) in
            make.left.right.equalTo(view)
            make.top.equalTo(view.snp.topMargin)
            make.height.equalTo(150)
        }
        
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.equalTo(view)
            make.top.equalTo(spectrumView.snp.bottom)
            make.bottom.equalTo(view)
        }
    }
}


// MARK: - UITableViewDataSource
extension XBAudioEngineController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackPaths.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        cell?.textLabel?.text = trackPaths[indexPath.row]
        return cell!
    }
}


// MARK: - UITableViewDelegate
extension XBAudioEngineController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.stop()
        player.play(withFileName: trackPaths[indexPath.row])
    }
}

// MARK: - AudioSpectrumPlayerDelegate
extension XBAudioEngineController: AudioSpectrumPlayerDelegate {
    
    func player(_ player: AudioSpectrumPlayer, didGenerateSpectrum spectra: [[Float]]) {
        DispatchQueue.main.async {
            self.spectrumView.spectra = spectra
        }
    }
}
