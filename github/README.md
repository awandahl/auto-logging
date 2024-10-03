## GitHub logsync  

### Create a GitHub repository:  

- Go to GitHub.com and log in to your account.
- Click the "+" icon in the top-right corner and select "New repository".
- Name your repository (e.g., "ham-logs").
- Choose to make it private, at least that is what I did.
- Initialize with a README if you want.
- Click "Create repository".
  
### Set up SSH keys:
- Open a terminal on your local machine.
- Generate an SSH key pair: ssh-keygen -t ed25519 -C "your_email@example.com"
- Press Enter to accept the default file location.
- Enter a secure passphrase (or press Enter for no passphrase).
- Add the SSH key to your ssh-agent:
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```
- Copy the public key: 
```
cat ~/.ssh/id_ed25519.pub
```
- Go to GitHub.com → Settings → SSH and GPG keys → New SSH key
- Paste your public key and give it a title.
- Click "Add SSH key".
### Clone the repository:
- In your terminal, navigate to where you want to store the local copy, e.g., "ham-logs".
- Run:
```
git clone git@github.com:yourusername/ham-logs.git
```
- Change into the new directory: cd ham-logs
### Create the script:
- Create a new file named github_update.sh in the ham-logs directory.
- Copy the following code into the file:
```
#!/bin/bash
set -e

# Set the paths
REPO_DIR=~/ham-logs
WSJT_X_=~/.local/share/WSJT-X/wsjtx_.adi
REPO_=$REPO_DIR/wsjtx_.adi
UPDATE_=$REPO_DIR/github_update.

# Function to  messages
_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$UPDATE_"
}

echo "Starting push process..."
_message "Starting push process"

# Change to the repository directory
cd $REPO_DIR

# Copy the WSJT-X  file to the repo
cp $WSJT_X_ $REPO_

# Add the  file to git
git add -f $REPO_

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes to commit."
    _message "No changes to commit"
else
    # Commit changes
    commit_message="Update  file $(date)"
    git commit -m "$commit_message"

    # Push to GitHub
    if git push origin main; then
        echo "Changes pushed to GitHub."
        _message "Successfully pushed changes to GitHub: $commit_message"
    else
        echo "Failed to push changes to GitHub."
        _message "Failed to push changes to GitHub"
    fi
fi

echo "Push process completed."
_message "Push process completed"
```

### Make the script executable:
```
chmod +x github_update.sh
```
### Set up automatic execution:
- Open your crontab:
```
crontab -e
```
- Add this line to run the script every 5 minutes:
```
*/5 * * * * /path/to/ham-logs/github_update.sh
```
### Initial commit:
- Add the script to your repository:
```
git add github_update.sh
git commit -m "Add log sync script"
git push origin main
```

This setup will automatically sync your WSJT-X log file to GitHub every 5 minutes. The script checks for changes, commits them if any are found, and pushes to GitHub.
Remember to keep your SSH keys secure and never share them publicly. If you need to share this setup with others, instruct them to generate their own SSH keys and add them to their GitHub accounts.
