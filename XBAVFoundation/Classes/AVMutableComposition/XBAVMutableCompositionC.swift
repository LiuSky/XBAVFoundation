//
//  XBAVMutableCompositionC.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/3/20.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit


/// MARK - 音视频合成控制器
final class XBAVMutableCompositionC: UITableViewController {

    private var array = ["两个音频文件合成",
                         "两个视频文件合成"]
    
    private lazy var mutableComposition = XBAVMutableComposition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "音视频合成"
        tableView.rowHeight = 50
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.tableFooterView = UIView()
    }

    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = array[indexPath.row]
        return cell
    }
    

    // MARK - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            
            let paths = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
                .compactMap { URL(fileURLWithPath: $0) }
            
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
            let exportUrl = URL(string: URL(fileURLWithPath: documentsDirectory ?? "").appendingPathComponent("\(UUID().uuidString).m4a").absoluteString)!
            
            mutableComposition.progress = { progress in
                debugPrint("合成进度\(progress)")
            }
            
            mutableComposition.audioSynthetic(paths,
                                              exportUrl: exportUrl) { (e) in
                                                if let temE = e {
                                                    debugPrint(temE)
                                                    return
                                                }
                                                debugPrint("合成成功")
            }
        case 1:
            
            let paths = Bundle.main.paths(forResourcesOfType: "mp4", inDirectory: nil)
                .compactMap { URL(fileURLWithPath: $0) }
            
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
            let exportUrl = URL(string: URL(fileURLWithPath: documentsDirectory ?? "").appendingPathComponent("\(UUID().uuidString).mp4").absoluteString)!
            debugPrint(exportUrl)
            mutableComposition.progress = { progress in
                debugPrint("合成进度\(progress)")
            }
            
            mutableComposition.videoSynthetic(paths,
                                              exportUrl: exportUrl) { (e) in
                                                if let temE = e {
                                                    debugPrint(temE)
                                                    return
                                                }
                                                debugPrint("合成成功")
            }
            
            
            break
        default:
            break
        }
        
    }
}
