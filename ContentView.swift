//
//  ContentView.swift
//  ProjectCSE335
//
//  Created by Alexis Urias on 4/1/24.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import MapKit

/*
 Hello, i had to change a few things in order to get my virtual wardrobe application up and running.
 I was not able to find a free clothing store api so I did not implement features related to buying clothing.
 I used Unsplash (photograph website) for json data in order to get clothing images populated for the user.
 So the homepage populates clothing images from the Unsplash API, this is so users can scroll through the images and get clothing inspiration.
 I used Firebase for authentication and data storage. So the login page runs off of firebase authentication and wishlist stores permanent data for the user in regards to clothing items.
 I made map view for the user so they could search for clothing stores nearest to them.
 For wardrobe and profile, in wardrobe images are populated for user by assets...I would have liked to add a feature for users to add images but time is short. In the profile view users information will be populated and they can choose their own profile images, users are also able to logout in profileview.
 Used resources from modules and apple developer
 
 */


struct ContentView: View {
    @ObservedObject var viewModel: ViewModelApplication
    @State var isShowing = false
    @State var isAuthenticated = false
    @State var email:String
    @State var password: String
    
    var body: some View {
        NavigationView {
            VStack {
                if isAuthenticated == true {
                    HomePageView(isAuthenticated: $isAuthenticated)
                    .navigationBarHidden(true)
                    } else {
                        LoginView(viewModel: viewModel, email: email, password: password, isAuthenticated: $isAuthenticated)

                }
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: ViewModelApplication
    @State var email: String = ""
    @State var password: String = ""
    @State var showAlert = false
    @State var isShowing = false
    @Binding var isAuthenticated:Bool
    
    var body: some View {
        VStack {
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.bottom, 30)
            VStack(spacing: 16.0) {
                InputFieldView(data: $email, title: "Email", isSecure: false)
                InputFieldView(data: $password, title: "Password", isSecure: true)
            }
            .padding(10)
            Button(action: {
                signIn()
            }) {
                Text("Sign In")
                    .fontWeight(.bold)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors:[.blue, .indigo]),
                                               startPoint: .leading,
                                                endPoint: .trailing))
                    .cornerRadius(30)
            }
            Button(action: {
                self.isShowing.toggle()
            }) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors:[.indigo, .blue]),
                                               startPoint: .leading,
                                               endPoint: .trailing))
                    .cornerRadius(30)
            }
            .sheet(isPresented: $isShowing) {
                SignUpView(viewModel: viewModel)
            }
            
            HStack {
                Spacer()
                Text("Forgotten Password?")
                    .fontWeight(.thin)
                    .foregroundColor(Color.blue)
                    .underline()
            }.padding(.top, 16)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Alert"), message: Text("Incorrect username or password"), dismissButton: .default(Text("OK")))
        }
    }
    
    func signIn() {
        viewModel.signIn(email: email, password: password) { result in
            switch result {
            case .success:
                isAuthenticated = true //sign-in is successful
            case .failure:
                showAlert = true // sign-in fails
                isAuthenticated = false
            }
        }
    }


}

struct InputFieldView: View {
    @Binding var data: String
    var title: String?
    var isSecure: Bool
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.thin)
                    .foregroundColor(Color.gray)
                    .padding(.leading, 4)
            }
            if isSecure {
                SecureField("", text: $data)
                    .padding(.horizontal, 10)
                    .frame(height: 45)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            else {
                TextField("", text: $data)
                    .padding(.horizontal, 10)
                    .frame(height: 45)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
        }
        .padding(5)
    }
}

