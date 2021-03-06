//
//  BinaryStream.swift
//  HackintoshBuild
//
//  Created by bugprogrammer on 2021/3/4.
//  Copyright © 2021 bugprogrammer. All rights reserved.
//  参照开源方案 https://github.com/DigiDNA/Silicon MIT License.

import Foundation

public class BinaryStream
{
    public enum Error: Swift.Error
    {
        case FileDoesNotExist( String )
        case FileIsADirectory( String )
        case FileIsNotReadable( String )
        case ReadError( String )
        case InvalidFixedFloatingPointFormat( String )
    }
    
    private var stream: InputStream
    private var url:    URL
    
    public convenience init( path: String ) throws
    {
        do
        {
            try self.init( url: URL( fileURLWithPath: path  ) )
        }
        catch let e
        {
            throw e
        }
    }
    
    public init( url: URL ) throws
    {
        var dir: ObjCBool = false
        
        if FileManager.default.fileExists( atPath: url.path, isDirectory: &dir ) == false
        {
            throw Error.FileDoesNotExist( url.path )
        }
        
        if dir.boolValue
        {
            throw Error.FileIsADirectory( url.path )
        }
        
        guard let s = InputStream( url: url ) else
        {
            throw Error.FileIsNotReadable( url.path )
        }
        
        self.url    = url
        self.stream = s
        
        self.stream.open()
    }
    
    deinit
    {
        self.stream.close()
    }
    
    public func readUnsignedChar() throws -> UInt8
    {
        do
        {
            let buf = try self.read( size: 1 )
            
            return buf[ 0 ]
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readSignedChar() throws -> Int8
    {
        do
        {
            let buf = try self.read( size: 1 )
            
            return Int8( buf[ 0 ] )
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readBigEndianUnsignedShort() throws -> UInt16
    {
        do
        {
            let buf = try self.read( size: 2 )
            let n1  = UInt16( buf[ 0 ] )
            let n2  = UInt16( buf[ 1 ] )
            
            return ( n1 << 8 ) | n2
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readLittleEndianUnsignedShort() throws -> UInt16
    {
        do
        {
            let buf = try self.read( size: 2 )
            let n1  = UInt16( buf[ 1 ] )
            let n2  = UInt16( buf[ 0 ] )
            
            return ( n1 << 8 ) | n2
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readBigEndianUnsignedInteger() throws -> UInt32
    {
        do
        {
            let buf = try self.read( size: 4 )
            let n1  = UInt32( buf[ 0 ] )
            let n2  = UInt32( buf[ 1 ] )
            let n3  = UInt32( buf[ 2 ] )
            let n4  = UInt32( buf[ 3 ] )
            
            return ( n1 << 24 ) | ( n2 << 16 ) | ( n3 << 8 ) | n4
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readLittleEndianUnsignedInteger() throws -> UInt32
    {
        do
        {
            let buf = try self.read( size: 4 )
            let n1  = UInt32( buf[ 3 ] )
            let n2  = UInt32( buf[ 2 ] )
            let n3  = UInt32( buf[ 1 ] )
            let n4  = UInt32( buf[ 0 ] )
            
            return ( n1 << 24 ) | ( n2 << 16 ) | ( n3 << 8 ) | n4
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readBigEndianUnsignedLong() throws -> UInt64
    {
        do
        {
            let buf = try self.read( size: 8 )
            let n1  = UInt64( buf[ 0 ] )
            let n2  = UInt64( buf[ 1 ] )
            let n3  = UInt64( buf[ 2 ] )
            let n4  = UInt64( buf[ 3 ] )
            let n5  = UInt64( buf[ 4 ] )
            let n6  = UInt64( buf[ 5 ] )
            let n7  = UInt64( buf[ 6 ] )
            let n8  = UInt64( buf[ 7 ] )
            
            var res = ( n1 << 56 )
            res    |= ( n2 << 48 )
            res    |= ( n3 << 40 )
            res    |= ( n4 << 32 )
            res    |= ( n5 << 24 )
            res    |= ( n6 << 16 )
            res    |= ( n7 << 8 )
            res    |= n8
            
            return res
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readLittleEndianUnsignedLong() throws -> UInt64
    {
        do
        {
            let buf = try self.read( size: 8 )
            let n1  = UInt64( buf[ 7 ] )
            let n2  = UInt64( buf[ 6 ] )
            let n3  = UInt64( buf[ 5 ] )
            let n4  = UInt64( buf[ 4 ] )
            let n5  = UInt64( buf[ 3 ] )
            let n6  = UInt64( buf[ 2 ] )
            let n7  = UInt64( buf[ 1 ] )
            let n8  = UInt64( buf[ 0 ] )
            
            var res = ( n1 << 56 )
            res    |= ( n2 << 48 )
            res    |= ( n3 << 40 )
            res    |= ( n4 << 32 )
            res    |= ( n5 << 24 )
            res    |= ( n6 << 16 )
            res    |= ( n7 << 8 )
            res    |= n8
            
            return res
        }
        catch let e
        {
            throw e
        }
    }
    
    public func readNULLTerminatedString() throws -> String
    {
        var s = String()
        
        while true
        {
            do
            {
                let c = try self.read( size: 1 )[ 0 ]
                
                if c == 0
                {
                    break
                }
                
                s.append( Character( UnicodeScalar( c ) ) )
            }
            catch let e
            {
                throw e
            }
        }
        
        return s
    }
    
    public func read( size: UInt ) throws -> [ UInt8 ]
    {
        if size == 0
        {
            return []
        }
        
        let buf = UnsafeMutablePointer< UInt8 >.allocate( capacity: Int( size ) )
        
        defer
        {
            buf.deallocate()
        }
        
        if self.stream.read( buf, maxLength: Int( size ) ) != Int( size )
        {
            throw Error.ReadError( self.url.path )
        }
        
        var array = [ UInt8 ]()
        
        for i in 0 ..< size
        {
            array.append( buf[ Int( i ) ] )
        }
        
        return array
    }
}

