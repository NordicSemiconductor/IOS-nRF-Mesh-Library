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

import UIKit

class NodeProgressViewCell: NodeViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var progressIndicator: CircularProgressView!
    @IBOutlet weak var throughoutLabel: UILabel!
    
    // MARK: - Properties
    
    var progress: Float? {
        didSet {
            guard !failure && !success else {
                return
            }
            if let progress = progress {
                progressIndicator?.progress = progress
                progressIndicator?.isHidden = progress == 1.0
                throughoutLabel?.isHidden = progress == 1.0 || progress == 0
            } else {
                progressIndicator?.isHidden = true
                throughoutLabel?.isHidden = true
            }
        }
    }
    
    var speedBytesPerSecond: Float? {
        didSet {
            if let speedBytesPerSecond = speedBytesPerSecond {
                throughoutLabel?.text = String(format: "%.2f kB/s", speedBytesPerSecond / 1024)
            }
        }
    }
    
    var failure: Bool = false {
        didSet {
            if failure {
                progressIndicator?.isHidden = true
                throughoutLabel?.isHidden = true
                accessoryView = UIImageView(image: UIImage(systemName: "xmark"))
                tintColor = .systemRed
            }
        }
    }
    
    var success: Bool = false {
        didSet {
            if success && !failure {
                progressIndicator?.isHidden = true
                throughoutLabel?.isHidden = true
                accessoryType = .checkmark
                accessoryView = nil
            }
        }
    }
}
