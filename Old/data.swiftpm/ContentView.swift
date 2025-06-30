import SwiftUI
import ZIPFoundation

// ViewModel for managing the ZIP file contents
class ZipViewModel: ObservableObject {
    @Published var fileNames: [String] = []
    
    // Load the ZIP file from the Resources folder
    func loadZipContents() {
        guard let zipURL = Bundle.main.url(forResource: "Data", withExtension: "zip") else {
            print("Failed to locate ZIP file in resources.")
            return
        }
        
        do {
            // Open the ZIP file for reading
            let archive = try Archive(url: zipURL, accessMode: .read)
            
            // Get the list of file entries in the ZIP
            var entries: [String] = []
            for entry in archive {
                // Only add the file name to the list
                entries.append(entry.path)
            }
            
            // Store the file names
            self.fileNames = entries
        } catch {
            print("Error reading ZIP contents: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ZipViewModel()
    
    var body: some View {
        VStack {
            // Title or Header
            Text("ZIP File Contents")
                .font(.title)
                .padding()
            
            // List to display the contents of the ZIP file
            List(viewModel.fileNames, id: \.self) { fileName in
                Text(fileName)
            }
        }
        .padding()
        .onAppear {
            // Automatically load ZIP contents when the view appears
            viewModel.loadZipContents()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
