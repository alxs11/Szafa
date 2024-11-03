//
//  ViewModelApplication.swift
//  MyProject-CSE335
//
//  Created by Alexis Urias on 4/4/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import UIKit
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift


public class ViewModelApplication: ObservableObject {
    @Published var users: [User] = []
    
    @Published var clothingItems: [ClothingItem] = []
    
    @Published var outfits: [Outfit] = []
    
    @Published var currentUser: User?
    
    @Published var photoURLs: [URL] = []
    
  //  init() { preload()}
    
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign In Failed: ", error)
                completion(.failure(error))
            } else {
                print("Sign In Successful")
                completion(.success(()))
            }
        }
    }

    
    
    func signUp(firstName: String, lastName: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign Up Failed: ", error)
                completion(.failure(error))
            }
            else if let authResult = authResult {
                print("Sign Up Successful")
                let newUser = User(firstName: firstName, lastName: lastName, email: email, password: password, uid: authResult.user.uid)
                self.users.append(newUser)
                completion(.success(newUser))
            }

        }
    }
    
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedImage: Image?

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: ImagePicker

            init(parent: ImagePicker) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let uiImage = info[.originalImage] as? UIImage {
                    parent.selectedImage = Image(uiImage: uiImage)
                }
                parent.presentationMode.wrappedValue.dismiss()
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            return picker
        }

        func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    }
    
    func fetchUserInfo() {
            if let currentUser = Auth.auth().currentUser {
                // If a user is logged in, create a User object and assign it to currentUser
                self.currentUser = User(firstName: "", lastName: "", email: currentUser.email ?? "", password: "", uid: currentUser.uid)
            } else {
                // If no user is logged in, set currentUser to nil
                self.currentUser = nil
            }
    }

            
            func fetchClothing() {
                let accessKey = "2bVNTmsFnT0x_l5Anm3tYDbM79jQMfKABKauUmZ4RnA"
                let query = "clothing"
                let perPage = 30 // Number of results per page
                let page = 1 // Initial page
                
                let urlString = "https://api.unsplash.com/search/photos?query=\(query)&client_id=\(accessKey)&per_page=\(perPage)&page=\(page)"

                if let url = URL(string: urlString) {
                    let session = URLSession.shared
                    let dataTask = session.dataTask(with: url) { data, response, error in
                        if let error = error {
                            print("Error: \(error)")
                            return
                        }
                        
                        guard let responseData = data else {
                            print("No data received")
                            return
                        }
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                                if let results = json["results"] as? [[String: Any]] {
                                    var photoURLs: [URL] = []
                                    for result in results {
                                        if let urls = result["urls"] as? [String: Any], let regularURLString = urls["regular"] as? String, let regularURL = URL(string: regularURLString) {
                                            photoURLs.append(regularURL)
                                        }
                                    }
                                    DispatchQueue.main.async {
                                        self.photoURLs = photoURLs
                                    }
                                }
                            }
                        } catch {
                            print("Error decoding JSON: \(error)")
                        }
                    }
                    dataTask.resume()
                } else {
                    print("Invalid URL")
                }
            }
    
   /* func preload() {
        let selectedClothingItem = [
            ClothingItem(itemName: "Coat", brand: "Staud", category: "Winter", color: "Brown", size: "Medium", price: 500, location: "Europe", imageURL: "brownCoat")
        ]
        
        self.clothingItems = selectedClothingItem
    }*/

    func addClothingItemToWishlist(clothingItem: ClothingItem) {
        let db = Firestore.firestore()
        let clothingItemData: [String: Any] = [
            "itemName": clothingItem.itemName,
            "brand": clothingItem.brand,
            "category": clothingItem.category,
            "color": clothingItem.color,
            "size": clothingItem.size,
            "price": clothingItem.price,
            "location": clothingItem.location,
            "imageURL": clothingItem.imageURL
        ]
        db.collection("wishlist").addDocument(data: clothingItemData) { error in
            if let error = error {
                print("Error adding clothing item: \(error.localizedDescription)")
            } else {
                print("Clothing item added successfully")
            }
        }
    }
    
    func fetchClothingItems() {
        let db = Firestore.firestore()
        db.collection("wishlist").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching clothing items: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                self.clothingItems = snapshot.documents.compactMap { document in
                    let data = document.data()
                    let itemName = data["itemName"] as? String ?? ""
                    let brand = data["brand"] as? String ?? ""
                    let category = data["category"] as? String ?? ""
                    let color = data["color"] as? String ?? ""
                    let size = data["size"] as? String ?? ""
                    let price = data["price"] as? Double ?? 0.0
                    let location = data["location"] as? String ?? ""
                    let imageURL = data["imageURL"] as? String ?? ""
                    
                    guard !itemName.isEmpty && !brand.isEmpty else {
                                        return nil // blank fields 
                                    }
                    
                    return ClothingItem(itemName: itemName, brand: brand, category: category, color: color, size: size, price: price, location: location, imageURL: imageURL)
                }
            }
        }
    }


    
    func deleteClothingItem(clothingItem: ClothingItem) {
        let db = Firestore.firestore()
        let clothingItemsRef = db.collection("wishlist")
        let query = clothingItemsRef.whereField("itemName", isEqualTo: clothingItem.itemName)
        
        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            if let document = documents.first {
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting document: \(error)")
                    } else {
                        print("Document successfully deleted")
                        
                        // Call fetchClothingItems to refresh the clothingItems array after deletion
                        self.fetchClothingItems()
                    }
                }
            }
        }
    }

    
    
}
