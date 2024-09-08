//
//  CategorySearchingView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 08/09/2024.
//

import SwiftUI
import Combine


class SelectedCategories : ObservableObject {
    private var networkManager = NetworkManager()
    private var cancellables = Set<AnyCancellable>()

    private var categoriesFromSearch: [CategoryName] = []
    private var categoriesById: [String: CategoryName] = [:]
    var selectedItems = Set<String>()
    @Published var categoriesToShowInList: [CategoryName] = []
        
    func selectedCategories() -> [CategoryName] {
        var result: [CategoryName] = []
        for s in selectedItems {
            let category = self.categoriesById[s]
            result.append(category.unsafelyUnwrapped)
        }
        
        return result
    }

    func start() {
        print("Starting search...")
        
        networkManager.$categoryResults.sink {
            [weak self] searchResults in

            let searchResultsList = searchResults.map( { String(describing: $0) }).joined(separator: ", ")
            let selectedCategories = self.unsafelyUnwrapped.selectedItems.map( { x in self.unsafelyUnwrapped.categoriesById[x].unsafelyUnwrapped.name }).joined(separator: ", ")
            print("Updating categories after search")
            print("  Categories: \(searchResultsList)")
            print("  Selected: \(selectedCategories)")
            
            guard let self = self else { return }
        
            for c in searchResults {
                self.categoriesById[c.id] = c
            }

            self.categoriesFromSearch = searchResults
            self.update()
        }
        .store(in: &cancellables)
        
        networkManager.makeRequestToWikimedia(prefix: "Parc naturel", limit: 5)
    }
    
    func search(terms: String) {
        if terms.count < 3 {
            print("Clearing results")
            self.categoriesFromSearch.removeAll()
            self.update()
            return
        }
        
        print("Searching for \(terms)")
        networkManager.makeRequestToWikimedia(prefix: terms, limit: 5)
    }
    
    func update() {
        print("update() called, selected: \(self.selectedItems.count), from search: \(self.categoriesFromSearch.count)")
        var result: [(Bool, CategoryName)] = []

        for x in self.categoriesFromSearch {
            result.append((true, x))
        }
        for selectedId in selectedItems {
            guard let x = self.categoriesById[selectedId] else {
                print("Cannot find \(selectedId)")
                continue
            }
            
            var shouldAdd = true
            for alreadyIn in result {
                if alreadyIn.1.name == x.name {
                    print("  skipping already present \(x.name)")
                    shouldAdd = false
                    break
                }
            }
            
            if shouldAdd {
                result.append((false, x))
            }
        }

        result.sort(by: { (first, second) in
            if first.0 != second.0 {
                return first.0
            }
            
            let firstItem = first.1
            let secondItem = second.1
            return firstItem.name < secondItem.name
        })
        self.categoriesToShowInList = result.map( { x in x.1 })
    }
}

struct CategorySearchingView: View {
    @State private var selectedCategoryNames = Set<String>()
    @State private var searchTerm: String = ""
    
    @Binding var results: [CategoryName]
    @StateObject var categories: SelectedCategories = SelectedCategories()
    
    var body: some View {
        Form {
            Section {
                TextField("Search categories...", text: $searchTerm)
                    .onChange(of: searchTerm) { newValue in
                        categories.search(terms: newValue)
                    }
            }
            Section {
                CategoriesListView(selectedCategoryIds: $categories.selectedItems, allCategoriesToShow: $categories.categoriesToShowInList, parent: self)
            }
        }
        .onAppear {
            categories.start()
        }
    }
    
    func toggleSelection(item: CategoryName) {
        if categories.selectedItems.contains(item.id) {
            categories.selectedItems.remove(item.id)
        } else {
            categories.selectedItems.insert(item.id)
        }
        
        categories.update()
        results = categories.selectedCategories()
    }
}

