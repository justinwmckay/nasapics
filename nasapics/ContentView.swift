import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @State private var imageUrl: URL?
    @State private var imageDate: String = ""
    @State private var favoriteImageDates: [String] = []

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()

                if let imageUrl = imageUrl {
                    WebImage(url: imageUrl)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .padding(.bottom)
                } else {
                    Text("No image to display.")
                        .foregroundColor(.white)
                }

                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: fetchNASAImage) {
                        Text("Fetch NASA Image")
                            .padding()
                            .font(.title2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: saveFavoriteImage) {
                        Text("Favorite")
                            .padding()
                            .font(.title2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 20)

                if !favoriteImageDates.isEmpty {
                    Picker(selection: $imageDate, label: Text("Favorite Images")) {
                        ForEach(favoriteImageDates, id: \.self) { date in
                            Text(date).tag(date)
                        }
                    }
                    .onChange(of: imageDate) { newValue in
                        if favoriteImageDates.contains(newValue) {
                            fetchFavoriteImage()
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
            .padding()
        }
        .onAppear(perform: fetchNASAImage)
    }
    
    private func fetchNASAImage() {
        NetworkManager.shared.fetchRandomNASAImage { image in
            if let image = image, let url = URL(string: image.url) {
                DispatchQueue.main.async {
                    self.imageUrl = url
                    self.imageDate = image.date
                }
            }
        }
    }
    
    private func saveFavoriteImage() {
        if !favoriteImageDates.contains(imageDate) {
            self.favoriteImageDates.append(imageDate)
        }
    }

    private func fetchFavoriteImage() {
        NetworkManager.shared.fetchImage(for: imageDate) { image in
            if let image = image, let url = URL(string: image.url) {
                DispatchQueue.main.async {
                    self.imageUrl = url
                }
            }
        }
    }

}
