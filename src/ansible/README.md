# Ansible Project: OS Hardening with Lynis

## Introduction

**Ansible** is an open-source automation tool used for configuration management, application deployment, and task automation. It allows you to define the desired state of your systems using simple, human-readable YAML files called "playbooks." Ansible is agentless, meaning you don't need to install any software on the target machines except for SSH and Python.

**OS Hardening** means securing your operating system by reducing its attack surface—disabling unnecessary services, enforcing strong configurations, and applying security best practices.

**Lynis** is a popular open-source security auditing tool for Unix-based systems. It scans your system and provides a security score (out of 100) along with recommendations for improvement.

---

## Project Goal

Automate the hardening of your Linux system using Ansible, so that after running your playbook, your system achieves a Lynis security score of at least 75. All tasks must use Ansible modules (not raw shell commands), and each independent task should use Ansible tags for easy execution.

---

## Project Structure

A best-practice Ansible project should look like this:

```
Project/
├── README.md
├── inventory.ini
├── playbook.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── common/
│   │   └── tasks/
│   │       └── main.yml
│   ├── dns/
│   │   └── tasks/
│   │       └── main.yml
│   ├── docker/
│   │   └── tasks/
│   │       └── main.yml
│   ├── firewall/
│   │   └── tasks/
│   │       └── main.yml
│   ├── lynis/
│   │   └── tasks/
│   │       └── main.yml
│   ├── network/
│   │   └── tasks/
│   │       └── main.yml
│   ├── ntp/
│   │   └── tasks/
│   │       └── main.yml
│   ├── ssh/
│   │   └── tasks/
│   │       └── main.yml
│   ├── sysctl/
│   │   └── tasks/
│   │       └── main.yml
│   ├── fail2ban/
│   │   └── tasks/
│   │       └── main.yml
```

**Explanation:**

- `inventory.ini`: Lists the target hosts for Ansible.
- `playbook.yml`: The main playbook that includes all roles.
- `group_vars/all.yml`: Variables shared across all hosts.
- `roles/`: Each major configuration area (ntp, ssh, etc.) is a separate role for modularity and reuse.

---

## Step-by-Step Guide

### 1. Install Ansible

**What:** Ansible must be installed on your control machine (your laptop or a server).

**How:**  

```sh
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --true --update ppa:ansible/ansible
sudo apt install ansible
```

**Why:** This gives you the `ansible` and `ansible-playbook` commands.

---

### 2. Create Your Inventory

**What:** The inventory file (`inventory.ini`) lists the IP addresses or hostnames of the machines you want to manage.

**Example:**

```ini
[all]
192.168.1.10 ansible_user=youruser
```

**Why:** Ansible needs to know which machines to connect to and how.

---

### 3. Create the Playbook

**What:** The playbook (`playbook.yml`) is the main file that tells Ansible what to do.

**Example:**

```yaml
- name: OS Hardening Playbook
  hosts: all
  become: true
  roles:
    - common
    - ntp
    - ssh
    - docker
    - network
    - dns
    - sysctl
    - firewall
    - fail2ban
    - lynis
```

**Why:** This structure makes it easy to add/remove roles and keeps your playbook organized.

---

### 4. Create Roles

**What:** Roles are self-contained units of configuration, each with its own tasks, variables, and files.

**How:**  

```sh
ansible-galaxy init roles/ntp
```

Repeat for each role (`ssh`, `docker`, etc.).

**Why:** Roles make your playbooks modular, reusable, and easier to maintain.

---

### 5. Write Tasks Using Ansible Modules

**What:** Each role's `tasks/main.yml` should use Ansible modules (not raw shell commands).

**Examples:**

- **Install Packages (common role):**

  ```yaml
  - name: Install required packages
    ansible.builtin.package:
      name:
        - ntp
        - ufw
        - lynis
      state: present
    tags: packages
  ```

