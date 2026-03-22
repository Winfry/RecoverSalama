"""
USSD Main Menu — Phase 6 (Weeks 13-16).

The full USSD logic is implemented in:
    backend/app/services/channels/ussd_service.py

This file exists so the ussd/ directory in the project structure
has a clear entry point. It re-exports the backend's USSD service
to avoid code duplication.
"""

# The USSDService class handles the full menu tree:
# *384*SALAMA# →
#   1. Check-In ya Leo → pain → symptoms → risk assessment
#   2. Ushauri wa Mlo → days since surgery → diet recommendations
#   3. Piga Simu Hospitali → emergency numbers
#   4. Msaada → help text

# To use: from ussd.menus.main_menu import USSDService
# Or directly: from backend.app.services.channels.ussd_service import USSDService
