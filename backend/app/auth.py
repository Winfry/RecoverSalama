"""
Authentication middleware — validates Supabase JWT tokens.

Every protected route uses `Depends(get_current_user)` to extract
the authenticated user from the Authorization header.

The Flutter app and React dashboard send:
    Authorization: Bearer <supabase-access-token>

This middleware validates the token against Supabase and returns
the user's ID and metadata.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.database import get_supabase_client

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Extract and validate the Supabase JWT from the Authorization header.
    Returns a dict with the user's id, email, and phone.
    """
    token = credentials.credentials

    try:
        db = get_supabase_client()
        user_response = db.auth.get_user(token)
        user = user_response.user

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )

        return {
            "id": user.id,
            "email": user.email or "",
            "phone": user.phone or "",
        }

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )


async def get_patient_id(user: dict = Depends(get_current_user)) -> str:
    """
    Convenience dependency: looks up the patient record for the current user.
    Returns the patient_id (UUID) so routes don't need to accept it from the client.
    """
    db = get_supabase_client()
    result = (
        db.table("patients")
        .select("id")
        .eq("user_id", user["id"])
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No patient profile found. Please complete profile setup first.",
        )

    return result.data[0]["id"]
