import SwiftUI
import SDWebImageSwiftUI
import CoreData
import Photos

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
    @State private var isLoading: Bool = true
    @State private var showSaveConfirmation: Bool = false

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var isFavorite: Bool {
        return favoriteImageTitles.contains(imageTitle)
    }

    @ViewBuilder
    var imageView: some View {
        if isLoading {
            Text("...🚀")
                .font(.title)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        } else if let imageUrl = imageUrl {
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
                    VStack() {
                        Text(imageTitle)
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(imageDate)
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text(imageExplanation)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                        Text(imageUrl.absoluteString)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Button(action: {
                            saveImageToPhotos()
                        }) {
                            Text("Save to Photos")
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
                .transition(.opacity)
        }
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            colorScheme == .dark ? Color.black.edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)


            VStack {
                Text(imageTitle)
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 30)
                Text(imageDate)
                    .font(.title3)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                
                imageView

                Spacer()

                HStack(spacing: 20) {
                    Button(action: {
                        if isFavorite {
                            removeFavoriteImage()
                        } else {
                            saveFavoriteImage()
                        }
                    }) {
                        Text(isLoading ? " " : "❤️")
                            .padding()
                            .font(.title2)
                            .background(isFavorite ? Color.blue : (colorScheme == .dark ? .black : .white))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .cornerRadius(10)
                    }
                    Picker(selection: $selectedFavoriteTitle, label: EmptyView()) {
                        ForEach(favoriteImageTitles, id: \.self) { title in
                            Text(title).tag(title)
                        }
                    }
                    .onChange(of: selectedFavoriteTitle) { newValue in
                        withAnimation(.easeInOut(duration: 1.0)) {
                            imageUrl = favoriteImageUrls[newValue]
                            imageTitle = newValue
                            imageExplanation = imageExplanations[newValue] ?? ""
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isLoading = false
                fetchNASAImage()
                loadFavoriteImages()
            }
        })
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Saved to Photos"),
                message: Text("The image has been saved to your Photos."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveImageToPhotos() {
        print("Triggered saveImageToPhotos!!!!")
        guard let imageUrl = imageUrl else {
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized {
                let fetchOptions = PHFetchOptions()
                fetchOptions.fetchLimit = 1
                let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                
                if let album = fetchResult.firstObject {
                    PHPhotoLibrary.shared().performChanges {
                        let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageUrl)
                        assetChangeRequest?.creationDate = Date()
                        assetChangeRequest?.location = CLLocation()
                        
                        let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset
                        let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                        albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
                    } completionHandler: { success, error in
                        if let error = error {
                            print("Failed to save image to Photos: \(error)")
                        } else {
                            DispatchQueue.main.async {
                                showSaveConfirmation = true
                            }
                        }
                    }
                }
            } else {
                print("Photo library access denied.")
            }
        }
    }
    
    private func fetchNASAImage() {
        NetworkManager.shared.fetchRandomNASAImage { image in
            if let image = image, let url = URL(string: image.url) {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.imageUrl = url
                        self.imageTitle = image.title
                        self.imageExplanation = image.explanation
                        self.imageDate = image.date
                    }
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
