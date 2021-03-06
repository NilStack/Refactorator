//
//  NewRefactorator.swift
//  refactord
//
//  Created by John Holdsworth on 29/01/2016.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Refactorator/refactord/NewRefactorator.swift#23 $
//
//  Repo: https://github.com/johnno1962/Refactorator
//
//

import Foundation

@objc public class NewRefactorator: Refactorator, RefactoratorRequest {

    public func refactorFile( filePath: String, byteOffset: Int32, oldValue: String,
            logDir: String, graph: String?, indexDB: String, plugin: RefactoratorResponse ) -> Int32 {

        if graph == nil {

            xcode = plugin

            if let data = NSData( contentsOfFile: filePath ), indexdb = IndexDB( dbPath: indexDB ) {

                let bytes = UnsafePointer<UInt8>( data.bytes ), end = Int(byteOffset), nl = "\n".utf8.first!
                var pos = 0, line = 1, col = 1

                while pos < end {
                    if bytes[pos] == nl {
                        line += 1
                        col = 1
                    }
                    else {
                        col += 1
                    }
                    pos += 1
                }

                usrToPatch = indexdb.usrInFile( filePath, line: line, col: col )

                if usrToPatch == nil && parseForUSR( filePath, byteOffset: byteOffset, logDir: logDir ) == nil {
                    return -1
                }

                if usrToPatch != nil {
                    xcode.foundUSR( usrToPatch, text: demangle( usrToPatch ) )

                    patches = indexdb.entitiesForUSR( usrToPatch, oldValue: oldValue ).sort(<)

                    for entity in patches {
                        if let contents = NSData( contentsOfFile: entity.file ), patch = entity.patchText( contents, value: oldValue ) {
                            xcode.willPatchFile( entity.file, line: Int32(entity.line), col: Int32(entity.col), text: patch )
                        }
                    }

                    if patches.count != 0 {
                        return Int32(patches.count)
                    }
                }
            }
            else {
                xcode.log( "Error initialising, falling back to previous code" )
            }
        }

        return refactorFile( filePath, byteOffset: byteOffset, oldValue: oldValue, logDir: logDir, graph: graph, plugin: plugin )
    }

}
