"""
Webhook routes — handles incoming messages from WhatsApp and USSD.

Africa's Talking sends HTTP POST requests to these endpoints when:
- A patient sends a WhatsApp message
- A patient dials the USSD short code (*384*SALAMA#)

The webhook receives the message, processes it through the same
AI/ML pipeline as the Flutter app, and sends a response back
through the same channel.

This is how SalamaRecover serves patients WITHOUT smartphones.
"""

from fastapi import APIRouter, Request

from app.services.channels.whatsapp_service import WhatsAppService
from app.services.channels.ussd_service import USSDService

router = APIRouter()
whatsapp = WhatsAppService()
ussd = USSDService()


@router.post("/whatsapp")
async def whatsapp_webhook(request: Request):
    """
    Receives WhatsApp messages via Africa's Talking.
    Processes them through the AI pipeline and responds in
    the same language (English or Kiswahili).
    """
    form_data = await request.form()
    phone = form_data.get("from", "")
    message = form_data.get("text", "")

    response = await whatsapp.handle_message(phone=phone, message=message)
    return {"status": "processed", "response": response}


@router.post("/ussd")
async def ussd_webhook(request: Request):
    """
    Receives USSD session data via Africa's Talking.
    Returns menu text for feature phone users.

    USSD is menu-based (not free text), so responses are
    rule-based rather than LLM-powered.
    """
    form_data = await request.form()
    session_id = form_data.get("sessionId", "")
    phone = form_data.get("phoneNumber", "")
    text = form_data.get("text", "")

    response = ussd.handle_session(
        session_id=session_id,
        phone=phone,
        text=text,
    )
    return response
