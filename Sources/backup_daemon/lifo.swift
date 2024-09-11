//
//  File.swift
//  backup_daemon
//
//  Created by Reece Dowding on 11/09/2024.
//

import Foundation
// Need a mechanism to sort through the dates found in the folder names, and sort according to oldest first. Probably should do that in the main.

enum StackTypes<T: Hashable> {
    case single(T)
    case array([T])
    case set(Set<T>)
    case dictionary([T: Any])
}

/** A stack of type hashable. Native LIFO system.*/
struct LIFO<T: Hashable>  {
    private var stack: [T] = []
    
    /** Adds elements to the end of the stack.  */
    mutating func push(_ element: StackTypes<T>) {
        switch element {
        case .single(let singleElement):
            stack.append(singleElement)
        case .array(let arrElement):
            stack.append(contentsOf: arrElement)
        case .set(let setElement):
            stack.append(contentsOf: setElement)
        case .dictionary(let dictElement):
            stack.append(contentsOf: dictElement.keys)
        }
    }
    
    /** Removes the element at index 0. As its a LIFO stack.*/
    mutating func pop() -> Void {
        if self.stack.isEmpty {
            return
        } else {
            self.stack.remove(at: self.stack.startIndex)
        }
    }
    
    /** Returns elements from the stack within the given range. */
    func getElements(_ range: Range<Int>) -> ArraySlice<T> {
        precondition(range.upperBound >= 0 && range.upperBound <= getSize(), "Range out of index!")
        return self.stack[range.lowerBound ... range.upperBound]
    }
    
    /** Starting from the 0th index.*/
    func getSize() -> Int {
        return self.stack.count - 1
    }
}
