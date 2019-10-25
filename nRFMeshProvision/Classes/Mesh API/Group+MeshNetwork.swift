//
//  Group+MeshNetwork.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 16/07/2019.
//

import Foundation

public extension Group {
    
    /// Returns whether the Group is in use in the given mesh network.
    ///
    /// A Group in use may either be a parent of some other Group,
    /// or set as a publication or subcsription for any Model or any
    /// Element of any Node belonging to this network.
    ///
    /// - returns: Whether the Group is in use in the mesh network.
    var isUsed: Bool {
        guard let meshNetwork = meshNetwork else {
            return false
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
                    if model.subscribe.contains(_address) {
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
        return parent._address == _parentAddress
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
    /// - parameter parent: The parent Group.
    func setAsChildOf(_ parent: Group) {
        guard parent != self else {
            return
        }
        _parentAddress = parent._address
        meshNetwork?.timestamp = Date()
    }
    
    /// Sets the parent-child relationship between this and the given Group.
    ///
    /// - parameter child: The child Group.
    func setAsParentOf(_ child: Group) {
        guard child != self else {
            return
        }
        child._parentAddress = _address
        meshNetwork?.timestamp = Date()
    }
    
}
