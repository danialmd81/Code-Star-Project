## 1. What is an SSH Bastion Host?

**SSH Bastion Host** is a secure server that acts as a gateway for SSH access to private/internal nodes in your infrastructure.  

- **Why use it?**  
  - Only expose one public-facing SSH endpoint (the bastion), reducing attack surface.
  - Internal nodes (workers) remain private and protected.
  - You connect to the bastion first, then it forwards your SSH session to the target node.

**In your architecture:**  

- Your master nodes (`master-1`, `master-2`) have public IPs and act as bastion hosts.
- Worker nodes only have private IPs.

---

## 2. Setting Up SSH Bastion on Master Nodes

### Step 1: Install and Harden SSH Server

**On each master node:**

1. **Install SSH server** (if not already installed):

   ````bash
   sudo apt update
   sudo apt install openssh-server
   ````

2. **Harden SSH security:**
   - Edit sshd_config:
     - Disable root login:  
       `PermitRootLogin no`
     - Use key-based authentication (disable password login for production):  
       `PasswordAuthentication no`
   - Restart SSH:

     ````bash
     sudo systemctl restart ssh
     ````

3. **Open SSH port (22) in firewall/security group.**

**Best Practice:**  

- Use strong SSH keys.
- Limit SSH access to trusted IPs (firewall rules).

---

## 3. SSH Key Setup

### Step 2: Generate and Distribute SSH Keys

**On your local machine:**

1. **Generate SSH key** (if you don’t have one):

   ````bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ````

2. **Copy your public key to master nodes:**

   ````bash
   ssh-copy-id youruser@185.60.126.8      # master-1 public IP
   ssh-copy-id youruser@185.60.126.52     # master-2 public IP
   ````

3. **From master node, copy your key to worker nodes:**
   - SSH into master node:

     ````bash
     ssh youruser@185.60.126.8
     ````

   - From master, copy key to worker:

     ````bash
     ssh-copy-id youruser@192.168.1.19    # worker-1
     ssh-copy-id youruser@192.168.1.8     # worker-2
     ssh-copy-id youruser@192.168.1.122   # worker-3
     ````

**Why?**  

- This lets you “hop” from master to worker without entering passwords.

---

## 4. SSH Config on Your Local Machine

### Step 3: Configure `~/.ssh/config` for Named Access

**Edit (or create) `~/.ssh/config`:**

````ssh

````

**Explanation:**

- `Host`: The name you’ll use to SSH (e.g., `ssh worker-1`)
- `HostName`: The actual IP of the node
- `ProxyJump`: Tells SSH to first connect to the bastion (`master-1`), then forward to the worker node

**Best Practice:**  

- Use `ProxyJump` (available in OpenSSH 7.3+). For older SSH, use `ProxyCommand`.

---

## 5. Usage

Now you can SSH to any node by name:

````bash
ssh worker-1
ssh master-2
````

SSH will automatically route your connection through the bastion.

---

## 6. How It Works in Production

- **Security:** Only master nodes are exposed to the internet. Workers are protected.
- **Automation:** Tools like Ansible use your SSH config to automate tasks across all nodes.
- **Scalability:** Add more worker nodes without exposing them publicly.

---

## 7. Diagram

```
[Your Laptop]
      |
      | ssh worker-1
      |
   [Master Node] (Bastion, Public IP)
      |
      | ssh worker-1 (private IP)
      |
   [Worker Node] (Private IP)
```

---

## 8. Common Pitfalls

- Not copying your SSH key to both bastion and worker nodes.
- Incorrect usernames in SSH config.
- Firewall blocking SSH traffic.
- Not using `ProxyJump` (older SSH versions use `ProxyCommand`).

---

## 9. Further Learning

- [SSH Config Manual](https://man.openbsd.org/ssh_config)
- [Bastion Host Best Practices (AWS)](https://docs.aws.amazon.com/whitepapers/latest/bastion-hosts/bastion-hosts.pdf)
- [Linux SSH Hardening Guide](https://www.ssh.com/academy/ssh/security-best-practices)
- [Ansible SSH ProxyJump](https://docs.ansible.com/ansible/latest/user_guide/intro_ssh.html#connecting-through-a-bastion-host)

---

**Summary:**  
You set up your master nodes as SSH bastion hosts, copy your SSH key to all nodes, and configure your local SSH to use node names. This is secure, scalable, and industry-standard for production clusters.
