//
//  main.swift
//  gls
//
//  Created by Olivier Poitrey on 9/6/15.
//  Copyright (c) 2015 Hackemist. All rights reserved.
//

import Foundation
import AppKit

let fileManager = NSFileManager.defaultManager()
let workspace = NSWorkspace.sharedWorkspace()

// Read path from first argument if any, fallback to current directory
var path = fileManager.currentDirectoryPath
if Process.arguments.count >= 2 {
    path = Process.arguments[1]
    if Array(path)[0] != "/" {
        path = fileManager.currentDirectoryPath.stringByAppendingPathComponent(path)
    }
}

// List directory content
var error: NSError? = nil
let pathURL = NSURL(fileURLWithPath: path)
let properties = [NSURLIsSymbolicLinkKey, NSURLFileResourceTypeKey]
let contents = fileManager.contentsOfDirectoryAtURL(pathURL!, includingPropertiesForKeys: properties, options: (.SkipsHiddenFiles), error: &error)
let graphicOutput = isatty(STDOUT_FILENO) != 0

for url in contents as! [NSURL] {
    path = url.path!

    if graphicOutput {
        // Get file icon
        let icon = workspace.iconForFile(path)

        // Resize
        let scaledSize = NSSize(width: 16, height: 16)
        let scaledIcon = NSImage(size: scaledSize)
        scaledIcon.lockFocus()
        icon.drawInRect(NSRect(x: 0, y: 0, width: scaledSize.width, height: scaledSize.height), fromRect: CGRect(origin: CGPointZero, size: icon.size), operation: NSCompositingOperation.CompositeSourceOver, fraction: CGFloat(1.0))
        scaledIcon.unlockFocus()

        // Convert to base64
        var data: NSData = scaledIcon.TIFFRepresentation!
        var bitmap: NSBitmapImageRep = NSBitmapImageRep(data: data)!
        data = bitmap.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
        let iconB64 = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)

        // Output line

        print("\u{001B}]1337;File=inline=1;height=1;width=2;preserveAspectRatio=true:")
        print(iconB64)
        print("\u{0007}")
    }
    print(path.lastPathComponent)

    // Add file type specific info
    var rsrc: AnyObject?
    url.getResourceValue(&rsrc, forKey: NSURLFileResourceTypeKey, error: nil)
    if let type = rsrc as? String {
        switch type {
        case NSURLFileResourceTypeDirectory:
            print("/")
        case NSURLFileResourceTypeSymbolicLink:
            print(" -> ")
            print(fileManager.destinationOfSymbolicLinkAtPath(path, error: nil)!)
        default:
            break
        }
    }
    println()
}
