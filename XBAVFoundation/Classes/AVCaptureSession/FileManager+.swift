//
//  FileManager+.swift
//  XBAVFoundation
//
//  Created by xiaobin liu on 2019/1/11.
//  Copyright © 2019 Sky. All rights reserved.
//


import Foundation


//extension FileManager {
//    
//    func temporaryDirectory(withTemplateString templateString: String) -> String {
//        
//        let mkdTemplate = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(templateString).absoluteString
//        
//        let templateCString = (mkdTemplate as NSString).fileSystemRepresentation
//        let buffer = Int8(malloc(strlen(templateCString) + 1))
//        strcpy(buffer, templateCString)
//        
//        var directoryPath: String? = nil
//        
//        let result = mkdtemp(buffer)
//        if result {
//            directoryPath = string(withFileSystemRepresentation: &buffer, length: strlen(result))
//        }
//        free(buffer)
//        return directoryPath
//    }
//    
//}
