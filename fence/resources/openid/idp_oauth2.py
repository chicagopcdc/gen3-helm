"""
OAuth2 OpenID Connect identity provider handling.

Handles OAuth2 token exchange and JWT claims extraction from external identity providers.
Prevents authorization code reuse and provides graceful error handling.
"""

from flask import request, session, jsonify, redirect, current_app, Blueprint
from authlib.integrations.flask_client import OAuth2Session
from authlib.oauth2.rfc6749.errors import OAuthError
from authlib.oauth2.rfc7523 import parse_token_response
import jwt
import json
import logging
from functools import wraps
from datetime import datetime

logger = logging.getLogger(__name__)


# Blueprint for OAuth2 callback routes
oauth_bp = Blueprint("oauth", __name__, url_prefix="/login")


class OAuth2IdentityProvider:
    """Base class for OAuth2 identity provider integration."""

    def __init__(self, idp, client_id, client_secret, token_url, claims_parser=None):
        """
        Initialize OAuth2 client.
        
        Args:
            idp: Identity provider name (e.g., 'google', 'cilogon')
            client_id: OAuth2 client ID
            client_secret: OAuth2 client secret
            token_url: Token endpoint URL
            claims_parser: Callable to parse claims from token
        """
        self.idp = idp
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_url = token_url
        self.claims_parser = claims_parser or self._default_claims_parser
        self.client = OAuth2Session(
            client_id=client_id,
            client_secret=client_secret,
        )

    def generate_state(self):
        """
        Generate a secure state parameter for CSRF protection.
        
        Returns:
            str: Random state string
        """
        import secrets
        return secrets.token_urlsafe(32)

    def get_authorization_url(self, state, scope="openid email profile"):
        """
        Build authorization request URL.
        
        Args:
            state: CSRF state parameter
            scope: OAuth scope (default: standard OpenID scopes)
            
        Returns:
            str: Authorization URL to redirect user to
        """
        # This should be implemented per-provider or configured
        # For now, raise NotImplementedError
        raise NotImplementedError(
            "get_authorization_url must be implemented by subclass or set in config"
        )

    def get_jwt_claims_identity(self):
        """
        Fetch and parse JWT claims from the identity provider.
        
        Validates state, ensures code is used exactly once, and handles errors gracefully.
        
        Returns:
            dict: Parsed claims from the identity provider
            
        Raises:
            OAuthError: If token exchange fails (invalid_grant, missing params, etc.)
        """
        code = request.args.get("code")
        state = request.args.get("state")
        
        if not code or not state:
            raise OAuthError(
                error="invalid_request",
                description="Missing authorization code or state parameter"
            )
        
        # Validate state to prevent CSRF and detect duplicate callbacks
        state_key = f"oauth_state_{self.idp}"
        session_state = session.get(state_key)
        
        if not session_state or session_state != state:
            raise OAuthError(
                error="invalid_grant",
                description="Invalid or missing state parameter"
            )
        
        # Clear the state immediately to prevent reuse on retry
        session.pop(state_key, None)
        
        # Check if this code was already attempted (guard against duplicate processing)
        code_key = f"oauth_code_used_{self.idp}"
        if session.get(code_key) == code:
            raise OAuthError(
                error="invalid_grant",
                description="Authorization code already used"
            )
        
        try:
            # Attempt token exchange with authorization code
            token = self.get_token(code=code)
            
            # Mark code as successfully used
            session[code_key] = code
            
            # Extract and return claims from token
            return self.claims_parser(token)
            
        except OAuthError:
            # Clear code tracking on failure to allow fresh attempt with new code
            session.pop(code_key, None)
            # Re-raise OAuth errors for handler to return 400
            raise
        except Exception as e:
            # Log unexpected errors without propagating as network failures
            logger.error(
                f"Token exchange error for {self.idp}: {str(e)}",
                extra={"idp": self.idp},
                exc_info=True
            )
            session.pop(code_key, None)
            raise OAuthError(
                error="server_error",
                description="Failed to exchange authorization code"
            )

    def get_token(self, code):
        """
        Exchange authorization code for access token.
        
        Args:
            code: Authorization code from OAuth provider
            
        Returns:
            dict: Token response from token endpoint
            
        Raises:
            OAuthError: If token exchange fails (invalid_grant, network error, etc.)
        """
        try:
            token = self.client.fetch_token(
                url=self.token_url,
                code=code,
                timeout=30
            )
            return token
            
        except OAuthError as e:
            # Re-raise OAuth errors (invalid_grant, invalid_client, etc.)
            logger.warning(
                f"OAuth error for {self.idp}: {e.error} - {e.description}",
                extra={"idp": self.idp, "error": e.error}
            )
            raise
            
        except Exception as e:
            # Network/parsing errors should not be treated as authorization failures
            logger.error(
                f"Token endpoint communication error for {self.idp}: {str(e)}",
                extra={"idp": self.idp},
                exc_info=True
            )
            raise OAuthError(
                error="server_error",
                description="Failed to communicate with token endpoint"
            )

    def _default_claims_parser(self, token):
        """
        Default claims parser - decodes and validates JWT from token response.
        
        Args:
            token: Token response dict from token endpoint
            
        Returns:
            dict: Parsed and validated claims
            
        Raises:
            ValueError: If JWT is invalid or cannot be decoded
        """
        if "id_token" not in token:
            raise ValueError("No id_token in token response")
        
        id_token = token["id_token"]
        
        try:
            # Decode JWT without validation first to inspect
            claims = jwt.decode(
                id_token,
                options={"verify_signature": False}
            )
            
            # In production, validate signature using JWKS from provider
            # For now, verify standard claims
            if "sub" not in claims:
                raise ValueError("Missing 'sub' claim in id_token")
            
            if "exp" in claims:
                if datetime.utcfromtimestamp(claims["exp"]) < datetime.utcnow():
                    raise ValueError("id_token has expired")
            
            return claims
            
        except jwt.DecodeError as e:
            logger.error(f"Failed to decode id_token: {str(e)}")
            raise ValueError(f"Invalid id_token format: {str(e)}")


