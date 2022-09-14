/*
* Copyright (c) 2019, Nordic Semiconductor
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

public extension Group {
    
    /// Returns whether the Group is in use in the given mesh network.
    ///
    /// A Group in use may either be a parent of some other Group,
    /// or set as a publication or subscription for any Model or any
    /// Element of any Node belonging to this network.
    ///
    /// - returns: Whether the Group is in use in the mesh network.
    var isUsed: Bool {
        guard let meshNetwork = meshNetwork else {
            return false
        }
        guard !address.address.isSpecialGroup else {
            // Special groups are considered as used by design.
            return true
        }
        for group in meshNetwork.groups {
            // If the Group is a parent of some other Group, return `true`.
            if isDirectParentOf(group) {
                return true
            }
        }
        for node in meshNetwork.nodes {
            for element in node.elements {
                for model in element.models {
                    // If any Node is publishing to this Group, return `true`.
                    if let publish = model.publish {
                        if publish.publicationAddress == address {
                            return true
                        }
                    }
                    // If any Node is subscribed to this Group, return `true`.
                    if model.subscribe.contains(groupAddress) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    /// Returns whether this Group is a direct child group of the
    /// given one.
    ///
    /// - parameter parent: The Group to compare.
    /// - returns: `True` if this Group is a child group of the given one,
    ///            otherwise `false`.
    func isDirectChildOf(_ parent: Group) -> Bool {
        return parent.groupAddress == parentAddress
    }
    
    /// Returns whether this Group is the parent group of the
    /// given one.
    ///
    /// - parameter child: The Group to compare.
    /// - returns: `True` if the given Group is a child group of this one,
    ///            otherwise `false`.
    func isDirectParentOf(_ child: Group) -> Bool {
        return child.isDirectChildOf(self)
    }
    
    /// Returns whether this Group is a child group of the
    /// given one.
    ///
    /// - parameter parent: The Group to compare.
    /// - returns: `True` if this Group is a child group of the given one,
    ///            otherwise `false`.
    func isChildOf(_ parent: Group) -> Bool {
        var group: Group = self
        while let p = group.parent {
            if p == parent {
                return true
            }
            group = p
        }
        return false
    }
    
    /// Returns whether this Group is a parent group of the
    /// given one.
    ///
    /// - parameter child: The Group to compare.
    /// - returns: `True` if this Group is a parent group of the given one,
    ///            otherwise `false`.
    func isParentOf(_ child: Group) -> Bool {
        return child.isChildOf(self)
    }
    
    /// Sets the parent-child relationship between this and the given Group.
    ///
    /// Neigher the Group, or the parent Group can be a Special Group.
    ///
    /// - parameter parent: The parent Group.
    func setAsChildOf(_ parent: Group) {
        guard parent != self else {
            return
        }
        guard !address.address.isSpecialGroup &&
              !parent.address.address.isSpecialGroup else {
            return
        }
        parentAddress = parent.groupAddress
        meshNetwork?.timestamp = Date()
    }
    
    /// Sets the parent-child relationship between this and the given Group.
    ///
    /// Neigher the Group, or the child Group can be a Special Group.
    ///
    /// - parameter child: The child Group.
    func setAsParentOf(_ child: Group) {
        guard child != self else {
            return
        }
        guard !address.address.isSpecialGroup &&
              !child.address.address.isSpecialGroup else {
            return
        }
        child.parentAddress = groupAddress
        meshNetwork?.timestamp = Date()
    }
    
}
