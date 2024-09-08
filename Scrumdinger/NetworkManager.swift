import Foundation

private struct AllCategoriesData {
    // Define a structure for each category in the 'allcategories' array
    public struct Category: Codable {
        let name: String
        
        // Use a custom coding key to map the JSON key '*' to the property 'name'
        private enum CodingKeys: String, CodingKey {
            case name = "*"
        }
    }
    
    // Define a structure for the 'query' object
    public struct Query: Codable {
        let allcategories: [Category]
    }
    
    // Define a structure for the root of the JSON
    public struct Root: Codable {
        let batchcomplete: String
        let query: Query
    }
}

struct CategoryName: Identifiable, CustomStringConvertible {
    let name: String
    
    var id: String {
        get {
            return name
        }
    }
    
    var description: String {
        return name
    }
}

private struct SearchPagesData {
    public struct Page: Codable {
        let ns: Int
        let title: String
        // let missing: String?
    }
    
    public struct Query: Codable {
        let pages: [String: Page]
    }
    
    public struct Root: Codable {
        let batchcomplete: String
        let query: Query
    }
}

private struct SearchData {
    public struct Page: Codable {
        let ns: Int
        let title: String
        let pageid: Int
        let size: Int?
        let wordcount: Int?
        let snippet: String
        let timestamp: String
    }
    
    public struct SearchInfo: Codable {
        let totalhits: Int
    }
    
    public struct QueryResults: Codable {
        let searchinfo: SearchInfo
        let search: [Page]
    }
    
    public struct Root: Codable {
        let batchcomplete: String
        let query: QueryResults
    }
}

public struct SearchMatch {
    let pageId: Int
    let title: String
    let description: String
    let timestamp: String
}

class NetworkManager: ObservableObject {
    @Published var categoryResults: [CategoryName] = []
    @Published var pageExists: Bool = false
    @Published var searchResults: [SearchMatch] = []
    
    private let commonsApiUrl = "https://commons.wikimedia.org/w/api.php"
    private let wikidataApiUrl = "https://wikidata.org/w/api.php"
    private var lastPageExistsRequest: String? = nil
    private var latestSearchRequest: String? = nil
    
    func makeRequestToWikimedia(prefix: String, limit: Int) {
        // Replace with your own API endpoint
        guard let url = URL(string: "\(commonsApiUrl)?action=query&format=json&list=allcategories&acprefix=\(prefix)&aclimit=\(limit)") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        
        print("Making request for '\(prefix)'")
        // Create a data task with URLSession
        URLSession.shared.dataTask(with: request) { data, response, error in
            // print("before sleep")
            // sleep(5)
            // print("after sleep")

            // Handle error
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            
            // Handle response and decode the data
            if let data = data {
                do {
                    var result: [CategoryName] = []
                    let decodedUser = try JSONDecoder().decode(AllCategoriesData.Root.self, from: data)
                    for r in decodedUser.query.allcategories {
                        result.append(CategoryName(name: r.name))
                    }
                    DispatchQueue.main.async {
                        self.categoryResults = result
                    }

                } catch {
                    print("Error decoding data: \(error)")
                }
            }
        }.resume()
    }
    
    func checkIfFileExists(name: String) {
        // Replace with your own API endpoint
        guard let url = URL(string: "\(commonsApiUrl)?action=query&format=json&titles=File:\(name)") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        
        print("Making request for 'File:\(name)'")
        self.lastPageExistsRequest = name

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                print("Result: \(String(bytes: data, encoding: .utf8) ?? "ERROR"))")
                
                let queryResult = try JSONDecoder().decode(SearchPagesData.Root.self, from: data)
                let pages = queryResult.query.pages
                let pageExists = !pages.keys.contains("-1")
                DispatchQueue.main.async {
                    print("Page exists? \(pageExists)")
                    if self.lastPageExistsRequest == name {
                        self.pageExists = pageExists
                    }
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
    
    func searchWikidataEntities(terms: String, limit: Int = 15) {
        guard let url = URL(string: "\(wikidataApiUrl)?action=query&format=json&list=search&srsearch=\(terms)&srlimit=\(limit)") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        
        print("Making Wikidata request for 'File:\(terms)'")
        self.latestSearchRequest = terms

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                print("Result: \(String(bytes: data, encoding: .utf8) ?? "ERROR"))")
                
                let queryResult = try JSONDecoder().decode(SearchData.Root.self, from: data)
                let matches = queryResult.query.search
                var outputMatches: [SearchMatch] = []
                for match in matches {
                    outputMatches.append(SearchMatch(pageId: match.pageid, title: match.title, description: match.snippet, timestamp: match.timestamp))
                }
                
                let data = outputMatches.map({ match in match.description.isEmpty ? match.title : match.description }).joined(separator: ", ")
                print("Output: \(data)")
                DispatchQueue.main.async {
                    if self.latestSearchRequest == terms {
                        self.searchResults = outputMatches
                    }
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }

}
