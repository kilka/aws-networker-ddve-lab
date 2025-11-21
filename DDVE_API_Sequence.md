# DDVE REST API Call Sequence

Complete workflow for configuring Data Domain Virtual Edition via REST API.

## Complete API Workflow (In Order)

### 1. **Authentication** (Try standard password first)
```
POST https://<ddve_host>:3009/rest/v1.0/auth
Body: {
  "username": "sysadmin",
  "password": "Changeme123!"
}
Expected: 201
Returns: X-DD-AUTH-TOKEN header
```

### 2. **Authentication Fallback** (If step 1 fails - use instance ID)
```
POST https://<ddve_host>:3009/rest/v1.0/auth
Body: {
  "username": "sysadmin",
  "password": "<instance_id>"  // e.g., i-0123456789abcdef0
}
Expected: 201
Returns: X-DD-AUTH-TOKEN header
```

### 3. **Change Password** (If authenticated with instance ID)
```
PUT https://<ddve_host>:3009/rest/v1.0/dd-systems/0/users/sysadmin
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "user_modify": {
    "current_password": "<instance_id>",
    "new_password": "Changeme123!"
  }
}
Expected: 200
```

### 4. **Set System Passphrase** (Required for object store)
```
PUT https://<ddve_host>:3009/rest/v2.0/dd-systems/0/systems
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "system_modify": {
    "operation": "set_pphrase",
    "pphrase_request": {
      "new_pphrase": "Changeme123!"
    }
  }
}
Expected: 200
```

### 5. **List Available Disks** (Get metadata disks)
```
GET https://<ddve_host>:3009/api/v1/dd-systems/0/storage/disks
Headers: {
  "X-DD-AUTH-TOKEN": "<token>"
}
Expected: 200
Returns: JSON with diskInfo array
Filter: status='UNKNOWN' AND tierType='OTHER'
```

### 6. **Check Object Store Status** (See if already configured)
```
GET https://<ddve_host>:3009/api/v1/dd-systems/0/file-systems/object-stores
Headers: {
  "X-DD-AUTH-TOKEN": "<token>"
}
Expected: 200
Returns: { "enabled": true/false }
```

### 7. **Configure S3 Object Store** (If not already enabled)
```
PUT https://<ddve_host>:3009/api/v1/dd-systems/0/file-systems/object-stores/aws
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "object_store_detail": {
    "bucketType": "<s3_bucket_name>",
    "acceptCertificate": true,
    "disks": ["<disk1>", "<disk2>"]  // First 2 metadata disks from step 5
  }
}
Expected: 200
Timeout: 600s (can take up to 10 minutes)
```

### 8. **Create Filesystem**
```
PUT https://<ddve_host>:3009/rest/v1.0/dd-systems/0/file-systems
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "filesys_modify": {
    "operation": "create"
  }
}
Expected: 200, 201, 400, 500 (400/500 = already exists)
Timeout: 600s
```

### 9. **Enable Filesystem**
```
PUT https://<ddve_host>:3009/rest/v1.0/dd-systems/0/file-systems
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "filesys_modify": {
    "operation": "enable"
  }
}
Expected: 200, 201, 400, 500
Timeout: 600s
```

### 10. **Check DD Boost Status**
```
GET https://<ddve_host>:3009/rest/v1.0/dd-systems/0/protocols/ddboost
Headers: {
  "X-DD-AUTH-TOKEN": "<token>"
}
Expected: 200
Returns: { "ddboost_status": "enabled" | "disabled" }
```

### 11. **Enable DD Boost** (If not already enabled)
```
PUT https://<ddve_host>:3009/rest/v1.0/dd-systems/0/protocols/ddboost
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "ddboost_modify": {
    "operation": "enable"
  }
}
Expected: 200
```

### 12. **Create DD Boost User**
```
POST https://<ddve_host>:3009/api/v2/dd-systems/0/users
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "user_create_2": {
    "name": "networker",  // or "avamar", "ppdm"
    "password": "Changeme123!"
  }
}
Expected: 200, 201, 400 (400 = already exists)
```

### 13. **Create DD Boost Storage Unit**
```
POST https://<ddve_host>:3009/rest/v2.0/dd-systems/0/protocols/ddboost/storage-units
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "ddboost_storage_unit_create": {
    "name": "NetWorker_SU",  // or "Avamar_SU", "PPDM_SU"
    "user": "networker"
  }
}
Expected: 200, 201, 400
```

### 14. **Assign DD Boost User**
```
PUT https://<ddve_host>:3009/rest/v1.0/dd-systems/0/protocols/ddboost/users
Headers: {
  "X-DD-AUTH-TOKEN": "<token>",
  "Content-Type": "application/json"
}
Body: {
  "ddboost_users_modify": {
    "operation": "assign",
    "user": "networker"
  }
}
Expected: 200, 201, 400
```

---

## API Call Summary

### Statistics
- **Total API Calls**: 14 (12 core + 2 conditional)
- **Auth Calls**: 2 (standard password + fallback)
- **GET Calls**: 3 (disks, object store status, DD Boost status)
- **POST Calls**: 3 (auth x2, create user, create storage unit)
- **PUT Calls**: 8 (password change, passphrase, S3 config, filesystem create/enable, DD Boost enable, user assign)

### Timing Considerations
- **Longest Operations**:
  - S3 object store configuration: up to 10 minutes
  - Filesystem create/enable: up to 10 minutes each
- **Quick Operations**: Authentication, status checks, user management (< 1 minute)

### Error Handling
- Status codes 400/500 on filesystem operations usually mean "already exists" or "already enabled"
- All operations use `ignore_errors: yes` in Ansible for idempotency
- Authentication has automatic retry with 3 attempts and 10-second delay

### Multi-Product Support
For environments with Avamar and PowerProtect Data Manager:
- **Step 12**: Create additional users (`avamar`, `ppdm`)
- **Step 13**: Create additional storage units (`Avamar_SU`, `PPDM_SU`)
- **Step 14**: Assign each user to their respective storage unit

## Notes
- All API calls use HTTPS on port 3009
- Authentication token from step 1/2 is required for all subsequent calls
- Certificate validation is disabled (`validate_certs: no`) for lab environments
- Initial password is the AWS EC2 instance ID (e.g., `i-0123456789abcdef0`)
- Standard password after setup: `Changeme123!`
