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

/// Export configuration allows to narrow down the exported configuration to a
/// required minimum.
///
/// When sharing a mesh network configuration a care must be taken not to
/// share sensitive information to prevent unauthorized use.
///
/// When sharing a configuration with a guest, a separate Network Key and
/// set of Application Keys should be created. The Nodes given to the guest under
/// control should be configured to use the keys. The guest can be fgiven only
/// the part of the network related to the guest Network Key, with all other data
/// excluded. Also, to prevent reconfiguration of the Nodes, only partial Nodes
/// configuration can be shared, which excludes the Device Keys of those Nodes.
public enum ExportConfiguration {
    
    /// Network Keys configuration.
    public enum NetworkKeysConfiguration {
        /// All Network Keys will be exported.
        case all
        /// Only given Network Keys will be exported.
        ///
        /// Nodes that do not know the given Network Keys will be excluded
        /// (even when nodes are exported with
        /// ``ExportConfiguration/NetworkKeysConfiguration/all`` option).
        /// Excluded keys will also be excluded from Model binding on exported Nodes.
        case some([NetworkKey])
    }
    
    /// Application Keys configuration.
    public enum ApplicationKeysConfiguration {
        /// All Application Keys will be exported.
        case all
        /// Only given Application Keys will be exported.
        ///
        /// Excluded keys will be excluded from Model binding on exported Nodes.
        case some([ApplicationKey])
    }
    
    /// Export configuration related to ``Provisioner``s.
    public enum ProvisionersConfiguration {
        /// All Provisioner objects will be exported.
        case all
        /// Only the given Provisioner will be exported. This is usually the
        /// object that should then be assigned to the device this configuration
        /// will be imported on. The Provisioner object should be prepared before
        /// exporting the network configuration.
        case one(Provisioner)
        /// The given Provisioners will be exported. The list cannot be empty.
        case some([Provisioner])
    }
    
    /// Export configuration related to Nodes. This allows exporting
    /// a subset of Nodes or excluding the Device Keys.
    public enum NodesConfiguration {
        /// All Nodes that match Network Keys and Application Keys filter will be
        /// exported. Nodes belonging to excluded Provisioners will not be
        /// exported.
        case allWithDeviceKey
        /// The same as ``ExportConfiguration/NodesConfiguration/allWithDeviceKey``,
        /// but device keys will not be exported.
        case allWithoutDeviceKey
        /// The given Nodes will be exported. This allows to export Nodes with
        /// Device Key (full) or without Device Key (partial). The device on which
        /// partial configuration is imported will not be able to reconfigure
        /// such Nodes. At least one Node must be exported.
        case some(withDeviceKey: [Node], andSomeWithout: [Node])
    }
    
    /// Export configuration related to user-defined Groups.
    public enum GroupsConfiguration {
        /// All Groups will be exported, also those that none of the Models is
        /// subscribed to.
        case all
        /// The exported configuration will contain only those Groups, that any
        /// exported Model is subscribed or publishing to.
        case related
        /// Only the given Groups will be exported. Excluded Groups will also be
        /// excluded from subscription lists and publish information in exported
        /// Models.
        case some([Group])
    }
    
    /// Export configuration related to user-defined Scenes.
    public enum ScenesConfiguration {
        /// All Scenes will be exported. The scenes will not contain addresses of
        /// excluded Nodes.
        case all
        /// The exported configuration will contain only those Scenes, that are
        /// stored on any exported Node. The scenes will not contain addresses of
        /// excluded Nodes.
        case related
        /// Only the given Scenes will be exported. The scenes will not contain
        /// addresses of excluded Nodes.
        case some([Scene])
    }
    
    /// This configuration will contain the whole copy of local mesh network.
    case full
    /// Using partial export configuration only some information can be exported.
    ///
    /// This may be useful when sharing mesh configuration with a guest, which
    /// does not need to know all Nodes, or their Device Keys. Guest may only be
    /// allowed to control Nodes, but not to change their configuration.
    case partial(networkKeys: NetworkKeysConfiguration,
                 applicationKeys: ApplicationKeysConfiguration,
                 provisioners: ProvisionersConfiguration,
                 nodes: NodesConfiguration,
                 groups: GroupsConfiguration = .related,
                 scenes: ScenesConfiguration = .related)
}

