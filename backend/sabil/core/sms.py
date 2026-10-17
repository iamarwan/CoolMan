# core/sms.py
#
# Sending a text message. The rest of the app only calls
#
#       await get_sms_sender().send("+201012345678", "your text")
#
# and does not care which company delivers it. To add a real provider:
#
#   1. Write a class with an `async def send(self, phone: str, text: str) -> None`
#      that calls the provider's API (raise an exception if it fails).
#   2. Add it to SENDERS below, e.g.  SENDERS = {"console": ConsoleSmsSender, "myprovider": MyProvider}
#   3. Start the server with SABIL_SMS_PROVIDER=myprovider (and the provider's own
#      keys, read in your class from environment variables, never from the code).
#
# Which provider to use (and what it costs per SMS in Egypt) is still to be decided.

import logging
from typing import Optional, Protocol

from sabil.core.config import SMS_PROVIDER


class SmsSender(Protocol):
    async def send(self, phone: str, text: str) -> None: ...


class ConsoleSmsSender:
    """Development only: prints the message in the server log instead of sending it."""

    async def send(self, phone: str, text: str) -> None:
        logging.getLogger("sabil.sms").warning("SMS to %s: %s", phone, text)


SENDERS: dict[str, type] = {"console": ConsoleSmsSender}

# Tests put a fake sender here so they can read the code that "was sent".
_override: Optional[SmsSender] = None


def set_sms_sender(sender: Optional[SmsSender]) -> None:
    global _override
    _override = sender


def phone_login_enabled() -> bool:
    return _override is not None or SMS_PROVIDER in SENDERS


def get_sms_sender() -> SmsSender:
    if _override is not None:
        return _override
    return SENDERS[SMS_PROVIDER]()
