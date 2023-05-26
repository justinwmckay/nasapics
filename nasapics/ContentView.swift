import SwiftUI
import SDWebImageSwiftUI
import CoreData

struct ContentView: View {
    @State private var imageUrl: URL?
    @State private var imageTitle: String = ""
    @State private var selectedFavoriteTitle: String = ""
    @State private var favoriteImageTitles: [String] = []
    @State private var favoriteImageUrls: [String: URL] = [:]
    @State private var imageExplanation: String = ""
    @State private var imageExplanations: [String: String] = [:]
    @State private var imageDate: String = ""
    @State private var showExplanationPopover: Bool = false

    @Environment(\.managedObjectContext) private var viewContext

    var isFavorite: Bool {
        return favoriteImageTitles.contains(imageTitle)
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                Text(imageTitle)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 30)
                Text(imageDate)
                    .font(.title3)
                    .foregroundColor(.white)
                Spacer()
                

                if let imageUrl = imageUrl {
                    WebImage(url: imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .padding(.bottom)
                        .onTapGesture {
                            fetchNASAImage()
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 1.0)
                                .onEnded { _ in
                                    self.showExplanationPopover = true
                                }
                        )
                        .popover(
                            isPresented: self.$showExplanationPopover,
                            arrowEdge: .bottom
                        ) {
                            Text(imageTitle)
                                .font(.title2)
                            Text(imageDate)
                                .font(.title3)
                            Text(imageExplanation).padding()
                        }
                } else {
                    Text("...🚀")
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 20) {
//                    if !favoriteImageTitles.isEmpty {
                        Button(action: {
                            if isFavorite {
                                removeFavoriteImage()
                            } else {
                                saveFavoriteImage()
                            }
                        }) {
                            Text("❤️")
                                .padding()
                                .font(.title2)
                                .background(isFavorite ? Color.green : Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
//
                        Picker(selection: $selectedFavoriteTitle, label: EmptyView()) {
                            ForEach(favoriteImageTitles, id: \.self) { title in
                                Text(title).tag(title)
                            }
                        }
                        .onChange(of: selectedFavoriteTitle) { newValue in
                            imageUrl = favoriteImageUrls[newValue]
                            imageTitle = newValue
                            imageExplanation = imageExplanations[newValue] ?? ""
                            
                        }
//                    }
                }
            }
            .padding()
        }
        .onAppear(perform: {
            fetchNASAImage()
            loadFavoriteImages()
        })
    }

    private func fetchNASAImage() {
        NetworkManager.shared.fetchRandomNASAImage { image in
            if let image = image, let url = URL(string: image.url) {
                DispatchQueue.main.async {
                    self.imageUrl = url
                    self.imageTitle = image.title
                    self.imageExplanation = image.explanation
                    self.imageDate = image.date
                }
            }
        }
    }

    private func saveFavoriteImage() {
        if !favoriteImageTitles.contains(imageTitle) {
            self.favoriteImageTitles.append(imageTitle)
            self.favoriteImageUrls[imageTitle] = imageUrl
            self.imageExplanations[imageTitle] = imageExplanation
            saveFavoriteImages()
        }
    }

    private func removeFavoriteImage() {
        if let index = favoriteImageTitles.firstIndex(of: imageTitle) {
            self.favoriteImageTitles.remove(at: index)
            self.favoriteImageUrls[imageTitle] = nil
            saveFavoriteImages()
        }
    }

    private func saveFavoriteImages() {
        let context = PersistenceManager.shared.context
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<FavoriteImage> = FavoriteImage.fetchRequest()
                let savedFavorites = try context.fetch(fetchRequest)
                for savedFavorite in savedFavorites {
                    context.delete(savedFavorite)
                }
                for title in favoriteImageTitles {
                    let favoriteImage = FavoriteImage(context: context)
                    favoriteImage.title = title
                    favoriteImage.url = favoriteImageUrls[title]?.absoluteString
                    favoriteImage.explanation = imageExplanations[title]
                }
                try context.save()
            } catch {
                print("Failed to save favorite images: \(error)")
            }
        }
    }

    private func loadFavoriteImages() {
        let context = PersistenceManager.shared.context
        context.performAndWait {
            do {
                let fetchRequest: NSFetchRequest<FavoriteImage> = FavoriteImage.fetchRequest()
                let savedFavorites = try context.fetch(fetchRequest)
                favoriteImageTitles = savedFavorites.compactMap { $0.title }
                for savedFavorite in savedFavorites {
                    if let title = savedFavorite.title, let urlString = savedFavorite.url, let url = URL(string: urlString), let explanation = savedFavorite.explanation {
                        favoriteImageUrls[title] = url
                        imageExplanations[title] = explanation
                    }
                }
                if let firstTitle = favoriteImageTitles.first {
                    selectedFavoriteTitle = firstTitle
                    imageUrl = favoriteImageUrls[firstTitle]
                    imageTitle = firstTitle
                }
            } catch {
                print("Failed to load favorite images: \(error)")
            }
        }
    }
}
