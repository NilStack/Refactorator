//
//  LineGenerator.swift
//  refactord
//
//  Created by John Holdsworth on 19/12/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Refactorator/refactord/LineGenerator.swift#7 $
//
//  Repo: https://github.com/johnno1962/Refactorator
//

import Foundation

class LineGenerator: GeneratorType {

    let eol: Int32
    let task = NSTask()
    let stdout: NSFileHandle
    let readBuffer = NSMutableData()

    init( command: String, lineSeparator: String = "\n" ) {
        self.eol = Int32(lineSeparator.utf16.first!)

        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exec \(command)"]
        task.currentDirectoryPath = "/tmp"

        let pipe = NSPipe()
        task.standardOutput = pipe.fileHandleForWriting
        stdout = pipe.fileHandleForReading
        task.launch()

        pipe.fileHandleForWriting.closeFile()
    }

    func next() -> String? {
        while true {
            let endOfLine = UnsafeMutablePointer<Int8>( memchr( readBuffer.bytes, eol, readBuffer.length ) )
            if endOfLine != nil {
                endOfLine[0] = 0

                let line = String.fromCString( UnsafePointer<Int8>(readBuffer.bytes) )?
                    .stringByTrimmingCharactersInSet( NSCharacterSet.whitespaceAndNewlineCharacterSet() )
                let consumed = NSMakeRange( 0, UnsafePointer<Void>(endOfLine) + 1 - readBuffer.bytes )
                readBuffer.replaceBytesInRange( consumed, withBytes:nil, length:0 )
                return line
            }

            let bytesRead = stdout.availableData
            if bytesRead.length <= 0 {
                break ///
            }

            readBuffer.appendData( bytesRead )
        }
        return nil
    }

    var sequence: AnySequence<String> {
        return AnySequence({self})
    }

    deinit {
        stdout.closeFile()
        task.terminate()
    }

}
