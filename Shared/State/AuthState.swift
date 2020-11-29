//
//  UserState.swift
//  Chimp
//
//  Created by Maximilian Gravemeyer on 03.09.20.
//

import Foundation
import CoreData
import SwiftUI
class AuthState: ObservableObject {
    
    //ONLY in Auth (here), the "flow" of data saving is to DB*  first, CoreData follows after.
    //Flow: Auth via REST API -> get token and user_uid -> saves token and  user_uid to CoreData
    //that means user_uid will be generated by the backend (no need to send from here)
    
    //Just in case you're curious why the flow is  different:
    //it's  simply because the use of the DB* in Auth is used to Authenticate
    //whereas in others (unless mentioned), it's  for backup purposes.
    
    //* via REST API (backend services)
    
    init() {
        //TO:DO: creating fetch request auth state from core data
        //checkAuth(authDetail: T##FetchedResults<AuthDetail>)
    }
    
    @Published var loggedIn = true
    @Published var token = ""
    @Published var user_uid = ""
    @Published var authLoading = true
    
    private let authService = AuthService.instance
    
    //checking if user is Authed (at least fired once on intial app launched)
    func checkAuth() {
        let authStateFetched = CoreDataManager.shared.fetch("AuthDetail")
        if !authStateFetched.isEmpty || authStateFetched != [] {
            
            var user_uid = String()
            var token = String()
            
            for result in authStateFetched as [NSManagedObject] {
                user_uid = result.value(forKey: "user_uid") as! String
                token = result.value(forKey: "token") as! String
            }
            // if there is  data stored in AuthDetail CoreData
            //means it's very very likely that the  user is authenticated (logged in)
            
            if user_uid != "" && token != "" { // just to double check
                DispatchQueue.main.async{
                    self.token = token
                    self.user_uid = user_uid
                    self.loggedIn = true
                }
            }
        }
        
        DispatchQueue.main.async{
            self.authLoading = false
        }
    }
    
    //creating a new user in DB on sign up
    // and or returning response (token and user_uid a.k.a AuthDetail) from DB
    //then, on saveAuthDetail() call, it saves the responses to CoreData
    func authUser(email: String, password: String, option: AuthOptions, authDetail:FetchedResults<AuthDetail>, viewContext: NSManagedObjectContext) {
        authService.authUser(email: email, password: password, option: option) {[unowned self] (result) in
            switch result {
            case .success(let response):
                self.saveAuthDetail(result: response,  viewContext: viewContext)
            case .failure(let err):
                print(err.localizedDescription) // maybe assign it to a state and display to user?
            }
        }
    }
    
    //delete corresponding uid and its token from db
    //then, on deleteAuthDetail(), it deletes the uid and token from coreData
    func deauthUser(authDetail: FetchedResults<AuthDetail>, viewContext: NSManagedObjectContext){
        authService.deauthUser(user_uid: user_uid, token: token) {[unowned self] (result) in
            switch result{
            case .success(_):
                // _ is msg (from backend)  - assign it as a var if you wanna access it.
                self.deleteAuthDetail(authDetail: authDetail, viewContext: viewContext)
            case .failure(let err):
                print(err.localizedDescription) // maybe assign it to a state and display to user?
            }
        }
        DispatchQueue.main.async {
            self.loggedIn = false
        }
    }
    
    //saving the token and user_uid to CoreData of type AuthDetail
    private func saveAuthDetail(result: [String: String], viewContext: NSManagedObjectContext){
        guard let token = result["token"], let user_uid = result["user_uid"] else {
            return
        }

        let newAuthDetail = AuthDetail(context: viewContext)
        newAuthDetail.token = token
        newAuthDetail.user_uid = user_uid
        CoreDataManager.shared.save() {[unowned self] (saved) in
            if(saved){
                DispatchQueue.main.async {
                    self.loggedIn = true
                    self.token = token
                    self.user_uid = user_uid
                }
            }
        }
        
    }
    
    //deleting the token and user_uid to CoreData of type AuthDetail
    func deleteAuthDetail(authDetail: FetchedResults<AuthDetail>, viewContext: NSManagedObjectContext){
        for (userD) in authDetail{
            viewContext.delete(userD)
        }
        
        CoreDataManager.shared.save(){[unowned self] (saved) in
            if saved{
                DispatchQueue.main.async{
                    self.loggedIn = false
                }
            }

        }
    }
    
}