- **Docker Installation (docker role, using official Docker method):**
  1. **Uninstall old Docker versions (if any):**

     ```yaml
     - name: Remove old Docker versions
       ansible.builtin.package:
         name:
           - docker
           - docker-engine
           - docker.io
           - containerd
           - runc
         state: absent
       tags: docker
     ```

  2. **Install prerequisites:**

     ```yaml
     - name: Install prerequisites for Docker
       ansible.builtin.package:
         name:
           - ca-certificates
           - curl
           - gnupg
         state: present
       tags: docker
     ```

  3. **Add Docker’s official GPG key:**

     ```yaml
     - name: Add Docker's official GPG key
       ansible.builtin.shell: |
         install -m 0755 -d /etc/apt/keyrings
         curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
         chmod a+r /etc/apt/keyrings/docker.gpg
       args:
         creates: /etc/apt/keyrings/docker.gpg
       tags: docker
     ```

  4. **Set up the Docker repository:**

     ```yaml
     - name: Add Docker repository
       ansible.builtin.apt_repository:
         repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
         state: present
         filename: docker
       tags: docker
     ```

  5. **Update apt and install Docker Engine:**

     ```yaml
     - name: Update apt cache
       ansible.builtin.apt:
         update_cache: true
       tags: docker

     - name: Install Docker Engine and related packages
       ansible.builtin.package:
         name:
           - docker-ce
           - docker-ce-cli
           - containerd.io
           - docker-buildx-plugin
           - docker-compose-plugin
         state: present
       tags: docker
     ```

  6. **Ensure Docker is running:**

     ```yaml
     - name: Ensure Docker is started and enabled
       ansible.builtin.service:
         name: docker
         state: started
         enabled: true
       tags: docker
     ```

  **Why this method?**
  - This follows Docker’s official documentation, ensuring you get the latest, most secure, and best-supported version.
  - Avoids issues with outdated packages from OS repositories.
  - Used in real-world and production environments for reliability and support.

- **NTP Configuration (ntp role):**

  ```yaml
  - name: Ensure NTP is installed and running
    ansible.builtin.service:
      name: ntp
      state: started
      enabled: true
    tags: ntp
  ```

- **SSH Configuration (ssh role):**

  ```yaml
  - name: Harden SSH configuration
    ansible.builtin.copy:
      src: sshd_config
      dest: /etc/ssh/sshd_config
      owner: root
      group: root
      mode: "0600"
      backup: true
    notify: Restart ssh
    tags: ssh
  ```

- **Firewall (firewall role):**

  ```yaml
  - name: Enable UFW firewall
    community.general.ufw:
      state: enabled
    tags: firewall
  ```

- **Lynis Scan (lynis role):**

  ```yaml
  - name: Run Lynis audit and save output to temp file
    ansible.builtin.shell:
      cmd: set -o pipefail && lynis audit system | tee /tmp/lynis_audit_{{ inventory_hostname }}.log
      executable: /bin/bash
    changed_when: false
    tags: lynis

  - name: Fetch Lynis audit log to control node
    ansible.builtin.fetch:
      src: /tmp/lynis_audit_{{ inventory_hostname }}.log
      dest: ./lynis_logs/{{ inventory_hostname }}.log
      flat: true
    tags: lynis
  ```

**Why:** Ansible modules are idempotent (safe to run multiple times), and they abstract away OS differences.

---

### 6. Use Tags

**What:** Tags let you run only specific parts of your playbook.

**How:**  
Add `tags: <name>` to each task or role.

**Example:**  

```sh
ansible-playbook -i inventory.ini playbook.yml --tags "firewall"
```

**Why:** This saves time and allows targeted changes.

---

### 7. Variables and Group Vars

**What:** Use variables to avoid hardcoding values.

**How:**  
Define variables in `group_vars/all.yml`:

```yaml
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
```

**Why:** This makes your playbooks flexible and reusable.

---

### 8. Handlers

**What:** Handlers are special tasks that run only when notified (e.g., restart a service after config changes).

**Where to put handlers:**
> Place handlers in: `roles/<role_name>/handlers/main.yml` (for example, `roles/ssh/handlers/main.yml`)

**How:**  
In your role, create a file like this:

```yaml
# roles/ssh/handlers/main.yml
---
- name: Restart ssh
  ansible.builtin.service:
    name: ssh
    state: restarted
```

**How to use:**  
In your task (e.g., in `roles/ssh/tasks/main.yml`), use `notify: Restart ssh` to trigger this handler.

**Why:** This ensures services are only restarted when needed and keeps your roles organized.

---

### 9. Run Your Playbook

**How:**  

```sh
ansible-playbook -i inventory.ini playbook.yml
```

**Why:** This applies all your hardening steps automatically.

---

### 10. Dry Run (Check Mode) Your Playbook

**What:** Dry run (check mode) lets you see what changes Ansible would make, without actually applying them.

**How:**

```sh
ansible-playbook -i inventory.ini playbook.yml --check
```

**Why:** This is a safe way to test your playbook before making real changes, especially in production environments.

---

### 11. Check Your Lynis Score

After running the playbook, SSH into your target machine and run:

```sh
sudo lynis audit system
```