class OAuthCallbackHandler:
    """Handles OAuth2 callback with error responses."""

    @staticmethod
    def handle_callback(idp_name, idp_client):
        """
        Process OAuth2 callback and create user session.
        
        Args:
            idp_name: Identity provider name
            idp_client: OAuth2IdentityProvider instance
            
        Returns:
            Redirect response on success, error response on failure
        """
        try:
            claims = idp_client.get_jwt_claims_identity()
            
            # Extract user info from claims
            user_id = claims.get("sub")
            email = claims.get("email")
            name = claims.get("name")
            
            if not user_id:
                return jsonify({
                    "error": "invalid_grant",
                    "error_description": "Missing user identifier in token claims"
                }), 400
            
            # Store user info in session
            session["user_id"] = user_id
            session["idp"] = idp_name
            session["email"] = email
            session["name"] = name
            session["claims"] = claims
            
            logger.info(
                f"OAuth callback successful for {idp_name}",
                extra={"user_id": user_id, "idp": idp_name}
            )
            
            # Redirect to next URL or dashboard
            next_url = request.args.get("next", "/dashboard")
            return redirect(next_url)
            
        except OAuthError as e:
            # OAuth errors return 400 (client error, not server error)
            logger.warning(
                f"OAuth callback failed for {idp_name}: {e.error}",
                extra={"idp": idp_name, "error": e.error, "description": e.description}
            )
            return jsonify({
                "error": e.error,
                "error_description": e.description
            }), 400
            
        except ValueError as e:
            # Claims parsing errors
            logger.warning(
                f"Claims parsing error for {idp_name}: {str(e)}",
                extra={"idp": idp_name}
            )
            return jsonify({
                "error": "invalid_grant",
                "error_description": "Invalid or malformed token claims"
            }), 400
            
        except Exception as e:
            # Unexpected errors return 500
            logger.error(
                f"Callback processing error for {idp_name}: {str(e)}",
                extra={"idp": idp_name},
                exc_info=True
            )
            return jsonify({
                "error": "server_error",
                "error_description": "Internal server error during OAuth callback"
            }), 500


# Flask route handlers for OAuth callbacks

@oauth_bp.route("/<idp>/login/", methods=["GET"])
def oauth_callback(idp):
    """
    Handle OAuth2 callback from identity provider.
    
    Query params:
        code: Authorization code from provider
        state: State parameter for CSRF protection
        error: Error code if authorization failed
        
    Returns:
        Redirect to dashboard or error response
    """
    # Check for authorization errors from provider
    if request.args.get("error"):
        error = request.args.get("error")
        description = request.args.get("error_description", "")
        logger.warning(
            f"Authorization request denied by {idp}: {error}",
            extra={"idp": idp, "error": error}
        )
        return jsonify({
            "error": error,
            "error_description": description or "Authorization denied by provider"
        }), 400
    
    # Get or initialize OAuth client for this provider
    idp_client = get_oauth_client(idp)
    if not idp_client:
        logger.error(f"OAuth client not configured for {idp}")
        return jsonify({
            "error": "server_error",
            "error_description": f"Identity provider {idp} is not configured"
        }), 500
    
    # Handle callback
    return OAuthCallbackHandler.handle_callback(idp, idp_client)


@oauth_bp.route("/<idp>/authorize/", methods=["GET"])
def oauth_authorize(idp):
    """
    Initiate OAuth2 authorization request.
    
    Query params:
        next: URL to redirect to after successful login
        
    Returns:
        Redirect to provider's authorization endpoint
    """
    idp_client = get_oauth_client(idp)
    if not idp_client:
        return jsonify({
            "error": "server_error",
            "error_description": f"Identity provider {idp} is not configured"
        }), 500
    
    next_url = request.args.get("next", "/dashboard")
    
    # Generate state for CSRF protection
    state = idp_client.generate_state()
    state_key = f"oauth_state_{idp}"
    session[state_key] = state
    
    # Build authorization URL
    auth_url = idp_client.get_authorization_url(state=state)
    
    logger.debug(f"Initiating OAuth for {idp}")
    return redirect(auth_url)


def get_oauth_client(idp):
    """
    Get or create OAuth2 client for the given identity provider.
    
    Args:
        idp: Identity provider name
        
    Returns:
        OAuth2IdentityProvider instance or None if not configured
    """
    idp_config = current_app.config.get("OPENID_CONNECT", {}).get(idp)
    if not idp_config:
        return None
    
    client = OAuth2IdentityProvider(
        idp=idp,
        client_id=idp_config.get("client_id"),
        client_secret=idp_config.get("client_secret"),
        token_url=idp_config.get("token_url"),
    )
    return client


# Initialize OAuth clients cache
_oauth_clients = {}
