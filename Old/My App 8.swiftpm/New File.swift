import SwiftUI

// Generic ItemWrapper class inside ContentView.swift

class ItemWrapper<T> {
    
    enum Content {
        case item(T)
        case items([ItemWrapper<T>])
    }
    
    private(set) var content: Content
    
    // Initializer for a single item
    init(item: T) {
        self.content = .item(item)
    }
    
    // Initializer for an array of ItemWrappers
    init(items: [ItemWrapper<T>]) {
        self.content = .items(items)
    }
    
    // Add a nested ItemWrapper (creating a new ItemWrapper to preserve immutability)
    func add(nestedItem: ItemWrapper<T>) -> ItemWrapper<T> {
        switch content {
        case .items(var items):
            items.append(nestedItem)
            return ItemWrapper(items: items)
        case .item:
            return ItemWrapper(items: [self, nestedItem])
        }
    }
    
    // Check if the current wrapper holds a single item
    var isSingleItem: Bool {
        if case .item = content {
            return true
        }
        return false
    }
    
    // Get all the items if it's a wrapper holding multiple items
    var allItems: [ItemWrapper<T>]? {
        if case .items(let items) = content {
            return items
        }
        return nil
    }
    
    // Get the item if it's a single item wrapper
    var item: T? {
        if case .item(let singleItem) = content {
            return singleItem
        }
        return nil
    }
    
    // Custom description to print the contents of the wrapper
    var description: String {
        switch content {
        case .item(let item):
            return "Item(\(item))"
        case .items(let items):
            return "Items([\(items.map { $0.description }.joined(separator: ", "))])"
        }
    }
    
    // Custom debug description to help with debugging
    var debugDescription: String {
        return "ItemWrapper(content: \(description))"
    }
}

// Function to recursively print wrapped strings
func printWrappedStrings<T>(_ wrapper: ItemWrapper<T>, result: inout String) {
    switch wrapper.content {
    case .item(let item):
        // We only want to print the string if the item is a String
        if let stringItem = item as? String {
            result += "\(stringItem) "
        }
    case .items(let items):
        // If it's a list of wrapped items, recursively print each one
        for itemWrapper in items {
            printWrappedStrings(itemWrapper, result: &result)
        }
    }
}

struct ContentView: View {
    
    @State private var resultText: String = ""
    
    var body: some View {
        VStack {
            Text(resultText)
                .padding()
                .font(.title)
                .frame(width: 300, height: 200, alignment: .top)
            
            Button(action: {
                // Test Case 1: Flat structure
                let wrapper1 = ItemWrapper(item: "one")
                let wrapper2 = ItemWrapper(item: "two")
                let wrapper3 = ItemWrapper(item: "three")
                let arrayWrapper1 = ItemWrapper(items: [wrapper1, wrapper2, wrapper3])
                
                // Test Case 2: Nested structure with one array inside
                let wrapper4 = ItemWrapper(item: "one")
                let arrayWrapper2 = ItemWrapper(item: "two")
                let wrapper5 = ItemWrapper(item: "three")
                let arrayWrapper3 = ItemWrapper(items: [arrayWrapper2, wrapper5])
                let arrayWrapper4 = ItemWrapper(items: [wrapper4, arrayWrapper3])
                
                // Test Case 3: Nested structure with multiple levels
                let wrapper6 = ItemWrapper(item: "one")
                let arrayWrapper5 = ItemWrapper(item: "two")
                let arrayWrapper6 = ItemWrapper(items: [arrayWrapper5])
                let arrayWrapper7 = ItemWrapper(items: [arrayWrapper6])
                let arrayWrapper8 = ItemWrapper(items: [wrapper6, arrayWrapper7])
                
                // Test Case 4: Deeply nested array inside array
                let wrapper9 = ItemWrapper(item: "one")
                let arrayWrapper9 = ItemWrapper(item: "two")
                let arrayWrapper10 = ItemWrapper(item: "three")
                let deepArrayWrapper = ItemWrapper(items: [arrayWrapper9, arrayWrapper10])
                let arrayWrapper11 = ItemWrapper(items: [wrapper9, deepArrayWrapper])
                
                // Test Case 5: Single element (not nested)
                let wrapper10 = ItemWrapper(item: "hello")
                
                // Prepare the result string
                var result = ""
                
                // Running all test cases
                // Test Case 1
                result += "Test Case 1: Flat structure\n"
                printWrappedStrings(arrayWrapper1, result: &result)
                result += "\n\n" // Add a line break between test cases
                
                // Test Case 2
                result += "Test Case 2: Nested structure with one array inside\n"
                printWrappedStrings(arrayWrapper4, result: &result)
                result += "\n\n"
                
                // Test Case 3
                result += "Test Case 3: Nested structure with multiple levels\n"
                printWrappedStrings(arrayWrapper8, result: &result)
                result += "\n\n"
                
                // Test Case 4
                result += "Test Case 4: Deeply nested array inside array\n"
                printWrappedStrings(arrayWrapper11, result: &result)
                result += "\n\n"
                
                // Test Case 5
                result += "Test Case 5: Single element\n"
                printWrappedStrings(wrapper10, result: &result)
                result += "\n\n"
                
                // Update the UI with all the results
                resultText = result
            }) {
                Text("Print All Test Cases")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
