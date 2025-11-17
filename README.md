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
kakao:
  client_id: your_kakao_client_id
  client_secret: your_kakao_client_secret
```

To get Kakao OAuth credentials:
1. Go to [Kakao Developers](https://developers.kakao.com/)
2. Create an application
3. Get your REST API Key (Client ID) and Client Secret

### 4. Run the Server

```bash
rails server
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
Handles the OAuth callback and returns JWT token.

Response:
```json
{
  "token": "eyJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "User Name",
    "profile_image": "https://..."
  }
}
```

#### Authentication Failure
```
GET /auth/failure
```
Returns error message when authentication fails.

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
