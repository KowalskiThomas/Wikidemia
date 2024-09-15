import SwiftUI
import Combine

struct EntitiesListView: View {
    @Binding var selectedEntityIds: Set<Int>
    @Binding var allCategoriesToShow: [EntityName]
    
    var parent: EntitySearchingView?
    
    var body: some View {
        List(selection: $selectedEntityIds) {
            ForEach($allCategoriesToShow) { $entity in
                Button(action: {
                    guard let parent = parent else { return }
                    
                    withAnimation{
                        parent.toggleSelection(item: entity)
                    }
                }) {
                    HStack {
                        Text("\(entity.name) \(entity.entity_description  )")
                        if selectedEntityIds.contains(entity.id)  {
                            Spacer()
                            Image(systemName: "globe")
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: selectedEntityIds.contains(entity.id))
                        }
                    }
                    .foregroundColor(selectedEntityIds.contains(entity.id) ? /*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/ : .black)
                    .animation(.easeInOut(duration: 0.2), value: selectedEntityIds.contains(entity.id))
                }
                .contentShape(Rectangle())
            }
        }
    }
}

#Preview {
    let output: [EntityName] = []
    let parent = EntitySearchingView(results: .constant(output))
    
    let allCategoriesToShow = [
        EntityName(name: "Reunion", entity_description: "French island", id: 1),
        EntityName(name: "Mauritius", entity_description: "Independent island", id: 2),
        EntityName(name: "France", entity_description: "Sovereign state in Europe", id: 3),
    ]
    let selected = Set<Int>(arrayLiteral: allCategoriesToShow[1].id)

    return EntitiesListView(
        selectedEntityIds: .constant(selected),
        allCategoriesToShow: .constant(allCategoriesToShow),
        parent: nil
    )
}