Look for the "Hardening index" at the end. Your goal is 75 or higher.

---

## Role Overview and Details

### 1. Common

- **Purpose:** Installs essential security packages, removes insecure software (like Telnet), sets legal warning banners, and enforces strict file permissions.
- **Key Concepts:**  
  - *Legal banners* warn unauthorized users and help with compliance.
  - *File permissions* restrict access to sensitive files.
- **Best Practices:** Always remove unused or insecure software and set strict permissions.

### 2. DNS

- **Purpose:** Configures `/etc/resolv.conf` with reliable public DNS servers (Google and Cloudflare) for robust name resolution.
- **Key Concepts:**  
  - *DNS (Domain Name System)* translates domain names to IP addresses.
  - *Redundancy* ensures connectivity even if one DNS server fails.
- **Best Practices:** Use multiple DNS servers for reliability.

### 3. Docker

- **Purpose:** Installs Docker using a custom repository, configures registry mirrors, and manages user access.
- **Key Concepts:**  
  - *Docker* is a platform for running applications in containers.
  - *Registry mirrors* speed up image downloads.
- **Best Practices:** Remove old Docker versions before installing new ones.

### 4. Firewall

- **Purpose:** Installs and configures UFW (Uncomplicated Firewall) to allow only essential ports (SSH on 2222, HTTP, HTTPS), blocks all other incoming traffic, and enables the firewall.
- **Key Concepts:**  
  - *Firewall* controls network traffic to protect servers.
  - *UFW* is a user-friendly firewall tool for Ubuntu/Debian.
- **Best Practices:** Always allow your SSH port before blocking other traffic.

### 5. Network

- **Purpose:** Installs and configures `firewalld` (for CentOS/RHEL/Fedora), allows only necessary ports, and blacklists unused network protocols.
- **Key Concepts:**  
  - *firewalld* is a firewall management tool for Linux.
  - *Protocol blacklisting* reduces attack surface.
- **Best Practices:** Only open required ports and disable unused protocols.

### 6. NTP

- **Purpose:** Installs and configures NTP to keep server clocks accurate, checks synchronization status, and warns about unsynchronized servers.
- **Key Concepts:**  
  - *NTP (Network Time Protocol)* keeps system time in sync.
  - *Time synchronization* is critical for security and logging.
- **Best Practices:** Use reliable NTP servers and monitor sync status.

### 7. Sysctl

- **Purpose:** Applies secure Linux kernel parameters using `sysctl` to harden the OS against network and kernel attacks.
- **Key Concepts:**  
  - *Kernel parameters* control OS behavior.
  - *sysctl* is used to set these parameters at runtime.
- **Best Practices:** Test changes in staging before production.

### 8. SSH

- **Purpose:** Copies a hardened `sshd_config` file to `/etc/ssh/sshd_config`, sets strict permissions, and restarts SSH to apply changes.
- **Key Concepts:**  
  - *SSH (Secure Shell)* is used for secure remote access.
  - *Hardening* means making configuration more secure (e.g., disabling root login, changing port).
- **Best Practices:** Always test SSH changes on a non-production server.

### 9. Fail2ban

- **Purpose:** Installs and configures Fail2ban to monitor logs and ban IPs with suspicious activity, deploys a custom configuration, and ensures logging is enabled.
- **Key Concepts:**  
  - *Fail2ban* protects against brute-force attacks.
  - *Log monitoring* is essential for detecting threats.
- **Best Practices:** Customize Fail2ban rules for your environment.

### 10. Lynis

- **Purpose:** Installs Lynis and runs a security audit, fetching the results for review.
- **Key Concepts:**  
  - *Lynis* is a security auditing tool for Linux.
  - *Auditing* helps identify and fix vulnerabilities.
- **Best Practices:** Review audit logs regularly and fix reported issues.

---

## Best Practices

- **Test in staging:** Always test hardening steps on a non-production server first.
- **Backup configs:** Keep backups of original configuration files.
- **Monitor regularly:** Use tools like Lynis and Fail2ban to monitor security status.
- **Document changes:** Track all changes for troubleshooting and compliance.
- **Restrict access:** Limit SSH and other sensitive services to trusted users and networks.

## Common Pitfalls

- Locking yourself out by misconfiguring SSH or firewall rules.
- Not restarting services after changing configs.
- Overwriting system files managed by other tools (like DHCP or cloud-init).
- Using outdated or insecure software.

## License

BSD

## Author Information

Created by your DevOps team. For questions, contact your team lead or refer to the documentation.
