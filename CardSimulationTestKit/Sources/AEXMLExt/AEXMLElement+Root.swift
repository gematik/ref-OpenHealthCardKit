//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import AEXML

extension AEXMLElement {
    /// Returns true if this `AEXMLElement` has no parent element.
    public var isRoot: Bool {
        self.parent == nil
    }

    /// Replace a child element with `child` at specified `index` and return the original replaced element.
    ///
    /// - Parameters:
    ///    - index: the index at which to place the new child
    ///    - child: the new element to replace the old one
    /// - Note: The replaced child keeps the reference to its parent but is no longer referenced from the parent.
    ///
    /// - Return: the previous element at `index`
    open func replaceChild(at index: Int, with child: AEXMLElement) -> AEXMLElement {
        let prev = children[index]
        var childrenCopied = children

        // Remove all children from self
        children.forEach { elem in
            elem.removeFromParent()
        }
        childrenCopied[index] = child
        childrenCopied.forEach { childCopied in
            self.addChild(childCopied)
        }

        return prev
    }
}
