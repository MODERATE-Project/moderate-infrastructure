import importlib
import json

import moderatecli.kc.data


def read_data(name):
    json_text = importlib.resources.read_text(moderatecli.kc.data, name)
    return json.loads(json_text)
