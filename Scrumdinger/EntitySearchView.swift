//
//  CategorySearchingView.swift
//  Scrumdinger
//
//  Created by Thomas Kowalski on 08/09/2024.
//

import SwiftUI
import Combine


class SelectedEntities : ObservableObject {
    private var networkManager = NetworkManager()
    private var cancellables = Set<AnyCancellable>()

    private var entitiesFromSearch: [EntityName] = []
    private var entitiesById: [Int: EntityName] = [:]
    var selectedItems = Set<Int>()
    @Published var entitiesToShowInList: [EntityName] = []
        
    func selectedEntities() -> [EntityName] {
        var result: [EntityName] = []
        for s in selectedItems {
            let category = self.entitiesById[s]
            result.append(category.unsafelyUnwrapped)
        }
        
        return result
    }

    func start() {
        print("Starting entity search...")
        
        networkManager.$entitySearchResults.sink {
            [weak self] searchResults in

            let searchResultsList = searchResults.map( { String(describing: $0) }).joined(separator: ", ")
            let selectedCategories = self.unsafelyUnwrapped.selectedItems.map( { x in self.unsafelyUnwrapped.entitiesById[x].unsafelyUnwrapped.name }).joined(separator: ", ")
            print("Updating entities after search")
            print("  Categories: \(searchResultsList)")
            print("  Selected: \(selectedCategories)")
            
            guard let self = self else { return }
        
            for c in searchResults {
                self.entitiesById[c.id] = c
            }

            self.entitiesFromSearch = searchResults
            self.update()
        }
        .store(in: &cancellables)
        
        networkManager.makeRequestToWikimedia(prefix: "Parc naturel", limit: 5)
    }
    
    func search(terms: String) {
        if terms.count < 3 {
            print("Clearing results")
            // self.entitiesById.removeAll()
            self.update()
            return
        }
        
        print("Searching for \(terms)")
        networkManager.searchWikidataEntities(terms: terms, limit: 5)
    }
    
    func update() {
        print("update() called, selected: \(self.selectedItems.count), from search: \(self.entitiesFromSearch.count)")
        var result: [(Bool, EntityName)] = []

        for x in self.entitiesFromSearch {
            result.append((true, x))
        }
        for selectedId in selectedItems {
            guard let x = self.entitiesById[selectedId] else {
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
        self.entitiesToShowInList = result.map( { x in x.1 })
    }
}

struct EntitySearchingView: View {
    @State private var selectedEntityNames = Set<String>()
    @State private var searchTerm: String = ""
    
    @Binding var results: [EntityName]
    @StateObject var entities = SelectedEntities()
    
    var body: some View {
        Form {
            Section {
                TextField("Search categories...", text: $searchTerm)
                    .onChange(of: searchTerm) { newValue in
                        entities.search(terms: newValue)
                    }
            }
            Section {
                EntitiesListView(selectedEntityIds: $entities.selectedItems, allCategoriesToShow: $entities.entitiesToShowInList, parent: self)
            }
        }
        .onAppear {
            entities.start()
        }
    }
    
    func toggleSelection(item: EntityName) {
        if entities.selectedItems.contains(item.id) {
            entities.selectedItems.remove(item.id)
        } else {
            entities.selectedItems.insert(item.id)
        }
        
        entities.update()
        results = entities.selectedEntities()
    }
}

