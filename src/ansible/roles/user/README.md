User Role
=========

This Ansible role manages Linux user accounts in an automated, idempotent, and production-safe way. It is designed to create users, assign groups, configure SSH access with public keys, and optionally grant passwordless sudo privileges. The role is fully parameterized, making it reusable for any user across your infrastructure.

Requirements
------------

- Ansible 2.9+ installed on your control node.
- Target hosts must be accessible via SSH and support user management (Linux).
- The public SSH key for the user must be available in the `files/` directory or specified via variable.
- Sudo privileges required for user creation and sudoers file management.

Role Variables
--------------

All variables can be set in your playbook, inventory, or via group/host vars.

| Variable           | Default Value                                 | Description                                                      |
|--------------------|-----------------------------------------------|------------------------------------------------------------------|
| `user_name`        | `"danial"`                                    | Username to create/manage.                                       |
| `user_groups`      | `"sudo"`                                      | Groups to add the user to (comma-separated string).              |
| `user_pubkey_path` | `"{{ role_path }}/files/id_ed25519.pub"`      | Path to the user's public SSH key file.                          |
| `user_sudo`        | `true`                                        | If true, grants passwordless sudo via `/etc/sudoers.d/<user>`.   |

You can override these defaults in your playbook or inventory.

Dependencies
------------

This role has no external dependencies. It uses only built-in Ansible modules (`user`, `authorized_key`, `lineinfile`).

Example Playbook
----------------

Here’s how to use the role in your playbook:

```yaml
- hosts: all
  become: true
  roles:
    - role: user
      vars:
        user_name: "danial"
        user_groups: "sudo"
        user_pubkey_path: "roles/user/files/id_ed25519.pub"
        user_sudo: true
```

To add a different user, simply change the variables:

```yaml
- hosts: all
  become: true
  roles:
    - role: user
      vars:
        user_name: "alice"
        user_groups: "docker"
        user_pubkey_path: "roles/user/files/alice_id_ed25519.pub"
        user_sudo: false
```

Best Practices & Security
-------------------------

- Always use SSH keys for authentication; never use passwords.
- Use `/etc/sudoers.d/` for sudo rules—never edit `/etc/sudoers` directly.
- Test changes on a staging node before production.
- Keep public keys secure and version-controlled.

Common Pitfalls
---------------

- Forgetting to set `become: true` (tasks require root privileges).
- Incorrect path to the public key file.
- Overwriting existing sudoers files—always use unique filenames per user.

License
-------

BSD

Author Information
------------------

Created by Danial and contributors. For questions, reach out via your team’s preferred contact