struct SignUpView: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmedPassword: String = ""
    @State private var passwordsMatch = true // Track if passwords match
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ViewModelApplication
    
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.bottom, 30)
            
            InputFieldView(data: $firstName, title: "First Name", isSecure: false)
            InputFieldView(data: $lastName, title: "Last Name", isSecure: false)
            InputFieldView(data: $email, title: "Email", isSecure: false)
            InputFieldView(data: $password, title: "Password", isSecure: true)
            InputFieldView(data: $confirmedPassword, title: "Confirm Password", isSecure: true)
            
            // error message if passwords don't match
            if !passwordsMatch {
                Text("Passwords do not match")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
            Button(action: signUp) {
                Text("Sign Up")
                    .fontWeight(.bold)
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .blue]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(30)
            }
            .padding(.top, 20)
        }
        .padding()
        .onReceive([password, confirmedPassword].publisher) { _ in
            passwordsMatch = password == confirmedPassword
        }
    }
    
    func signUp() {
        //  passwords match ?
        guard passwordsMatch else {
            return
        }
        
        viewModel.signUp(firstName: firstName, lastName: lastName, email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("User created: \(user.email)")
            case .failure(let error):
                print("Error creating user: \(error.localizedDescription)")
            }
        }
    }
}


struct HomePageView: View {
    @Binding var isAuthenticated: Bool
    var body: some View {
        TabView {
            ClothingView(viewModel: ViewModelApplication())
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
            WardrobeView()
                .tabItem {
                    Image(systemName: "hanger")
                    Text("Wardrobe")
                }
            ClothingStoreView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Map")
                }
            WishListView(viewModel: ViewModelApplication())
                .tabItem {
                    Image(systemName: "heart")
                    Text("Wishlist")
                }
            ProfileView(viewModel: ViewModelApplication(), isAuthenticated: $isAuthenticated)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

struct WardrobeView: View {
    var body: some View {
        NavigationView {
            VStack {
                SectionView(title: "Tops", photos: ["Top1", "Top2", "Top3"])

                SectionView(title: "Bottoms", photos: ["Bottom1", "Bottom2", "Bottom3"])
                
                SectionView(title: "Shoes", photos: ["Shoes1", "Shoes2", "Shoes3"])
            }
            .padding()
        }
    }
}

struct SectionView: View {
    let title: String
    let photos: [String] // photo URLs
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            TabView {
                ForEach(photos, id: \.self) { photo in
                    PhotoView(photo: photo)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(height: 150)
        }
        .padding(.horizontal)
    }
}

struct PhotoView: View {
    let photo: String // photo URL
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 150, height: 150)
            Image(photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 150) // Adjust size as needed
                .clipShape(Circle())
                .padding(1)
        }
    }
}


struct ProfileView: View {
    @ObservedObject var viewModel: ViewModelApplication
    @State private var profileImage: Image?
    @State private var isShowingImagePicker: Bool = false
    @Binding var isAuthenticated:Bool

    var body: some View {
        VStack {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding(.bottom, 20)
            } else {
                Button(action: {
                    isShowingImagePicker.toggle()
                }) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    ViewModelApplication.ImagePicker(selectedImage: $profileImage)
                }
                .padding(.bottom, 20)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Account Information")
                    .font(.headline)

                if let currentUser = viewModel.currentUser {
                    Text("First Name: \(currentUser.firstName)")
                    Text("Last Name: \(currentUser.lastName)")
                    Text("Email: \(currentUser.email)")
                } else {
                    Text("User information not available.")
                }
                Spacer()
                Button(action: {
                    signOut()
                            }) {
                                Text("Logout")
                                    .fontWeight(.bold)
                                    .font(.title3)
                                    .padding()
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Profile")
        .onAppear() {
            viewModel.fetchUserInfo()
        }
    }
    
    func signOut() {
            do {
                try Auth.auth().signOut()
                isAuthenticated = false
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }

}

struct ClothingView: View {
    @ObservedObject var viewModel: ViewModelApplication

    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.photoURLs, id: \.self) { url in
                    CustomImageView(url: url)
                        .frame(width: 250, height: 250)
                }
            }
        }
        .onAppear {
            viewModel.fetchClothing()
        }
    }
}


struct CustomImageView: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                Image(systemName: "xmark.circle")
            @unknown default:
                EmptyView()
            }
        }
    }
}

