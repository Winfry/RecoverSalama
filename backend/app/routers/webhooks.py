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
from fastapi.responses import PlainTextResponse

from app.services.channels.whatsapp_service import WhatsAppService
from app.services.channels.ussd_service import USSDService

router = APIRouter()
whatsapp = WhatsAppService()
ussd = USSDService()


@router.post("/whatsapp")
async def whatsapp_webhook(request: Request):
    """
    Receives WhatsApp messages via Africa's Talking or Twilio.
    AT uses: from, text
    Twilio uses: From, Body
    We handle both.
    """
    form_data = await request.form()

    # Africa's Talking format
    phone = form_data.get("from", "")
    message = form_data.get("text", "")

    # Twilio format (overrides AT if present)
    if not phone:
        phone = form_data.get("From", "")
    if not message:
        message = form_data.get("Body", "")

    # Twilio phone comes as "whatsapp:+254..." — strip the prefix
    if phone.startswith("whatsapp:"):
        phone = phone.replace("whatsapp:", "")

    if not message:
        return {"status": "ignored", "reason": "empty message"}

    reply = await whatsapp.handle_incoming(phone=phone, message=message)

    # Twilio expects TwiML XML response to send a reply
    # AT expects JSON
    if form_data.get("From", "").startswith("whatsapp:"):
        # Twilio — return TwiML
        twiml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Message>{reply}</Message>
</Response>"""
        from fastapi.responses import Response
        return Response(content=twiml, media_type="application/xml")

    # Africa's Talking — return JSON
    return {"status": "processed", "response": reply}


@router.post("/ussd")
async def ussd_webhook(request: Request):
    """
    Receives USSD session data via Africa's Talking.
    Returns menu text for feature phone users.

    USSD is menu-based (not free text), so responses are
    rule-based rather than LLM-powered.
    """
    from app.services.alert_service import AlertService

    form_data = await request.form()
    session_id = form_data.get("sessionId", "")
    phone = form_data.get("phoneNumber", "")
    text = form_data.get("text", "")

    response = ussd.handle_session(
        session_id=session_id,
        phone=phone,
        text=text,
    )

    # Fire alert if the sync handler queued one (avoids asyncio.create_task in sync context)
    if ussd._pending_alert:
        alert_kwargs = ussd._pending_alert
        ussd._pending_alert = None
        try:
            await AlertService().process_checkin(**alert_kwargs)
        except Exception:
            pass

    # AT requires plain text response — not JSON
    return PlainTextResponse(content=response, media_type="text/plain")
