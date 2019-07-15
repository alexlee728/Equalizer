//
//  Loner.swift
//  Equalizer
//
//  Created by Jian Hu on 16/9/27.
//  Copyright © 2016年 DataYP. All rights reserved.
//

import Foundation


private func findAllSourceFile() -> [Path] {
    
    var sourceFiles:[Path] = []
    let path = Path.current
    
    for child in try! path.recursiveChildren() {
        if(child.isDirectory){
            continue
        }
        if child.path.hasSuffix(".swift") {
           sourceFiles.append(child)
        }
    }
    
    return sourceFiles
}

func listLoners(imageSets: [ImageSet]) -> [String]{
    let sources = findAllSourceFile()
    
    var loners:[String] = []
    imageSets.forEach { imageSet in
        let imageSetName = imageSet.name
        
        var hasHost = false
        for srcPath: Path in sources {
            let content = try! srcPath.read(String.Encoding.utf8)
            if content.contains("\"\(imageSetName)\""){
                hasHost = true
                break
            }
        }
        if !hasHost { loners.append(imageSetName) }
    }
    return loners
}