struct WishListView: View {
    @ObservedObject var viewModel: ViewModelApplication
    @State var isShowing = false

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.clothingItems, id: \.self) { clothingItem in
                    NavigationLink(destination: ClothingItemDetailView(clothingItem: clothingItem)) {
                        ClothingItemRowView(clothingItem: clothingItem)
                    }
                }
                .onDelete { indexSet in
                                    indexSet.forEach { index in
                                        viewModel.deleteClothingItem(clothingItem: viewModel.clothingItems[index])
                                    }
                                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Wishlist", displayMode: .inline)
            .padding(10)
            .navigationBarItems(trailing: Button(action: {
                isShowing = true
            }) {
                Image(systemName: "plus")
            })
            .onAppear {
                viewModel.fetchClothingItems()
            }
            .sheet(isPresented: $isShowing) {
                AddClothingItemView(viewModel: viewModel, itemName: "", brand: "", category: "", color: "", size: "", price: "", location: "", imageURL: "")
            }
        }
    }
}


struct ClothingItemRowView: View {
    let clothingItem: ClothingItem
    var body: some View {
        HStack {
            Image(clothingItem.imageURL)
                .resizable()
                .frame(width: 50, height: 60)
            VStack(alignment: .leading) {
                Text(clothingItem.itemName)
                Text(clothingItem.brand)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ClothingItemDetailView: View {
    let clothingItem: ClothingItem
    
    var body : some View {
        let priceStr = String(clothingItem.price)
        VStack {
            Image(clothingItem.imageURL)
                .resizable()
                .frame(width: 200, height: 250)
            Text(clothingItem.itemName)
                .font(.title)
                .padding()
            Text("Brand: \(clothingItem.brand)")
            Text("Category: \(clothingItem.category)")
            Text("Color: \(clothingItem.color)")
            Text("Size: \(clothingItem.size)")
            Text("Price: \(priceStr)")
            Text("Location: \(clothingItem.location)")
                .padding()
        }
    }
}

struct AddClothingItemView : View {
    @ObservedObject var viewModel: ViewModelApplication
    @State  var itemName: String = ""
    @State  var brand: String = ""
    @State  var category: String = ""
    @State  var color: String = ""
    @State  var size: String = ""
    @State  var price: String = ""
    @State  var location: String = ""
    @State  var imageURL: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Image", text: $imageURL)
                TextField("Item Name", text: $itemName)
                TextField("Brand", text: $brand)
                TextField("Category", text: $category)
                TextField("Color", text: $color)
                TextField("size", text: $size)
                TextField("price", text: $price)
                TextField("location", text: $location)
            }
            .navigationBarTitle("Add Clothing Item")
            .navigationBarItems(trailing: Button("Save") {
                let newClothingItem = ClothingItem(itemName: itemName, brand: brand, category: category, color: color, size: size, price: Double(price) ?? 0.0, location: location, imageURL: imageURL)
                viewModel.addClothingItemToWishlist(clothingItem: newClothingItem)
                viewModel.fetchClothingItems()
            })
        }
    }
}

struct ClothingStoreView: View {
    @State private var searchQuery: String = ""
    @State private var mapItems: [MapItemWrapper] = []
    @State private var isSearching: Bool = false
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), //NOT HARDCODED just defaults to sanfran
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) // gets users location and finds nearest clothing store by search
    )
    
    var body: some View {
        VStack {
            TextField("Search for clothing stores", text: $searchQuery, onCommit: search)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isSearching {
                ProgressView()
                    .padding()
            } else {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: mapItems) { mapItem in
                    MapPin(coordinate: mapItem.placemark.coordinate, tint: .blue)
                }
                .frame(height: 300)
                
                List(mapItems) { mapItem in
                    VStack(alignment: .leading) {
                        Text(mapItem.name)
                            .font(.headline)
                        Text(mapItem.placemark.title ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Clothing Stores")
    }
    
    func search() {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            guard let response = response else {
                print("Error searching for clothing stores: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapItems = response.mapItems.map { MapItemWrapper(mapItem: $0) }
            if let firstItem = mapItems.first {
                region = MKCoordinateRegion(
                    center: firstItem.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
}

struct MapItemWrapper: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    
    var name: String {
        mapItem.name ?? ""
    }
    
    var placemark: MKPlacemark {
        mapItem.placemark
    }
}


#Preview {
    ContentView(viewModel: ViewModelApplication(), email: "", password: "")
}
