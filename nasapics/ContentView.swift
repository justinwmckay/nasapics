import SwiftUI
import SDWebImageSwiftUI
import CoreData

struct ContentView: View {
    @State private var imageUrl: URL?
    @State private var imageTitle: String = ""
    @State private var selectedFavoriteTitle: String = ""
    @State private var favoriteImageTitles: [String] = []
    @State private var favoriteImageUrls: [String: URL] = [:]
    
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
                    .padding(.top, 40)
                

                Spacer()

                if let imageUrl = imageUrl {
                    WebImage(url: imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .padding(.bottom)
                } else {
                    Text("loading...")
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 20) {
                    Button(action: fetchNASAImage) {
                        Text("🚀")
                            .padding()
                            .font(.title2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        if isFavorite {
                            removeFavoriteImage()
                        } else {
                            saveFavoriteImage()
                        }
                    }) {
                        Text(isFavorite ? "👎" : "👍")
                            .padding()
                            .font(.title2)
                            .background(isFavorite ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 20)

                if !favoriteImageTitles.isEmpty {
                    HStack(spacing: 5) {
                        Text("❤️")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Picker(selection: $selectedFavoriteTitle, label: EmptyView()) {
                            ForEach(favoriteImageTitles, id: \.self) { title in
                                Text(title).tag(title)
                            }
                        }
                        .onChange(of: selectedFavoriteTitle) { newValue in
                            imageUrl = favoriteImageUrls[newValue]
                            imageTitle = newValue
                        }
                    }
                    .padding(.bottom, 50)
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
                }
            }
        }
    }

    private func saveFavoriteImage() {
        if !favoriteImageTitles.contains(imageTitle) {
            self.favoriteImageTitles.append(imageTitle)
            self.favoriteImageUrls[imageTitle] = imageUrl
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
                    if let title = savedFavorite.title, let urlString = savedFavorite.url, let url = URL(string: urlString) {
                        favoriteImageUrls[title] = url
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
