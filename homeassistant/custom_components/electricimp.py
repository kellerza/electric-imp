"""
Electric Imp.

Custom Electric Imp platform
"""

import logging
import requests
from time import sleep

from homeassistant.helpers.discovery import load_platform
from homeassistant.components.light import Light
from homeassistant.components.switch import SwitchDevice
from homeassistant.components.binary_sensor import BinarySensorDevice
from homeassistant.helpers.entity import Entity
from homeassistant.helpers.event import track_utc_time_change
from homeassistant.const import EVENT_HOMEASSISTANT_START

_LOGGER = logging.getLogger(__name__)
# logger:
#     custom_components.electricimp: debug

DOMAIN = 'electricimp'

IMPURL = 'https://agent.electricimp.com/{}/all_values'


def push_obj(obj):
    """Save an object to be retrieved later."""
    import homeassistant.components.qwikswitch as qwikswitch
    oid = id(obj)
    qwikswitch.QSUSB[oid] = obj
    return oid


class ImpSet(object):
    """Write to imp url."""

    def __init__(self, url, name, prop_name, val):
        """Initialize the ToggleEntity."""
        self.url = url
        self._name = name
        self._prop_name = prop_name
        self._value = val

    def imp_set(self, value):
        """Write to imp url."""
        if value != self._value:
            result = requests.post(self.url, {self._prop_name: value})
            if result.status_code == 200:
                _LOGGER.debug('imp_set %s = %s [200]', self._name, value)
                self.update_value(value)
            else:
                _LOGGER.warning('imp_set %s failed [%s] %s \n%s', self._name,
                                result.status_code, result.text, self.url)

    # pylint: disable=no-self-use
    @property
    def should_poll(self):
        """State Polling needed."""
        return False

    @property
    def name(self):
        """Return the name of the light."""
        return self._name

    @property
    def is_on(self):
        """Check if On (non-zero)."""
        return self._value > 0

    def update_value(self, value):
        """Update HA state."""
        if (value > 0) != self._value:
            self._value = (value > 0)
            _LOGGER.debug("update_value %s = %s", self._name, self._value)
            # pylint: disable=no-member
            super().update_ha_state()  # Part of Entity/ToggleEntity

    # pylint: disable=unused-argument
    def turn_on(self, **kwargs):
        """Turn the device on."""
        self.imp_set(180)

    # pylint: disable=unused-argument
    def turn_off(self, **kwargs):
        """Turn the device off."""
        self.imp_set(0)


class ImpLight(ImpSet, Light):
    """Imp Light."""

    pass


class ImpSwitch(ImpSet, SwitchDevice):
    """Imp Light."""

    pass


class ImpBinarySensor(ImpSet, BinarySensorDevice):
    """Imp Light."""

    @property
    def sensor_class(self):
        """Return correct class."""
        if 'oor' in self._name:
            return 'opening'
        if 'imp' in self._name:
            return 'connectivity'
        return None


class ImpSensor(ImpSet, Entity):
    """Imp Light."""

    @property
    def state(self):
        """Return the state of the sensor."""
        return self._value


def get_json(agent_ids):
    """Get json."""
    res = {}
    for agent_id in agent_ids:
        try:
            response = requests.get(IMPURL.format(agent_id)).json()
            for key, val in response.items():
                res['{}@{}'.format(key, agent_id)] = val
        except ValueError as err:
            _LOGGER.warning('Agent %s did not return any values: %s',
                            agent_id, str(err))
    return res


# pylint: disable=too-many-locals
def setup(hass, config):
    """Setup the QSUSB component."""
    agent_ids = config[DOMAIN].get('agent_id')
    _LOGGER.debug('AgentIDs: %s', ', '.join(agent_ids))

    defs = {'light': (ImpLight, 'light'),
            'switch': (ImpSwitch, 'switch'),
            'binarysensor': (ImpBinarySensor, 'binary_sensor'),
            'sensor': (ImpSensor, 'sensor')}

    all_devices = {}

    def imp_discover(json):
        """Discover new devices."""
        dev_per_domain = {}
        for key, val in json.items():
            if key in all_devices:
                continue
            prop_name, _, agent_id = key.partition('@')
            imp_domain, _, display_name = prop_name.partition('_')
            if imp_domain not in defs:
                continue
            cls, hass_domain = defs[imp_domain]

            url = IMPURL.format(agent_id)

            all_devices[key] = cls(url, display_name, prop_name, val)

            # Store in dev per domain... used to add_devices
            if not hass_domain in dev_per_domain:
                dev_per_domain[hass_domain] = []

            dev_per_domain[hass_domain].append(all_devices[key])

        for dom in dev_per_domain:
            dev_per_domain[dom] = push_obj(dev_per_domain[dom])

        for dom in dev_per_domain:
            sleep(2)
            load_platform(hass, dom, 'generic',
                          {'domain': dom.title(),
                           'add_devices': dev_per_domain[dom]})

    def imp_timer(event):  # pylint: disable=unused-argument
        """Query the agents."""
        json = get_json(agent_ids)
        imp_discover(json)
        for key, val in json.items():
            if key in all_devices:
                try:
                    all_devices[key].update_value(val)
                except RuntimeError as err:
                    # add_devices not called yet
                    _LOGGER.error('Cannot update device: %s', str(err))

    def imp_start(event):
        sleep(1)
        json = get_json(agent_ids)
        imp_discover(json)
        track_utc_time_change(hass, imp_timer, second=[20, 50])

    hass.bus.listen_once(EVENT_HOMEASSISTANT_START, imp_start)
    

    return True
