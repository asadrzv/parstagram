//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Asad Rizvi on 10/15/21.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className:"Posts")
        
        // Get author object
        query.includeKey("author")
        
        // Get previous 20 posts
        query.limit = 20
        
        // Get stored posts list
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
        
        // Get current post
        let post = posts[indexPath.row]
        
        // Get current user
        let user = post["author"] as! PFUser
        
        // Set current post username and caption
        cell.usernameLabel.text = user.username
        cell.captionLabel.text = post["caption"] as? String
        
        // Get image url
        let imageFile = post["image"] as! PFFileObject
        let url = URL(string: imageFile.url!)!
        
        // Set current post image
        cell.photoView.af_setImage(withURL: url)
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        // Commment with text that keeps track of its post and author
        let comment = PFObject(className: "Comments")
        comment["text"] = "This is a random comment!"
        comment["post"] = post
        comment["author"] = PFUser.current()!
        
        // Add comment to post
        post.addUniqueObject(comment, forKey: "comments")
        
        // Save comment
        post.saveInBackground { (success, error) in
            if success {
                print("Comment saved!")
            } else {
                print("Error: \(error)")
            }
        }
    }
    
    // Logout user and switch back to login screen
    @IBAction func onLogout(_ sender: Any) {
        // Logout user
        PFUser.logOut()
        
        // Switch back to login screen
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let
                delegate = windowScene.delegate as? SceneDelegate else { return }
        
        delegate.window?.rootViewController = loginViewController
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
