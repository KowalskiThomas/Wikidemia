import SwiftUI
import Combine

struct CategoriesListView: View {
    @Binding var selectedCategoryIds: Set<String>
    @Binding var allCategoriesToShow: [CategoryName]
    
    var parent: CategorySearchingView?
    
    var body: some View {
        List(selection: $selectedCategoryIds) {
            ForEach($allCategoriesToShow) { $category in
                Button(action: {
                    guard let parent = parent else { return }
                    
                    withAnimation{
                        parent.toggleSelection(item: category)
                    }
                }) {
                    HStack {
                        Text("\(category.name)")
                        if selectedCategoryIds.contains(category.name)  {
                            Spacer()
                            Image(systemName: "globe")
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: selectedCategoryIds.contains(category.name))
                        }
                    }
                    .foregroundColor(selectedCategoryIds.contains(category.name) ? /*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/ : .black)
                    .animation(.easeInOut(duration: 0.2), value: selectedCategoryIds.contains(category.name))
                }
                .contentShape(Rectangle())
            }
        }
    }
}

#Preview {
    let output: [CategoryName] = []
    let parent = CategorySearchingView(results: .constant(output))
    
    let allCategoriesToShow = [
        CategoryName(name: "Reunion"),
        CategoryName(name: "Mauritius"),
        CategoryName(name: "France"),
    ]
    let selected = Set<String>(arrayLiteral: allCategoriesToShow[1].name)

    return CategoriesListView(selectedCategoryIds: .constant(selected), allCategoriesToShow: .constant(allCategoriesToShow), parent: nil)
}
