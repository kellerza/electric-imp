"""Generic platform."""
import logging

_LOGGER = logging.getLogger(__name__)


def setup_platform(hass, config, add_devices, discovery_info=None): \
        # pylint: disable=unused-argument
    """Generic platform component."""
    domain = __name__.split('.')[-2]
    add_dev_key = discovery_info.get('add_devices')
    if not isinstance(add_dev_key, str):
        _LOGGER.error(
            'No devices added: Expected discovery_info["add_devices"]')
        return False
    try:
        devices = hass.data.pop(add_dev_key)
    except KeyError:
        _LOGGER.error('No devices added: Expected hass.data["%s"]',
                      add_dev_key)
        return False
    _LOGGER.info('Added %s %s', len(devices), domain)
    add_devices(devices)
    return True
