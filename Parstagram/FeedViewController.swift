//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Asad Rizvi on 10/15/21.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let commentBar = MessageInputBar() // Comment input bar for keybaord
    var showsCommentBar = false
    
    var posts = [PFObject]()
    var selectedPost: PFObject!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Dismiss keyboard by dragging it down
        tableView.keyboardDismissMode = .interactive
        
        // Post office like notification center
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillBeHidden(noti: Notification) {
        // Clear text field
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    // Add comment bar at bottom of screen with the keyboard
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery(className:"Posts")
        
        // Get author and comments objects
        query.includeKeys(["author", "comments", "comments.author"])
        
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
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!

        // Add comment to post
        selectedPost.add(comment, forKey: "comments")
        
        tableView.reloadData()

        // Save comment
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved!")
            } else {
                print("Error saving comment: \(error)")
            }
        }
        
        // Clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    // Return number of comments in current post
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get current post and all its comments
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []

        // All comments for current post + AddCommentCell
        return comments.count + 2
    }
    
    // Return number of posts in feed
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Get current post and all its comments
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        // Post cell
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell

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
        // Comment cell
        else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            
            // Get current user and comment
            let comment = comments[indexPath.row - 1]
            let user = comment["author"] as! PFUser
            
            // Set current user name label and comment label
            cell.nameLabel.text = user.username
            cell.commentLabel.text = comment["text"] as? String

            return cell
        }
        // AddComment cell
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        
        // Commments with text that keep track of their posts and authors
        let comments = (PFObject(className: "Comments") as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            
            // Bring up keyboard
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
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
