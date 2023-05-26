import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    let baseURL = "https://api.nasa.gov/planetary/apod"
    let apiKey = "2RU6Yl2xEN8H5BYdAdc7HmoopC2DH3dk2j2kghdX"
    
    func fetchImage(for date: String, completion: @escaping (NASAImage?) -> Void) {
        guard let url = URL(string: "\(baseURL)?date=\(date)&api_key=\(apiKey)") else {
            completion(nil)
            return
        }

        fetchImage(from: url, completion: completion)
    }

    func fetchRandomNASAImage(completion: @escaping (NASAImage?) -> Void) {
        let randomDate = self.randomDateInPastTenYears()

        guard let url = URL(string: "\(baseURL)?date=\(randomDate)&api_key=\(apiKey)") else {
            completion(nil)
            return
        }

        fetchImage(from: url, completion: completion)
    }

    private func fetchImage(from url: URL, completion: @escaping (NASAImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            do {
                let image = try JSONDecoder().decode(NASAImage.self, from: data)
                completion(image)
            } catch {
                completion(nil)
            }
        }

        task.resume()
    }

    private func randomDateInPastTenYears() -> String {
        let days = Int(arc4random_uniform(365 * 10))
        let secondsPerDay = 86400
        let randomSeconds = -days * secondsPerDay
        let randomDate = Date(timeIntervalSinceNow: TimeInterval(randomSeconds))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: randomDate)
    }
}
