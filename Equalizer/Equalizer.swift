//
//  Equalizer.swift
//  Equalizer
//
//  Created by Jian Hu on 16/5/14.
//  Copyright © 2016年 DataYP. All rights reserved.
//

import Foundation


struct ImageSet {
    
    // File path to `.imageset` directory
    let path: String
    
    // Image set name
    let name: String
    
    // Dictionay of ``Contents.json`
    let content: Dictionary<String, AnyObject>
    
    // Check if imageset name matching file name
    func nameMatching() -> Bool{
        let images = content["images"] as! [[String:AnyObject]]
        for image in images{
            guard let fileName = image["filename"] else {
                continue
            }
            if !(fileName.hasPrefix("\(name)@")){
                return false
            }
        }
        
        return true
    }
}

func findTargetImageSets() -> [ImageSet] {
    
    var tagetImageSets:[ImageSet] = []
    let path = Path.current
    
    for child in try! path.children() {
        if(!child.isDirectory){
            continue
        }
        if child.path.hasSuffix(".imageset") {
            let imageSet = ImageSet(path: child.path, name: child.lastComponentWithoutExtension, content: readContent(path: Path("\(child.path)/Contents.json")))
            if !imageSet.nameMatching() {
                tagetImageSets.append(imageSet)
            }
        }else {
            child.chdir{
                tagetImageSets.append(contentsOf:findTargetImageSets())
            }
        }
    }
    
    return tagetImageSets
}

func findAllImageSets() -> [ImageSet] {
    
    var imageSets:[ImageSet] = []
    let path = Path.current
    
    for child in try! path.children() {
        if(!child.isDirectory){
            continue
        }
        if child.path.hasSuffix(".imageset") {
            let imageSet = ImageSet(path: child.path, name: child.lastComponentWithoutExtension, content: readContent(path: Path("\(child.path)/Contents.json")))
            imageSets.append(imageSet)
        }else {
            child.chdir{
                imageSets.append(contentsOf:findAllImageSets())
            }
        }
    }
    
    return imageSets
}

func readContent(path: Path) -> [String:AnyObject] {
    
    let content = try! JSONSerialization.jsonObject(with: try! path.read(), options: .allowFragments)
    
    return content as! [String : AnyObject]
}

func correctName(imageSet: ImageSet) {
    var content = imageSet.content
    let contentPath = Path("\(imageSet.path)/Contents.json")
    let imageSetName = imageSet.name
    
    var images = content["images"] as! [[String:AnyObject]]
    for (idx, image) in images.enumerated(){
        guard let fileName = image["filename"] else {
            continue
        }

        let scale = image["scale"] as! String
        var separator = "@"
        if scale == "1x" {
            separator = "."
        }

        var components = fileName.components(separatedBy: separator)
        if components.count == 1{
            separator = "."
            components = fileName.components(separatedBy: separator)
            if (components.count != 2) {
                continue
            }

            if (scale == "1x" || scale == "2x" || scale == "3x") {
                let oldComponents1 = components[1]
                components[1] = "\(scale)\(separator)\(oldComponents1)"
                separator = "@"
            }
        }
        else if components.count == 2{
        }
        else {
            continue
        }

        let correctFileName = "\(imageSetName)\(separator)\(components[1])"
        
        // change image name
        let srcFilePath = Path("\(imageSet.path)/\(fileName)")
        let destFilePath = Path("\(imageSet.path)/\(correctFileName)")

        if (FileManager.default.fileExists(atPath: srcFilePath.path) && !FileManager.default.fileExists(atPath: destFilePath.path)) {
            try! srcFilePath.move(destFilePath)
        }

        var mutImage = image
        mutImage["filename"] = correctFileName as AnyObject

        images[idx] = mutImage
    }
    
    content["images"] = images as AnyObject
    
    // write back content.json
    try! contentPath.delete()
    let data = try! JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
    try! contentPath.write(data)
}

