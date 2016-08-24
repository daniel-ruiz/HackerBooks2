//
//
//  AsyncData.swift
//  HackerBooksLite
//
//  Created by Fernando Rodríguez Romero on 7/12/16.
//  Copyright © 2016 KeepCoding. All rights reserved.
//

import Foundation
import UIKit



public
class  AsyncData {
    
    let url     : URL
    public var data    : Data
    weak public var delegate: AsyncDataDelegate?
    
    
    init(url: URL, defaultData : Data){
        self.url = url
        self.data = defaultData
    }
    
    //MARK: - Data Fetching
    public
    func loadData(){
        
        if loadLocalData() == false{
            loadAndSaveRemoteData()
        }
        
    }
    private
    func loadLocalData() -> Bool{
        
        let fm = FileManager.default
        let local = localURL(forRemoteURL: url)
        if fm.fileExists(atPath: local.path){
            data = try! Data(contentsOf: local)
            return true
        }else{
            return false
        }
    }
    
    private
    func loadAndSaveRemoteData(){
        
        if delegate?.asyncData(self, shouldStartLoadingFrom: url) == true {
            DispatchQueue.global(qos: .default).async {
                self.delegate?.asyncData(self, willStartLoadingFrom: self.url)
                
                let tmpData = try! Data(contentsOf: self.url)
                
                DispatchQueue.main.async {
                    self.data = tmpData
                    
                    self.delegate?.asyncData(self, didEndLoadingFrom: self.url)
                    self.sendNotification()
                    self.saveToLocalStorage()
                }
            }
            
        }
        
    }
    private
    func saveToLocalStorage(){
        
        let local = localURL(forRemoteURL: url)
        do{
            try data.write(to: local, options: .atomic)
        }catch let error as NSError{
            delegate?.asyncData(self, fileSystemDidFailAt: url, error: error)
        }
        
    }
    //MARK: - Utils
    class func sandboxSubfolderURL() -> URL{
        
        
        let fm = FileManager.default
        let urls = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        
        guard let url = urls.last?.appendingPathComponent("\(type(of:self))") else {
            fatalError("Unable to create url for local storage at \(urls)")
        }
        
        
        // If this folder doesn't exist, we'll create it
        if !fm.fileExists(atPath: url.path){
            do{
                try fm.createDirectory(at: url,
                                       withIntermediateDirectories: true,
                                       attributes: [:])
            }catch let error as NSError{
                print(error)
                
            }
        }
        
        return url
        
    }
    
    func localURL(forRemoteURL remoteURL: URL)  -> URL{
        
        // Sind it could happen that 2 images with different URLs
        // might have the same name, we can't save the image with its name.
        // That would cause collissions. Instead, we'll use the full url's
        // hashValue as a file name.
        // That's what core data does, BTW.
        let fileName = String(remoteURL.hashValue)
        return AsyncData.sandboxSubfolderURL().appendingPathComponent(fileName)
        
    }
    
    
}

//MARK: - Delegate
public
protocol AsyncDataDelegate : class{
    
    func asyncData(_ sender: AsyncData, shouldStartLoadingFrom url: URL )->Bool
    func asyncData(_ sender: AsyncData, willStartLoadingFrom url: URL)
    func asyncData(_ sender: AsyncData, didEndLoadingFrom url: URL)
    func asyncData(_ sender: AsyncData, didFailLoadingFrom url: URL, error: NSError)
    func asyncData(_ sender: AsyncData, fileSystemDidFailAt url: URL, error: NSError)

    
}
// Default implemntation for infrequently used methods
extension AsyncDataDelegate {
    func asyncData(_ sender: AsyncData, shouldStartLoadingFrom url: URL )->Bool{
        return true
    }
    
    func asyncData(_ sender: AsyncData, willStartLoadingFrom url: URL){}
    
    func asyncData(_ sender: AsyncData, didEndLoadingFrom url: URL){}
    
    func asyncData(_ sender: AsyncData, didFailLoadingFrom url: URL, error: NSError){
        print("Error loading \(url).\n \(error)")
    }
    
    func asyncData(_ sender: AsyncData, fileSystemDidFailAt url: URL, error: NSError){
        print("Error at \(url).\n \(error)")
    }
    
    
}


//MARK: - Notifications
let AsyncDataDidEndLoading = Notification.Name(rawValue: "io.keepCoding.AsyncDataDidEndLoading")

extension AsyncData{
    func sendNotification(){
        
        let n = Notification(name: AsyncDataDidEndLoading,
                             object: self, userInfo: ["url" : url, "data" : data])
        
        let nc = NotificationCenter.default
        
        nc.post(n)
        
        
    }
}





//MARK: - Cleaning up the cache
extension AsyncData{
    
    // deletes the local file represented by URL
    public
    func removeLocalFile(){
        
        let fm = FileManager.default
        let local = localURL(forRemoteURL: url)
        do{
            try fm.removeItem(at: local)
        }catch let error as NSError{
            delegate?.asyncData(self, fileSystemDidFailAt: local, error: error)
        }
        
        
    }
    
    // Removes all local files created by any instance of AsyncData
    public
    class func removeAllLocalFiles(){
        
        let fm = FileManager.default
        let local = sandboxSubfolderURL()
        do{
            try fm.removeItem(at: local)
        }catch let error as NSError{
            print("Error deleting folder at \(local). \(error)")
        }
    }
    
}


//MARK: - Equatable
extension AsyncData : Equatable{
    
    public static func ==(lhs: AsyncData, rhs: AsyncData) -> Bool{
        return lhs.url == rhs.url
    }
}























