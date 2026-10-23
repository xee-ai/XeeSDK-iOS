//
//  Data+Gzip.swift
//  XeeSDK
//

import Foundation
import zlib

extension Data {
    /// These bytes as gzip (RFC 1952), or `nil` when zlib fails.
    func gzipped() -> Data? {
        var stream = z_stream()
        let windowBitsForGzip = MAX_WBITS + 16
        guard deflateInit2_(
            &stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, windowBitsForGzip, 8, Z_DEFAULT_STRATEGY,
            ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)
        ) == Z_OK else { return nil }
        defer { deflateEnd(&stream) }

        var output = Data(count: Int(deflateBound(&stream, uLong(count))))
        let status: Int32 = withUnsafeBytes { input in
            output.withUnsafeMutableBytes { out in
                stream.next_in = UnsafeMutablePointer(mutating: input.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(input.count)
                stream.next_out = out.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(out.count)
                return deflate(&stream, Z_FINISH)
            }
        }
        guard status == Z_STREAM_END else { return nil }
        output.count = Int(stream.total_out)
        return output
    }
}
