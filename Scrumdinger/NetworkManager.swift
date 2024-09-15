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

struct EntityName: Identifiable, CustomStringConvertible {
    let name: String
    let entity_description: String
    let id: Int
        
    var description: String {
        return name.isEmpty ? "\(id)" : name
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

private struct CsrfTokenData {
    public struct Tokens: Codable {
        let logintoken: String
    }
    
    public struct Query: Codable {
        let tokens: Tokens
    }
    
    public struct Root: Codable {
        let batchcomplete: String
        let query: Query
    }
}

private struct UploadTokenData {
    public struct Tokens: Codable {
        let csrftoken: String
    }
    
    public struct Query: Codable {
        let tokens: Tokens
    }
    
    public struct Root: Codable {
        let batchcomplete: String
        let query: Query
    }
}

public struct LoginResultData {
    public struct Login: Codable {
        let result: String
        let reason: String?
        let lguserid: Int?
        let lgusername: String?
        
        enum CodingKeys: String, CodingKey {
            case result
            case reason
            case lguserid
            case lgusername
        }
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.result = try values.decode(String.self, forKey: .result)

            if values.contains(.reason) {
                self.reason = try values.decode(String.self, forKey: .reason)
            } else {
                self.reason = nil
            }

            if values.contains(.lguserid) {
                self.lguserid = try values.decode(Int.self, forKey: .lguserid)
            } else {
                self.lguserid = nil
            }

            if values.contains(.lgusername) {
                self.lgusername = try values.decode(String.self, forKey: .lgusername)
            } else {
                self.lgusername = nil
            }
        }
    }
    
    
    public struct Root: Codable {
        let login: Login
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
    @Published var entitySearchResults: [EntityName] = []

    private let commonsApiUrl = "https://commons.wikimedia.org/w/api.php"
    // private let wikidataApiUrl = ""
    private let wikidataApiUrl = "https://wikidata.org/w/api.php"
    // private let wikidataApiUrl = "https://test.wikipedia.org/w/api.php"
    
    private var lastPageExistsRequest: String? = nil
    private var lastEntitySearchRequest: String? = nil
    private var lastCategorySearchRequest: String? = nil

    private var _session: URLSession?
    private var session: URLSession {
        guard let session = self._session else {
            self._session = URLSession(configuration: self.config)
            return self.session
        }
        
        return session
    }
    
    private var config: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        return config
    }
    
    func makeRequestToWikimedia(prefix: String, limit: Int) {
        // Replace with your own API endpoint
        guard let url = URL(string: "\(commonsApiUrl)?action=query&format=json&list=allcategories&acprefix=\(prefix)&aclimit=\(limit)") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        self.lastCategorySearchRequest = prefix
        
        print("Making category search request for '\(prefix)'")
        // Create a data task with URLSession
        self.session.dataTask(with: request) { data, response, error in
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
                        if self.lastCategorySearchRequest == prefix {
                            self.categoryResults = result
                        }
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

        self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                let queryResult = try JSONDecoder().decode(SearchPagesData.Root.self, from: data)
                let pages = queryResult.query.pages
                let pageExists = !pages.keys.contains("-1")
                DispatchQueue.main.async {
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
        
        print("Making Wikidata request for '\(terms)'")
        self.lastEntitySearchRequest = terms

        self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                let queryResult = try JSONDecoder().decode(SearchData.Root.self, from: data)
                let matches = queryResult.query.search
                var outputMatches: [EntityName] = []
                for match in matches {
                    outputMatches.append(EntityName(name: match.title, entity_description: match.snippet, id: match.pageid)) // , timestamp: match.timestamp))
                }

                DispatchQueue.main.async {
                    if self.lastEntitySearchRequest == terms {
                        self.entitySearchResults = outputMatches
                    }
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
    
    func getToken() -> String {
        return ""
    }
    
    @Published var loggedUsername: String? = nil
    @Published var loginErrorReason: String? = nil
    func loginToWikidata(token: String, username: String, password: String) {
        guard let url = URL(string: "\(commonsApiUrl)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let formData: [String: String] = [
            "action": "login",
            "format": "json",
            "lgname": username,
            "lgpassword": password,
            "lgtoken": token,
        ]
        let formBodyString = formData.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics).unsafelyUnwrapped)" }.joined(separator: "&")
        let body = formBodyString.data(using: .utf8)
        request.httpBody = body
        
        print("Logging in...")
        self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                let rawResult = String(bytes: data, encoding: .utf8) ?? "ERROR"
                
                let loginResult = try JSONDecoder().decode(LoginResultData.Root.self, from: data)
                let loggedUsername = loginResult.login.lgusername
                DispatchQueue.main.async {
                    self.loggedUsername = loggedUsername
                    self.loginErrorReason = loginResult.login.reason

                    if let loggedUsername = self.loggedUsername {
                        print("Logged in as: \(loggedUsername)")
                    } else {
                        print("Couldn't log in: \(self.loginErrorReason.unsafelyUnwrapped)")
                    }
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
    
    func takeToken() -> String {
        let token = self.csrfToken
        self.csrfToken = ""
        return token
    }
    
    @Published var csrfToken: String = ""
    func getCsrfToken() {
        guard let url = URL(string: "\(commonsApiUrl)?action=query&format=json&meta=tokens&type=login") else {
            print("Invalid URL")
            return
        }
        
        let request = URLRequest(url: url)
        print("Fetching CSRF Token...")
        self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
        
            guard let data = data else {
                print("No data returned by request")
                return
            }

            do {
                let rawResult = String(bytes: data, encoding: .utf8) ?? "ERROR"
                print("Result: \(rawResult))")
                
                let queryResult = try JSONDecoder().decode(CsrfTokenData.Root.self, from: data)
                let token = queryResult.query.tokens.logintoken
                print("CSRF Token: \(token)")
                DispatchQueue.main.async {
                    self.csrfToken = token
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
    
    func doUpload(request: UploadRequest) {
        print("Uploading image as '\(request.title)'")
        
        guard let image = request.image else {
            print("Attempting to upload without an image, aborting.")
            return
        }
        
        guard let fileName = request.title else {
            print("Attempting to upload without a file name, aborting.")
            return
        }
        
        let data = image.jpegData(compressionQuality: 1.0)
        guard let data = data else {
            print("Could not read image data, abording")
            return
        }
        
        let fileSize = data.count
        
        let chunkSize = 50_000
        var bytesLeft = data.count
        var start = 0
        var chunks: [Data] = []
        while bytesLeft > 0 {
            let end = start + min(chunkSize, bytesLeft)
            let bytes = data[start...start+1]
            start += chunkSize
            bytesLeft -= chunkSize
            chunks.append(bytes)
        }
        
        print("Number of chunks \(chunks.count)")
        
        guard let csrfUrl = URL(string: "\(commonsApiUrl)?action=query&meta=tokens&format=json") else {
            print("Invalid URL for CSRF token")
            return
        }
        self.session.dataTask(with: URLRequest(url: csrfUrl)) { data, response, error in
            if let error = error {
                print("Could not get CSRF token: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data returned for CSRF token")
                return
            }
            
            var uploadToken = ""
            do {
                let rawResult = String(bytes: data, encoding: .utf8) ?? "ERROR"
                print("result: \(rawResult)")
                
                let queryResult = try JSONDecoder().decode(UploadTokenData.Root.self, from: data)
                uploadToken = queryResult.query.tokens.csrftoken
            } catch {
                print("Could not decode CSRF token: \(error)")
                return
            }
            
            print("Making first request")
            // ?action=upload&stash=1&filename=\(fileName)&filesize=\(fileSize)&offset=0&format=json&token=\(uploadToken)&ignorewarnings=1")
            guard let uploadUrl = URL(string: "\(self.commonsApiUrl)") else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: uploadUrl)
            request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            // action=upload&stash=1&filename=\(fileName)&filesize=\(fileSize)&offset=0&format=json&token=\(uploadToken)&ignorewarnings=1&file=aaaaaa
            let formData: [String: String] = [
                "action": "upload",
                "stash": "1",
                "filename": "\(fileName).jpg",
                "filesize": "\(fileSize)",
                "offset": "0",
                "format": "json",
                "token": uploadToken,
                "ignorewarnings": "1",
                "file": "aaaaa",
            ]
            let formBodyString = formData.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics).unsafelyUnwrapped)" }.joined(separator: "&")
            print("body string:", formBodyString)
            let body = formBodyString.data(using: .utf8)
            request.httpBody = body


            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching data: \(error)")
                    return
                }
                
                guard let data = data else {
                    print("No data returned by request")
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    print("headers:", response.allHeaderFields)
                } else {
                    print("not the right type")
                }
                do {
                    let rawResult = String(bytes: data, encoding: .utf8) ?? "ERROR"
                    print("Result: \(rawResult))")
                    
                    let queryResult = try JSONDecoder().decode(CsrfTokenData.Root.self, from: data)
                    let token = queryResult.query.tokens.logintoken
                    print("CSRF Token: \(token)")
                    DispatchQueue.main.async {
                        self.csrfToken = token
                    }
                } catch {
                    print("Error decoding data: \(error)")
                }
            }.resume()
        }.resume()
    }
}
