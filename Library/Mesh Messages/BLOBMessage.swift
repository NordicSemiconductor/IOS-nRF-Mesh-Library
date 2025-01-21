/*
* Copyright (c) 2025, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// Status codes used by the BLOB Transfer Server and the BLOB Transfer Client models.
public enum BLOBTransferMessageStatus: UInt8, Sendable {
    /// The message was processed successfully.
    case success                 = 0x00
    /// The Block Number field value is not within the range of blocks being transferred.
    case invalidBlockNumber      = 0x01
    /// The block size is smaller than the size indicated by the Min Block Size Log state or is
    /// larger than the size indicated by the Max Block Size Log state.
    case invalidBlockSize        = 0x02
    /// The chunk size exceeds the size indicated by the Max Chunk Size state, or the number of
    /// chunks exceeds the number specified by the Max Total Chunks state.
    case invalidChunkSize        = 0x03
    /// The operation cannot be performed while the server is in the current phase.
    case wrongPhase              = 0x04
    /// A parameter value in the message cannot be accepted.
    case invalidParameter        = 0x05
    /// The message contains a BLOB ID value that is not expected.
    case wrongBlobId             = 0x06
    /// There is not enough space available in memory to receive the BLOB.
    case blobTooLarge            = 0x07
    /// The transfer mode is not supported by the BLOB Transfer Server model.
    case unsupportedTransferMode = 0x08
    /// An internal error occurred on the node.
    case internalError           = 0x09
    /// The requested information cannot be provided while the server is in the current phase.
    case informationUnavailable  = 0x0A
}
