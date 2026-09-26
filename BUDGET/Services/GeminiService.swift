import Foundation

struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { var text: String? }
            var parts: [Part]?
        }
        var content: Content?
    }
    var candidates: [Candidate]?
    var error: GeminiAPIError?
}

struct GeminiAPIError: Decodable {
    var message: String?
}

enum GeminiServiceError: LocalizedError {
    case missingKey
    case emptyPrompt
    case network(String)
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return "Kunci API Gemini belum diatur."
        case .emptyPrompt:
            return "Pertanyaan kosong."
        case .network(let message):
            return message
        case .invalidResponse:
            return "Respons Gemini tidak dapat dibaca."
        case .api(let message):
            return message
        }
    }
}

actor GeminiService {
    static let shared = GeminiService()

    private let session: URLSession
    private let model = "gemini-2.0-flash"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func testConnection(apiKey: String) async throws -> String {
        try await generate(
            apiKey: apiKey,
            prompt: "Balas dengan satu kata: OK",
            system: "You are a connection test. Reply briefly."
        )
    }

    func generate(apiKey: String, prompt: String, system: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw GeminiServiceError.missingKey }
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw GeminiServiceError.emptyPrompt
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(trimmedKey)"
        guard let url = URL(string: urlString) else { throw GeminiServiceError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": system]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 1024
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GeminiServiceError.network(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let decoded = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let message = decoded.error?.message {
                throw GeminiServiceError.api(message)
            }
            throw GeminiServiceError.network("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        if let message = decoded.error?.message {
            throw GeminiServiceError.api(message)
        }
        let text = decoded.candidates?
            .first?
            .content?
            .parts?
            .compactMap(\ .text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else { throw GeminiServiceError.invalidResponse }
        return text
    }
}

enum GeminiPromptBuilder {
    static let system = """
    Kamu asisten keuangan pribadi yang berhati-hati.
    Gunakan hanya data yang diberikan pengguna.
    Jangan mengada-ada angka.
    Jangan memberi nasihat investasi.
    Jelaskan bahwa estimasi bukan jaminan.
    Jawab dalam bahasa Indonesia yang ringkas dan jelas.
    """

    static func summarize(context: String) -> String {
        "Ringkas pola pengeluaran berikut. Jangan menambah angka yang tidak ada.\n\n\(context)"
    }

    static func unusual(context: String) -> String {
        "Jelaskan perubahan pengeluaran yang tampak tidak biasa berdasarkan data berikut. Jika datanya kurang, katakan begitu.\n\n\(context)"
    }

    static func categorize(payee: String, note: String, categories: [String]) -> String {
        """
        Sarankan satu kategori yang paling cocok.
        Penerima: \(payee.isEmpty ? "(kosong)" : payee)
        Catatan: \(note.isEmpty ? "(kosong)" : note)
        Kategori tersedia: \(categories.joined(separator: ", "))
        Jawab dengan nama kategori saja jika memungkinkan, lalu satu kalimat alasan.
        """
    }

    static func question(_ question: String, context: String) -> String {
        "Pertanyaan pengguna: \(question)\n\nData lokal:\n\(context)"
    }
}
