"""Generic platform."""
import logging
from time import sleep
_LOGGER = logging.getLogger(__name__)


def pop_obj(oid):
    """Pop an Object by ID."""
    import homeassistant.components.qwikswitch as qwikswitch
    return qwikswitch.QSUSB.pop(oid)


# pylint: disable=unused-argument
def setup_platform(hass, config, add_devices, discovery_info=None):
    """Generic platform component."""
    if 'add_devices' in discovery_info:
        devices = pop_obj(discovery_info['add_devices'])
        domain = discovery_info.get('domain', '')
        _LOGGER.warning('Added %s %s', str(len(devices)), domain)
        add_devices(devices)
        sleep(len(devices))
        return True
    _LOGGER.error('No devices to add: %s', discovery_info.get('domain', ''))
    return False
