//
//  RequestBuilder.swift
//  Student eWallet
//
//  Created by Mạc Văn Vinh on 13/4/26.
//
import Foundation

struct RequestBuilder {
    
    static let baseURL = "https://ewallet-hn0m.onrender.com"
    
    static func build(
        endpoint: APIEndpoint,
        body: Data? = nil
    ) -> URLRequest? {
        var components = URLComponents(string: baseURL + endpoint.path)
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
}
