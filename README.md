# Route API

Rails API application with Kakao OAuth2 authentication and JWT token-based authorization.

## Features

- Kakao OAuth2 Login
- JWT Token Authentication
- User Management

## Requirements

- Ruby 3.4.7
- Rails 8.1.1
- SQLite3

## Setup

### 1. Install Dependencies

```bash
bundle install
```

### 2. Database Setup

```bash
rails db:create
rails db:migrate
```

### 3. Configure Credentials

Edit your credentials file:

```bash
EDITOR="vim" rails credentials:edit
```

Add the following configuration:

```yaml
development:
  kakao:
    client_id: your_kakao_client_id
    client_secret: your_kakao_client_secret

production:
  kakao:
    client_id: your_kakao_client_id
    client_secret: your_kakao_client_secret
```

To get Kakao OAuth credentials:
1. Go to [Kakao Developers](https://developers.kakao.com/)
2. Create an application
3. Get your REST API Key (Client ID) and Client Secret
4. Add redirect URI: `http://localhost:3000/auth/kakao/callback`

### 4. Configure Frontend URL (Optional)

Set the frontend URL environment variable (defaults to `http://localhost:3001`):

```bash
export FRONTEND_URL=http://localhost:3001
```

### 5. Run the Server

```bash
rails server
```

## OAuth Flow

### 1. User Authentication

When user wants to login:
1. Frontend redirects browser to: `http://localhost:3000/auth/kakao`
2. User completes Kakao login
3. Backend redirects to: `http://localhost:3001/auth/callback?token=JWT_TOKEN`

### 2. Frontend Receives JWT

The frontend should handle the `/auth/callback` route to:
- Extract `token` from URL query parameter
- Store token in localStorage/sessionStorage
- Redirect user to main page

Example frontend code:
```javascript
// On /auth/callback page
const urlParams = new URLSearchParams(window.location.search);
const token = urlParams.get('token');
if (token) {
  localStorage.setItem('jwt_token', token);
  window.location.href = '/dashboard';
}
```

## API Endpoints

### Authentication

#### Kakao OAuth Login
```
GET /auth/kakao
```
Redirects to Kakao login page.

#### OAuth Callback
```
GET /auth/kakao/callback
```
Handles OAuth callback and redirects to frontend with JWT token in URL.

Redirect example:
```
http://localhost:3001/auth/callback?token=eyJhbGc...
```

#### Authentication Failure
```
GET /auth/failure
```
Redirects to frontend with error message.

## Using JWT Token

Include the JWT token in the Authorization header for protected endpoints:

```
Authorization: Bearer <your_jwt_token>
```

Example:
```bash
curl -H "Authorization: Bearer eyJhbGc..." http://localhost:3000/api/protected_resource
```

## Development

### Run Tests
```bash
rails test
```

### Check Code Style
```bash
rubocop
```

### Security Audit
```bash
bundle exec bundler-audit
bundle exec brakeman
```

## Project Structure

```
app/
├── controllers/
│   ├── application_controller.rb    # JWT authentication logic
│   └── auth/
│       └── callbacks_controller.rb  # OAuth callback handling
├── models/
│   └── user.rb                      # User model with OAuth support
└── services/
    └── json_web_token.rb            # JWT encode/decode service

lib/
└── omniauth/
    └── strategies/
        └── kakao.rb                 # Custom Kakao OAuth2 strategy

config/
└── initializers/
    └── omniauth.rb                  # OmniAuth configuration
```

## License

This project is available as open source under the terms of the MIT License.
