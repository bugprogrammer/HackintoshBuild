//
//  MachOFile.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2021/3/4.
//  Copyright © 2021 bugprogrammer. All rights reserved.
//  参照开源方案 https://github.com/DigiDNA/Silicon MIT License.

import Foundation

public class MachOFile
{
    public private( set ) var architectures: [ String ] = []
    
    public init?( path: String )
    {
        do
        {
            let stream = try BinaryStream( path: path )
            let magic  = try stream.readBigEndianUnsignedInteger()
            
            if magic == 0xCAFEBABE
            {
                let count = try stream.readBigEndianUnsignedInteger()
                
                for _ in 0 ..< count
                {
                    let cpu = try stream.readBigEndianUnsignedInteger()
                    let _   = try stream.readBigEndianUnsignedInteger()
                    let _   = try stream.readBigEndianUnsignedInteger()
                    let _   = try stream.readBigEndianUnsignedInteger()
                    let _   = try stream.readBigEndianUnsignedInteger()
                    
                    self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
                }
            }
            else if magic == 0xCEFAEDFE
            {
                let cpu = try stream.readLittleEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xFEEDFACE
            {
                let cpu = try stream.readBigEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xCFFAEDFE
            {
                let cpu = try stream.readLittleEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else if magic == 0xFEEDFACF
            {
                let cpu = try stream.readBigEndianUnsignedInteger()
                
                self.architectures.append( MachOFile.cpuToArch( type: cpu ) )
            }
            else
            {
                return nil
            }
        }
        catch
        {
            return nil
        }
    }
    
    public static func cpuToArch( type: UInt32 ) -> String
    {
        if type == 7 | 0x01000000
        {
            return "x86_64"
        }
        else if type == 12 | 0x01000000
        {
            return "arm64"
        }
        
        return "<unknown>"
    }
}

