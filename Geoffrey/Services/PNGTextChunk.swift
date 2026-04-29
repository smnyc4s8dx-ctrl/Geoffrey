import Foundation

/// PNG `tEXt`-chunk read/write for Tavern Card embedded JSON.
/// Reference: https://www.w3.org/TR/png/#11tEXt
enum PNGTextChunk {

    enum Error: Swift.Error, LocalizedError {
        case notPNG
        case malformed
        case keywordNotFound

        var errorDescription: String? {
            switch self {
            case .notPNG: "Not a PNG file."
            case .malformed: "PNG file is corrupt or truncated."
            case .keywordNotFound: "PNG does not contain the expected tEXt keyword."
            }
        }
    }

    private static let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    // MARK: - Read

    /// Reads the value of a `tEXt` chunk by keyword (e.g. "chara", "ccv3").
    /// Returns the latin1-decoded text payload, or nil if not present.
    static func readText(_ keyword: String, from data: Data) throws -> String? {
        try readAllText(from: data)[keyword]
    }

    /// Reads every `tEXt` chunk into a [keyword: text] dictionary.
    static func readAllText(from data: Data) throws -> [String: String] {
        guard data.count > signature.count else { throw Error.notPNG }
        guard data.prefix(signature.count).elementsEqual(signature) else { throw Error.notPNG }

        var result: [String: String] = [:]
        var offset = signature.count

        while offset + 8 <= data.count {
            let length = Int(readUInt32BE(data, at: offset))
            let typeStart = offset + 4
            let dataStart = offset + 8
            let dataEnd = dataStart + length
            let crcEnd = dataEnd + 4

            guard crcEnd <= data.count, length >= 0 else { throw Error.malformed }

            let typeBytes = data[typeStart..<dataStart]
            let type = String(bytes: typeBytes, encoding: .ascii) ?? ""

            if type == "tEXt" {
                let chunkData = data[dataStart..<dataEnd]
                if let nullIndex = chunkData.firstIndex(of: 0) {
                    let keywordBytes = chunkData[chunkData.startIndex..<nullIndex]
                    let textBytes = chunkData[(nullIndex + 1)..<chunkData.endIndex]
                    if let key = String(bytes: keywordBytes, encoding: .isoLatin1),
                       let text = String(bytes: textBytes, encoding: .isoLatin1) {
                        result[key] = text
                    }
                }
            }

            if type == "IEND" { break }
            offset = crcEnd
        }

        return result
    }

    // MARK: - Write

    /// Returns a new PNG with a `tEXt` chunk inserted (or replaced) for `keyword`.
    /// Inserts the chunk immediately after the IHDR header per PNG spec convention.
    static func writeText(_ keyword: String, value: String, into pngData: Data) throws -> Data {
        guard pngData.count > signature.count else { throw Error.notPNG }
        guard pngData.prefix(signature.count).elementsEqual(signature) else { throw Error.notPNG }

        var output = Data()
        output.append(contentsOf: signature)

        var offset = signature.count
        var insertedAfterIHDR = false

        while offset + 8 <= pngData.count {
            let length = Int(readUInt32BE(pngData, at: offset))
            let chunkStart = offset
            let typeStart = offset + 4
            let dataStart = offset + 8
            let dataEnd = dataStart + length
            let crcEnd = dataEnd + 4

            guard crcEnd <= pngData.count, length >= 0 else { throw Error.malformed }

            let typeBytes = pngData[typeStart..<dataStart]
            let type = String(bytes: typeBytes, encoding: .ascii) ?? ""

            // Drop any existing tEXt chunk with the same keyword.
            if type == "tEXt" {
                let chunkData = pngData[dataStart..<dataEnd]
                if let nullIndex = chunkData.firstIndex(of: 0) {
                    let keywordBytes = chunkData[chunkData.startIndex..<nullIndex]
                    if let existingKeyword = String(bytes: keywordBytes, encoding: .isoLatin1),
                       existingKeyword == keyword {
                        offset = crcEnd
                        continue
                    }
                }
            }

            // Copy the chunk verbatim.
            output.append(pngData[chunkStart..<crcEnd])

            // Insert our chunk right after IHDR, before any other chunks.
            if type == "IHDR" && !insertedAfterIHDR {
                output.append(makeTextChunk(keyword: keyword, text: value))
                insertedAfterIHDR = true
            }

            if type == "IEND" { break }
            offset = crcEnd
        }

        guard insertedAfterIHDR else { throw Error.malformed }
        return output
    }

    // MARK: - Chunk construction

    private static func makeTextChunk(keyword: String, text: String) -> Data {
        let keywordBytes = Data(keyword.unicodeScalars.compactMap { $0.value < 256 ? UInt8($0.value) : nil })
        let textBytes = Data(text.unicodeScalars.compactMap { $0.value < 256 ? UInt8($0.value) : nil })

        var payload = Data()
        payload.append(keywordBytes)
        payload.append(0)
        payload.append(textBytes)

        var typeAndPayload = Data()
        typeAndPayload.append(contentsOf: Array("tEXt".utf8))
        typeAndPayload.append(payload)

        let crc = crc32(typeAndPayload)

        var chunk = Data()
        chunk.append(uint32BE(UInt32(payload.count)))
        chunk.append(typeAndPayload)
        chunk.append(uint32BE(crc))
        return chunk
    }

    // MARK: - Endian helpers

    private static func readUInt32BE(_ data: Data, at offset: Int) -> UInt32 {
        let b0 = UInt32(data[data.startIndex + offset])
        let b1 = UInt32(data[data.startIndex + offset + 1])
        let b2 = UInt32(data[data.startIndex + offset + 2])
        let b3 = UInt32(data[data.startIndex + offset + 3])
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    private static func uint32BE(_ value: UInt32) -> Data {
        var data = Data(count: 4)
        data[0] = UInt8((value >> 24) & 0xFF)
        data[1] = UInt8((value >> 16) & 0xFF)
        data[2] = UInt8((value >> 8) & 0xFF)
        data[3] = UInt8(value & 0xFF)
        return data
    }

    // MARK: - CRC32 (zlib polynomial, used by PNG)

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    private static func crc32(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        for byte in data {
            let idx = Int((c ^ UInt32(byte)) & 0xFF)
            c = crcTable[idx] ^ (c >> 8)
        }
        return c ^ 0xFFFFFFFF
    }
}
