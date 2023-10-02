import re
from collections.abc import Mapping
from typing import List


def dict_deep_merge(dct, merge_dct):
    dct = dct.copy()

    for k, _ in merge_dct.items():
        if k in dct and isinstance(dct[k], dict) and isinstance(merge_dct[k], Mapping):
            dct[k] = dict_deep_merge(dct[k], merge_dct[k])
        else:
            dct[k] = merge_dct[k]

    return dct


def join_url_parts(*args: List[str]) -> str:
    return "/".join(map(lambda x: str(x).rstrip("/"), args))


def slugify(*args: List[str]) -> str:
    return re.sub(r"[^\w\s-]", "", "-".join(args))


def snake_case(*args: List[str]) -> str:
    return "_".join(map(lambda x: str(x).lower().strip(), args))
